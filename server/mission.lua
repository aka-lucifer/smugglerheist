local config = require "config.server"
local vehicle = require "server.vehicle"
local mission = {}

GlobalState["echo_smugglerheist:started"] = false
GlobalState["echo_smugglerheist:cooldown"] = nil
GlobalState["echo_smugglerheist:hackingSystem"] = false

--- Start the mission on the creator
---@param source integer
function mission.start(source)
    local src = source --[[@as number]]
    GlobalState["echo_smugglerheist:started"] = true
    vehicle.createCargo()
    vehicle.createPlane(src)
    vehicle.startDistTask()
    TriggerClientEvent("echo_smugglerheist:client:sentNotify", src, locale('task.mission_start'))
end

--- Registers the mission server callbacks
function mission.init()
    lib.callback.register('echo_smugglerheist:requestMission', function(source)
        local src = source --[[@as number]]
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return false, locale("error.no_player") end

        if GlobalState["echo_smugglerheist:started"] then return false, locale("error.mission_active") end

        if GlobalState["echo_smugglerheist:cooldown"] and os.time() < GlobalState["echo_smugglerheist:cooldown"] then return false, locale("error.mission_cooldown") end

        local count, _ = exports.qbx_core:GetDutyCountType('leo')
        if count < config.requiredPolice then return false, locale("error.not_enough_police") end
        
        if player.PlayerData.money[config.paymentType] < config.missionCost then return false, locale("error.cant_afford") end
        
        player.Functions.RemoveMoney(config.paymentType, math.ceil(config.missionCost), "echo_smugglerheist - start")
        mission.start(src)
        return true
    end)
end

return mission