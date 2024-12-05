local config = require 'config.client'
local metersPerSecondConversion = 0.44704
local vehicle = {
    planeNet = nil,
    spawnedCrates = {}
}

function vehicle.attachCrates(entity)
    if not vehicle.planeNet or NetToVeh(vehicle.planeNet) ~= entity then return end 

    lib.requestModel(`ex_prop_crate_closed_mw`)
    for i = 1, #config.crateOffsets do
        local coords = GetOffsetFromEntityInWorldCoords(entity, config.crateOffsets[i].x, config.crateOffsets[i].y, config.crateOffsets[i].z - 4.0)
        local obj = CreateObject(`ex_prop_crate_closed_mw`, coords.x, coords.y, coords.z, false, false, false)
        local exists = lib.waitFor(function()
            if DoesEntityExist(obj) then return true end
        end)

        if not exists then return end

        FreezeEntityPosition(entity, true) -- Freeze crate position
        local planeRot = GetEntityRotation(entity, 2)
        SetEntityRotation(obj, planeRot.x, planeRot.y, planeRot.z, 2, false) -- Make sure plane and crate have some rotation
        SetEntityNoCollisionEntity(entity, obj, false) -- Disables collision between box and plane
        table.insert(vehicle.spawnedCrates, obj)
    end

    exports.ox_target:addLocalEntity(vehicle.spawnedCrates, {
        {
            name = "collect_crate",
            label = "Open Crate",
            icon = "fa-solid fa-box-open",
            distance = 2.0,
            canInteract = function()
                return GlobalState["echo_smugglerheist:started"] and LoggedIn
            end,
            onSelect = function(data)
                if data.entity and DoesEntityExist(data.entity) then
                    local index = -1
                    for i = 1, #vehicle.spawnedCrates do
                        if vehicle.spawnedCrates[i] == data.entity then
                            index = i
                            break
                        end
                    end

                    if index ~= -1 then
                        TriggerServerEvent("echo_smugglerheist:server:openCrate", index)
                    end
                end
            end
        }
    })
end

function vehicle.deleteCrates()
    for i = 1, #vehicle.spawnedCrates do
        if vehicle.spawnedCrates[i] and DoesEntityExist(vehicle.spawnedCrates[i]) then
            DeleteEntity(vehicle.spawnedCrates[i])
        end
    end

    vehicle.spawnedCrates = {}
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
function vehicle.headToDestination(driver, planeEntity)
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
        vehicle.convertSpeed(config.travelSpeed), -- Speed (meters per second)
        0.0,
        150.0,
        600.0, -- Max height
        580.0, -- Min height
        1
    )

    SetVehicleForwardSpeed(planeEntity, vehicle.convertSpeed(config.travelSpeed)) -- Stops the freefall and makes it fly from current position
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

--- Make the jet attack a specified target
---@param pilot integer Ped pilot handle
---@param plane integer Jet vehicle handle
---@param target integer Target vehicle handle
function vehicle.startAttacking(pilot, plane, target)
    CreateThread(function()
        while DoesEntityExist(plane) and DoesEntityExist(target) do

            -- NEED TO CONVERT TO SERVER LOGIC
            print("destroyed", IsEntityDead(target), GetVehicleEngineHealth(target), GetVehicleEngineHealth(target))
            -- if IsEntityDead(target) then -- If your plane is destroyed make them wander away
            --     RemoveBlip(plane)
            --     TaskVehicleDriveWander(pilot, plane, 30.0, 786603)
            --     SetTimeout(30000, function()
            --         DeleteEntity(plane)
            --     end)
            --     return
            -- end
            -- ]] NEED TO CONVERT TO SERVER LOGIC

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

-- Cargoplane & Pilot
AddStateBagChangeHandler("heistCargoPlane", '', function(entity, _, value)
    local planeEntity, netId = GetEntityAndNetIdFromBagName(entity)
    if planeEntity then
        if not value or not value.pilotNet then return end
        if not NetworkDoesEntityExistWithNetworkId(value.pilotNet) then return end
        local pilotEntity = NetworkGetEntityFromNetworkId(value.pilotNet)

        if not planeEntity or not pilotEntity then return error(err) end
        vehicle.planeNet = netId
        lib.print.info("Found entity handle from netId")

        vehicle.makeBlip(planeEntity, config.blip.cargoplane)
        vehicle.startUp(pilotEntity, planeEntity)
        vehicle.headToDestination(pilotEntity, planeEntity)
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

        if not planeEntity or not pilotEntity or not targetEntity then return error(err) end
        lib.print.info("Found entity handle from netId")
    
        vehicle.makeBlip(planeEntity, config.blip.jet) -- Register jet blip
        vehicle.startUp(pilotEntity, planeEntity) -- Start up the jet engine
        SetVehicleForwardSpeed(planeEntity, 100.0) -- Stops the freefall and makes it fly from current position
        vehicle.startAttacking(pilotEntity, planeEntity, targetEntity) -- Make the jet attack the mission plane
    end
end)

---@param crateIndex integer
RegisterNetEvent("echo_smugglerheist:client:openCrate", function(crateIndex)
    if not crateIndex or type(crateIndex) ~= "number" then return end
    if vehicle.spawnedCrates[crateIndex] and DoesEntityExist(vehicle.spawnedCrates[crateIndex]) then
        exports.ox_target:removeLocalEntity(vehicle.spawnedCrates[crateIndex], "collect_crate")
        DeleteEntity(vehicle.spawnedCrates[crateIndex])
        table.remove(vehicle.spawnedCrates, crateIndex)
    end
end)

return vehicle