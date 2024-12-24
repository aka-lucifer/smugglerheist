local config = require "config.server"
local sharedConfig = require "config.shared"

local vehicle = {
    cargoHandle = nil,
    pilotHandle = nil,
    planeHandle = nil,
    warningsRecieved = 0,
    dispatchedJets = false,
    spawnedJets = {},
    crates = {}
}

GlobalState["echo_smugglerheist:hackingSystem"] = false
GlobalState["echo_smugglerheist:hacked"] = false
GlobalState["echo_smugglerheist:bombed"] = false
GlobalState['echo_smugglerheist:cratesOpened'] = 0

--- Returns a random value between negative and positive of the provided int
---@param randomInt integer Field to get a random value from 
---@return integer
local function randomOffset(randomInt)
    return math.random(math.abs(randomInt)*-1, randomInt)
end

--- Registers the vehicle server callbacks
function vehicle.init()
    lib.callback.register('echo_smugglerheist:hackPlane', function(source)
        if not GlobalState["echo_smugglerheist:started"] then return false, locale("error.mission_not_active") end
        if GlobalState["echo_smugglerheist:hacked"] then return false, locale("error.already_hacked") end
        if GlobalState["echo_smugglerheist:hackingSystem"] then return false, locale("error.being_hacked") end

        local src = source --[[@as number]]
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return false, locale("error.no_player") end

        GlobalState["echo_smugglerheist:hackingSystem"] = true
        return true
    end)

    for i = 1, #sharedConfig.bombPlacementOffsets do
        GlobalState[string.format("echo_smugglerheist:bombPlaced:%s", i)] = false
    end
end

-- Reset the statebags for the heist
function vehicle.finish()
    vehicle.deleteCargo(true)
    vehicle.deleteJets()
    vehicle.warningsRecieved = 0
    vehicle.dispatchedJets = false
    GlobalState["echo_smugglerheist:hackingSystem"] = false
    GlobalState["echo_smugglerheist:hacked"] = false
    GlobalState["echo_smugglerheist:bombed"] = false
    GlobalState['echo_smugglerheist:cratesOpened'] = 0
end

---@return boolean
function vehicle.cargoExists()
    return vehicle.cargoHandle and DoesEntityExist(vehicle.cargoHandle) -- Checks if variable is defined and entity exists on server
end

---@return boolean
function vehicle.pilotExists()
    return vehicle.pilotHandle and DoesEntityExist(vehicle.pilotHandle) -- Checks if variable is defined and entity exists on server
end

---@return boolean
function vehicle.planeExists()
    return vehicle.planeHandle and DoesEntityExist(vehicle.planeHandle) -- Checks if variable is defined and entity exists on server
end

--- Delete cargoplane, pilot and mission plane if exists
---@param deleteMission? boolean Whether or not to delete the mission plane too
function vehicle.deleteCargo(deleteMission)
    if vehicle.cargoExists() then -- Make sure the cargoplane actually exists
        DeleteEntity(vehicle.cargoHandle) -- Delete entity
        vehicle.cargoHandle = nil -- Set cargoplane variable to null
    end

    if vehicle.pilotExists() then -- Make sure the pilot actually exists
        DeleteEntity(vehicle.pilotHandle) -- Delete entity
        vehicle.pilotHandle = nil -- Set pilot variable to null
    end

    if not deleteMission then return end
    if vehicle.planeExists() then -- Make sure the plane actually exists
        DeleteEntity(vehicle.planeHandle) -- Delete entity
        vehicle.planeHandle = nil -- Set plane variable to null
    end
end

--- Create cargoplane
function vehicle.createCargo()
    if vehicle.cargoExists() then -- If the plane already exists delete it for whatever case
        vehicle.deleteCargo()
    end

    local entity = CreateVehicleServerSetter(`cargoplane`, "plane", config.cargoSpawn.x, config.cargoSpawn.y, config.cargoSpawn.z, config.cargoSpawn.w)
    while not DoesEntityExist(entity) do Wait(0) end
   
    SetEntityDistanceCullingRadius(entity, 999999.0) -- Have to handle it this way so it will be in scope all over the map as RPC for seating ped in vehicle is broken asf
    
    local ped = CreatePed(1, `s_m_y_pilot_01`, config.cargoSpawn.x, config.cargoSpawn.y, config.cargoSpawn.z, config.cargoSpawn.w, true, false)
    SetEntityDistanceCullingRadius(ped, 999999.0) -- Have to handle it this way so it will be in scope all over the map as RPC for seating ped in vehicle is broken asf

    vehicle.cargoHandle = entity
    vehicle.pilotHandle = ped

    Entity(entity).state:set("heistCargoPlane", {
        pilotNet = NetworkGetNetworkIdFromEntity(ped)
    })
end

