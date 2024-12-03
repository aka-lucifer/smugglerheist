-- THINGS THAT NEED DOING
--
-- SPAWNING CRATES ON SERVER / DELETE ON RESTART
-- DETECTION OF VEHICLE CRASHING/EXPLODING INTO GROUND
-- LOGIC FOR HANDLING IF PEOPLE IN HEIST ARE TOO CLOSE TO PLANE OR TOO HIGH

local config = require 'config.server'

local vehicle = {
    cargoHandle = nil,
    pilotHandle = nil,
    spawnedJets = {}
}

---@return boolean
function vehicle.cargoExists()
    return vehicle.cargoHandle and DoesEntityExist(vehicle.cargoHandle) -- Checks if variable is defined and entity exists on server
end

---@return boolean
function vehicle.pilotExists()
    return vehicle.pilotHandle and DoesEntityExist(vehicle.pilotHandle) -- Checks if variable is defined and entity exists on server
end

function vehicle.deleteCargo()
    if vehicle.cargoExists() then -- Make sure the plane actually exists
        DeleteEntity(vehicle.cargoHandle) -- Delete entity
        vehicle.cargoHandle = nil -- Set plane variable to null
    end

    if vehicle.pilotExists() then -- Make sure the pilot actually exists
        DeleteEntity(vehicle.pilotHandle) -- Delete entity
        vehicle.pilotHandle = nil -- Set pilot variable to null
    end
end

function vehicle.createCargo()
    if vehicle.cargoExists() then -- If the plane already exists delete it for whatever case
        vehicle.deleteCargo()
    end

    local entity = CreateVehicleServerSetter(`cargoplane`, "plane", config.spawnCoords.x, config.spawnCoords.y, config.spawnCoords.z, config.spawnCoords.w)
    while not DoesEntityExist(entity) do Wait(0) end
   
    SetEntityDistanceCullingRadius(entity, 999999.0) -- Have to handle it this way so it will be in scope all over the map as RPC for seating ped in vehicle is broken asf
    TriggerClientEvent("echo_smugglerheist:client:createdCargo", -1, NetworkGetNetworkIdFromEntity(entity))

    local ped = CreatePed(1, `s_m_y_pilot_01`, config.spawnCoords.x, config.spawnCoords.y, config.spawnCoords.z, config.spawnCoords.w, true, false)
    if ped and DoesEntityExist(ped) then
        Entity(ped).state:set("cargoPlaneDriver", true, true)
    end
    SetEntityDistanceCullingRadius(ped, 999999.0) -- Have to handle it this way so it will be in scope all over the map as RPC for seating ped in vehicle is broken asf

    vehicle.cargoHandle = entity
    vehicle.pilotHandle = ped
end

function vehicle.createPlane()
    if not vehicle.cargoExists then return end
    local entity = CreateVehicleServerSetter(`lazer`, "plane", -137.32, 8515.78, 1391.48, 177.75)
    while not DoesEntityExist(entity) do Wait(0) end
    print("lazer")
    local src = 1
    local ped = GetPlayerPed(src)
    print("ped", ped, entity)
    TaskWarpPedIntoVehicle(ped, entity, -1)
end

return vehicle