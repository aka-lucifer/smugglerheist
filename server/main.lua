lib.locale()

local vehicle = require "server.vehicle"
local mission = require "server.mission"

AddEventHandler("onResourceStop", function(res)
    if GetCurrentResourceName() == res then
        vehicle.deleteCargo()
    end
end)

CreateThread(function()
    mission.init()
    vehicle.init()
end)

RegisterCommand("plane", function(source, args, raw)
    vehicle.createCargo()
end, false)