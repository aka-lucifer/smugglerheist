lib.locale()

vehicle = require "server.vehicle"
mission = require "server.mission"

AddEventHandler("onResourceStop", function(res)
    if GetCurrentResourceName() == res then
        vehicle.deleteCargo()
    end
end)

CreateThread(function()
    mission.init()
    vehicle.init()
end)