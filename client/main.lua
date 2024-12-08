lib.locale()

local config = require "config.client"
local sharedConfig = require "config.shared"
local mission = require "client.mission"
local vehicle = require "client.vehicle"

LoggedIn = false -- Set to false on prod

AddEventHandler("onResourceStop", function(res)
    if GetCurrentResourceName() == res then
        vehicle.deleteCrates()
    end
end)

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

AddEventHandler('gameEventTriggered', function (name, args)
    if name == 'CEventNetworkEntityDamage' then
        local entity = args[1]
        local isDestroyed = args[6] == 1
        local weapon = args[7]

        if not isDestroyed then return end
        
        if weapon ~= `WEAPON_EXPLOSION` then return end
        if entity ~= NetToVeh(vehicle.cargoNet) then return end

        lib.print.info("Cargoplane Crashed With Explosion")
        
        while GetEntitySpeed(entity) > 0.1 do
            Wait(5)
        end

        print("stopped")
        local dieCoords = GetEntityCoords(entity, false)
        DeleteEntity(entity) -- do this via server

        local crateLocs = {}

        for i = 1, 4 do
            print("get locations")
            local offsetCoords = vector3(
                dieCoords.x + math.random(config.crateOffset.min, config.crateOffset.max),
                dieCoords.y + math.random(config.crateOffset.min, config.crateOffset.max),
                dieCoords.z
            )
            local found, zCoord = getGroundCoord(offsetCoords)
            print("found", dieCoords, offsetCoords, found, zCoord)
            if found then
                offsetCoords = vector(offsetCoords.x, offsetCoords.y, zCoord)
            else
                print("couldnt find ground, so using plane Z coord")
            end

            table.insert(crateLocs, offsetCoords)
            makeCrate(offsetCoords)
        end


        CreateThread(function()
            while true do
                DrawMarker(1, dieCoords.x, dieCoords.y, dieCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 20.0, 20.0, 9999.0, 0, 255, 0, 255, false, true, 2, true)
                for i = 1, #crateLocs do
                    DrawMarker(1, crateLocs[i].x, crateLocs[i].y, crateLocs[i].z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 20.0, 20.0, 9999.0, 0, 0, 255, 150, false, true, 2, true)
                end

                for i = 1, #objs do
                    print("obj", objs[i])
                    if DoesEntityExist(objs[i]) then
                        draw3DText(GetEntityCoords(objs[i], false), "FUCKING TWAT")
                    end
                end

                Wait(0)
            end
        end)
        -- if not GlobalState["echo_smugglerheist:bombed"] then return end -- Disable looting unless done by bombs

        -- -- NOT IDEAl, SOMETIMES PLACES INTO WALLS, NEED TO FIND A BETTER METHOD FOR THIS
        -- SetVehicleOnGroundProperly(entity)
        -- -- SetEntityRotation(entity, config.flatRotation.x, config.flatRotation.y, config.flatRotation.z, 2, false)
        -- -- NOT IDEAL, SOMETIMES PLACES INTO WALLS, NEED TO FIND A BETTER METHOD FOR THIS

        -- SetVehicleDoorBroken(entity, config.cargoRearDoorId, false) -- Detach the rear door incase it doesn't come off when plane is destroyed
        -- SetVehicleDoorBroken(entity, config.cargoCockpitDoorId, false) -- Detach the front cockpit door incase it doesn't come off when plane is destroyed
        -- vehicle.attachCrates(entity)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    mission.setup()
    LoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    LoggedIn = false
end)

--- Sends a GTA style notification
---@param notification string
---@param time? integer
RegisterNetEvent("echo_smugglerheist:client:sentNotify", function(notification, time)
    Notify(notification, time)
end)

-- Heist resetting
AddStateBagChangeHandler("echo_smugglerheist:started", "", function(bagName, key, value, reserved, replicated)
    if not value then
        print("heist finished, clear drop off target")
        mission.finish()
        vehicle.finish()
    end
end)