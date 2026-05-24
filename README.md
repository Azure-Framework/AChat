# AChat
<img width="589" height="543" alt="image" src="https://github.com/user-attachments/assets/6cb11efb-fd7f-4b48-ab9a-6a27274fe791" />
<img width="600" height="907" alt="image" src="https://github.com/user-attachments/assets/3b7c711c-5a31-41d1-a8bf-bc58216e0285" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/db7fcdee-d543-43c0-bf9e-cb464019cbf3" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/9b87645c-9db2-4816-b60a-159d6e5728b4" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/6314dce5-9844-4981-96a7-545b40629300" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/bc0c6777-f7bc-4298-9c80-2f31f8e73859" />
<img width="597" height="228" alt="image" src="https://github.com/user-attachments/assets/a5f84755-8a3c-4602-8494-2539032b139e" />


![FiveM](https://img.shields.io/badge/FiveM-Chat%20Resource-blue)
![Lua](https://img.shields.io/badge/Lua-5.4-blueviolet)
![NUI](https://img.shields.io/badge/NUI-HTML%2FCSS%2FJS-orange)
![Frameworks](https://img.shields.io/badge/Frameworks-QBX%20%7C%20QB%20%7C%20ESX%20%7C%20NDCore-success)


AChat is a modern FiveM NUI chat replacement built for roleplay servers. It includes local chat, OOC, `/me`, `/do`, advertisements, reports, staff moderation, chat styles, GIF support, command guide support, input blocking while typing, and automatic framework detection.

## Important: Disable Other Chat Resources

AChat is a full replacement for the default FiveM chat. Do not run the default `chat` resource or any other custom chat resource at the same time.

Running multiple chat resources can cause duplicate messages, broken suggestions, focus issues, keybind conflicts, commands firing twice, or the wrong UI opening.

In `server.cfg`, remove or comment out other chat resources:

```cfg
# Do not run these with AChat
# ensure chat
# ensure qb-chat
# ensure okokChat
# ensure cc-chat
# ensure mChat
# ensure rpchat
# ensure any-other-chat-resource
```

You can also add stop lines before starting AChat as a safety fallback:

```cfg
stop chat
stop qb-chat
stop okokChat
stop cc-chat
stop mChat
stop rpchat
ensure AChat
```

The best setup is to completely remove the old chat `ensure` lines and only start one chat resource: `AChat`.

## Supported Frameworks

AChat can automatically detect and run with:

- Qbox / QBX: `qbx_core`
- QB-Core: `qb-core`
- ESX: `es_extended`
- NDCore: `ND_Core`
- Standalone fallback

The default detection order is controlled in `config.lua`:

```lua
Config.Framework = {
    name = 'auto',
    detectionOrder = { 'qbx_core', 'qb-core', 'es_extended', 'ND_Core' }
}
```

You can force a framework by changing `Config.Framework.name`.

Accepted values:

```txt
auto
qbx_core
qbx-core
qbox
qb-core
qbcore
esx
es_extended
ND_Core
NDCore
ndcore
standalone
```

## Features

- Multi-framework auto-detection
- Character name support across QBX, QB-Core, ESX, and NDCore
- Job label, duty status, and job icon support
- Local proximity chat
- Global OOC chat
- `/me` and `/do` roleplay commands
- Server advertisement board
- Custom ad profiles with name, banner, background, accent color, and style options
- Chat style system with ACE and Discord role support
- Staff report center
- In-city X-style social feed
- In-city Facebook-style social feed
- GIF search support through Giphy or Tenor
- Emoji support
- Searchable `/help` command guide
- Staff moderation commands
- Input lock while typing so inventory, radio, phone, and other keybinds do not open
- Smoke / black transparent NUI theme
- No hard `qb-core` dependency

## Installation

1. Download or clone this resource.
2. Place the folder in your server resources directory.
3. Make sure the folder is named:

```txt
AChat
```

4. Start your framework before AChat.
5. Add the correct start order to `server.cfg`.

### Qbox / QBX

```cfg
ensure qbx_core
ensure AChat
```

### QB-Core

```cfg
ensure qb-core
ensure AChat
```

### ESX

```cfg
ensure es_extended
ensure AChat
```

### NDCore

```cfg
ensure ND_Core
ensure AChat
```

### Standalone

```cfg
ensure AChat
```

## Recommended Start Order

```cfg
ensure ox_lib
ensure qbx_core
ensure AChat
```

Replace `qbx_core` with your actual framework resource if you are not using Qbox.

## Qbox / QBX Notes

Qbox uses the real resource name `qbx_core`. Do not start or depend on `qbx-core` as a resource name.

AChat uses the QBX server export path and client player-data cache fallback so chat names resolve from character data instead of falling back to the FiveM player name.

If you use Qbox, make sure `qb-core` is not forced as a dependency in any edited version of this resource.

## Configuration

Main configuration files:

```txt
config.lua
server_config.lua
state.json
```

### `config.lua`

Controls:

- Framework detection
- Theme colors
- Layout
- Chat modes
- Commands
- Command guide
- Staff moderation permissions
- Input blocking
- Auto announcements
- Job icons
- Advertisement board
- Chat styles
- GIF provider settings

### `server_config.lua`

Controls server-only integrations:

- Discord role integration
- Discord bot token
- Discord guild ID
- Moderation role IDs
- Chat style role data

Discord integration is disabled by default for public release safety:

```lua
ServerConfig.Discord = {
    enabled = false,
    guildId = '',
    botToken = '',
    cacheSeconds = 300,
    liveRefreshSeconds = 45
}
```

Never commit a real Discord bot token to GitHub.

### `state.json`

Stores runtime data for chat state. Keep the file present, but do not use it to store private information.

## ACE Permissions

AChat supports ACE-based moderation permissions.

Recommended example:

```cfg
add_ace group.admin orpchat.mod.admin allow
add_ace group.admin orpchat.mod allow
add_ace group.mod orpchat.mod allow
```

Optional chat style ACE examples:

```cfg
add_ace group.admin orpchat.role.staff allow
add_ace group.admin orpchat.role.admin allow
add_ace group.admin orpchat.style.rgb allow
```

The ACE permission names can be edited in `config.lua`.

## Player Commands

```txt
/ooc <message>
/l <message>
/me <message>
/do <message>
/ad <message>
/ads
/adname <name>
/adbanner <url>
/adbg <url>
/adcolor <hex>
/adstyle <style>
/chatstyle
/help
/report <message>
/reports
/x
/fb
/clearchat
```

## Staff Commands

```txt
/announce <message>
/purge
/slowmode <seconds>
/freezechat
/unfreezechat
/warn <id> <reason>
/timeout <id> <minutes> <reason>
/mute <id> <reason>
/unmute <id>
/shadowmute <id> <reason>
/filterword add <word>
/filterword remove <word>
/blocklastgif
/countdown <seconds> <message>
```

## Chat Keybinds

Default open key:

```txt
T
```

Default visibility cycle key:

```txt
SEMICOLON
```

These can be changed in `config.lua`:

```lua
Config.Chat.openKeyDefault = 't'
Config.Visibility.cycleKeyDefault = 'SEMICOLON'
```

## Input Blocking

AChat blocks common gameplay controls while the chat input is focused. This prevents other resources such as inventory, phone, radio, or interaction menus from opening while the player is typing.

Config section:

```lua
Config.InputBlock = {
    enabled = true,
    enforceFocusEveryFrame = true,
    blockOxInventory = true,
    exposeStateBag = true,
    stateBagName = 'AChatInputOpen'
}
```

When enabled, AChat also exposes a local state bag value that other resources can check:

```lua
LocalPlayer.state.AChatInputOpen
```

## GIF Provider

AChat supports Giphy and Tenor.

Config section:

```lua
Config.Integrations = {
    emoji = true,
    gifs = true,
    provider = 'giphy'
}
```

For public GitHub releases, replace any production API keys with your own release-safe key or leave the provider disabled until configured.

## Folder Structure

```txt
AChat/
├── bridge/
│   ├── client.lua
│   └── server.lua
├── client/
│   └── main.lua
├── server/
│   └── main.lua
├── html/
│   ├── assets/
│   │   └── logo.svg
│   ├── app.js
│   ├── index.html
│   └── style.css
├── config.lua
├── fxmanifest.lua
├── README.md
├── server_config.lua
└── state.json
```

## Troubleshooting

### Chat shows the FiveM name instead of character name

Make sure your framework starts before AChat.

For Qbox, the framework resource must be named:

```txt
qbx_core
```

Then restart AChat after your character is fully loaded:

```cfg
restart AChat
```

### Job shows unemployed

The player data may not have loaded yet, or the framework was started after AChat. Restart AChat after the framework and character system are loaded.

### Qbox is trying to use QB-Core

Set the framework manually in `config.lua`:

```lua
Config.Framework.name = 'qbx_core'
```

Also confirm `fxmanifest.lua` does not contain a forced `qb-core` dependency.

### Keybinds open while typing

Make sure input blocking is enabled:

```lua
Config.InputBlock.enabled = true
Config.InputBlock.enforceFocusEveryFrame = true
```

### NUI has a dark overlay or black screen

Avoid adding forced page-level `color-scheme: dark;` or heavy drop-shadow effects. AChat is designed to use a transparent smoke theme without forced full-screen dark overlays.

### Discord roles are not working

Discord role integration is disabled by default. Configure `server_config.lua` with your guild ID and bot token, then enable it:

```lua
ServerConfig.Discord.enabled = true
```

Make sure your bot has access to read guild members and roles.

## Updating

Before updating, back up:

```txt
config.lua
server_config.lua
state.json
```

Then replace the resource files and merge your config changes manually.

## Credits

Created by Azure.

## License

Use, edit, and distribute according to your server or project license terms. If you release a public fork, keep credits intact and never include private tokens, guild secrets, or server-only configuration data.
