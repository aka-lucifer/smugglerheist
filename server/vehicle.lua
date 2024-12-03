-- THINGS THAT NEED DOING
--
-- SPAWNING CRATES ON SERVER / DELETE ON RESTART
-- DETECTION OF VEHICLE CRASHING/EXPLODING INTO GROUND
-- LOGIC FOR HANDLING IF PEOPLE IN HEIST ARE TOO CLOSE TO PLANE OR TOO HIGH
-- WHEN IT CRASHES (EXPLODES NEED LOGIC FOR LYING FLAT, THEN REMOVE BACK DOOR & SPAWN CRATES TO SEARCH)

local config = require 'config.server'

local vehicle = {
    cargoHandle = nil,
    pilotHandle = nil,
    planeHandle = nil,
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

---@return boolean
function vehicle.planeExists()
    return vehicle.planeHandle and DoesEntityExist(vehicle.planeHandle) -- Checks if variable is defined and entity exists on server
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

--- Create plane for players to use to follow the cargoplane
---@param source integer
function vehicle.createPlane(source)
    if not vehicle.cargoExists then return end
    local ped = GetPlayerPed(source)
    local currentVehicle = GetVehiclePedIsIn(ped, false)
    if currentVehicle and currentVehicle ~= 0 then
        exports.qbx_core:DeleteVehicle(currentVehicle)
    end

    local _, entity = qbx.spawnVehicle({
        model = `lazer`,
        spawnSource = ped,
        warp = true,
    })

    local plate = qbx.getVehiclePlate(entity)
    exports.qbx_vehiclekeys:GiveKeys(source, plate)

    vehicle.planeHandle = entity
end

function vehicle.startJetTask()
    if not vehicle.cargoExists() or not vehicle.planeExists() then return end

    CreateThread(function()
        while vehicle.cargoExists() and vehicle.planeExists do
            lib.print.info("Running interval on jet task")

            local cargoCoords = GetEntityCoords(vehicle.cargoHandle, false)
            local planeCoords = GetEntityCoords(vehicle.planeHandle, false)
            local dist = #(cargoCoords - planeCoords)
            local heightDifference = planeCoords.z - cargoCoords.z

            if dist < config.distanceThreshold then
                lib.print.warn("TOO CLOSE")
            end

            if dist < config.height.distance and heightDifference < config.height.threshold  then
                lib.print.warn("TOO HIGH AND CLOSE")
            end

            Wait(config.jetTaskInterval)
        end
    end)
end

return vehicle