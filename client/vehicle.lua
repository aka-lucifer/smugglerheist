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
    return math.round((mph * metersPerSecondConversion), 1)
end

--- Applies to logic to make the plane head to the deliver cargo coords
---@param driver integer
---@param planeEntity integer
function vehicle.headToDestination(driver, planeEntity)
    if not driver or not DoesEntityExist(driver) then return end

    if not planeEntity or not DoesEntityExist(planeEntity) then return end

    ControlLandingGear(planeEntity, 3) -- Put landing gear away
    SetVehicleEngineOn(planeEntity, true, true, false) -- Force engine on
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

AddStateBagChangeHandler("cargoPlaneDriver", '', function(entity, _, value)
    local entity, netId = GetEntityAndNetIdFromBagName(entity)
    if entity then
        vehicle.driverNet = netId

        if vehicle.planeNet then
            local planeEntity = NetworkGetEntityFromNetworkId(vehicle.planeNet)
            if not planeEntity or not DoesEntityExist(planeEntity) then return error("Plane entity doesn't exist or not found!") end
            
            SetPedIntoVehicle(entity, planeEntity, -1) -- Forces ped into driver seat as server side not working
            vehicle.headToDestination(entity, planeEntity)
        end
    end
end)

RegisterNetEvent("echo_smugglerheist:client:createdCargo", function(netId)
    local entity, err = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetworkGetEntityFromNetworkId(netId)
        end
    end, "timed out whilst getting entity handle from netId", 10000)
    
    if not entity then return error(err) end
    lib.print.debug("Found entity handle from netId")
    vehicle.planeNet = netId

    local blip = AddBlipForEntity(entity)
    SetBlipSprite(blip, config.blip.cargoplane.sprite)
    SetBlipColour(blip, config.blip.cargoplane.colour)
    SetBlipRotation(blip, GetEntityHeading(entity))
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Cargo Plane")
    EndTextCommandSetBlipName(blip)
end)

return vehicle