local commandMap = {}
for _, cmd in ipairs(Config.Commands) do
    commandMap[cmd.id] = cmd
end

local frozen = {}
local Actions = {}

local function notify(target, msg, kind)
    TriggerClientEvent('codera-adminmenu:client:notify', target, msg, kind)
end

local function frameworkAllowed(cmd)
    if not cmd.frameworks then return true end
    for _, name in ipairs(cmd.frameworks) do
        if name == Config.Framework then return true end
    end
    return false
end

local function canUse(src, cmd)
    return frameworkAllowed(cmd) and Bridge.HasPermission(src, cmd.perms or Config.Permission) and true or false
end

local function hasDb()
    return GetResourceState('oxmysql') == 'started'
end

local function safeName(value, max)
    return (tostring(value or ''):gsub('[^%w_%-%.]', ''):sub(1, max or 50))
end

local function inList(list, value)
    for _, entry in ipairs(list) do
        if entry == value then return true end
    end
    return false
end

local function randomPlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate = ''
    for _ = 1, 8 do
        local index = math.random(1, #chars)
        plate = plate .. chars:sub(index, index)
    end
    return plate
end

local function allPlayers()
    local list = {}
    for _, playerId in ipairs(GetPlayers()) do
        if Bridge.GetPlayer(playerId) then
            list[#list + 1] = tonumber(playerId)
        end
    end
    return list
end

local function buildPlayerList()
    local list = {}
    for _, playerId in ipairs(allPlayers()) do
        list[#list + 1] = {
            id = playerId,
            name = ('(%s) %s'):format(playerId, Bridge.GetName(playerId))
        }
    end
    return list
end

local function buildCommandList(src)
    local list = {}
    for _, cmd in ipairs(Config.Commands) do
        if canUse(src, cmd) then
            list[#list + 1] = cmd
        end
    end
    return list
end

local function buildLists()
    local locations = {}
    for _, loc in ipairs(Config.Locations) do
        locations[#locations + 1] = loc.label
    end

    return {
        Weathers = Config.Weathers,
        TimeOptions = Config.TimeOptions,
        Locations = locations,
        GarageStates = Config.GarageStates,
        Peds = Config.Peds,
        Items = Bridge.GetItems(),
        Vehicles = Bridge.GetVehicles(),
        Jobs = Bridge.GetJobs(),
        Gangs = Bridge.GetGangs(),
    }
end

local function findLocation(label)
    for _, loc in ipairs(Config.Locations) do
        if loc.label == label then return loc.coords end
    end
    return nil
end

local function parseAmount(value)
    local amount = math.floor(tonumber(value) or 0)
    if amount <= 0 then return nil end
    return amount
end

local function openInventoryFor(src, kind, id, opts)
    local inv = Bridge.Inventory()

    if inv == 'ox_inventory' then
        TriggerClientEvent('codera-adminmenu:client:openInventory', src, 'ox', kind, id)
    elseif inv == 'qb-inventory' then
        local ok
        if kind == 'player' then
            ok = pcall(function() exports['qb-inventory']:OpenInventoryById(src, id) end)
        else
            ok = pcall(function() exports['qb-inventory']:OpenInventory(src, id, opts) end)
        end
        if not ok then
            TriggerClientEvent('codera-adminmenu:client:openInventory', src, 'legacy', kind, id, opts)
        end
    elseif inv then
        TriggerClientEvent('codera-adminmenu:client:openInventory', src, 'legacy', kind, id, opts)
    else
        notify(src, 'No supported inventory resource found.', 'error')
    end
end

RegisterNetEvent('codera-adminmenu:server:open', function()
    local src = source
    print(('^3[codera-adminmenu]^7 open request from #%s (framework=%s)'):format(src, tostring(Config.Framework)))

    local ok, allowed = pcall(Bridge.HasPermission, src, Config.Permission)
    if not ok then
        print('^1[codera-adminmenu] permission check error: ' .. tostring(allowed) .. '^7')
        notify(src, 'Permission check error - see server console.', 'error')
        return
    end
    if not allowed then
        print(('^1[codera-adminmenu]^7 #%s denied'):format(src))
        notify(src, 'You do not have permission to use this.', 'error')
        return
    end

    local built, players, commands, lists = pcall(function()
        return buildPlayerList(), buildCommandList(src), buildLists()
    end)
    if not built then
        print('^1[codera-adminmenu] build error: ' .. tostring(players) .. '^7')
        notify(src, 'Menu build error - see server console.', 'error')
        return
    end

    print(('^2[codera-adminmenu]^7 #%s allowed, %d commands'):format(src, #commands))
    TriggerClientEvent('codera-adminmenu:client:open', src, players, commands, lists)
end)

RegisterNetEvent('codera-adminmenu:server:noclipKey', function()
    local src = source
    if Bridge.HasPermission(src, 'mod') then
        TriggerClientEvent('codera-adminmenu:client:runAction', src, 'noclip', {})
    end
end)

RegisterNetEvent('codera-adminmenu:server:requestBlips', function()
    local src = source
    if not Bridge.HasPermission(src, 'mod') then return end

    local data = {}
    for _, playerId in ipairs(allPlayers()) do
        local coords = GetEntityCoords(GetPlayerPed(playerId))
        data[#data + 1] = { id = playerId, name = ('[%s] %s'):format(playerId, Bridge.GetName(playerId)), x = coords.x, y = coords.y, z = coords.z }
    end
    TriggerClientEvent('codera-adminmenu:client:blipsData', src, data)
end)

Actions.make_drunk = function(src, p, target)
    TriggerClientEvent('codera-adminmenu:client:makeDrunk', target, Config.DrunkDuration)
    notify(src, 'Drunk effect applied.', 'success')
end

Actions.set_perms = function(src, p, target)
    local group = safeName(p.group, 30)
    if not inList(Config.PermissionGroups, group) then
        notify(src, 'Invalid permission group.', 'error')
        return
    end
    if Bridge.SetPermission(target, group) then
        notify(src, ('Set %s to %s.'):format(Bridge.GetName(target), group), 'success')
    else
        notify(src, 'Could not set permission group.', 'error')
    end
end

Actions.give_money = function(src, p, target)
    local amount = parseAmount(p.amount)
    local kind = p.type or Config.MoneyTypes[1]
    if not amount or not inList(Config.MoneyTypes, kind) then
        notify(src, 'Invalid amount or money type.', 'error')
        return
    end
    Bridge.AddMoney(target, kind, amount, 'admin-give')
    notify(src, ('Gave %s %s to %s.'):format(amount, kind, Bridge.GetName(target)), 'success')
    notify(target, ('An admin gave you %s %s.'):format(amount, kind), 'success')
end

Actions.give_money_all = function(src, p)
    local amount = parseAmount(p.amount)
    local kind = p.type or Config.MoneyTypes[1]
    if not amount or not inList(Config.MoneyTypes, kind) then
        notify(src, 'Invalid amount or money type.', 'error')
        return
    end
    local count = 0
    for _, playerId in ipairs(allPlayers()) do
        Bridge.AddMoney(playerId, kind, amount, 'admin-give-all')
        notify(playerId, ('An admin gave you %s %s.'):format(amount, kind), 'success')
        count = count + 1
    end
    notify(src, ('Gave %s %s to %s player(s).'):format(amount, kind, count), 'success')
end

Actions.remove_money = function(src, p, target)
    local amount = parseAmount(p.amount)
    local kind = p.type or Config.MoneyTypes[1]
    if not amount or not inList(Config.MoneyTypes, kind) then
        notify(src, 'Invalid amount or money type.', 'error')
        return
    end
    Bridge.RemoveMoney(target, kind, amount, 'admin-remove')
    notify(src, ('Removed %s %s from %s.'):format(amount, kind, Bridge.GetName(target)), 'success')
    notify(target, ('An admin removed %s %s from you.'):format(amount, kind), 'error')
end

Actions.give_item = function(src, p, target)
    local item = safeName(p.item, 60)
    local amount = parseAmount(p.amount)
    if item == '' or not amount then
        notify(src, 'Invalid item or amount.', 'error')
        return
    end
    if Bridge.GiveItem(target, item, amount) then
        notify(src, ('Gave %sx %s to %s.'):format(amount, item, Bridge.GetName(target)), 'success')
    else
        notify(src, 'Could not give that item.', 'error')
    end
end

Actions.give_item_all = function(src, p)
    local item = safeName(p.item, 60)
    local amount = parseAmount(p.amount)
    if item == '' or not amount then
        notify(src, 'Invalid item or amount.', 'error')
        return
    end
    local count = 0
    for _, playerId in ipairs(allPlayers()) do
        if Bridge.GiveItem(playerId, item, amount) then
            count = count + 1
        end
    end
    notify(src, ('Gave %sx %s to %s player(s).'):format(amount, item, count), 'success')
end

Actions.set_job = function(src, p, target)
    local job = safeName(p.job, 50)
    local grade = math.floor(tonumber(p.grade) or 0)
    if Bridge.SetJob(target, job, grade) then
        notify(src, ('Set %s job to %s (%s).'):format(Bridge.GetName(target), job, grade), 'success')
        notify(target, ('Your job was set to %s.'):format(job), 'primary')
    else
        notify(src, 'Invalid job or grade.', 'error')
    end
end

Actions.set_gang = function(src, p, target)
    local gang = safeName(p.gang, 50)
    local grade = math.floor(tonumber(p.grade) or 0)
    if Bridge.SetGang(target, gang, grade) then
        notify(src, ('Set %s gang to %s (%s).'):format(Bridge.GetName(target), gang, grade), 'success')
        notify(target, ('Your gang was set to %s.'):format(gang), 'primary')
    else
        notify(src, 'Invalid gang or grade.', 'error')
    end
end

Actions.toggle_duty = function(src)
    local state = Bridge.ToggleDuty(src)
    if state == nil then return end
    notify(src, state and 'You are now on duty.' or 'You are now off duty.', 'primary')
end

Actions.bring_player = function(src, p, target)
    local coords = GetEntityCoords(GetPlayerPed(src))
    TriggerClientEvent('codera-adminmenu:client:bringHere', target, { x = coords.x, y = coords.y, z = coords.z })
    notify(src, ('Brought %s to you.'):format(Bridge.GetName(target)), 'success')
end

Actions.teleport_to_player = function(src, p, target)
    local coords = GetEntityCoords(GetPlayerPed(target))
    TriggerClientEvent('codera-adminmenu:client:teleport', src, { x = coords.x, y = coords.y, z = coords.z })
end

Actions.teleport_location = function(src, p)
    local coords = findLocation(p.value)
    if coords then
        TriggerClientEvent('codera-adminmenu:client:teleport', src, { x = coords.x, y = coords.y, z = coords.z, w = coords.w })
    end
end

Actions.kick_player = function(src, p, target)
    local reason = tostring(p.reason or ''):sub(1, 200)
    if reason == '' then reason = 'No reason given' end
    local name = Bridge.GetName(target)
    DropPlayer(target, ('You were kicked by an admin.\nReason: %s'):format(reason))
    notify(src, ('Kicked %s.'):format(name), 'success')
end

Actions.warn_player = function(src, p, target)
    local reason = tostring(p.reason or ''):sub(1, 200)
    if reason == '' then reason = 'No reason given' end
    notify(target, ('You have been warned: %s'):format(reason), 'error')
    notify(src, ('Warned %s.'):format(Bridge.GetName(target)), 'success')
end

Actions.ban_player = function(src, p, target)
    if not hasDb() then
        notify(src, 'oxmysql is required for bans.', 'error')
        return
    end

    local reason = tostring(p.reason or ''):sub(1, 200)
    if reason == '' then reason = 'No reason given' end

    local duration = tonumber(p.duration) or 600
    local expire = duration >= 2147483647 and 2147483647 or os.time() + math.floor(duration)

    local name = GetPlayerName(target) or 'Unknown'
    local license = GetPlayerIdentifierByType(target, 'license') or ''
    local discord = GetPlayerIdentifierByType(target, 'discord') or ''
    local ip = GetPlayerIdentifierByType(target, 'ip') or ''
    local adminName = GetPlayerName(src) or 'Unknown'

    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        exports.oxmysql:insert_async(
            'INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { name, license, discord, ip, reason, expire, adminName }
        )
    else
        exports.oxmysql:insert_async(
            'INSERT INTO codera_bans (name, license, discord, ip, reason, expire, banned_by) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { name, license, discord, ip, reason, expire, adminName }
        )
    end

    DropPlayer(target, ('You were banned by an admin.\nReason: %s'):format(reason))
    notify(src, ('Banned %s.'):format(name), 'success')
end

Actions.freeze_player = function(src, p, target)
    frozen[target] = not frozen[target]
    TriggerClientEvent('codera-adminmenu:client:freeze', target, frozen[target])
    notify(src, ('%s %s.'):format(frozen[target] and 'Froze' or 'Unfroze', Bridge.GetName(target)), 'success')
end

Actions.mute_player = function(src, p, target)
    TriggerClientEvent('codera-adminmenu:client:mutePlayer', src, target)
end

Actions.spectate_player = function(src, p, target)
    if target == src then
        notify(src, 'You cannot spectate yourself.', 'error')
        return
    end
    local coords = GetEntityCoords(GetPlayerPed(target))
    TriggerClientEvent('codera-adminmenu:client:spectate', src, target, { x = coords.x, y = coords.y, z = coords.z })
end

Actions.revive_player = function(src, p, target)
    TriggerClientEvent(Config.ReviveEvent, target)
    notify(src, ('Revived %s.'):format(Bridge.GetName(target)), 'success')
end

Actions.revive_all = function(src)
    local count = 0
    for _, playerId in ipairs(allPlayers()) do
        TriggerClientEvent(Config.ReviveEvent, playerId)
        count = count + 1
    end
    notify(src, ('Revived %s player(s).'):format(count), 'success')
end

Actions.revive_radius = function(src)
    local coords = GetEntityCoords(GetPlayerPed(src))
    local count = 0
    for _, playerId in ipairs(allPlayers()) do
        local pcoords = GetEntityCoords(GetPlayerPed(playerId))
        if #(coords - pcoords) <= Config.ReviveRadius then
            TriggerClientEvent(Config.ReviveEvent, playerId)
            count = count + 1
        end
    end
    notify(src, ('Revived %s player(s) nearby.'):format(count), 'success')
end

Actions.clothing_menu = function(src, p, target)
    local event
    if GetResourceState('illenium-appearance') == 'started' then
        event = 'illenium-appearance:client:openClothingShop'
    elseif GetResourceState('qb-clothing') == 'started' then
        event = 'qb-clothing:client:openMenu'
    elseif GetResourceState('esx_skin') == 'started' then
        event = 'esx_skin:openSaveableMenu'
    end

    if not event then
        notify(src, 'No supported clothing resource found.', 'error')
        return
    end

    TriggerClientEvent(event, target, true)
    notify(src, ('Opened the clothing menu for %s.'):format(Bridge.GetName(target)), 'success')
end

Actions.set_ped = function(src, p, target)
    local ped = safeName(p.ped, 60)
    if ped == '' then
        notify(src, 'Enter a ped model.', 'error')
        return
    end
    TriggerClientEvent('codera-adminmenu:client:setPed', target, ped)
    notify(src, ('Changed the ped of %s.'):format(Bridge.GetName(target)), 'success')
end

Actions.toggle_cuffs = function(src, p, target)
    if not Config.CuffEvent then
        notify(src, 'Set Config.CuffEvent for cuffs.', 'error')
        return
    end
    TriggerClientEvent(Config.CuffEvent, target, src)
    notify(src, ('Toggled cuffs on %s.'):format(Bridge.GetName(target)), 'success')
end

Actions.open_inventory = function(src, p, target)
    openInventoryFor(src, 'player', target)
end

Actions.clear_inventory = function(src, p, target)
    if Bridge.ClearInventory(target) then
        notify(src, ('Cleared the inventory of %s.'):format(Bridge.GetName(target)), 'success')
        notify(target, 'An admin cleared your inventory.', 'error')
    else
        notify(src, 'Could not clear that inventory.', 'error')
    end
end

Actions.clear_inventory_offline = function(src, p)
    local identifier = safeName(p.identifier, 60)
    if identifier == '' then
        notify(src, 'Enter a citizen ID.', 'error')
        return
    end
    if Bridge.ClearInventoryOffline(identifier) then
        notify(src, ('Cleared the inventory of %s.'):format(identifier), 'success')
    else
        notify(src, 'No player found with that ID (or oxmysql is missing).', 'error')
    end
end

Actions.remove_stress = function(src, p, target)
    Bridge.SetStress(target)
    notify(src, ('Removed stress from %s.'):format(Bridge.GetName(target)), 'success')
end

Actions.set_bucket = function(src, p, target)
    local bucket = math.floor(tonumber(p.bucket) or 0)
    SetPlayerRoutingBucket(target, bucket)
    notify(src, ('Set the bucket of %s to %s.'):format(Bridge.GetName(target), bucket), 'success')
end

Actions.get_bucket = function(src, p, target)
    notify(src, ('%s is in bucket %s.'):format(Bridge.GetName(target), GetPlayerRoutingBucket(target)), 'primary')
end

Actions.play_sound = function(src, p, target)
    TriggerClientEvent('codera-adminmenu:client:playSound', target, tostring(p.sound or 'alert'))
    notify(src, 'Sound played.', 'success')
end

Actions.fix_vehicle_for = function(src, p, target)
    TriggerClientEvent('codera-adminmenu:client:fixVehicle', target)
    notify(src, ('Fixed the vehicle of %s.'):format(Bridge.GetName(target)), 'success')
end

Actions.give_car = function(src, p, target)
    if not hasDb() then
        notify(src, 'oxmysql is required for this command.', 'error')
        return
    end

    local model = safeName(p.vehicle, 40)
    if model == '' then
        notify(src, 'Enter a vehicle model.', 'error')
        return
    end

    local plate = safeName(p.plate, 8):upper()
    if plate == '' then plate = randomPlate() end

    local garage = tostring(p.garage or ''):gsub('[^%w_%- ]', ''):sub(1, 50)
    if garage == '' then garage = Config.DefaultGarage end

    local table_, plateColumn = 'player_vehicles', 'plate'
    if Config.Framework == 'esx' then table_ = 'owned_vehicles' end

    local exists = exports.oxmysql:scalar_async(('SELECT COUNT(*) FROM %s WHERE %s = ?'):format(table_, plateColumn), { plate })
    if (exists or 0) > 0 then
        notify(src, 'That plate is already in use.', 'error')
        return
    end

    local hash = joaat(model)

    if Config.Framework == 'esx' then
        local identifier = Bridge.GetIdentifier(target)
        exports.oxmysql:insert_async(
            'INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (?, ?, ?, ?)',
            { identifier, plate, json.encode({ model = hash, plate = plate }), 1 }
        )
    else
        local identifier = Bridge.GetIdentifier(target)
        local license = GetPlayerIdentifierByType(target, 'license') or ''
        exports.oxmysql:insert_async(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            { license, identifier, model, tostring(hash), '{}', plate, garage, 1 }
        )
    end

    notify(src, ('Gave %s (%s) to %s.'):format(model, plate, Bridge.GetName(target)), 'success')
    notify(target, ('You received a vehicle: %s (%s).'):format(model, plate), 'success')
end

Actions.set_garage_state = function(src, p)
    if not hasDb() then
        notify(src, 'oxmysql is required for this command.', 'error')
        return
    end

    local plate = safeName(p.plate, 8):upper()
    local state = tostring(p.state or '')
    if plate == '' or not inList(Config.GarageStates, state) then
        notify(src, 'Invalid plate or state.', 'error')
        return
    end

    local affected
    if Config.Framework == 'esx' then
        local stored = state == 'garaged' and 1 or 0
        affected = exports.oxmysql:update_async('UPDATE owned_vehicles SET stored = ? WHERE plate = ?', { stored, plate })
    else
        local map = { out = 0, garaged = 1, impound = 2 }
        affected = exports.oxmysql:update_async('UPDATE player_vehicles SET state = ? WHERE plate = ?', { map[state], plate })
    end

    if (affected or 0) > 0 then
        notify(src, ('Vehicle %s set to %s.'):format(plate, state), 'success')
    else
        notify(src, 'No owned vehicle found with that plate.', 'error')
    end
end

Actions.spawn_personal_vehicle = function(src, p)
    if not hasDb() then
        notify(src, 'oxmysql is required for this command.', 'error')
        return
    end

    local plate = safeName(p.plate, 8):upper()
    if plate == '' then
        notify(src, 'Enter a plate.', 'error')
        return
    end

    local model
    if Config.Framework == 'esx' then
        local row = exports.oxmysql:single_async('SELECT vehicle FROM owned_vehicles WHERE plate = ?', { plate })
        local data = row and json.decode(row.vehicle)
        model = data and data.model
    else
        local row = exports.oxmysql:single_async('SELECT vehicle, hash FROM player_vehicles WHERE plate = ?', { plate })
        model = row and (row.vehicle ~= '' and row.vehicle or row.hash)
    end

    if not model then
        notify(src, 'No owned vehicle found with that plate.', 'error')
        return
    end

    TriggerClientEvent('codera-adminmenu:client:spawnVehicle', src, model, plate)
end

Actions.open_trunk = function(src, p)
    local plate = safeName(p.plate, 8):upper()
    if plate == '' then
        notify(src, 'Enter a plate.', 'error')
        return
    end
    openInventoryFor(src, 'trunk', plate, { maxweight = Config.TrunkMaxWeight, slots = Config.TrunkSlots })
end

Actions.open_stash = function(src, p)
    local stash = safeName(p.stash, 50)
    if stash == '' then
        notify(src, 'Enter a stash ID.', 'error')
        return
    end

    local stashId = 'stash_' .. stash
    local opts = { maxweight = Config.StashMaxWeight, slots = Config.StashSlots, label = 'Stash ' .. stash }

    if Bridge.Inventory() == 'ox_inventory' then
        exports.ox_inventory:RegisterStash(stashId, opts.label, opts.slots, opts.maxweight)
    end
    openInventoryFor(src, 'stash', stashId, opts)
end

Actions.change_weather = function(src, p)
    local weather = safeName(p.value, 30):upper()
    if not inList(Config.Weathers, weather) then
        notify(src, 'Invalid weather.', 'error')
        return
    end
    TriggerClientEvent(Config.WeatherEvent, -1, weather)
    notify(src, ('Weather set to %s.'):format(weather), 'success')
end

Actions.change_time = function(src, p)
    local hour = (math.floor(tonumber(p.value) or 12)) % 24
    TriggerClientEvent(Config.TimeEvent, -1, hour, 0)
    notify(src, ('Time set to %02d:00.'):format(hour), 'success')
end

Actions.blackout = function(src)
    local state = not GlobalState.coderaBlackout
    GlobalState.coderaBlackout = state
    notify(src, state and 'Blackout enabled.' or 'Blackout disabled.', 'primary')
end

Actions.resource_control = function(src, p)
    local resource = safeName(p.resource, 60)
    local action = tostring(p.action or '')

    if resource == '' or not inList({ 'restart', 'start', 'stop', 'ensure' }, action) then
        notify(src, 'Invalid resource or action.', 'error')
        return
    end

    if resource == GetCurrentResourceName() then
        notify(src, 'You cannot control this resource from its own menu.', 'error')
        return
    end

    if GetResourceState(resource) == 'missing' then
        notify(src, 'Resource not found.', 'error')
        return
    end

    ExecuteCommand(('%s %s'):format(action, resource))
    notify(src, ('%s %s.'):format(action, resource), 'success')
end

Actions.show_commands = function(src)
    local names = {}
    for _, cmd in ipairs(GetRegisteredCommands()) do
        names[#names + 1] = cmd.name
    end
    table.sort(names)
    TriggerClientEvent('codera-adminmenu:client:printCommands', src, names)
end

RegisterNetEvent('codera-adminmenu:server:runCommand', function(id, payload)
    local src = source
    if type(id) ~= 'string' or type(payload) ~= 'table' then return end

    local cmd = commandMap[id]
    local action = Actions[id]
    if not cmd or not action then return end

    if not canUse(src, cmd) then
        notify(src, 'You do not have permission to use this.', 'error')
        return
    end

    if not Bridge.GetPlayer(src) then return end

    local target
    if cmd.type == 'player' then
        local targetId = tonumber(payload.player)
        if (not targetId) and cmd.optionalPlayer then
            targetId = src
        end
        if not targetId or not Bridge.GetPlayer(targetId) then
            notify(src, 'Player is not online.', 'error')
            return
        end
        target = targetId
    end

    action(src, payload, target)
end)

if Config.Framework ~= 'qb' and Config.Framework ~= 'qbx' then
    CreateThread(function()
        Wait(2000)
        if hasDb() then
            exports.oxmysql:query_async([[CREATE TABLE IF NOT EXISTS codera_bans (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100),
                license VARCHAR(100),
                discord VARCHAR(100),
                ip VARCHAR(100),
                reason TEXT,
                expire INT,
                banned_by VARCHAR(100),
                INDEX (license)
            )]])
        end
    end)

    AddEventHandler('playerConnecting', function(_, _, deferrals)
        local src = source
        deferrals.defer()
        Wait(0)

        if hasDb() then
            local license = GetPlayerIdentifierByType(src, 'license')
            local row = license and exports.oxmysql:single_async(
                'SELECT reason, expire FROM codera_bans WHERE license = ? AND expire > ? ORDER BY expire DESC LIMIT 1',
                { license, os.time() }
            )
            if row then
                deferrals.done(('You are banned.\nReason: %s'):format(row.reason or 'No reason given'))
                return
            end
        end

        deferrals.done()
    end)
end

AddEventHandler('playerDropped', function()
    frozen[source] = nil
end)
