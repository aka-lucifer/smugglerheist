local config = require "config.server"

local vehicle = {
    cargoHandle = nil,
    pilotHandle = nil,
    planeHandle = nil,
    warningsRecieved = 0,
    dispatchedJets = false,
    spawnedJets = {},
    openingCrate = false
}

--- Returns a random value between negative and positive of the provided int
---@param randomInt integer Field to get a random value from 
---@return integer
local function randomOffset(randomInt)
    return math.random(math.abs(randomInt)*-1, randomInt)
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

--- Delete cargoplane and mission plane if exists
function vehicle.deleteCargo()
    if vehicle.cargoExists() then -- Make sure the cargoplane actually exists
        DeleteEntity(vehicle.cargoHandle) -- Delete entity
        vehicle.cargoHandle = nil -- Set cargoplane variable to null
    end

    if vehicle.pilotExists() then -- Make sure the pilot actually exists
        DeleteEntity(vehicle.pilotHandle) -- Delete entity
        vehicle.pilotHandle = nil -- Set pilot variable to null
    end

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

---@param crateIndex integer
RegisterNetEvent("echo_smugglerheist:server:openCrate", function(crateIndex)
    if not crateIndex or type(crateIndex) ~= "number" then return end
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    -- Use this to prevent open crate spam/possible exploit
    if vehicle.openingCrate then return end
    vehicle.openingCrate = true

    player.Functions.AddMoney("cash", math.random(1000, 2000), "echo_smugglerheist - open crate") -- replace with item
    TriggerClientEvent("echo_smugglerheist:client:openCrate", -1, crateIndex)
    vehicle.openingCrate = false
end)

print("height", -15.0 < -20.0)

return vehicle