--- Create plane for players to use to follow the cargoplane
---@param source integer
function vehicle.createPlane(source)
    if not vehicle.cargoExists then return end
    local ped = GetPlayerPed(source)
    local currentVehicle = GetVehiclePedIsIn(ped, false)
    if currentVehicle and currentVehicle ~= 0 then
        exports.qbx_core:DeleteVehicle(currentVehicle)
    end

    local netId, entity = qbx.spawnVehicle({
        model = config.missionPlane.model,
        spawnSource = config.missionPlane.coords,
    })

    Entity(entity).state:set('doorslockstate', 1, true)
    exports.qbx_vehiclekeys:GiveKeys(source, entity)
    

    vehicle.planeHandle = entity
    TriggerClientEvent("echo_smugglerheist:client:createdPlane", -1, netId)
end

-- Handle deleting jets if mission plane is destroyed
function vehicle.deleteJets()
    for _, jet in pairs(vehicle.spawnedJets) do
        if DoesEntityExist(jet) then
            DeleteEntity(jet)
        end
    end
    
    vehicle.spawnedJets = {}
end

-- Task for checking if mission plane has been destroyed by jets
function vehicle.startDestroyedTask()
    if not vehicle.planeExists() then return end
    CreateThread(function()
        while vehicle.planeHandle and DoesEntityExist(vehicle.planeHandle) and GetVehicleEngineHealth(vehicle.planeHandle) > 0 do
            lib.print.info("Running mission plane destroyed detection task")
            Wait(config.missionPlane.taskInterval)
        end

        if vehicle.planeHandle and DoesEntityExist(vehicle.planeHandle) and GetVehicleEngineHealth(vehicle.planeHandle) <= 0.0 then
            lib.print.info("Mission plane destroyed, delete jets")
            vehicle.deleteJets()
        end
    end)
end

--- Create jets and send to client for handling attack logic
function vehicle.dispatchJets()
    if not vehicle.cargoExists() then return end
    if not vehicle.planeExists() then return end
    local cargoPlaneHeading = GetEntityHeading(vehicle.cargoHandle)

    for i = 1, config.jetCount do
        local coords = GetOffsetFromEntityInWorldCoords(
            vehicle.cargoHandle,
            randomOffset(config.jetSpawnOffset),
            -800.0,
            30.0
        )
        
        local entity = CreateVehicleServerSetter(`lazer`, "plane", coords.x, coords.y, coords.z, cargoPlaneHeading)
        while not DoesEntityExist(entity) do Wait(0) end
    
        SetEntityDistanceCullingRadius(entity, 999999.0) -- Have to handle it this way so it will be in scope all over the map as RPC for seating ped in vehicle is broken asf

        local ped = CreatePed(1, `s_m_y_pilot_01`, coords.x, coords.y, coords.z, cargoPlaneHeading, true, false)
        if ped and DoesEntityExist(ped) then
            Entity(ped).state:set("jetPlaneDriver", true, true)
        end
        SetEntityDistanceCullingRadius(ped, 999999.0) -- Have to handle it this way so it will be in scope all over the map as RPC for seating ped in vehicle is broken asf
        
        Entity(entity).state:set("cargoPlaneJet", {
            pilotNet = NetworkGetNetworkIdFromEntity(ped),
            targetNet = NetworkGetNetworkIdFromEntity(vehicle.planeHandle)
        })

        table.insert(vehicle.spawnedJets, entity)
    end

    vehicle.startDestroyedTask()
end

--- Creates the task of handling if you"re too close or too high above the cargoplane
function vehicle.startDistTask()
    if not vehicle.cargoExists() or not vehicle.planeExists() then return end

    CreateThread(function()
        while (vehicle.cargoExists() and vehicle.planeExists()) and not vehicle.dispatchedJets do
            if GlobalState["echo_smugglerheist:hacked"] then
                lib.print.info("Disabling jet dispatcher task")
                vehicle.deleteJets() -- Delete jets if they exist
                return -- Destroy the thread
            end

            lib.print.info("Running interval on jet task | Warnings: " .. vehicle.warningsRecieved)

            local cargoCoords = GetEntityCoords(vehicle.cargoHandle, false)
            local planeCoords = GetEntityCoords(vehicle.planeHandle, false)
            local dist = #(cargoCoords - planeCoords)
            local heightDifference = planeCoords.z - cargoCoords.z
            -- lib.print.info(("Distance: %s | Height: %s"):format(dist, heightDifference))

            if (dist < config.distanceThreshold) or (dist < config.height.distance and heightDifference > config.height.threshold) then
                -- lib.print.warn("TOO CLOSE OR HIGH")
                vehicle.warningsRecieved += 1
                if vehicle.warningsRecieved >= config.warningCount then
                    lib.print.info("Too many warnings recieved, dispatching jets")
                    vehicle.dispatchedJets = true
                    vehicle.dispatchJets()
                    return
                end

                for i = -1, config.planeSeats - 2 do
                    local ped = GetPedInVehicleSeat(vehicle.planeHandle, i)
                    if ped > 0 then
                        local pedOwner = NetworkGetEntityOwner(ped)
                        if pedOwner > 0 then
                            lib.notify(pedOwner, {
                                description = "You\"re flying too close/high, back off or jets will be dispatched!",
                                type = "error",
                                duration = 5000,
                                sound = {
                                    name = "Out_Of_Bounds_Timer",
                                    set = "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS"
                                }
                            })
                        end
                    end
                end

                Wait(3000)
            else
                if config.resetWarnings and vehicle.warningsRecieved > 0 then
                    lib.print.info("No longer close or high enough, resetting warnings recieved")
                    vehicle.warningsRecieved = 0
                end
            end

            Wait(config.jetTaskInterval)
        end
    end)
