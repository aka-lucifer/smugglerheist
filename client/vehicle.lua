local config = require 'config.client'
local metersPerSecondConversion = 0.44704
local vehicle = {
    planeNet = nil
}

AddEventHandler('gameEventTriggered', function (name, args)
    if name == 'CEventNetworkEntityDamage' then
        local entity = args[1]
        local isDestroyed = args[6] == 1
        local weapon = args[7]

        if entity ~= NetToVeh(vehicle.planeNet) then return end
        if not isDestroyed then return end
        if weapon ~= `WEAPON_EXPLOSION` then return end

        lib.print.info("Cargoplane Crashed With Explosion")
    end
end)

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
        -1325.82,
        -5204.93,
        340.37,
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
    
        vehicle.makeBlip(planeEntity, config.blip.jet)
        vehicle.startUp(pilotEntity, planeEntity)
        SetVehicleForwardSpeed(planeEntity, 100.0) -- Stops the freefall and makes it fly from current position
    
        CreateThread(function()
            while DoesEntityExist(planeEntity) and DoesEntityExist(targetEntity) do

                -- NEED TO CONVERT TO SERVER LOGIC
                print("destroyed", IsEntityDead(targetEntity), GetVehicleEngineHealth(targetEntity), GetVehicleEngineHealth(targetEntity) <= -4000)
                -- if IsEntityDead(targetEntity) then -- If your plane is destroyed make them wander away
                --     RemoveBlip(planeEntity)
                --     TaskVehicleDriveWander(pilotEntity, planeEntity, 30.0, 786603)
                --     SetTimeout(30000, function()
                --         DeleteEntity(planeEntity)
                --     end)
                --     return
                -- end
                -- ]] NEED TO CONVERT TO SERVER LOGIC

                local targetPos = GetEntityCoords(targetEntity, false)

                TaskPlaneMission(
                    pilotEntity,
                    planeEntity,
                    targetEntity,
                    GetPedInVehicleSeat(targetEntity, -1),
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

                SetCurrentPedVehicleWeapon(pilotEntity, `VEHICLE_WEAPON_SPACE_ROCKET`)
                SetPedCanSwitchWeapon(pilotEntity, false)

                Wait(1000)
            end
        end)
    end
end)

return vehicle