local menuOpen = false
local favourites = {}
local ClientActions = {}

local state = {
    noclip = false,
    laser = false,
    god = false,
    invisible = false,
    ammo = false,
    coords = false,
    names = false,
    blips = false,
    vehDev = false,
    spectating = false,
}

local lastCoords = nil
local spectateReturn = nil
local blips = {}
local muted = {}

local function notify(msg, kind)
    Bridge.Notify(msg, kind)
end

local function releaseFocus()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

local function closeMenu()
    menuOpen = false
    releaseFocus()
    SendNUIMessage({ action = 'close' })
    CreateThread(function()
        Wait(100)
        if not menuOpen then releaseFocus() end
    end)
end

local pendingOpen = 0

local function openMenu()
    if menuOpen then return end
    TriggerServerEvent('codera-adminmenu:server:open')
    pendingOpen = GetGameTimer()
    local mine = pendingOpen
    CreateThread(function()
        Wait(4000)
        if pendingOpen == mine and not menuOpen then
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName('Admin menu: no response from server. Check server console (F8 too).')
            EndTextCommandThefeedPostTicker(false, false)
        end
    end)
end

local function drawText2D(x, y, text, scale)
    SetTextFont(4)
    SetTextScale(0.0, scale or 0.35)
    SetTextColour(255, 255, 255, 230)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

local function drawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end
    SetTextScale(0.0, 0.32)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 230)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

local function currentVehicle()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 and DoesEntityExist(veh) then return veh end
    return nil
end

local function resolveFuelResource()
    if Config.Fuel ~= 'auto' then return Config.Fuel end
    for _, name in ipairs({ 'cdn-fuel', 'ox_fuel', 'LegacyFuel', 'ps-fuel', 'lc_fuel' }) do
        if GetResourceState(name) == 'started' then return name end
    end
    return nil
end

local function setFuel(veh)
    local resource = resolveFuelResource()
    if resource == 'ox_fuel' then
        Entity(veh).state:set('fuel', 100.0, true)
    elseif resource then
        pcall(function() exports[resource]:SetFuel(veh, 100.0) end)
    end
    SetVehicleFuelLevel(veh, 100.0)
end

local function giveKeys(plate)
    if GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
    end
end

