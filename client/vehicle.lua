local config = require 'config.client'
local sharedConfig = require 'config.shared'
local metersPerSecondConversion = 0.44704
local showingHack = false
local hackingPlane = false
local crashBlip = nil
local vehicle = {
    cargoNet = nil,
    planeNet = nil,
    crates = {}
}

--- Get groundZ coord at passed x & y coordinates (credit qbox core)
---@param coords vector3
---@return boolean, number
local function getGroundCoord(coords) -- Credit qbx_core
    local x, y, groundZ, Z_START = coords.x, coords.y, 850.0, 950.0
    local found = false

    for i = Z_START, 0, -25.0 do
        local z = i
        if (i % 2) ~= 0 then
            z = Z_START - i
        end

        -- Get ground coord. As mentioned in the natives, this only works if the client is in render distance.
        found, groundZ = GetGroundZFor_3dCoord(x, y, z, false);
        if found then
            return true, groundZ
        end
        Wait(0)
    end

    return false, -1
end

--- Register the vehicle client callbacks
function vehicle.init()
    
    ---@param cargoCoords vector3
    ---@param crateCount integer
    lib.callback.register("echo_smugglerheist:getCratePositions", function(cargoCoords, crateCount)
        if not cargoCoords or type(cargoCoords) ~= "vector3" then return end
        if not crateCount or type(crateCount) ~= "number" then return end
        
        local offsets = {}

        for i = 1, crateCount do
            local offsetCoords = vector3(
                cargoCoords.x + math.random(config.crateOffset.min, config.crateOffset.max),
                cargoCoords.y + math.random(config.crateOffset.min, config.crateOffset.max),
                cargoCoords.z + config.crateHeight
            )
            
            table.insert(offsets, offsetCoords)
        end

        return offsets
    end)
end

--- Converts MPH to meters per second.
---@param mph number -- Speed in MPH
---@return number
function vehicle.convertSpeed(mph)
    return math.round((mph * metersPerSecondConversion), 1)
end

--- Applies to logic to make the plane head to the deliver cargo coords
---@param driver integer
---@param planeEntity integer
---@param speed number
function vehicle.headToDestination(driver, planeEntity, speed)
    if not driver or not DoesEntityExist(driver) then return end

    if not planeEntity or not DoesEntityExist(planeEntity) then return end

    TaskPlaneMission( -- Make the plane fly to coords
        driver,
        planeEntity,
        0,
        0,
        config.cargoDestination.x,
        config.cargoDestination.y,
        config.cargoDestination.z,
        4,
        vehicle.convertSpeed(speed), -- Speed (meters per second)
        0.0,
        150.0,
        600.0, -- Max height
        580.0, -- Min height
        1
    )

    SetVehicleForwardSpeed(planeEntity, vehicle.convertSpeed(speed)) -- Stops the freefall and makes it fly from current position
end

--- Make a blip for the passed entity with the provided fields
---@param entity integer
---@param blipData BlipData
function vehicle.makeBlip(entity, blipData)
    local blip = AddBlipForEntity(entity)
    SetBlipSprite(blip, blipData.sprite)
    SetBlipColour(blip, blipData.colour)
    SetBlipRotation(blip, GetEntityHeading(entity))
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipData.name)
    EndTextCommandSetBlipName(blip)
end

--- Starts up plane
---@param pilot integer
---@param vehicle integer
function vehicle.startUp(pilot, vehicle)
    SetPedIntoVehicle(pilot, vehicle, -1) -- Forces ped into driver seat as server side not working
    ControlLandingGear(vehicle, 3) -- Put landing gear away
    SetVehicleEngineOn(vehicle, true, true, false) -- Force engine on
end

--- Start hacking the plane
function vehicle.hackPlane()
    if showingHack then
        showingHack = false
        lib.hideTextUI()
    end

    CreateThread(function()
        hackingPlane = true
        -- local success = exports.fallouthacking:start(math.random(6, 8), 5)
        local success = true
        TriggerServerEvent("echo_smugglerheist:server:attemptedHack", success)
        hackingPlane = false
    end)
end

