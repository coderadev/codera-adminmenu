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

function Bridge.Notify(msg, kind)
    local ok = pcall(Bridge.NotifyFramework, msg, kind)
    if not ok then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(tostring(msg))
        EndTextCommandThefeedPostTicker(false, false)
    end
end

function Bridge.NotifyFramework(msg, kind)
    loadCore()
    kind = kind or 'primary'

    if framework == 'qb' then
        QBCore.Functions.Notify(msg, kind)
    elseif framework == 'qbx' then
        exports.qbx_core:Notify(msg, kind == 'primary' and 'inform' or kind)
    elseif framework == 'esx' then
        ESX.ShowNotification(msg, kind == 'primary' and 'info' or kind)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, false)
    end
end
