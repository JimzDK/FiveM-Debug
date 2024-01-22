local DebugModeEnabled = false
local FreezeEnabled = false
local entityPool, pdata = {}, {}

RegisterCommand('db', function()
    ToggleDebug()
end)

local function Draw2DText(text, pos, scale)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(scale or 0.25, scale or 0.25)
    SetTextColour(200, 150, 20, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(pos.x, pos.y)
end

local function Draw3DText(text, coords)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x, y)
        DrawRect(x, y + 0.0125, 0.035 + (text:len() / 370), 0.03, 0, 0, 0, 100)
    end
end

local function UpdatePlayerInfo()
    if not DebugModeEnabled then return end
    local ped = PlayerPedId()
    local player = PlayerId()
    local coords = GetEntityCoords(ped)
    pdata = {
        ped = ped,
        coords = coords,
        heading = GetEntityHeading(ped),
        health = math.floor(GetEntityHealth(ped) / 2),
        maxhealth = math.floor(GetPedMaxHealth(ped) / 2),
        armor = GetPedArmour(ped),
        maxarmor = GetPlayerMaxArmour(player),
        model = GetEntityArchetypeName(ped),
        speed = GetEntitySpeed(ped) * 2.23694, -- MPH = 2.23694 | KMH 3.6
        attachedEnts = GetEntityAttachedTo(ped),
        frameTime = GetFrameTime(),
        currentStreetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)),
    }
    SetTimeout(100, UpdatePlayerInfo)
end

local function UpdateEntityPool()
    if not DebugModeEnabled then return end
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local _entityPool = {}
    for _, currentPool in pairs({'CPed', 'CObject', 'CVehicle'}) do
        for _, entity in pairs(GetGamePool(currentPool)) do
            if #(GetEntityCoords(entity) - pCoords) < 10 then
                if entity ~= ped then
                    if etype == 2 then
                        _entityPool[#_entityPool + 1] = {
                            ['entity'] = entity,
                            ['model'] = GetEntityModel(entity),
                            ['name'] = GetDisplayNameFromVehicleModel(GetEntityModel(entity)),
                            ['type'] = GetEntityType(entity)
                        }
                    else
                        _entityPool[#_entityPool + 1] = {
                            ['entity'] = entity,
                            ['model'] = GetEntityModel(entity),
                            ['name'] = GetEntityArchetypeName(entity),
                            ['type'] = GetEntityType(entity)
                        }
                    end
                end
            end
        end
    end
    entityPool = _entityPool
    SetTimeout(2000, UpdateEntityPool)
end

function ToggleDebug()
    FreezeEnabled = false
    DebugModeEnabled = not DebugModeEnabled
    UpdatePlayerInfo()
    UpdateEntityPool()
    CreateThread(function()
        while DebugModeEnabled do
            Draw2DText('General Info:', vector2(0.01, 0.27), 0.4)
            Draw2DText(('Freeze Enabled: %s'):format(FreezeEnabled and 'Yes' or 'No'), vector2(0.01, 0.3))
            Draw2DText(('Coords: %s'):format(pdata.coords), vector2(0.01, 0.32))
            Draw2DText(('Heading: %s'):format(pdata.heading), vector2(0.01, 0.34))
            Draw2DText(('Health: %s/%s'):format(pdata.health, pdata.maxhealth), vector2(0.01, 0.36))
            Draw2DText(('Armor: %s/%s'):format(pdata.armor, pdata.maxarmor), vector2(0.01, 0.38))
            Draw2DText(('Model: %s'):format(pdata.model), vector2(0.01, 0.4))
            Draw2DText(('Speed (MPH): %s'):format(pdata.speed), vector2(0.01, 0.42))
            Draw2DText(('Attached Entities: %s'):format(pdata.attachedEnts), vector2(0.01, 0.44))
            Draw2DText(('Frame Time: %s'):format(pdata.frameTime), vector2(0.01, 0.46))
            Draw2DText(('Street: %s'):format(pdata.currentStreetName), vector2(0.01, 0.48))
            Draw2DText('Keybindings:', vector2(0.01, 0.52), 0.4)
            Draw2DText('E - Freeze Entites', vector2(0.01, 0.55))
            Draw2DText('X - Disable Debug', vector2(0.01, 0.57))

            for _, edata in pairs(entityPool) do
                local coords = GetEntityCoords(edata.entity)
                local frozen = IsEntityPositionFrozen(edata.entity)
                if edata.type == 2 or edata.type == 3 then coords = vector3(coords.x, coords.y, coords.z + 1) end
                if edata.type == 1 then
                    Draw3DText(('Ped: %s Model: %s Name: %s%s'):format(edata.entity, edata.model, edata.name, frozen and ' (FROZEN)' or ''), coords)
                elseif edata.type == 2 then
                    Draw3DText(('Vehicle: %s Model: %s Name: %s%s'):format(edata.entity, edata.model, edata.name, frozen and ' (FROZEN)' or ''), coords)
                else
                    Draw3DText(('Object: %s Model: %s Name: %s%s'):format(edata.entity, edata.model, edata.name, frozen and ' (FROZEN)' or ''), coords)
                end
                if GetVehiclePedIsIn(pdata.ped) ~= edata.entity then
                    FreezeEntityPosition(edata.entity, FreezeEnabled)
                end
            end

            if IsControlJustReleased(2, 38) then
                FreezeEnabled = not FreezeEnabled
            end

            if IsControlJustPressed(2, 73) then
                DebugModeEnabled = false
            end

            Wait(1)
        end
    end)
end