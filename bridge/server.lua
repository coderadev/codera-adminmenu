Bridge = {}

local framework = Config.Framework
local QBCore, ESX

local function loadCore()
    if framework == 'qb' and not QBCore then
        pcall(function() QBCore = exports['qb-core']:GetCoreObject() end)
    elseif framework == 'esx' and not ESX then
        pcall(function() ESX = exports['es_extended']:getSharedObject() end)
    end
end
loadCore()

local function started(name)
    return GetResourceState(name) == 'started'
end

local function toList(source, labelOf)
    local list = {}
    for name, data in pairs(source or {}) do
        local key = tostring(name)
        local ok, label = pcall(labelOf, name, data)
        if not ok or label == nil then label = key end
        list[#list + 1] = { value = key, label = tostring(label) }
    end
    table.sort(list, function(a, b) return a.value < b.value end)
    return list
end

function Bridge.Inventory()
    loadCore()
    if started('ox_inventory') then return 'ox_inventory' end
    if started('ps-inventory') then return 'ps-inventory' end
    if started('lj-inventory') then return 'lj-inventory' end
    if started('qb-inventory') then return 'qb-inventory' end
    return nil
end

function Bridge.GetPlayer(src)
    loadCore()
    src = tonumber(src)
    if not src then return nil end

    if framework == 'qb' then
        return QBCore.Functions.GetPlayer(src)
    elseif framework == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    elseif framework == 'esx' then
        return ESX.GetPlayerFromId(src)
    end

    return GetPlayerName(src) and { source = src } or nil
end

function Bridge.GetName(src)
    loadCore()
    local player = Bridge.GetPlayer(src)
    if not player then return GetPlayerName(src) or 'Unknown' end

    if framework == 'esx' then
        return player.getName() or GetPlayerName(src)
    end

    local info = player.PlayerData and player.PlayerData.charinfo
    if info then
        return ('%s %s'):format(info.firstname, info.lastname)
    end

    return GetPlayerName(src) or 'Unknown'
end

function Bridge.GetIdentifier(src)
    loadCore()
    local player = Bridge.GetPlayer(src)
    if not player then return nil end

    if framework == 'esx' then
        return player.identifier
    end

    return player.PlayerData and player.PlayerData.citizenid
end

local LEVELS = {
    mod = { 'mod', 'admin', 'god', 'superadmin' },
    admin = { 'admin', 'god', 'superadmin' },
    god = { 'god', 'superadmin' },
}

local function aceCheck(src, level)
    for _, l in ipairs(LEVELS[level] or { level }) do
        if IsPlayerAceAllowed(src, l)
            or IsPlayerAceAllowed(src, 'group.' .. l)
            or IsPlayerAceAllowed(src, 'qbcore.' .. l)
            or IsPlayerAceAllowed(src, 'qbox.' .. l) then
            return true
        end
    end
    return IsPlayerAceAllowed(src, 'command')
end

local RANK = { user = 0, mod = 1, admin = 2, god = 3, superadmin = 3 }

local function identifierCheck(src, level)
    if not Config.Admins then return false end
    local need = RANK[level] or RANK.admin
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        local rank = Config.Admins[id]
        if rank and (RANK[rank] or 0) >= need then return true end
    end
    return false
end

function Bridge.HasPermission(src, level)
    loadCore()
    level = level or Config.Permission
    src = tonumber(src)
    if not src then return false end

    if identifierCheck(src, level) then return true end

    if framework == 'esx' then
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        local group = player.getGroup()
        for _, allowed in ipairs(Config.EsxGroups[level] or Config.EsxGroups.admin) do
            if group == allowed then return true end
        end
        return false
    end

    if framework == 'qb' then
        local ok, res = pcall(QBCore.Functions.HasPermission, src, level)
        if ok and res then return true end
    elseif framework == 'qbx' then
        local ok, res = pcall(function() return exports.qbx_core:HasPermission(src, level) end)
        if ok and res then return true end
    end

    return aceCheck(src, level)
end

RegisterCommand('adminmenu_perm', function(src)
    if src == 0 then return print('Run this in-game.') end
    local lines = { ('framework=%s'):format(Config.Framework) }
    for _, l in ipairs({ 'mod', 'admin', 'god' }) do
        lines[#lines + 1] = ('%s=%s'):format(l, tostring(Bridge.HasPermission(src, l)))
    end
    for _, ace in ipairs({ 'mod', 'admin', 'god', 'command', 'group.admin', 'qbcore.admin' }) do
        lines[#lines + 1] = ('ace[%s]=%s'):format(ace, tostring(IsPlayerAceAllowed(src, ace)))
    end
    print(('[codera-adminmenu] #%d -> %s'):format(src, table.concat(lines, ' | ')))
    TriggerClientEvent('codera-adminmenu:client:notify', src, table.concat(lines, ' | ', 1, 4), 'primary')
end, false)

function Bridge.SetPermission(src, group)
    loadCore()
    if framework == 'qb' then
        if group == 'user' then
            QBCore.Functions.RemovePermission(src)
        else
            QBCore.Functions.RemovePermission(src)
            QBCore.Functions.AddPermission(src, group)
        end
        return true
    elseif framework == 'qbx' then
        local ok
        if group == 'user' then
            ok = pcall(function() exports.qbx_core:RemovePermission(src) end)
        else
            ok = pcall(function()
                exports.qbx_core:RemovePermission(src)
                exports.qbx_core:AddPermission(src, group)
            end)
        end
        return ok
    elseif framework == 'esx' then
        local player = ESX.GetPlayerFromId(src)
        if not player then return false end
        player.setGroup(group)
        return true
    end

    return false
end

function Bridge.AddMoney(src, kind, amount, reason)
    loadCore()
    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if framework == 'qb' or framework == 'qbx' then
        return player.Functions.AddMoney(kind, amount, reason)
    elseif framework == 'esx' then
        if kind == 'money' then
            player.addMoney(amount, reason)
        else
            player.addAccountMoney(kind, amount, reason)
        end
        return true
    end

    return false
end

function Bridge.RemoveMoney(src, kind, amount, reason)
    loadCore()
    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if framework == 'qb' or framework == 'qbx' then
        return player.Functions.RemoveMoney(kind, amount, reason)
    elseif framework == 'esx' then
        if kind == 'money' then
            player.removeMoney(amount, reason)
        else
            player.removeAccountMoney(kind, amount, reason)
        end
        return true
    end

    return false
end

function Bridge.SetJob(src, job, grade)
    loadCore()
    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if framework == 'qb' or framework == 'qbx' then
        return player.Functions.SetJob(job, grade) and true or false
    elseif framework == 'esx' then
        if not ESX.DoesJobExist(job, grade) then return false end
        player.setJob(job, grade)
        return true
    end

    return false
end

function Bridge.SetGang(src, gang, grade)
    loadCore()
    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if framework == 'qb' or framework == 'qbx' then
        return player.Functions.SetGang(gang, grade) and true or false
    end

    return false
end

function Bridge.ToggleDuty(src)
    loadCore()
    local player = Bridge.GetPlayer(src)
    if not player or not player.PlayerData then return nil end

    local newState = not player.PlayerData.job.onduty
    player.Functions.SetJobDuty(newState)
    return newState
end

function Bridge.SetStress(src)
    loadCore()
    local player = Bridge.GetPlayer(src)
    if not player then return end

    if framework == 'qb' or framework == 'qbx' then
        player.Functions.SetMetaData('stress', 0)
        TriggerClientEvent('hud:client:UpdateStress', src, 0)
    elseif framework == 'esx' then
        TriggerClientEvent('esx_status:set', src, 'stress', 0)
    end
end

function Bridge.GiveItem(src, item, amount)
    loadCore()
    local inv = Bridge.Inventory()

    if inv == 'ox_inventory' then
        return exports.ox_inventory:AddItem(src, item, amount) and true or false
    end

    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if framework == 'qb' or framework == 'qbx' then
        return player.Functions.AddItem(item, amount) and true or false
    elseif framework == 'esx' then
        player.addInventoryItem(item, amount)
        return true
    end

    return false
end

function Bridge.ClearInventory(src)
    loadCore()
    local inv = Bridge.Inventory()

    if inv == 'ox_inventory' then
        exports.ox_inventory:ClearInventory(src)
        return true
    end

    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if framework == 'qb' or framework == 'qbx' then
        if inv == 'qb-inventory' then
            local ok = pcall(function() exports['qb-inventory']:ClearInventory(src) end)
            if ok then return true end
        end
        player.Functions.ClearInventory()
        return true
    elseif framework == 'esx' then
        for _, item in pairs(player.getInventory()) do
            if item.count > 0 then
                player.setInventoryItem(item.name, 0)
            end
        end
        return true
    end

    return false
end

function Bridge.ClearInventoryOffline(identifier)
    loadCore()
    if GetResourceState('oxmysql') ~= 'started' then return false end

    if framework == 'qb' or framework == 'qbx' then
        return (exports.oxmysql:update_async('UPDATE players SET inventory = ? WHERE citizenid = ?', { '[]', identifier }) or 0) > 0
    elseif framework == 'esx' then
        return (exports.oxmysql:update_async('UPDATE users SET inventory = ? WHERE identifier = ?', { '[]', identifier }) or 0) > 0
    end

    return false
end

function Bridge.GetItems()
    loadCore()
    if started('ox_inventory') then
        local ok, items = pcall(function() return exports.ox_inventory:Items() end)
        if ok and items then
            return toList(items, function(name, data) return data.label or name end)
        end
    end

    if framework == 'qb' then
        return toList(QBCore.Shared.Items, function(name, data) return data.label or name end)
    elseif framework == 'esx' and ESX.Items then
        return toList(ESX.Items, function(name, data) return data.label or name end)
    end

    return {}
end

function Bridge.GetVehicles()
    loadCore()
    local source

    if framework == 'qb' then
        source = QBCore.Shared.Vehicles
    elseif framework == 'qbx' then
        local ok, vehicles = pcall(function() return exports.qbx_core:GetVehiclesByName() end)
        source = ok and vehicles or {}
    end

    return toList(source, function(name, data)
        local brand = data.brand or ''
        local label = data.name or name
        return (brand ~= '' and (brand .. ' ' .. label) or label)
    end)
end

function Bridge.GetJobs()
    loadCore()
    local source

    if framework == 'qb' then
        source = QBCore.Shared.Jobs
    elseif framework == 'qbx' then
        local ok, jobs = pcall(function() return exports.qbx_core:GetJobs() end)
        source = ok and jobs or {}
    elseif framework == 'esx' then
        source = ESX.Jobs
    end

    return toList(source, function(name, data) return data.label or name end)
end

function Bridge.GetGangs()
    loadCore()
    local source

    if framework == 'qb' then
        source = QBCore.Shared.Gangs
    elseif framework == 'qbx' then
        local ok, gangs = pcall(function() return exports.qbx_core:GetGangs() end)
        source = ok and gangs or {}
    end

    return toList(source, function(name, data) return data.label or name end)
end
