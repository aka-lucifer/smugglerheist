local config = require 'config.client'
local metersPerSecondConversion = 0.44704
local vehicle = {
    planeNet = nil,
    driverNet = nil
}

--- Converts MPH to meters per second.
---@param mph number -- Speed in MPH
---@return number
function vehicle.convertSpeed(mph)
    print("speed convert", config.travelSpeed, mph, mph * metersPerSecondConversion, math.round((mph * metersPerSecondConversion), 1))
    return math.round((mph * metersPerSecondConversion), 1)
end

--- Applies to logic to make the plane head to the deliver cargo coords
---@param driver integer
---@param planeEntity integer
function vehicle.headToDestination(driver, planeEntity)
    if not driver or not DoesEntityExist(driver) then return end

    if not planeEntity or not DoesEntityExist(planeEntity) then return end

    ControlLandingGear(planeEntity, 3)
    SetVehicleEngineOn(planeEntity, true, true, false)
    TaskPlaneMission(
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

    while DoesEntityExist(planeEntity) do
        print("speed", GetEntitySpeed(planeEntity), GetEntitySpeed(planeEntity) * 2.236936)
        Wait(100)
    end
end

AddStateBagChangeHandler("cargoPlaneDriver", '', function(entity, _, value)
    local entity, netId = GetEntityAndNetIdFromBagName(entity)
    if entity then
        vehicle.driverNet = netId

        if vehicle.planeNet then
            local planeEntity = NetworkGetEntityFromNetworkId(vehicle.planeNet)
            if not planeEntity or not DoesEntityExist(planeEntity) then return error("Plane entity doesn't exist or not found!") end
            
            SetPedIntoVehicle(entity, planeEntity, -1)
            vehicle.headToDestination(entity, planeEntity)
        end
    end

    print("cargo driver", entity, netId)
end)

RegisterNetEvent("echo_smugglerheist:client:createdCargo", function(netId)
    print("net id", netId)
    local entity, err = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetworkGetEntityFromNetworkId(netId)
        end
    end, "timed out whilst getting entity handle from netId", 10000)
    
    if not entity then return error(err) end
    print("plane net id bs", entity, netId)
    vehicle.planeNet = netId
    AddBlipForEntity(entity)
end)

return vehicle