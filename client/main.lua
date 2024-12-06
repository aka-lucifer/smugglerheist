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

        if not GlobalState["echo_smugglerheist:bombed"] then return end -- Disable looting unless done by bombs

        -- NOT IDEAl, SOMETIMES PLACES INTO WALLS, NEED TO FIND A BETTER METHOD FOR THIS
        SetVehicleOnGroundProperly(entity)
        -- SetEntityRotation(entity, config.flatRotation.x, config.flatRotation.y, config.flatRotation.z, 2, false)
        -- NOT IDEAL, SOMETIMES PLACES INTO WALLS, NEED TO FIND A BETTER METHOD FOR THIS

        SetVehicleDoorBroken(entity, config.cargoRearDoorId, false) -- Detach the rear door incase it doesn't come off when plane is destroyed
        SetVehicleDoorBroken(entity, config.cargoCockpitDoorId, false) -- Detach the front cockpit door incase it doesn't come off when plane is destroyed
        vehicle.attachCrates(entity)
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
    end
end)