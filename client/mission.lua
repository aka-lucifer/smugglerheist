local config = require "config.client"
local sharedConfig = require "config.shared"
local mission = {
    startZone = nil,
    dropOffPed = nil
}

--- Create mission start & drop off items logic
function mission.setup()
    mission.startZone = exports.ox_target:addBoxZone({
        name = "mission",
        coords = config.startPosition.coords,
        size = config.startPosition.size,
        rotation = config.startPosition.rotation,
        debug = sharedConfig.debug,
        options = {
            {
                name = "request_mission",
                label = "Request Mission",
                icon = "fa-solid fa-clipboard",
                distance = 2.0,
                canInteract = function()
                    return not GlobalState["echo_smugglerheist:started"] and LoggedIn
                end,
                onSelect = function()
                    local started, error = lib.callback.await("echo_smugglerheist:requestMission", false)
                    if not started then Notify(error) end
                end
            }
        }
    })

    RegisterNetEvent("echo_smugglerheist:client:openedCrates", function()
        lib.requestModel(`g_m_y_ballaorig_01`, 1000)
        local ped = CreatePed(4, `g_m_y_ballaorig_01`, config.dropOff.x, config.dropOff.y, config.dropOff.z, config.dropOff.w, false, false)
        lib.waitFor(function()
            if DoesEntityExist(ped) then return true end
        end)

        -- Disable fleeing and make sure they remain still
        SetEntityAsMissionEntity(ped, true, true)
        FreezeEntityPosition(ped, true)
        SetPedCanRagdoll(ped, false)
        TaskSetBlockingOfNonTemporaryEvents(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 17, true)
        SetEntityInvincible(ped, true)
        SetPedSeeingRange(ped, 0)
        SetPedDefaultComponentVariation(ped)
        SetModelAsNoLongerNeeded(`g_m_y_ballaorig_01`)
        ClearPedTasks(ped)

        local pedCoords = GetEntityCoords(ped, false)
        SetNewWaypoint(pedCoords.x, pedCoords.y)
        Notify(locale("task.drop_off_goods"))

        exports.ox_target:addLocalEntity(ped, {
            {
                name = "deliver_goods",
                label = "Drop Off Goods",
                icon = "fa-solid fa-briefcase",
                distance = 2.0,
                canInteract = function()
                    return GlobalState["echo_smugglerheist:started"]
                    and not GlobalState["echo_smugglerheist:cooldown"]
                    and GlobalState["echo_smugglerheist:bombed"]
                    and GlobalState['echo_smugglerheist:cratesOpened'] == #sharedConfig.crateOffsets
                    and LoggedIn
                end,
                onSelect = function()
                    local started, error = lib.callback.await("echo_smugglerheist:deliverGoods", false)
                    if not started then Notify(error) end
                end
            }
        })

        mission.dropOffPed = ped
    end)
end

--- Remove the drop off items target
function mission.finish()
    if not mission.dropOffPed or not DoesEntityExist(mission.dropOffPed) then return end
    exports.ox_target:removeLocalEntity(mission.dropOffPed, "deliver_goods")
    mission.dropOffPed = nil
end

return mission