local vehicle = {
    planeNet = nil,
    driverNet = nil
}


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
        44.7, -- Speed (meters per second)
        0.0,
        150.0,
        600.0, -- Max height
        580.0, -- Min height
        1
    )

    SetVehicleForwardSpeed(planeEntity, 44) -- Stops the freefall and makes it fly from current position
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

RegisterNetEvent("netIdSync", function(netId)
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