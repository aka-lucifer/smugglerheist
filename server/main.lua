local vehicle = require 'server.vehicle'

AddEventHandler("onResourceStop", function(res)
    if GetCurrentResourceName() == res then
        vehicle.deleteCargo()
    end
end)

RegisterCommand("plane", function(source, args, raw)
    local src = source
    vehicle.createCargo(src)
    vehicle.createPlane(src)
    vehicle.startJetTask()
end, false)