local clientConfig = require "config.client"
local sharedConfig = require "config.shared"
local mission = {
    startZone = nil
}

function mission.setup()
    mission.startZone = exports.ox_target:addBoxZone({
        name = "mission",
        coords = clientConfig.startPosition.coords,
        size = clientConfig.startPosition.size,
        rotation = clientConfig.startPosition.rotation,
        debug = sharedConfig.debug,
        options = {
            {
                name = "request_mission",
                label = "Request Mission",
                icon = "fa-solid fa-clipboard",
                distance = 2.0,
                canInteract = function()
                    return not MissionActive
                end,
                onSelect = function()
                    local started, error = lib.callback.await("echo_smugglerheist:requestMission", false)
                    if not started then Notify(error) end
                end
            }
        }
    })
end

return mission