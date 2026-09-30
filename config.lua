Config = {}

Config.Framework = 'auto'

local function isPresent(name)
    local state = GetResourceState(name)
    return state ~= 'missing' and state ~= 'unknown'
end

if Config.Framework == 'auto' then
    if isPresent('qbx_core') then
        Config.Framework = 'qbx'
    elseif isPresent('qb-core') then
        Config.Framework = 'qb'
    elseif isPresent('es_extended') then
        Config.Framework = 'esx'
    else
        Config.Framework = 'none'
    end
end

Config.Permission = 'mod'
Config.ResourcePerms = 'admin'
Config.ShowCommandsPerms = 'admin'

-- Identifier-based admins (works even if ACE / principals are misconfigured).
-- Rank: 'mod' < 'admin' < 'god'. Identifiers: discord:ID or license:HASH
Config.Admins = {
    ['discord:547851682839658517']  = 'god',
    ['discord:765197614336704553']  = 'god',
    ['discord:852907065692258315']  = 'god',
    ['discord:1029375829127467028'] = 'god',
    ['discord:812357995023433779']  = 'god',
    ['discord:893958983486963712']  = 'god',
}

Config.EsxGroups = {
    mod = { 'mod', 'admin', 'superadmin' },
    admin = { 'admin', 'superadmin' },
    god = { 'superadmin' },
}

Config.PermissionGroups = ({
    qb  = { 'user', 'mod', 'admin', 'god' },
    qbx = { 'user', 'mod', 'admin', 'god' },
    esx = { 'user', 'mod', 'admin', 'superadmin' },
})[Config.Framework] or { 'user', 'mod', 'admin', 'god' }

Config.Keybindings = true
Config.OpenKey = 'F6'
Config.NoclipKey = 'PageUp'
Config.Command = 'adminmenu'

Config.Fuel = 'auto'
Config.DefaultGarage = 'pillboxgarage'
Config.RenewedPhone = false

Config.AdminVehicle = 'admincar'

Config.Weathers = {
    'EXTRASUNNY', 'CLEAR', 'NEUTRAL', 'SMOG', 'FOGGY', 'OVERCAST', 'CLOUDS',
    'CLEARING', 'RAIN', 'THUNDER', 'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS', 'HALLOWEEN'
}
Config.WeatherEvent = 'codera-adminmenu:client:setWeather'

Config.TimeOptions = {
    { label = 'Sunrise', value = '6' },
    { label = 'Morning', value = '9' },
    { label = 'Noon',    value = '12' },
    { label = 'Sunset',  value = '21' },
    { label = 'Evening', value = '22' },
    { label = 'Night',   value = '0' },
}
Config.TimeEvent = 'codera-adminmenu:client:setTime'

Config.Locations = {
    { label = 'Pillbox Hospital',   coords = vector4(308.7, -595.0, 43.2, 205.9) },
    { label = 'Legion Square',      coords = vector4(195.8, -933.6, 30.7, 358.0) },
    { label = 'Sandy Shores',       coords = vector4(1961.7, 3740.5, 32.3, 305.0) },
    { label = 'Paleto Bay PD',      coords = vector4(-448.6, 6012.0, 31.7, 225.0) },
    { label = 'Airport',            coords = vector4(-1034.6, -2733.6, 20.2, 240.0) },
}

