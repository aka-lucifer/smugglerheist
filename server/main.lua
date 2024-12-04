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
end)

RegisterCommand("plane", function(source, args, raw)
    local src = source
    vehicle.createCargo(src)
    vehicle.createPlane(src)
    vehicle.startJetTask()
end, false)