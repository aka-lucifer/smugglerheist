lib.locale()
local mission = require 'client.mission'
LoggedIn = true -- Set to false on prod
MissionActive = false

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
function Notify(notification, time)
    BeginTextCommandPrint("STRING")
    AddTextComponentSubstringPlayerName(notification)
    EndTextCommandPrint(time or 5000, true)
end

--- Sends a GTA style notification
---@param notification string
---@param time? integer
RegisterNetEvent("echo_smugglerheist:client:sentNotify", function(notification, time)
    Notify(notification, time)
end)

CreateThread(function()
    mission.setup()
end)

RegisterCommand("startminigame", function()
    print("win?", exports.fallouthacking:start(2, 10))
end, false)

RegisterCommand("endminigame", function()
    exports.fallouthacking:cancel()
end, false)