Config.Peds = {
    'mp_m_freemode_01', 'mp_f_freemode_01', 'a_m_m_business_01', 'a_m_y_hipster_01', 'a_f_y_hipster_01',
    'a_m_y_beach_01', 'a_f_y_beach_01', 'a_m_y_skater_01', 'a_m_y_runner_01', 'a_f_y_fitness_01',
    's_m_y_cop_01', 's_f_y_cop_01', 's_m_y_sheriff_01', 's_m_y_swat_01', 's_m_m_paramedic_01',
    's_m_y_fireman_01', 's_m_y_construct_01', 's_m_m_doctor_01', 's_f_y_scrubs_01', 's_m_m_pilot_01',
    'a_m_m_farmer_01', 'a_m_m_hillbilly_01', 'a_m_y_gay_01', 'a_m_y_musclbeac_01', 'a_m_m_tramp_01',
    'g_m_y_ballaeast_01', 'g_m_y_famca_01', 'g_m_y_lost_01', 'g_m_y_mexgoon_01', 'g_m_y_korean_01',
    'u_m_y_zombie_01', 'u_m_y_juggernaut_01', 'u_m_y_pogo_01', 'u_m_m_jesus_01', 'ig_lestercrest',
    'ig_trevor', 'player_zero', 'player_one', 'player_two', 'a_c_deer',
    'a_c_husky', 'a_c_cat_01', 'a_c_chimp', 'a_c_cow', 'a_c_pig',
    'a_c_rottweiler', 'a_c_shepherd', 'a_c_hen', 'a_c_rabbit_01', 'a_c_mtlion'
}

Config.ReviveRadius = 15.0
Config.ReviveEvent = ({
    qb  = 'hospital:client:Revive',
    qbx = 'qbx_medical:client:playerRevived',
    esx = 'esx_ambulancejob:revive'
})[Config.Framework] or 'hospital:client:Revive'

Config.CuffEvent = ({
    qb  = 'police:client:GetCuffed',
    qbx = 'police:client:GetCuffed',
    esx = 'esx_policejob:handcuff'
})[Config.Framework]

Config.DrunkDuration = 30000

Config.MoneyTypes = ({
    qb  = { 'cash', 'bank', 'crypto' },
    qbx = { 'cash', 'bank', 'crypto' },
    esx = { 'money', 'bank', 'black_money' }
})[Config.Framework] or { 'cash', 'bank' }

Config.StashMaxWeight = 4000000
Config.StashSlots = 500

Config.TrunkMaxWeight = 60000
Config.TrunkSlots = 50

Config.GarageStates = { 'out', 'garaged', 'impound' }

Config.BanDurations = {
    { label = 'Permanent',  value = '2147483647' },
    { label = '10 Minutes', value = '600' },
    { label = '30 Minutes', value = '1800' },
    { label = '1 Hour',     value = '3600' },
    { label = '6 Hours',    value = '21600' },
    { label = '12 Hours',   value = '43200' },
    { label = '1 Day',      value = '86400' },
    { label = '3 Days',     value = '259200' },
    { label = '1 Week',     value = '604800' },
    { label = '3 Weeks',    value = '1814400' },
}

Config.Sounds = {
    { label = 'Alert',      value = 'alert' },
    { label = 'Cuff',       value = 'cuff' },
    { label = 'Air Wrench', value = 'airwrench' },
}

