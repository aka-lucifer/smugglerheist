-- THINGS THAT NEED DOING
--
-- Client task for handling how close you are (showing minigame open prompt) & hiding minigame if active and no longer close enough
-- Client task for placing each bomb
-- Disable distTask if plane is destroyed (obvs not if hacked)
-- Disable spawning crates if not destroyed by bombs

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
    vehicle.createCargo()
end, false)