---@param entity integer The mission plane entity
function vehicle.startHackTask(entity)
    CreateThread(function()
        while DoesEntityExist(entity) and not GlobalState["echo_smugglerheist:hacked"] do
            local sleep = 5000 -- Can have it sleep 5 seconds because entity should well exist by then and you have to travel to plane anyway
            if vehicle.cargoNet and NetworkDoesEntityExistWithNetworkId(vehicle.cargoNet) then
                sleep = 1000
                if cache.vehicle and cache.vehicle == entity then
                    local missionCoords = GetEntityCoords(entity, false)
                    local cargoPlane = NetworkGetEntityFromNetworkId(vehicle.cargoNet)
                    local cargoCoords = GetEntityCoords(cargoPlane, false)
                    local dist = #(missionCoords - cargoCoords)
                    if dist <= sharedConfig.hackDistance then
                        if not GlobalState["echo_smugglerheist:hackingSystem"] then
                            sleep = 5
                            if not showingHack then
                                showingHack = true
                                lib.showTextUI('[E] - Hack Plane')
                            end

                            if IsControlJustPressed(0, 38) then
                                local started, error = lib.callback.await("echo_smugglerheist:hackPlane", false)
                                if not started then Notify(error) end
                                vehicle.hackPlane()
                            end
                        else
                            sleep = 1000
                            if showingHack then
                                showingHack = false
                                lib.hideTextUI()
                            end
                        end
                    else
                        sleep = 1000
                        if showingHack then
                            showingHack = false
                            lib.hideTextUI()
                        end

                        if hackingPlane then
                            hackingPlane = false
                            exports.fallouthacking:cancel()
                        end
                    end
                end
            else
                sleep = 5000
            end

            Wait(sleep)
        end

        if showingHack then -- if for some reason hack prompt is showing
            showingHack = false
            lib.hideTextUI()
        end
    end)
end

--- Make the jet attack a specified target
---@param pilot integer Ped pilot handle
---@param plane integer Jet vehicle handle
---@param target integer Target vehicle handle
function vehicle.startAttacking(pilot, plane, target)
    CreateThread(function()
        while DoesEntityExist(plane) and DoesEntityExist(target) do
            local targetPos = GetEntityCoords(target, false)

            TaskPlaneMission(
                pilot,
                plane,
                target,
                GetPedInVehicleSeat(target, -1),
                targetPos.x,
                targetPos.y,
                targetPos.z,
                6,
                70.0,
                -1.0,
                30.0,
                500,
                50
            )

            SetCurrentPedVehicleWeapon(pilot, `VEHICLE_WEAPON_SPACE_ROCKET`)
            SetPedCanSwitchWeapon(pilot, false)

            Wait(1000)
        end
    end)
end

--- Task that handles logic for placing bombs on plane
---@param entity integer
function vehicle.startBombTask(entity)
    CreateThread(function()
        local closestIndex = nil
        local closestCoords = nil
        local sleep = 1000
        local plantingBomb = false
        while DoesEntityExist(entity) and GlobalState["echo_smugglerheist:hacked"] and not GlobalState["echo_smugglerheist:bombed"] do
            for i = 1, #sharedConfig.bombPlacementOffsets do
                if not GlobalState[string.format("echo_smugglerheist:bombPlaced:%s", i)] then
                    local myCoords = GetEntityCoords(cache.ped, false)
                    local engineCoords = GetOffsetFromEntityInWorldCoords(entity, sharedConfig.bombPlacementOffsets[i].explode.x, sharedConfig.bombPlacementOffsets[i].explode.y, sharedConfig.bombPlacementOffsets[i].explode.z)

                    if #(myCoords - engineCoords) <= 2.0 then
                        sleep = 5
                        closestIndex = i
                        closestCoords = engineCoords
                        lib.showTextUI('[E] - Plant Bomb')

                        if IsControlJustPressed(0, 38) then
                            plantingBomb = true
                            local planted = lib.progressBar({
                                duration = 2000,
                                label = 'Planting Bomb',
                                useWhileDead = false,
                                canCancel = true,
                                disable = {
                                    move = true,
                                    combat = true,
                                    sprint = true
                                }
                            })
                            
                            if planted then
                                local bombPlacement = sharedConfig.bombPlacementOffsets[closestIndex]
                                local entityCoords = GetEntityCoords(entity, false)
                                local obj = CreateObject(`prop_bomb_01`, entityCoords.x, entityCoords.y, entityCoords.z, false, false, false)
                                
                                AttachEntityToEntity(obj, entity, GetEntityBoneIndexByName(entity, "chassis_dummy"), bombPlacement.attach.x, bombPlacement.attach.y, bombPlacement.attach.z, 0.0, 0.0, 0.0, false, false, false, false, 2, false)
                                
                                if GlobalState["echo_smugglerheist:bombsPlaced"] == #sharedConfig.bombPlacementOffsets then -- Last bomb
                                    Notify(locale('task.escape'))
                                end
                                
                                Wait(5000)
                                local explodeCoords = GetOffsetFromEntityInWorldCoords(entity, bombPlacement.explode.x, bombPlacement.explode.y, bombPlacement.explode.z) -- Update coords again (have to do this as the plane is moving)
                                AddExplosion(explodeCoords.x, explodeCoords.y, explodeCoords.z, 2, 1.0, true, false, 1.0)
                                DeleteEntity(obj)
                                TriggerServerEvent("echo_smugglerheist:server:bombedPlane", vehicle.cargoNet, i)
                            end

                            plantingBomb = false
                        end
                    else
                        if closestIndex and closestCoords and #(myCoords - closestCoords) > 2.0 then
                            closestIndex = nil
                            closestCoords = nil
                            sleep = 1000
                            lib.hideTextUI()
                        end
                    end
                else
                    sleep = 1000
                end
            end
            
            Wait(sleep)
        end

    end)