local function requestModelLoaded(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local waited = 0
    while not HasModelLoaded(model) and waited < 5000 do
        Wait(10)
        waited = waited + 10
    end
    return HasModelLoaded(model)
end

local function spawnVehicle(modelName, plate)
    local ped = PlayerPedId()
    local model = tonumber(modelName) or joaat(tostring(modelName))

    if not IsModelAVehicle(model) or not requestModelLoaded(model) then
        notify('Could not load vehicle model: ' .. tostring(modelName), 'error')
        return nil
    end

    local coords = GetEntityCoords(ped)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    SetPedIntoVehicle(ped, veh, -1)
    SetModelAsNoLongerNeeded(model)

    if plate and plate ~= '' then
        SetVehicleNumberPlateText(veh, plate:sub(1, 8))
    end

    setFuel(veh)
    giveKeys(GetVehicleNumberPlateText(veh))
    return veh
end

local function fixVehicle(veh)
    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleUndriveable(veh, false)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehiclePetrolTankHealth(veh, 1000.0)
    SetVehicleDirtLevel(veh, 0.0)
end

local function rotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function teleportTo(coords, heading)
    local ped = PlayerPedId()
    lastCoords = GetEntityCoords(ped)
    DoScreenFadeOut(300)
    Wait(350)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    if heading then SetEntityHeading(ped, heading) end
    Wait(200)
    DoScreenFadeIn(300)
end

RegisterNetEvent('codera-adminmenu:client:open', function(players, commands, lists)
    pendingOpen = 0
    print('[codera-adminmenu] open payload received: ' .. tostring(commands and #commands or 'nil') .. ' commands')
    if menuOpen then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        commands = commands,
        players = players,
        favourites = favourites,
        lists = lists
    })
end)

RegisterCommand(Config.Command, function()
    openMenu()
end, false)

RegisterKeyMapping(Config.Command, 'Open Admin Menu', 'keyboard', Config.OpenKey)

if Config.Keybindings then
    RegisterCommand('codera_adminmenu_noclip', function()
        TriggerServerEvent('codera-adminmenu:server:noclipKey')
    end, false)
    RegisterKeyMapping('codera_adminmenu_noclip', 'Admin Noclip', 'keyboard', Config.NoclipKey)
end

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterCommand('adminmenu_fixfocus', function()
    menuOpen = false
    releaseFocus()
    SendNUIMessage({ action = 'close' })
end, false)

RegisterNUICallback('toggleFavourite', function(data, cb)
    favourites[data.id] = not favourites[data.id] or nil
    cb('ok')
end)

ClientActions.noclip = function()
    state.noclip = not state.noclip
    local ped = PlayerPedId()
    SetEntityCollision(ped, not state.noclip, not state.noclip)
    FreezeEntityPosition(ped, false)
    if state.noclip then
        CreateThread(function()
            while state.noclip do
                Wait(0)
                local p = PlayerPedId()
                DisableControlAction(0, 21, true)
                local coords = GetEntityCoords(p)
                local heading = GetEntityHeading(p)
                local speed = IsControlPressed(0, 21) and 0.75 or 0.35
                local fwd, right = 0.0, 0.0
                if IsControlPressed(0, 32) then fwd = fwd + speed end
                if IsControlPressed(0, 33) then fwd = fwd - speed end
                if IsControlPressed(0, 34) then right = right - speed end
                if IsControlPressed(0, 35) then right = right + speed end
                local up = 0.0
                if IsControlPressed(0, 44) then up = up + speed end
                if IsControlPressed(0, 20) then up = up - speed end

                local rad = math.rad(heading)
                local x = coords.x - math.sin(rad) * fwd + math.cos(rad) * right
                local y = coords.y + math.cos(rad) * fwd + math.sin(rad) * right
                SetEntityCoordsNoOffset(p, x, y, coords.z + up, true, true, true)
            end
        end)
    end
    notify('Noclip ' .. (state.noclip and 'enabled' or 'disabled') .. '.', 'primary')
end

ClientActions.toggle_laser = function()
    state.laser = not state.laser
    if state.laser then
        CreateThread(function()
            while state.laser do
                Wait(0)
                local ped = PlayerPedId()
                local camRot = GetGameplayCamRot(2)
                local camPos = GetGameplayCamCoord()
                local dir = rotationToDirection(camRot)
                local dest = vector3(camPos.x + dir.x * 100.0, camPos.y + dir.y * 100.0, camPos.z + dir.z * 100.0)
                local _, _, endCoords = GetShapeTestResult(StartShapeTestRay(
                    camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, ped, 0
                ))
                DrawLine(camPos.x, camPos.y, camPos.z, endCoords.x, endCoords.y, endCoords.z, 255, 30, 30, 200)
                DrawMarker(28, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.15, 0.15, 255, 30, 30, 200, false, true, 2, false, nil, nil, false)
            end
        end)
    end
    notify('Laser ' .. (state.laser and 'enabled' or 'disabled') .. '.', 'primary')
end

ClientActions.god_mode = function()
    state.god = not state.god
    if state.god then
        CreateThread(function()
            while state.god do
                Wait(200)
                local ped = PlayerPedId()
                SetPlayerInvincible(PlayerId(), true)
                SetEntityHealth(ped, GetEntityMaxHealth(ped))
                ClearPedBloodDamage(ped)
                RestorePlayerStamina(PlayerId(), 1.0)
            end
            SetPlayerInvincible(PlayerId(), false)
        end)
    end
    notify('God mode ' .. (state.god and 'enabled' or 'disabled') .. '.', 'primary')
end

ClientActions.invisible = function()
    state.invisible = not state.invisible
    SetEntityVisible(PlayerPedId(), not state.invisible, false)
    notify('Invisibility ' .. (state.invisible and 'enabled' or 'disabled') .. '.', 'primary')
end

ClientActions.infinite_ammo = function()
    state.ammo = not state.ammo
    local ped = PlayerPedId()
    SetPedInfiniteAmmoClip(ped, state.ammo)
    SetPedInfiniteAmmo(ped, state.ammo, GetSelectedPedWeapon(ped))
    notify('Infinite ammo ' .. (state.ammo and 'enabled' or 'disabled') .. '.', 'primary')
end

ClientActions.set_ammo = function(payload)
    local amount = math.floor(tonumber(payload.amount) or 0)
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon == joaat("WEAPON_UNARMED") then
        notify('You are not holding a weapon.', 'error')
        return
    end
    SetPedAmmo(ped, weapon, amount)
    notify(('Ammo set to %s.'):format(amount), 'success')
end

ClientActions.fix_vehicle = function()
    local veh = currentVehicle()
    if not veh then
        notify('You are not in a vehicle.', 'error')
        return
    end
    fixVehicle(veh)
    notify('Vehicle repaired.', 'success')
end

ClientActions.admin_car = function()
    if spawnVehicle(Config.AdminVehicle) then
        notify('Admin vehicle spawned.', 'success')
    end
end

ClientActions.spawn_vehicle = function(payload)
    local model = tostring(payload.vehicle or '')
    if model == '' then
        notify('Enter a vehicle model.', 'error')
        return
    end
    if spawnVehicle(model) then
        notify('Vehicle spawned.', 'success')
    end
end

ClientActions.delete_vehicle = function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    if veh ~= 0 and DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        notify('Vehicle deleted.', 'success')
    else
        notify('No vehicle found nearby.', 'error')
    end
end

ClientActions.refuel_vehicle = function()
    local veh = currentVehicle()
    if not veh then
        notify('You are not in a vehicle.', 'error')
        return
    end
    setFuel(veh)
    notify('Vehicle refueled.', 'success')
end

ClientActions.max_mods = function()
    local veh = currentVehicle()
    if not veh then
        notify('You are not in a vehicle.', 'error')
        return
    end
    SetVehicleModKit(veh, 0)
    for modType = 0, 49 do
        if modType < 17 or modType > 22 then
            local count = GetNumVehicleMods(veh, modType)
            if count > 0 then
                SetVehicleMod(veh, modType, count - 1, false)
            end
        end
    end
    ToggleVehicleMod(veh, 18, true)
    ToggleVehicleMod(veh, 20, true)
    ToggleVehicleMod(veh, 22, true)
    SetVehicleWindowTint(veh, 1)
    SetVehicleTyresCanBurst(veh, false)
    notify('Vehicle mods maxed.', 'success')
end

ClientActions.change_plate = function(payload)
    local veh = currentVehicle()
    local plate = tostring(payload.plate or ''):upper():sub(1, 8)
    if not veh then
        notify('You are not in a vehicle.', 'error')
        return
    end
    if plate == '' then
        notify('Enter a plate.', 'error')
        return
    end
    SetVehicleNumberPlateText(veh, plate)
    giveKeys(plate)
    notify('Plate changed to ' .. plate .. '.', 'success')
end

ClientActions.set_garage_state = function(payload)
    local plate = tostring(payload.plate or '')
    if plate == '' then
        local veh = currentVehicle()
        if not veh then
            notify('Enter a plate or sit in a vehicle.', 'error')
            return
        end
        plate = GetVehicleNumberPlateText(veh):gsub('%s+', '')
        payload.plate = plate
    end
    TriggerServerEvent('codera-adminmenu:server:runCommand', 'set_garage_state', payload)
end

ClientActions.vehicle_dev = function()
    state.vehDev = not state.vehDev
    if state.vehDev then
        CreateThread(function()
            while state.vehDev do
                Wait(0)
                local veh = currentVehicle()
                if veh then
                    local lines = {
                        ('Model: %s'):format(GetDisplayNameFromVehicleModel(GetEntityModel(veh))),
                        ('Plate: %s'):format(GetVehicleNumberPlateText(veh)),
                        ('Speed: %.1f km/h'):format(GetEntitySpeed(veh) * 3.6),
                        ('Gear: %s'):format(GetVehicleCurrentGear(veh)),
                        ('RPM: %.2f'):format(GetVehicleCurrentRpm(veh)),
                        ('Engine: %.0f'):format(GetVehicleEngineHealth(veh)),
                        ('Body: %.0f'):format(GetVehicleBodyHealth(veh)),
                        ('Fuel: %.1f'):format(GetVehicleFuelLevel(veh)),
                        ('Mass: %.0f'):format(GetVehicleHandlingFloat(veh, 'CHandlingData', 'fMass')),
                        ('Top Speed: %.1f'):format(GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveMaxFlatVel')),
                    }
                    for i, line in ipairs(lines) do
                        drawText2D(0.015, 0.25 + (i - 1) * 0.028, line, 0.35)
                    end
                end
            end
        end)
    end
    notify('Vehicle dev menu ' .. (state.vehDev and 'enabled' or 'disabled') .. '.', 'primary')
end

ClientActions.toggle_coords = function()
    state.coords = not state.coords
    if state.coords then
        CreateThread(function()
            while state.coords do
                Wait(0)
                local ped = PlayerPedId()
                local c = GetEntityCoords(ped)
                drawText2D(0.015, 0.02, ('X: %.2f  Y: %.2f  Z: %.2f  H: %.2f'):format(c.x, c.y, c.z, GetEntityHeading(ped)), 0.4)
            end
        end)
    end
end

ClientActions.toggle_names = function()
    state.names = not state.names
    if state.names then
        CreateThread(function()
            while state.names do
                Wait(0)
                local myCoords = GetEntityCoords(PlayerPedId())
                for _, player in ipairs(GetActivePlayers()) do
                    local ped = GetPlayerPed(player)
                    local coords = GetEntityCoords(ped)
                    if #(myCoords - coords) < 250.0 then
                        drawText3D(vector3(coords.x, coords.y, coords.z + 1.1), ('[%s] %s'):format(GetPlayerServerId(player), GetPlayerName(player)))
                    end
                end
            end
        end)
    end
    notify('Player names ' .. (state.names and 'enabled' or 'disabled') .. '.', 'primary')
end

local function clearBlips()
    for id, blip in pairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        blips[id] = nil
    end
end

ClientActions.toggle_blips = function()
    state.blips = not state.blips
    if state.blips then
        CreateThread(function()
            while state.blips do
                TriggerServerEvent('codera-adminmenu:server:requestBlips')
                Wait(1500)
            end
            clearBlips()
        end)
    end
    notify('Player blips ' .. (state.blips and 'enabled' or 'disabled') .. '.', 'primary')
end

RegisterNetEvent('codera-adminmenu:client:blipsData', function(data)
    if not state.blips then return end
    local myId = GetPlayerServerId(PlayerId())
    local seen = {}

    for _, entry in ipairs(data) do
        if entry.id ~= myId then
            seen[entry.id] = true
            local blip = blips[entry.id]
            if not blip or not DoesBlipExist(blip) then
                blip = AddBlipForCoord(entry.x, entry.y, entry.z)
                SetBlipSprite(blip, 1)
                SetBlipColour(blip, 3)
                SetBlipScale(blip, 0.85)
                SetBlipAsShortRange(blip, false)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(entry.name)
                EndTextCommandSetBlipName(blip)
                blips[entry.id] = blip
            else
                SetBlipCoords(blip, entry.x, entry.y, entry.z)
            end
        end
    end

    for id, blip in pairs(blips) do
        if not seen[id] then
            if DoesBlipExist(blip) then RemoveBlip(blip) end
            blips[id] = nil
        end
    end
end)

ClientActions.teleport_to_coords = function(payload)
    local numbers = {}
    for n in tostring(payload.coords or ''):gmatch('-?%d+%.?%d*') do
        numbers[#numbers + 1] = tonumber(n)
    end
    if #numbers < 3 then
        notify('Use the format: x, y, z', 'error')
        return
    end
    teleportTo({ x = numbers[1], y = numbers[2], z = numbers[3] })
end

ClientActions.teleport_to_marker = function()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then
        notify('Set a waypoint on the map first.', 'error')
        return
    end

    local target = GetBlipInfoIdCoord(blip)
    local ped = PlayerPedId()
    lastCoords = GetEntityCoords(ped)
    DoScreenFadeOut(300)
    Wait(350)
    FreezeEntityPosition(ped, true)

    local groundZ
    for z = 1000.0, 0.0, -25.0 do
        SetEntityCoordsNoOffset(ped, target.x, target.y, z, false, false, false)
        RequestCollisionAtCoord(target.x, target.y, z)
        Wait(20)
        local found, height = GetGroundZFor_3dCoord(target.x, target.y, z, false)
        if found then
            groundZ = height
            break
        end
    end

    SetEntityCoords(ped, target.x, target.y, (groundZ or 50.0) + 1.0, false, false, false, true)
    FreezeEntityPosition(ped, false)
    Wait(200)
    DoScreenFadeIn(300)
end

ClientActions.teleport_back = function()
    if not lastCoords then
        notify('No previous position saved.', 'error')
        return
    end
    local ped = PlayerPedId()
    local target = lastCoords
    lastCoords = GetEntityCoords(ped)
    SetEntityCoords(ped, target.x, target.y, target.z, false, false, false, true)
end

ClientActions.copy_coords = function(payload)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local format = payload.format
    local text

    if format == 'vector2' then
        text = ('vector2(%.2f, %.2f)'):format(c.x, c.y)
    elseif format == 'vector4' then
        text = ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(c.x, c.y, c.z, h)
    elseif format == 'heading' then
        text = ('%.2f'):format(h)
    else
        text = ('vector3(%.2f, %.2f, %.2f)'):format(c.x, c.y, c.z)
    end

    SendNUIMessage({ action = 'copy', text = text })
    notify('Copied: ' .. text, 'success')
end

RegisterNUICallback('runCommand', function(data, cb)
    local id = data.id
    local payload = data.payload or {}
    local action = ClientActions[id]

    if action then
        action(payload)
    else
        TriggerServerEvent('codera-adminmenu:server:runCommand', id, payload)
    end

    cb('ok')
end)

RegisterNetEvent('codera-adminmenu:client:runAction', function(id, payload)
    local action = ClientActions[id]
    if action then action(payload or {}) end
end)

RegisterNetEvent('codera-adminmenu:client:makeDrunk', function(duration)
    local endTime = GetGameTimer() + duration
    CreateThread(function()
        while GetGameTimer() < endTime do
            Wait(0)
            ShakeGameplayCam('DRUNK_SHAKE', 1.2)
            SetPedMotionBlur(PlayerPedId(), true)
            SetTimecycleModifier('drug_drive_incar_01')
        end
        StopGameplayCamShaking(true)
        ClearTimecycleModifier()
    end)
end)

RegisterNetEvent('codera-adminmenu:client:teleport', function(coords)
    teleportTo(coords, coords.w)
end)

RegisterNetEvent('codera-adminmenu:client:bringHere', function(coords)
    local ped = PlayerPedId()
    lastCoords = GetEntityCoords(ped)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
end)

RegisterNetEvent('codera-adminmenu:client:freeze', function(freeze)
    FreezeEntityPosition(PlayerPedId(), freeze)
    if freeze then
        notify('You have been frozen by an admin.', 'error')
    else
        notify('You have been unfrozen.', 'success')
    end
end)

RegisterNetEvent('codera-adminmenu:client:fixVehicle', function()
    local veh = currentVehicle()
    if veh then
        fixVehicle(veh)
        notify('An admin repaired your vehicle.', 'success')
    end
end)

RegisterNetEvent('codera-adminmenu:client:spawnVehicle', function(model, plate)
    if spawnVehicle(model, plate) then
        notify('Vehicle spawned.', 'success')
    end
end)

RegisterNetEvent('codera-adminmenu:client:setPed', function(pedModel)
    local model = joaat(pedModel)
    if not IsModelInCdimage(model) or not requestModelLoaded(model) then
        notify('Invalid ped model.', 'error')
        return
    end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    SetPedDefaultComponentVariation(PlayerPedId())
end)

RegisterNetEvent('codera-adminmenu:client:mutePlayer', function(target)
    if GetResourceState('pma-voice') ~= 'started' then
        notify('pma-voice is required for muting.', 'error')
        return
    end
    exports['pma-voice']:toggleMutePlayer(target)
    muted[target] = not muted[target]
    notify(('Player %s %s.'):format(target, muted[target] and 'muted' or 'unmuted'), 'success')
end)

local sounds = {
    alert = { 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS' },
    cuff = { 'Pin_Good', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS' },
    airwrench = { 'Bed', 'WastedSounds' },
}

RegisterNetEvent('codera-adminmenu:client:playSound', function(name)
    local sound = sounds[name] or sounds.alert
    PlaySoundFrontend(-1, sound[1], sound[2], true)
end)

local function stopSpectate()
    local ped = PlayerPedId()
    NetworkSetInSpectatorMode(false, ped)
    state.spectating = false
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    if spectateReturn then
        SetEntityCoords(ped, spectateReturn.x, spectateReturn.y, spectateReturn.z, false, false, false, true)
        spectateReturn = nil
    end
end

RegisterNetEvent('codera-adminmenu:client:spectate', function(targetId, coords)
    if state.spectating then
        stopSpectate()
        return
    end

    local ped = PlayerPedId()
    spectateReturn = GetEntityCoords(ped)
    state.spectating = true

    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, coords.x, coords.y, coords.z + 20.0, false, false, false, false)

    CreateThread(function()
        local player = GetPlayerFromServerId(targetId)
        local waited = 0
        while state.spectating and (player == -1 or GetPlayerPed(player) == 0) and waited < 5000 do
            Wait(100)
            waited = waited + 100
            player = GetPlayerFromServerId(targetId)
        end

        if not state.spectating then return end
        if player == -1 or GetPlayerPed(player) == 0 then
            notify('Could not spectate that player.', 'error')
            stopSpectate()
            return
        end

        NetworkSetInSpectatorMode(true, GetPlayerPed(player))

        while state.spectating do
            Wait(0)
            drawText2D(0.42, 0.93, 'Spectating - press BACKSPACE to stop', 0.4)
            if IsControlJustPressed(0, 177) or GetPlayerFromServerId(targetId) == -1 then
                stopSpectate()
            end
        end
    end)
end)

RegisterNetEvent('codera-adminmenu:client:openInventory', function(mode, kind, id, opts)
    if mode == 'ox' then
        if kind == 'player' then
            exports.ox_inventory:openInventory('player', id)
        elseif kind == 'trunk' then
            exports.ox_inventory:openInventory('trunk', { id = 'trunk' .. id })
        else
            exports.ox_inventory:openInventory('stash', id)
        end
    else
        if kind == 'player' then
            TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', id)
        elseif kind == 'trunk' then
            TriggerServerEvent('inventory:server:OpenInventory', 'trunk', id, opts)
            TriggerEvent('inventory:client:SetCurrentTrunk', id)
        else
            TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, opts)
            TriggerEvent('inventory:client:SetCurrentStash', id)
        end
    end
end)

RegisterNetEvent('codera-adminmenu:client:setWeather', function(weather)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)
    SetForceVehicleTrails(weather == 'XMAS' or weather == 'SNOW' or weather == 'BLIZZARD' or weather == 'SNOWLIGHT')
    SetForcePedFootstepsTracks(weather == 'XMAS' or weather == 'SNOW' or weather == 'BLIZZARD' or weather == 'SNOWLIGHT')
end)

RegisterNetEvent('codera-adminmenu:client:setTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute or 0, 0)
end)

RegisterNetEvent('codera-adminmenu:client:printCommands', function(names)
    print(('^2[codera-adminmenu]^7 %s registered commands:'):format(#names))
    print(table.concat(names, ', '))
    notify('Command list printed to your F8 console.', 'success')
end)

RegisterNetEvent('codera-adminmenu:client:notify', function(msg, msgType)
    Bridge.Notify(msg, msgType or 'primary')
end)

AddStateBagChangeHandler('coderaBlackout', 'global', function(_, _, value)
    SetArtificialLightsState(value == true)
    SetArtificialLightsStateAffectsVehicles(false)
end)

CreateThread(function()
    Wait(1000)
    if GlobalState.coderaBlackout then
        SetArtificialLightsState(true)
        SetArtificialLightsStateAffectsVehicles(false)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if menuOpen then SetNuiFocus(false, false) end
    for key in pairs(state) do state[key] = false end
    clearBlips()
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetPlayerInvincible(PlayerId(), false)
end)
