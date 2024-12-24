lib.locale()

local config = require "config.client"
local sharedConfig = require "config.shared"
local mission = require "client.mission"
local vehicle = require "client.vehicle"

LoggedIn = true

AddEventHandler("onResourceStop", function(res)
    if GetCurrentResourceName() == res then
        vehicle.deleteCrates()
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