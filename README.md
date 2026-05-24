<div align="center">

# AChat

### Modern multi-framework FiveM NUI chat replacement

![FiveM](https://img.shields.io/badge/FiveM-Chat%20Resource-blue?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-blueviolet?style=for-the-badge)
![NUI](https://img.shields.io/badge/NUI-HTML%2FCSS%2FJS-orange?style=for-the-badge)
![Frameworks](https://img.shields.io/badge/QBX%20%7C%20QB%20%7C%20ESX%20%7C%20NDCore-supported-success?style=for-the-badge)

AChat is a clean, modern FiveM chat system built for roleplay servers.
It replaces the default FiveM chat with a polished NUI, multi-framework character support, moderation tools, social feeds, ads, GIFs, and typing input protection.

</div>

---

## Stop Other Chat Resources First

> [!IMPORTANT]
> AChat is a full chat replacement. You should not run the default FiveM `chat` resource or any other custom chat at the same time.

Running multiple chat resources can cause duplicate messages, broken suggestions, focus issues, keybind conflicts, commands firing twice, wrong UI focus, or the wrong chat opening.

Use **one chat resource only**.

```cfg
stop chat
stop qb-chat
stop okokChat
stop cc-chat
stop mChat
stop rpchat
ensure AChat
```

The best setup is to remove old chat `ensure` lines entirely and only start `AChat`.

---

## Preview

<details open>
<summary><b>Show screenshots</b></summary>

<br>

<div align="center">

<table>
<tr>
<td align="center" width="50%">
<img src="https://github.com/user-attachments/assets/6cb11efb-fd7f-4b48-ab9a-6a27274fe791" width="100%" alt="AChat preview 1">
</td>
<td align="center" width="50%">
<img src="https://github.com/user-attachments/assets/3b7c711c-5a31-41d1-a8bf-bc58216e0285" width="100%" alt="AChat preview 2">
</td>
</tr>
<tr>
<td align="center" width="50%">
<img src="https://github.com/user-attachments/assets/db7fcdee-d543-43c0-bf9e-cb464019cbf3" width="100%" alt="AChat preview 3">
</td>
<td align="center" width="50%">
<img src="https://github.com/user-attachments/assets/9b87645c-9db2-4816-b60a-159d6e5728b4" width="100%" alt="AChat preview 4">
</td>
</tr>
<tr>
<td align="center" width="50%">
<img src="https://github.com/user-attachments/assets/6314dce5-9844-4981-96a7-545b40629300" width="100%" alt="AChat preview 5">
</td>
<td align="center" width="50%">
<img src="https://github.com/user-attachments/assets/bc0c6777-f7bc-4298-9c80-2f31f8e73859" width="100%" alt="AChat preview 6">
</td>
</tr>
<tr>
<td align="center" colspan="2">
<img src="https://github.com/user-attachments/assets/a5f84755-8a3c-4602-8494-2539032b139e" width="70%" alt="AChat preview 7">
</td>
</tr>
</table>

</div>

</details>

---

## Supported Frameworks

AChat automatically detects your framework on startup.

| Framework | Resource Name | Status |
|---|---:|:---:|
| Qbox / QBX | `qbx_core` | Supported |
| QB-Core | `qb-core` | Supported |
| ESX | `es_extended` | Supported |
| NDCore | `ND_Core` | Supported |
| Standalone | none | Supported |

Detection order is controlled in `config.lua`:

```lua
Config.Framework = {
    name = 'auto',
    detectionOrder = { 'qbx_core', 'qb-core', 'es_extended', 'ND_Core' }
}
```

<details>
<summary><b>Manual framework values</b></summary>

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

</details>

---

## Features

<div align="center">

| Core Chat | Roleplay Tools | Staff Tools |
|---|---|---|
| Multi-framework detection | Local proximity chat | Staff report center |
| Character names | OOC chat | Staff moderation commands |
| Job labels and duty status | `/me` and `/do` | Slowmode and freeze chat |
| Input lock while typing | Advertisements | Warning, mute, timeout tools |
| Smoke / black transparent UI | X-style social feed | Word filter controls |
| No hard `qb-core` dependency | Facebook-style social feed | GIF blocking support |

</div>

Additional support includes chat styles, ACE permissions, Discord role integration, Giphy/Tenor GIFs, emoji support, command guide support, and configurable job icons.

---

## Installation

1. Download or clone the resource.
2. Place it in your server resources folder.
3. Make sure the folder is named exactly:

```txt
AChat
```

4. Stop/remove default FiveM `chat` and every other custom chat resource.
5. Start your framework before AChat.
6. Add AChat to `server.cfg`.

<details open>
<summary><b>Start order examples</b></summary>

### Qbox / QBX

```cfg
stop chat
ensure qbx_core
ensure AChat
```

### QB-Core

```cfg
stop chat
ensure qb-core
ensure AChat
```

### ESX

```cfg
stop chat
ensure es_extended
ensure AChat
```

### NDCore

```cfg
stop chat
ensure ND_Core
ensure AChat
```

### Standalone

```cfg
stop chat
ensure AChat
```

</details>

Recommended order when using utility libraries:

```cfg
ensure ox_lib
stop chat
ensure qbx_core
ensure AChat
```

Replace `qbx_core` with your framework resource if you are not using Qbox.

---

## Qbox / QBX Notes

> [!NOTE]
> Qbox uses the real resource name `qbx_core`. Do not use `qbx-core` as the actual resource folder/resource name.

AChat uses the QBX server export path and client player-data cache fallback so chat names resolve from character data instead of falling back to the FiveM player name.

If you use Qbox, make sure `qb-core` is not forced as a dependency in any edited version of this resource.

---

## Configuration

Main files:

```txt
config.lua
server_config.lua
state.json
```

<details open>
<summary><b>config.lua</b></summary>

Controls client/shared settings:

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

</details>

<details>
<summary><b>server_config.lua</b></summary>

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

> [!WARNING]
> Never commit a real Discord bot token to GitHub.

</details>

<details>
<summary><b>state.json</b></summary>

Stores runtime chat data.

Keep this file present, but do not store private information inside it.

</details>

---

## Permissions

AChat supports ACE-based moderation permissions.

```cfg
add_ace group.admin achat.mod.admin allow
add_ace group.admin achat.mod allow
add_ace group.mod achat.mod allow
```

Optional chat style ACE examples:

```cfg
add_ace group.admin achat.role.staff allow
add_ace group.admin achat.role.admin allow
add_ace group.admin achat.style.rgb allow
```

The ACE permission names can be changed in `config.lua`.

---

## Commands

<details open>
<summary><b>Player commands</b></summary>

| Command | Description |
|---|---|
| `/ooc <message>` | Send global OOC message |
| `/l <message>` | Send local message |
| `/me <message>` | Roleplay action |
| `/do <message>` | Roleplay scene/description |
| `/ad <message>` | Post advertisement |
| `/ads` | Open advertisement board |
| `/adname <name>` | Set advertisement name |
| `/adbanner <url>` | Set advertisement banner |
| `/adbg <url>` | Set advertisement background |
| `/adcolor <hex>` | Set advertisement color |
| `/adstyle <style>` | Set advertisement style |
| `/chatstyle` | Open chat style selector |
| `/help` | Open command/help guide |
| `/report <message>` | Submit staff report |
| `/reports` | Open report center if permitted |
| `/x` | Open X-style social feed |
| `/fb` | Open Facebook-style feed |
| `/clearchat` | Clear local chat UI |

</details>

<details>
<summary><b>Staff commands</b></summary>

| Command | Description |
|---|---|
| `/announce <message>` | Send staff announcement |
| `/purge` | Clear chat for everyone |
| `/slowmode <seconds>` | Set slowmode |
| `/freezechat` | Freeze chat |
| `/unfreezechat` | Unfreeze chat |
| `/warn <id> <reason>` | Warn player |
| `/timeout <id> <minutes> <reason>` | Timeout player |
| `/mute <id> <reason>` | Mute player |
| `/unmute <id>` | Unmute player |
| `/shadowmute <id> <reason>` | Shadow mute player |
| `/filterword add <word>` | Add filtered word |
| `/filterword remove <word>` | Remove filtered word |
| `/blocklastgif` | Block the last GIF |
| `/countdown <seconds> <message>` | Start countdown announcement |

</details>

---

## Keybinds

| Action | Default |
|---|---:|
| Open chat | `T` |
| Cycle visibility | `SEMICOLON` |

Change these in `config.lua`:

```lua
Config.Chat.openKeyDefault = 't'
Config.Visibility.cycleKeyDefault = 'SEMICOLON'
```

---

## Input Blocking

AChat blocks common gameplay controls while the chat input is focused. This prevents inventory, phone, radio, interaction menus, and other keybinds from opening while the player is typing.

```lua
Config.InputBlock = {
    enabled = true,
    enforceFocusEveryFrame = true,
    blockOxInventory = true,
    exposeStateBag = true,
    stateBagName = 'achatInputOpen'
}
```

When enabled, other resources can check:

```lua
LocalPlayer.state.achatInputOpen
```

---

## GIF Provider

AChat supports Giphy and Tenor.

```lua
Config.Integrations = {
    emoji = true,
    gifs = true,
    provider = 'giphy'
}
```

For public GitHub releases, replace production API keys with your own safe key or leave the provider disabled until configured.

---

## Folder Structure

<details open>
<summary><b>View resource structure</b></summary>

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

</details>

---

## Troubleshooting

<details open>
<summary><b>Chat messages are duplicated</b></summary>

You are running more than one chat resource. Stop the default `chat` resource and every other custom chat resource.

```cfg
stop chat
stop qb-chat
stop okokChat
stop cc-chat
stop mChat
stop rpchat
restart AChat
```

</details>

<details>
<summary><b>The wrong chat UI opens</b></summary>

Another chat resource is still running. Only one chat resource should be active.

Remove other chat `ensure` lines from `server.cfg`, restart the server, then start only AChat.

</details>

<details>
<summary><b>Chat shows the FiveM name instead of character name</b></summary>

Make sure your framework starts before AChat.

For Qbox, the framework resource must be named:

```txt
qbx_core
```

Then restart AChat after your character is fully loaded:

```cfg
restart AChat
```

</details>

<details>
<summary><b>Job shows unemployed</b></summary>

The player data may not have loaded yet, or the framework was started after AChat.

Start your framework first, load into your character, then restart AChat.

</details>

<details>
<summary><b>Qbox is trying to use QB-Core</b></summary>

Set the framework manually in `config.lua`:

```lua
Config.Framework.name = 'qbx_core'
```

Also confirm `fxmanifest.lua` does not contain a forced `qb-core` dependency.

</details>

<details>
<summary><b>Keybinds open while typing</b></summary>

Make sure input blocking is enabled:

```lua
Config.InputBlock.enabled = true
Config.InputBlock.enforceFocusEveryFrame = true
```

</details>

<details>
<summary><b>NUI has a dark overlay or black screen</b></summary>

Avoid adding forced page-level `color-scheme: dark;` or heavy drop-shadow effects.

AChat is designed to use a transparent smoke theme without forced full-screen dark overlays.

</details>

<details>
<summary><b>Discord roles are not working</b></summary>

Discord role integration is disabled by default.

Configure `server_config.lua` with your guild ID and bot token, then enable it:

```lua
ServerConfig.Discord.enabled = true
```

Make sure your bot has permission to read guild members and roles.

</details>

---

## Updating

Before updating, back up:

```txt
config.lua
server_config.lua
state.json
```

Then replace the resource files and manually merge your config changes.

---

## Credits

Created by Azure.

---

## License

Use, edit, and distribute according to your server or project license terms.

If you release a public fork, keep credits intact and never include private tokens, guild secrets, or server-only configuration data.
