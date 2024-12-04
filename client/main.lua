lib.locale()

local config = require "config.client"
local mission = require "client.mission"
local vehicle = require "client.vehicle"

LoggedIn = true -- Set to false on prod
MissionActive = false

AddEventHandler("onResourceStop", function(res)
    if GetCurrentResourceName() == res then
        vehicle.deleteCrates()
    end
end)

AddEventHandler('gameEventTriggered', function (name, args)
    if name == 'CEventNetworkEntityDamage' then
        local entity = args[1]
        local isDestroyed = args[6] == 1
        local weapon = args[7]

        print(
            string.format(
                "Plane Net/Handle - %s/%s | Entity Damage - %s | Destroyed - %s | Weapon - %s | Weapon Hash - %s",
                vehicle.planeNet,
                NetworkGetEntityFromNetworkId(vehicle.planeNet),
                tostring(entity),
                tostring(isDestroyed),
                tostring(weapon),
                `WEAPON_EXPLOSION`
            )
        )
        if entity ~= NetToVeh(vehicle.planeNet) then return end
        if not isDestroyed then return end
        
        if weapon ~= `WEAPON_EXPLOSION` then return end

        lib.print.info("Cargoplane Crashed With Explosion")
        
        while GetEntitySpeed(entity) > 0.1 do
            Wait(5)
        end

        -- NOT IDEAl, SOMETIMES PLACES INTO WALLS, NEED TO FIND A BETTER METHOD FOR THIS
        SetVehicleOnGroundProperly(entity)
        -- SetEntityRotation(entity, config.flatRotation.x, config.flatRotation.y, config.flatRotation.z, 2, false)
        -- NOT IDEAl, SOMETIMES PLACES INTO WALLS, NEED TO FIND A BETTER METHOD FOR THIS

        SetVehicleDoorBroken(entity, config.cargoRearDoorId, false) -- Detach the rear door incase it doesn't come off when plane is destroyed
        SetVehicleDoorBroken(entity, config.cargoCockpitDoorId, false) -- Detach the front cockpit door incase it doesn't come off when plane is destroyed
        vehicle.attachCrates(entity)
    end
end)

RegisterNetEvent("echo_smugglerheist:client:startedMission", function()
    MissionActive = true
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

CreateThread(function()
    mission.setup()
end)