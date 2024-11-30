local planeRearDoor = 2 -- Door ID
local planeSpawn = vec3(-1124.9, -3068.59, 13.94)
local planeEntity = nil
local offsetObjs = {}

AddEventHandler("onResourceStop", function(res)
    if GetCurrentResourceName() == res then
        if planeEntity then
            DeleteEntity(planeEntity)
            planeEntity = nil
        end

        for i = 1, #offsetObjs do
            if offsetObjs[i] and DoesEntityExist(offsetObjs[i]) then
                DeleteEntity(offsetObjs[i])
                table.remove(offsetObjs, i)
            end
        end
    end
end)

local function draw3DText(coords, text)
    SetTextScale(0.4, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, false)
    local factor = (string.len(text)) / 250
    DrawRect(0.0, 0.0125, 0.003 + factor, 0.03, 0, 0, 0, 150)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

--- Returns the position of the center bone with decreased Z coord for position
---@return vector3 | nil
local function getBoneCenterPos()
    if not planeEntity then return nil end
    local boneIndex = GetEntityBoneIndexByName(planeEntity, "chassis_dummy")
    if boneIndex ~= -1 then
        local bonePos = GetWorldPositionOfEntityBone(planeEntity, boneIndex)
        return vector3(bonePos.x, bonePos.y, bonePos.z - 3.0)
    end

    return nil
end

local offsets = {
    vec3(-1.7, 25.7, 0.0), -- FL
    vec3(1.6, 26.0, 0.0), -- FR
    vec3(-1.9, 2.4, 0.0), -- RL
    vec3(1.9, 2.5, 0.0) -- RR
}

RegisterCommand("offsets", function(source, args, raw)
    if not planeEntity or not DoesEntityExist(planeEntity) then return end
    lib.requestModel(`ex_prop_crate_closed_mw`)
    for i = 1, #offsets do
        local coords = GetOffsetFromEntityInWorldCoords(planeEntity, offsets[i].x, offsets[i].y, offsets[i].z - 4.0)
        local obj = CreateObject(`ex_prop_crate_closed_mw`, coords.x, coords.y, coords.z, true, false, false)
        local exists = lib.waitFor(function()
            if DoesEntityExist(obj) then return true end
        end)

        if not exists then return end
        SetEntityNoCollisionEntity(planeEntity, obj, false) -- Disables collision between box and plane
        table.insert(offsetObjs, obj)
    end
end, false)

RegisterCommand("cargo", function()
    lib.requestModel(`cargoplane`)
    planeEntity = CreateVehicle(`cargoplane`, planeSpawn.x, planeSpawn.y, planeSpawn.z, math.random(360), true, false)
    local exists = lib.waitFor(function()
        if DoesEntityExist(planeEntity) then return true end
    end)

    if not exists then return end

    lib.print.info("cargoplane exists", planeEntity, "rotation", GetEntityRotation(planeEntity))

    local centerPos = getBoneCenterPos()
    if centerPos then
        SetVehicleDoorBroken(planeEntity, planeRearDoor, false) -- Detach the rear door incase it doesn't come off when plane is destroyed
        CreateThread(function ()
            while planeEntity and DoesEntityExist(planeEntity) do
                draw3DText(centerPos, "Center")
                Wait(0)
            end
        end)
    end
end, false)