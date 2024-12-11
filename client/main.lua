lib.locale()

local config = require "config.client"
local sharedConfig = require "config.shared"
local mission = require "client.mission"
local vehicle = require "client.vehicle"

LoggedIn = false

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

        lib.print.info("Cargoplane Stopped Moving")
        if cache.serverId == GlobalState["echo_smugglerheist:host"] then
            TriggerServerEvent("echo_smugglerheist:server:cargoDestroyed", vehicle.cargoNet)
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
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
        mission.finish()
        vehicle.finish()
    end
end)

mission.setup()
vehicle.init()