end

--- Create cargoplane crate globalstates
function vehicle.setupCrates()
    for i = 1, sharedConfig.crateCount do
        GlobalState[string.format("echo_smugglerheist:crate:%s:opened", i)] = false
    end
end

--- Cleanup cargoplane crate globalstates
function vehicle.cleanupCrates()
    for i = 1, sharedConfig.crateCount do
        GlobalState[string.format("echo_smugglerheist:crate:%s:opened", i)] = nil
    end
end

---@param success boolean Was the hack successful
RegisterNetEvent("echo_smugglerheist:server:attemptedHack", function(success)
    if not GlobalState["echo_smugglerheist:started"] then return end
    if GlobalState["echo_smugglerheist:hacked"] then return end
    if not GlobalState["echo_smugglerheist:hackingSystem"] then return end

    local src = source --[[@as number]]
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local playerPed = GetPlayerPed(src)
    local playerVeh = GetVehiclePedIsIn(playerPed, false)
    if playerVeh ~= vehicle.planeHandle then return end
    
    local vehCoords = GetEntityCoords(playerVeh, false)
    local cargoCoords = GetEntityCoords(vehicle.cargoHandle, false)
    if #(vehCoords - cargoCoords) > sharedConfig.hackDistance then return end

    GlobalState["echo_smugglerheist:hackingSystem"] = false
    if success then
        GlobalState["echo_smugglerheist:hacked"] = true
        TriggerClientEvent("echo_smugglerheist:client:hackedPlane", -1, NetworkGetNetworkIdFromEntity(vehicle.cargoHandle))
        TriggerClientEvent("echo_smugglerheist:client:sentNotify", src, locale('task.plant_bombs'))
    end
end)

---@param vehicleNet integer
---@param bombIndex integer
RegisterNetEvent("echo_smugglerheist:server:bombedPlane", function(vehicleNet, bombIndex)
    if not bombIndex or type(bombIndex) ~= "number" then return end
    if not GlobalState["echo_smugglerheist:started"] then return end
    if not GlobalState["echo_smugglerheist:hacked"] then return end
    if GlobalState[string.format("echo_smugglerheist:bombPlaced:%s", bombIndex)] then return end
    if vehicleNet ~= NetworkGetNetworkIdFromEntity(vehicle.cargoHandle) then return end

    local src = source --[[@as number]]
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    GlobalState[string.format("echo_smugglerheist:bombPlaced:%s", bombIndex)] = true
    if bombIndex == #sharedConfig.bombPlacementOffsets then -- Bombed both engines
        print("bombed plane")
        GlobalState["echo_smugglerheist:bombed"] = true
        local cargoCoords = GetEntityCoords(vehicle.cargoHandle)
        print("start crate drop")

        local cratePositions = lib.callback.await("echo_smugglerheist:getCratePositions", src, cargoCoords, sharedConfig.crateCount)
        if not cratePositions then return end
        
        if sharedConfig.debug then
            print("crate positions", json.encode(cratePositions, { indent = true }))
        end

        vehicle.setupCrates()
        TriggerClientEvent("echo_smugglerheist:client:cargoCrashed", -1, cargoCoords, cratePositions)
    end
end)

---@param crateIndex integer
RegisterNetEvent("echo_smugglerheist:server:openedCrate", function(crateIndex)
    if not crateIndex or type(crateIndex) ~= "number" then return end
    if not GlobalState["echo_smugglerheist:started"] then return end
    if not GlobalState["echo_smugglerheist:hacked"] then return end
    if not GlobalState["echo_smugglerheist:bombed"] then return end

    local src = source --[[@as number]]
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    -- Use this to prevent open crate spam/possible exploit
    if mission.openingCrate then return end
    mission.openingCrate = true
    
    GlobalState[string.format("echo_smugglerheist:crate:%s:opened", crateIndex)] = nil

    -- Probably could change this up a bit, but not exactly bad or broken
    for i = 1, #config.crateItems do
        exports.ox_inventory:AddItem(src, config.crateItems[i].item, config.crateItems[i].amount)
        mission.itemsGiven[config.crateItems[i].item] = config.crateItems[i].amount
    end
    -- Probably could change this up a bit, but not exactly bad or broken

    TriggerClientEvent("echo_smugglerheist:client:openedCrate", -1, crateIndex)
    mission.openingCrate = false
    GlobalState['echo_smugglerheist:cratesOpened'] += 1

    if GlobalState['echo_smugglerheist:cratesOpened'] == sharedConfig.crateCount then -- opened all crates
        TriggerClientEvent("echo_smugglerheist:client:openedCrates", -1)
    end
end)

return vehicle