end

local crateHeights = {}

---comment
---@param positions vector3[]
function vehicle.createCrates(positions)
    -- Request the models
    lib.requestModel(`ex_prop_crate_closed_mw`)
    lib.requestModel(`p_cargo_chute_s`)

    for i = 1, #positions do
        local crate = CreateObject(`ex_prop_crate_closed_mw`, positions[i].x, positions[i].y, positions[i].z, false, false, false)
        local parachute = CreateObject(`p_cargo_chute_s`, positions[i].x, positions[i].y, positions[i].z, false, false, false)
        local exists = lib.waitFor(function()
            if DoesEntityExist(crate) and DoesEntityExist(parachute) then return true end
        end)

        if not exists then return end

        -- Handle dropping in air as no better way for getting it on the ground from my testing
        FreezeEntityPosition(crate, false)
        -- Make it so can be seen from far distances
        SetEntityLodDist(crate, 1000)
        -- Make object drop
        ActivatePhysics(crate)
        SetDamping(crate, 2, 0.1) -- Not a clue what this does but R* uses it
        SetEntityVelocity(crate, 0.0, 0.0, -0.2)

        -- Make it so can be seen from far distances
        SetEntityLodDist(crate, 1000)
        -- Make parachute drop at same rate as crate
        SetEntityVelocity(parachute, 0.0, 0.0, -0.2)

        -- Attach the parachute to the crate
        AttachEntityToEntity(parachute, crate, 0, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

        table.insert(vehicle.crates, {
            object = crate,
            chuteLink = parachute,
            chute = false
        })

        table.insert(vehicle.crates, {
            object = parachute,
            crateLink = crate,
            chute = true,
            onGround = false
        })

        if sharedConfig.debug then
            -- AddBlipForCoord(positions[i].x, positions[i].y, positions[i].z)
            AddBlipForEntity(crate)
        end
        
        exports.ox_target:addLocalEntity(crate, {
            {
                name = "collect_crate",
                label = locale("target.open_crate"),
                icon = "fa-solid fa-box-open",
                distance = 2.0,
                canInteract = function()
                    return GlobalState["echo_smugglerheist:started"]
                    and GlobalState["echo_smugglerheist:bombed"]
                    and not GlobalState[string.format("echo_smugglerheist:crate:%s:opened", i)]
                    and LoggedIn
                end,
                onSelect = function(data)
                    if data.entity and DoesEntityExist(data.entity) then
                        TriggerServerEvent("echo_smugglerheist:server:openedCrate", i)
                    end
                end
            }
        })
    end

    -- Wait a second to start processing to make shit they don't collide with plane 

    Wait(1000)
    -- Thread for checking if object is on ground yet or not, if so delete parachute
    local allLanded = false
    local finishCount = 0

    CreateThread(function()
        while not allLanded do
            for i = 1, #vehicle.crates do
                if vehicle.crates[i].chute and not vehicle.crates[i].onGround then

                    while not crateHeights[vehicle.crates[i].object] or GetEntityHeightAboveGround(vehicle.crates[i].object) ~= crateHeights[vehicle.crates[i].object] do
                        crateHeights[vehicle.crates[i].object] = GetEntityHeightAboveGround(vehicle.crates[i].object)
                        Wait(5)
                    end

                    vehicle.crates[i].onGround = true
                    
                    -- Run this to place flat on ground incase it rolled over or whatever
                    PlaceObjectOnGroundProperly(vehicle.crates[i].crateLink)
                    
                    -- Now freeze it, as it's in a correct place
                    FreezeEntityPosition(vehicle.crates[i].crateLink, true)

                    -- Delete the parachute
                    DeleteEntity(vehicle.crates[i].object)
                    if sharedConfig.debug then lib.print.info("crate stopped moving") end

                    finishCount += 1
                end
            end


            if finishCount == sharedConfig.crateCount then allLanded = true end
            Wait(250)
        end
    end)

    table.wipe(crateHeights)
end

-- Remove all crates from the cargoplane
function vehicle.deleteCrates()
    for i = 1, #vehicle.crates do
        if DoesEntityExist(vehicle.crates[i].object) then
            DeleteEntity(vehicle.crates[i].object)
        end
    end

    table.wipe(vehicle.crates)
end

-- Clean up memory
function vehicle.finish()
    vehicle.cargoNet = nil
    vehicle.planeNet = nil

    if crashBlip then
        RemoveBlip(crashBlip)
        crashBlip = nil
    end
end

-- Cargoplane & Pilot
AddStateBagChangeHandler("heistCargoPlane", '', function(entity, _, value)
    local planeEntity, netId = GetEntityAndNetIdFromBagName(entity)
    if planeEntity then
        if not value or not value.pilotNet then return end
        if not NetworkDoesEntityExistWithNetworkId(value.pilotNet) then return end
        local pilotEntity = NetworkGetEntityFromNetworkId(value.pilotNet)

        if not planeEntity or not pilotEntity then return error("Unable to get cargoplane entity from netId") end
        vehicle.cargoNet = netId
        lib.print.info("Found entity handle from netId")

        vehicle.makeBlip(planeEntity, config.blip.cargoplane)
        vehicle.startUp(pilotEntity, planeEntity)
        vehicle.headToDestination(pilotEntity, planeEntity, config.travelSpeed)
    end
end)

-- Military Jets
AddStateBagChangeHandler("cargoPlaneJet", '', function(entity, _, value)
    local planeEntity, netId = GetEntityAndNetIdFromBagName(entity)
    if planeEntity then
        if not value or not value.pilotNet or not value.targetNet then return end
        if not NetworkDoesEntityExistWithNetworkId(value.pilotNet) then return end
        if not NetworkDoesEntityExistWithNetworkId(value.targetNet) then return end
        local pilotEntity = NetworkGetEntityFromNetworkId(value.pilotNet)
        local targetEntity = NetworkGetEntityFromNetworkId(value.targetNet)

        if not planeEntity or not pilotEntity or not targetEntity then return error("Unable to get jet entity from netId") end
        lib.print.info("Found entity handle from netId")
    
        vehicle.makeBlip(planeEntity, config.blip.jet) -- Register jet blip
        vehicle.startUp(pilotEntity, planeEntity) -- Start up the jet engine
        SetVehicleForwardSpeed(planeEntity, 100.0) -- Stops the freefall and makes it fly from current position
        vehicle.startAttacking(pilotEntity, planeEntity, targetEntity) -- Make the jet attack the mission plane
    end
end)

-- Plane Hacking
AddStateBagChangeHandler("echo_smugglerheist:hacked", "", function(bagName, key, value, reserved, replicated)
    if value then
        if not vehicle.cargoNet or not NetworkDoesEntityExistWithNetworkId(vehicle.cargoNet) then return end
        local entity = NetworkGetEntityFromNetworkId(vehicle.cargoNet)
        if not entity or not DoesEntityExist(entity) then return end
        
        local pilot = GetPedInVehicleSeat(entity, -1)
        vehicle.headToDestination(pilot, entity, config.hackedSpeed) -- Slow down the plane
        vehicle.startBombTask(entity) -- Start thread for placing bombs
    end
end)

---@param netId integer
RegisterNetEvent("echo_smugglerheist:client:createdPlane", function(netId)
    if not netId or not NetworkDoesEntityExistWithNetworkId(netId) then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or not DoesEntityExist(entity) then return end
    vehicle.planeNet = netId
    vehicle.startHackTask(entity)
end)

---@param crashCoords vector3
---@param cratePositions vector3[]
RegisterNetEvent("echo_smugglerheist:client:cargoCrashed", function(crashCoords, cratePositions)
    if crashBlip then
        RemoveBlip(crashBlip)
        crashBlip = nil
    end

    crashBlip = AddBlipForRadius(crashCoords.x, crashCoords.y, crashCoords.z, 300.0)
    SetBlipColour(crashBlip, config.blip.crash.colour)
    SetBlipAlpha(crashBlip, config.blip.crash.alpha)

    SetTimeout(config.blip.crash.length, function()
        RemoveBlip(crashBlip)
    end)

    vehicle.createCrates(cratePositions)
end)

---@param crateIndex integer
RegisterNetEvent("echo_smugglerheist:client:openedCrate", function(crateIndex)
    if not crateIndex or type(crateIndex) ~= "number" then return end
    if vehicle.crates[crateIndex] and DoesEntityExist(vehicle.crates[crateIndex].object) then
        exports.ox_target:removeLocalEntity(vehicle.crates[crateIndex].object, "collect_crate")
        DeleteEntity(vehicle.crates[crateIndex].object)
        table.remove(vehicle.crates, crateIndex)
    end
end)

return vehicle