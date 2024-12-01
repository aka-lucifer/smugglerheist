-- THINGS THAT NEED DOING
--
-- SPAWNING CRATES ON SERVER / DELETE ON RESTART
-- DETECTION OF VEHICLE CRASHING/EXPLODING INTO GROUND
-- LOGIC FOR HANDLING IF PEOPLE IN HEIST ARE TOO CLOSE TO PLANE OR TOO HIGH

local config = require 'config.server'

local vehicle = {
    planeHandle = nil,
    pilotHandle = nil,
    spawnedJets = {}
}

---@return boolean
function vehicle.planeExists()
    return vehicle.planeHandle and DoesEntityExist(vehicle.planeHandle) -- Checks if variable is defined and entity exists on server
end

---@return boolean
function vehicle.pilotExists()
    return vehicle.pilotHandle and DoesEntityExist(vehicle.pilotHandle) -- Checks if variable is defined and entity exists on server
end

function vehicle.deletePlane()
    if vehicle.planeExists() then -- Make sure the plane actually exists
        DeleteEntity(vehicle.planeHandle) -- Delete entity
        vehicle.planeHandle = nil -- Set plane variable to null
    end

    if vehicle.pilotExists() then -- Make sure the pilot actually exists
        DeleteEntity(vehicle.pilotHandle) -- Delete entity
        vehicle.pilotHandle = nil -- Set pilot variable to null
    end
end

function vehicle.createPlane()
    if vehicle.planeExists() then -- If the plane already exists delete it for whatever case
        vehicle.deletePlane()
    end

    local entity = CreateVehicleServerSetter(`cargoplane`, "plane", config.spawnCoords.x, config.spawnCoords.y, config.spawnCoords.z, config.spawnCoords.w)
    while not DoesEntityExist(entity) do Wait(0) end
   
    SetEntityDistanceCullingRadius(entity, 999999.0) -- Have to handle it this way so it will be in scope all over the map as RPC for seating ped in vehicle is broken asf
    TriggerClientEvent("netIdSync", -1, NetworkGetNetworkIdFromEntity(entity))

    local ped = CreatePed(1, `s_m_y_pilot_01`, config.spawnCoords.x, config.spawnCoords.y, config.spawnCoords.z, config.spawnCoords.w, true, false)
    if ped and DoesEntityExist(ped) then
        Entity(ped).state:set("cargoPlaneDriver", true, true)
    end
    SetEntityDistanceCullingRadius(ped, 999999.0) -- Have to handle it this way so it will be in scope all over the map as RPC for seating ped in vehicle is broken asf

    vehicle.planeHandle = entity
    vehicle.pilotHandle = ped
end

return vehicle