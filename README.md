<img width="1919" height="1079" alt="Screenshot 2026-09-30 061524" src="https://github.com/user-attachments/assets/3492358d-1308-4165-8735-24813c129731" />
# codera-adminmenu

A modern, dark-themed admin menu for FiveM with a searchable command-palette interface.
Works with **ESX**, **QBCore** and **QBox (qbx_core)**, with **64 commands in 6 categories**.

## Features

- Searchable command palette with category filters and favourites
- 64 admin commands (players, economy, vehicles, teleport, utility, user tools)
- Automatic framework detection (ESX / QBCore / QBox)
- Per-command permission levels (`mod` / `admin`), checked again on the server for every action
- Identifier-based admin list that works even if ACE / principals are misconfigured
- Supports `ox_inventory`, `qb-inventory`, `ps-inventory` and `lj-inventory`
- Built-in debug tools and clear server-console logs

## Requirements

| Resource | Required for |
| --- | --- |
| ESX, QBCore or QBox | Core functionality (one of them) |
| `oxmysql` | Bans, Give Car, Set Garage State, Clear Inventory (Offline) |
| `pma-voice` | Mute |
| An inventory resource (see above) | Open Inventory, Clear Inventory, Give Item, Stash, Trunk |

## Installation

1. Place the `codera-adminmenu` folder inside your `resources` directory.
   The `fxmanifest.lua` must be directly inside the folder (no nested `codera-adminmenu/codera-adminmenu`).
2. Add this to your `server.cfg`, **after** your framework, `oxmysql` and inventory:

   ```
   ensure codera-adminmenu
   ```
3. Set up permissions (see the next section).
4. Restart the server and use `/adminmenu` or press `F6` in game.

The framework is detected automatically. To set it manually:

```lua
Config.Framework = 'qb' -- 'qb' | 'qbx' | 'esx'
```

## Permissions

The menu uses three levels: `mod` < `admin` < `god`.
`Config.Permission` is the minimum level needed to open the menu, and every command has its own `perms` value.
Only the commands a player is allowed to use are sent to their menu, and the server checks the permission again on every action.

A player is allowed when **any** of the following is true:

1. Their identifier is listed in `Config.Admins` (recommended and simplest).
2. The framework reports they have the permission (QBCore / QBox permission system, or ESX group).
3. They have a matching ACE (`mod`, `admin`, `god`, `group.*`, `qbcore.*`, `qbox.*`). The generic `command` ACE grants `mod` and `admin` only, never `god`.

Higher levels automatically include lower ones (`god` > `admin` > `mod`).

### Option 1: Config.Admins (all frameworks)

Add identifiers to `config.lua`. Both `discord:` and `license:` identifiers are supported:

```lua
Config.Admins = {
    ['discord:123456789012345678'] = 'god',
    ['license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = 'admin',
}
```

Discord identifiers only work if the player has the Discord desktop app open when connecting.
`license:` is the most reliable. You can see your identifiers with the `status` command in the server console.

### Option 2: QBCore / QBox ACE tree

Add this to your `server.cfg` or `permissions.cfg`:

```
add_ace qbcore.god command allow
add_principal qbcore.god group.admin
add_principal qbcore.god qbcore.admin
add_principal qbcore.admin qbcore.mod

add_ace qbcore.god god allow
add_ace qbcore.admin admin allow
add_ace qbcore.mod mod allow

# Needed for the "Set Perms" command
add_ace resource.qb-core command allow
add_ace resource.qb-core command.add_ace allow
add_ace resource.qb-core command.add_principal allow
add_ace resource.qb-core command.remove_principal allow
add_ace resource.qb-core command.stop allow
```

Then add your admins:

```
add_principal identifier.license:xxxxxxxxxxxxxxxx qbcore.god
```

ACE changes require a full server restart. Restarting only the resource is not enough.
For QBox, use the `qbox.*` equivalents.

### Option 3: ESX groups

Groups are read from `Config.EsxGroups`:

```lua
Config.EsxGroups = {
    mod   = { 'mod', 'admin', 'superadmin' },
    admin = { 'admin', 'superadmin' },
    god   = { 'superadmin' },
}
```


- Bans are saved in the `bans` table on QB / QBox. On ESX the `codera_bans` table is created automatically.
- Toggle Duty and Set Gang work on QB / QBox only.
- Mute requires `pma-voice`.
- Bans, Give Car, Set Garage State and offline inventory clearing require `oxmysql`.

## Troubleshooting

**"You do not have permission to use this."**
1. Run `/adminmenu_perm` in game. It shows your framework and which levels are granted.
2. The simplest fix is adding your identifier to `Config.Admins`.
3. If you use ACE, make sure the permission tree above exists and restart the whole server.
4. Make sure `add_principal` lines have both arguments (`add_principal <child> <parent>`).

**Nothing happens when opening the menu**
1. Check the server console. Each open request prints `open request`, then `allowed`, `denied` or an error message.
2. If you see `no response from server`, the resource likely failed to start. Run `ensure codera-adminmenu` and read the errors.
3. Confirm `fxmanifest.lua` is directly inside the resource folder.

**The cursor is stuck after closing**
Run `/adminmenu_fixfocus`.

**Menu fails to build (server console error)**
Check the error printed after `build error`. It usually points to a broken item, vehicle or job entry in your framework's shared files.


## Credits

Made by Codera.