Config.Commands = {
    { id = 'noclip', label = 'Noclip', desc = 'Toggle noclip for yourself', category = 'user', icon = 'ghost', type = 'self', perms = 'mod' },
    { id = 'god_mode', label = 'God Mode', desc = 'Toggle invincibility', category = 'user', icon = 'shield', type = 'self', perms = 'mod' },
    { id = 'invisible', label = 'Invisible', desc = 'Toggle invisibility', category = 'user', icon = 'ghost', type = 'self', perms = 'mod' },
    { id = 'toggle_laser', label = 'Toggle Laser', desc = 'Toggle the admin pointer beam', category = 'user', icon = 'zap', type = 'self', perms = 'mod' },
    { id = 'infinite_ammo', label = 'Infinite Ammo', desc = 'Toggle infinite ammo', category = 'user', icon = 'zap', type = 'self', perms = 'mod' },
    {
        id = 'set_ammo', label = 'Set Ammo', desc = 'Set ammo of the weapon in your hand',
        category = 'user', icon = 'zap', type = 'input', perms = 'admin',
        extra = { { key = 'amount', label = 'Ammo Amount', kind = 'number', default = '250', placeholder = '250' } }
    },
    { id = 'toggle_duty', label = 'Toggle Duty', desc = 'Toggle your job duty', category = 'user', icon = 'shield', type = 'self', perms = 'mod', frameworks = { 'qb', 'qbx' } },
    { id = 'make_drunk', label = 'Make Player Drunk', desc = 'Apply a temporary drunk effect to a player', category = 'user', icon = 'wine', type = 'player', perms = 'mod' },

    { id = 'admin_car', label = 'Admin Car', desc = 'Spawn the admin utility vehicle', category = 'vehicles', icon = 'car', type = 'self', perms = 'mod' },
    {
        id = 'spawn_vehicle', label = 'Spawn Vehicle', desc = 'Spawn a vehicle by model name',
        category = 'vehicles', icon = 'car', type = 'input', perms = 'mod',
        extra = { { key = 'vehicle', label = 'Vehicle', kind = 'datalist', optionsKey = 'Vehicles', placeholder = 'Model name' } }
    },
    {
        id = 'give_car', label = 'Give Car', desc = 'Give an owned vehicle to a player',
        category = 'vehicles', icon = 'car', type = 'player', perms = 'admin', frameworks = { 'qb', 'qbx', 'esx' },
        extra = {
            { key = 'vehicle', label = 'Vehicle', kind = 'datalist', optionsKey = 'Vehicles', placeholder = 'Model name' },
            { key = 'plate', label = 'Plate (Optional)', kind = 'text', placeholder = 'Random if empty' },
            { key = 'garage', label = 'Garage (Optional)', kind = 'text', placeholder = Config.DefaultGarage }
        }
    },
    { id = 'fix_vehicle', label = 'Fix Vehicle', desc = 'Repair the vehicle you are in', category = 'vehicles', icon = 'wrench', type = 'self', perms = 'mod' },
    { id = 'fix_vehicle_for', label = 'Fix Vehicle For Player', desc = 'Repair the vehicle a player is in', category = 'vehicles', icon = 'wrench', type = 'player', perms = 'mod' },
    { id = 'delete_vehicle', label = 'Delete Vehicle', desc = 'Delete your vehicle or the closest one', category = 'vehicles', icon = 'car', type = 'self', perms = 'mod' },
    { id = 'refuel_vehicle', label = 'Refuel Vehicle', desc = 'Fill the fuel tank of your vehicle', category = 'vehicles', icon = 'car', type = 'self', perms = 'mod' },
    { id = 'max_mods', label = 'Max Vehicle Mods', desc = 'Max out all mods of your vehicle', category = 'vehicles', icon = 'wrench', type = 'self', perms = 'mod' },
    {
        id = 'change_plate', label = 'Change Plate', desc = 'Change the plate of your vehicle',
        category = 'vehicles', icon = 'car', type = 'input', perms = 'mod',
        extra = { { key = 'plate', label = 'Plate', kind = 'text', placeholder = 'Max 8 characters' } }
    },
    {
        id = 'set_garage_state', label = 'Set Vehicle Garage State', desc = 'Set garage state of a vehicle by plate',
        category = 'vehicles', icon = 'warehouse', type = 'input', perms = 'mod', frameworks = { 'qb', 'qbx', 'esx' },
        extra = {
            { key = 'plate', label = 'Plate (Empty = current vehicle)', kind = 'text', placeholder = 'Plate' },
            { key = 'state', label = 'State', kind = 'select', options = Config.GarageStates }
        }
    },
    { id = 'vehicle_dev', label = 'Vehicle Dev Menu', desc = 'Show live info of your vehicle', category = 'vehicles', icon = 'car', type = 'self', perms = 'mod' },
    {
        id = 'open_trunk', label = 'Open Trunk', desc = 'Open the trunk inventory of a plate',
        category = 'vehicles', icon = 'box', type = 'input', perms = 'mod',
        extra = { { key = 'plate', label = 'Plate', kind = 'text', placeholder = 'Plate' } }
    },
    {
        id = 'spawn_personal_vehicle', label = 'Spawn Personal Vehicle', desc = 'Spawn an owned vehicle by plate',
        category = 'vehicles', icon = 'car', type = 'input', perms = 'mod', frameworks = { 'qb', 'qbx', 'esx' },
        extra = { { key = 'plate', label = 'Plate', kind = 'text', placeholder = 'Plate' } }
    },

    {
        id = 'teleport_location', label = 'Teleport To Location', desc = 'Set location and run this command',
        category = 'teleport', icon = 'map-pin', type = 'select', optionsKey = 'Locations', selectLabel = 'Location', perms = 'mod'
    },
    { id = 'teleport_to_player', label = 'Teleport To Player', desc = 'Teleport to a player', category = 'teleport', icon = 'move', type = 'player', perms = 'mod' },
    { id = 'bring_player', label = 'Bring Player', desc = 'Teleport player to your location', category = 'teleport', icon = 'move', type = 'player', perms = 'mod' },
    {
        id = 'teleport_to_coords', label = 'Teleport To Coords', desc = 'Teleport to x, y, z coordinates',
        category = 'teleport', icon = 'map-pin', type = 'input', perms = 'mod',
        extra = { { key = 'coords', label = 'Coords', kind = 'text', placeholder = 'x, y, z' } }
    },
    { id = 'teleport_to_marker', label = 'Teleport To Marker', desc = 'Teleport to your map waypoint', category = 'teleport', icon = 'map-pin', type = 'self', perms = 'mod' },
    { id = 'teleport_back', label = 'Teleport Back', desc = 'Return to your previous position', category = 'teleport', icon = 'move', type = 'self', perms = 'mod' },
    {
        id = 'copy_coords', label = 'Copy Coords', desc = 'Copy your coordinates to the clipboard',
        category = 'teleport', icon = 'map-pin', type = 'input', perms = 'mod',
        extra = {
            {
                key = 'format', label = 'Format', kind = 'select',
                options = {
                    { label = 'Copy Vector2', value = 'vector2' },
                    { label = 'Copy Vector3', value = 'vector3' },
                    { label = 'Copy Vector4', value = 'vector4' },
                    { label = 'Copy Heading', value = 'heading' },
                }
            }
        }
    },

    {
        id = 'ban_player', label = 'Ban Player', desc = 'Set player, reason, duration and run this command',
        category = 'players', icon = 'log-out', type = 'player', perms = 'mod',
        extra = {
            { key = 'reason', label = 'Reason', kind = 'text', placeholder = 'Reason for ban' },
            { key = 'duration', label = 'Duration', kind = 'select', options = Config.BanDurations }
        }
    },
    {
        id = 'kick_player', label = 'Kick Player', desc = 'Set player, reason and run this command',
        category = 'players', icon = 'log-out', type = 'player', perms = 'mod',
        extra = { { key = 'reason', label = 'Reason', kind = 'text', placeholder = 'Reason for kick' } }
    },
    {
        id = 'warn_player', label = 'Warn Player', desc = 'Set player, reason and run this command',
        category = 'players', icon = 'alert-triangle', type = 'player', perms = 'mod',
        extra = { { key = 'reason', label = 'Reason', kind = 'text', placeholder = 'Reason for warning' } }
    },
    { id = 'freeze_player', label = 'Freeze Player', desc = 'Toggle freeze on a player', category = 'players', icon = 'shield', type = 'player', perms = 'mod' },
    { id = 'mute_player', label = 'Mute Player', desc = 'Toggle voice mute on a player (pma-voice)', category = 'players', icon = 'shield', type = 'player', perms = 'mod' },
    { id = 'spectate_player', label = 'Spectate Player', desc = 'Spectate a player (Backspace to stop)', category = 'players', icon = 'ghost', type = 'player', perms = 'mod' },
    { id = 'revive_player', label = 'Revive Player', desc = 'Revive a player', category = 'players', icon = 'heart', type = 'player', perms = 'mod' },
    { id = 'revive_all', label = 'Revive All', desc = 'Revive every player on the server', category = 'players', icon = 'heart', type = 'self', perms = 'mod' },
    { id = 'clothing_menu', label = 'Give Clothing Menu', desc = 'Open the clothing menu for a player', category = 'players', icon = 'shield', type = 'player', perms = 'mod' },
    {
        id = 'set_ped', label = 'Set Ped', desc = 'Change the ped model of a player',
        category = 'players', icon = 'shield', type = 'player', perms = 'mod',
        extra = { { key = 'ped', label = 'Ped Model', kind = 'datalist', optionsKey = 'Peds', placeholder = 'Model name' } }
    },
    { id = 'toggle_cuffs', label = 'Toggle Cuffs', desc = 'Cuff or uncuff a player', category = 'players', icon = 'shield', type = 'player', perms = 'mod' },
    { id = 'open_inventory', label = 'Open Inventory', desc = 'Open the inventory of a player', category = 'players', icon = 'box', type = 'player', perms = 'mod' },
    { id = 'clear_inventory', label = 'Clear Inventory', desc = 'Clear the inventory of a player', category = 'players', icon = 'box', type = 'player', perms = 'mod' },
    {
        id = 'clear_inventory_offline', label = 'Clear Inventory Offline', desc = 'Clear the inventory of an offline player',
        category = 'players', icon = 'box', type = 'input', perms = 'mod', frameworks = { 'qb', 'qbx', 'esx' },
        extra = { { key = 'identifier', label = 'Citizen ID / Identifier', kind = 'text', placeholder = 'ABC12345' } }
    },
    { id = 'remove_stress', label = 'Remove Stress', desc = 'Remove stress from a player (empty = yourself)', category = 'players', icon = 'heart', type = 'player', optionalPlayer = true, perms = 'mod' },
    {
        id = 'set_bucket', label = 'Set Routing Bucket', desc = 'Set the routing bucket of a player',
        category = 'players', icon = 'shield', type = 'player', perms = 'mod',
        extra = { { key = 'bucket', label = 'Bucket', kind = 'number', default = '0', placeholder = '0' } }
    },
    { id = 'get_bucket', label = 'Get Routing Bucket', desc = 'Show the routing bucket of a player', category = 'players', icon = 'shield', type = 'player', perms = 'mod' },
    {
        id = 'play_sound', label = 'Play Sound', desc = 'Play a sound for a player',
        category = 'players', icon = 'zap', type = 'player', perms = 'mod',
        extra = { { key = 'sound', label = 'Sound', kind = 'select', options = Config.Sounds } }
    },
    {
        id = 'set_perms', label = 'Set Perms', desc = 'Set a player permission group',
        category = 'players', icon = 'shield', type = 'player', perms = 'admin',
        extra = { { key = 'group', label = 'Permission group', kind = 'select', options = Config.PermissionGroups } }
    },

    {
        id = 'give_money', label = 'Give Money', desc = 'Set player, amount, type and run this command',
        category = 'economy', icon = 'coins', type = 'player', perms = 'admin',
        extra = {
            { key = 'amount', label = 'Amount', kind = 'number', placeholder = '0' },
            { key = 'type', label = 'Type', kind = 'select', options = Config.MoneyTypes }
        }
    },
    {
        id = 'give_money_all', label = 'Give Money To All', desc = 'Give money to every player',
        category = 'economy', icon = 'coins', type = 'input', perms = 'admin',
        extra = {
            { key = 'amount', label = 'Amount', kind = 'number', placeholder = '0' },
            { key = 'type', label = 'Type', kind = 'select', options = Config.MoneyTypes }
        }
    },
    {
        id = 'remove_money', label = 'Remove Money', desc = 'Set player, amount, type and run this command',
        category = 'economy', icon = 'coins', type = 'player', perms = 'admin',
        extra = {
            { key = 'amount', label = 'Amount', kind = 'number', placeholder = '0' },
            { key = 'type', label = 'Type', kind = 'select', options = Config.MoneyTypes }
        }
    },
    {
        id = 'give_item', label = 'Give Item', desc = 'Give an item to a player',
        category = 'economy', icon = 'box', type = 'player', perms = 'mod',
        extra = {
            { key = 'item', label = 'Item', kind = 'datalist', optionsKey = 'Items', placeholder = 'Item name' },
            { key = 'amount', label = 'Amount', kind = 'number', default = '1', placeholder = '1' }
        }
    },
    {
        id = 'give_item_all', label = 'Give Item To All', desc = 'Give an item to every player',
        category = 'economy', icon = 'box', type = 'input', perms = 'mod',
        extra = {
            { key = 'item', label = 'Item', kind = 'datalist', optionsKey = 'Items', placeholder = 'Item name' },
            { key = 'amount', label = 'Amount', kind = 'number', default = '1', placeholder = '1' }
        }
    },
    {
        id = 'set_job', label = 'Set Job', desc = 'Set the job of a player',
        category = 'economy', icon = 'shield', type = 'player', perms = 'mod',
        extra = {
            { key = 'job', label = 'Job', kind = 'datalist', optionsKey = 'Jobs', placeholder = 'Job name' },
            { key = 'grade', label = 'Grade', kind = 'number', default = '0', placeholder = '0' }
        }
    },
    {
        id = 'set_gang', label = 'Set Gang', desc = 'Set the gang of a player',
        category = 'economy', icon = 'shield', type = 'player', perms = 'mod', frameworks = { 'qb', 'qbx' },
        extra = {
            { key = 'gang', label = 'Gang', kind = 'datalist', optionsKey = 'Gangs', placeholder = 'Gang name' },
            { key = 'grade', label = 'Grade', kind = 'number', default = '0', placeholder = '0' }
        }
    },
    {
        id = 'open_stash', label = 'Open Stash', desc = 'Set stash and run this command',
        category = 'economy', icon = 'box', type = 'input', perms = 'mod',
        extra = { { key = 'stash', label = 'Stash', kind = 'text', default = '1', placeholder = 'Stash ID' } }
    },

    {
        id = 'change_weather', label = 'Change Weather', desc = 'Set weather and run this command',
        category = 'utility', icon = 'cloud', type = 'select', optionsKey = 'Weathers', selectLabel = 'Weather', perms = 'mod'
    },
    {
        id = 'change_time', label = 'Change Time', desc = 'Set the time of day for everyone',
        category = 'utility', icon = 'cloud', type = 'select', optionsKey = 'TimeOptions', selectLabel = 'Time', perms = 'mod'
    },
    { id = 'blackout', label = 'Toggle Blackout', desc = 'Toggle the city blackout', category = 'utility', icon = 'zap', type = 'self', perms = 'mod' },
    { id = 'revive_radius', label = 'Revive Radius', desc = 'Revive all players near you', category = 'utility', icon = 'heart', type = 'self', perms = 'mod' },
    { id = 'toggle_coords', label = 'Toggle Coords', desc = 'Show your coordinates on screen', category = 'utility', icon = 'map-pin', type = 'self', perms = 'mod' },
    { id = 'toggle_blips', label = 'Toggle Blips', desc = 'Show all players on the map', category = 'utility', icon = 'map-pin', type = 'self', perms = 'mod' },
    { id = 'toggle_names', label = 'Toggle Names', desc = 'Show player names above heads', category = 'utility', icon = 'ghost', type = 'self', perms = 'mod' },
    {
        id = 'resource_control', label = 'Resource Control', desc = 'Start, stop or restart a resource',
        category = 'utility', icon = 'wrench', type = 'input', perms = Config.ResourcePerms,
        extra = {
            { key = 'resource', label = 'Resource', kind = 'text', placeholder = 'Resource name' },
            { key = 'action', label = 'Action', kind = 'select', options = { 'restart', 'start', 'stop', 'ensure' } }
        }
    },
    { id = 'show_commands', label = 'Show All Commands', desc = 'Print all registered commands to your F8 console', category = 'utility', icon = 'wrench', type = 'self', perms = Config.ShowCommandsPerms },
}
