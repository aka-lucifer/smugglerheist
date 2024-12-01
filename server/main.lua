local vehicle = require 'server.vehicle'

AddEventHandler("onResourceStop", function(res)
    if GetCurrentResourceName() == res then
        vehicle.deletePlane()
    end
end)

RegisterCommand("plane", vehicle.createPlane, false)