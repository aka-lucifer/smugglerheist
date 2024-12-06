local config = require "config.server"
local sharedConfig = require "config.shared"
local mission = {
    openingCrate = false,
    itemsGiven = {}
}

GlobalState["echo_smugglerheist:started"] = false
GlobalState["echo_smugglerheist:cooldown"] = nil

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

-- Reset the global statebags, enable cooldown and remove the cargoplane if it exists
function mission.finish()
    GlobalState["echo_smugglerheist:started"] = false
    GlobalState["echo_smugglerheist:cooldown"] = os.time() + 1800 -- 30 minute cooldown
    vehicle.finish()
    mission.openingCrate = false
    mission.itemsGiven = {}
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

    lib.callback.register('echo_smugglerheist:deliverGoods', function(source)
        if not GlobalState["echo_smugglerheist:started"] then return end
        if not GlobalState["echo_smugglerheist:hacked"] then return end
        if not GlobalState["echo_smugglerheist:bombed"] then return end
        if GlobalState['echo_smugglerheist:cratesOpened'] ~= #sharedConfig.crateOffsets then return end
        
        local src = source --[[@as number]]
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return end

        local hasAllItems = false

        for item, amount in pairs(mission.itemsGiven) do
            local itemCount = exports.ox_inventory:GetItemCount(src, item)
            if itemCount < amount then return false, locale("error.items_not_found") end

            if next(mission.itemsGiven, item) == nil then
                hasAllItems = true
            end
        end
        
        if hasAllItems then
            for item, amount in pairs(mission.itemsGiven) do
                exports.ox_inventory:RemoveItem(src, item, amount)
            end

            player.Functions.AddMoney("cash", config.reward, "echo_smugglerheist - delivered goods")
            mission.finish()

            return true
        end
    end)
end

return mission