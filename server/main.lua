local Framework = AZChatFramework

local RESOURCE_NAME = GetCurrentResourceName()
local STATE_FILE = 'state.json'

local lastPublicMessageAt = {}
local messageCounter = 0

local state = {
    warnings = {},
    timeouts = {},
    blockedGifUrls = {},
    lastGifMessageId = nil,
    lastGifUrl = nil,
    moderation = {
        slowmode = 0,
        freeze = false,
        shadowmutes = {},
        filterWords = {},
        mutes = {}
    },
    social = {
        xAccounts = {},
        fbAccounts = {},
        xPosts = {},
        fbPosts = {}
    },
    reports = {
        nextId = 1,
        items = {}
    },
    ads = {
        nextId = 1,
        items = {},
        cooldowns = {}
    },
    adProfiles = {},
    chatStyles = {
        selected = {},
        grants = {}
    }
}

local roleCache = {}
local moderationRoleCache = {}

local function trim(value)
    if type(value) ~= 'string' then return '' end
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function sanitizeMessage(value)
    value = trim(value or '')
    value = value:gsub('[\r\n]+', ' ')
    value = value:gsub('%^%d', '')
    if #value > Config.Chat.maxLength then
        value = value:sub(1, Config.Chat.maxLength)
    end
    return value
end

local function splitArguments(input)
    local args = {}
    for part in string.gmatch(input or '', '%S+') do
        args[#args + 1] = part
    end
    return args
end

local function urlencode(str)
    if not str then return '' end
    str = tostring(str)
    str = str:gsub('\n', '\r\n')
    str = str:gsub('([^%w %-_%.~])', function(c)
        return string.format('%%%02X', string.byte(c))
    end)
    return str:gsub(' ', '%%20')
end

local function loadState()
    local raw = LoadResourceFile(RESOURCE_NAME, STATE_FILE)
    if not raw or raw == '' then return end
    local ok, parsed = pcall(json.decode, raw)
    if not ok or type(parsed) ~= 'table' then return end

    state.warnings = parsed.warnings or state.warnings
    state.timeouts = parsed.timeouts or state.timeouts
    state.blockedGifUrls = parsed.blockedGifUrls or state.blockedGifUrls
    state.lastGifMessageId = parsed.lastGifMessageId or state.lastGifMessageId
    state.lastGifUrl = parsed.lastGifUrl or state.lastGifUrl
    state.moderation = parsed.moderation or state.moderation
    state.social = parsed.social or state.social
    state.reports = parsed.reports or state.reports
    state.ads = parsed.ads or state.ads
    state.adProfiles = parsed.adProfiles or state.adProfiles
    state.chatStyles = parsed.chatStyles or state.chatStyles

    state.moderation.shadowmutes = state.moderation.shadowmutes or {}
    state.moderation.filterWords = state.moderation.filterWords or {}
    state.moderation.mutes = state.moderation.mutes or {}
    state.social.xAccounts = state.social.xAccounts or {}
    state.social.fbAccounts = state.social.fbAccounts or {}
    state.social.xPosts = state.social.xPosts or {}
    state.social.fbPosts = state.social.fbPosts or {}
    state.reports.items = state.reports.items or {}
    state.reports.nextId = tonumber(state.reports.nextId) or 1
    state.ads.items = state.ads.items or {}
    state.ads.cooldowns = state.ads.cooldowns or {}
    state.ads.nextId = tonumber(state.ads.nextId) or 1
    state.adProfiles = state.adProfiles or {}
    state.chatStyles.selected = state.chatStyles.selected or {}
    state.chatStyles.grants = state.chatStyles.grants or {}
end

local function saveState()
    SaveResourceFile(RESOURCE_NAME, STATE_FILE, json.encode(state), -1)
end

loadState()

local function getPlayerObject(src)
    return Framework.GetPlayer(src)
end

local function getPlayerKey(src)
    return 'citizen:' .. Framework.GetIdentifier(src)
end

local function getDiscordId(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'discord:' then
            return identifier:sub(9)
        end
    end
    return nil
end

local function isAdminByDiscord(src)
    if src == 0 then return true end
    local discordId = getDiscordId(src)
    if not discordId then return false end

    local lists = {
        Config.AdminDiscordIds or {},
        (Config.ChatModeration and Config.ChatModeration.AdminDiscordIds) or {}
    }

    for _, list in ipairs(lists) do
        for _, allowed in ipairs(list) do
            if tostring(allowed) == tostring(discordId) then
                return true
            end
        end
    end

    return false
end

local function isPlaceholderRoleId(roleId)
    roleId = tostring(roleId or '')
    return roleId == '' or roleId:find('PASTE_', 1, true) == 1 or roleId:find('ROLE_ID', 1, true) ~= nil
end

ServerConfig = ServerConfig or {}

local function getDiscordApiConfig()
    local discord = ServerConfig.Discord or {}
    return {
        enabled = discord.enabled == true,
        guildId = trim(discord.guildId or ''),
        botToken = trim(discord.botToken or ''),
        cacheSeconds = tonumber(discord.cacheSeconds) or 300,
        liveRefreshSeconds = tonumber(discord.liveRefreshSeconds) or 45
    }
end

local function appendRoleIds(out, list)
    if type(list) ~= 'table' then return end
    for _, roleId in ipairs(list) do
        roleId = tostring(roleId or '')
        if not isPlaceholderRoleId(roleId) then out[#out + 1] = roleId end
    end
end

local function getModerationRoleIds(field)
    local output = {}
    appendRoleIds(output, (Config.ChatModeration or {})[field] or {})
    appendRoleIds(output, ((ServerConfig.ChatModeration or {})[field]) or {})
    return output
end

local function getStyleMappingRoleId(mapping)
    if type(mapping) ~= 'table' then return '' end
    local key = trim(mapping.serverRoleKey or mapping.roleKey or '')
    if key ~= '' and ServerConfig.ChatStyleRoles and ServerConfig.ChatStyleRoles[key] then
        local serverRoleId = tostring(ServerConfig.ChatStyleRoles[key] or '')
        if not isPlaceholderRoleId(serverRoleId) then return serverRoleId end
    end
    return tostring(mapping.roleId or '')
end

local function roleListHas(roleList, roles)
    if type(roleList) ~= 'table' or type(roles) ~= 'table' then return false end
    for _, roleId in ipairs(roleList) do
        roleId = tostring(roleId or '')
        if not isPlaceholderRoleId(roleId) and roles[roleId] == true then
            return true
        end
    end
    return false
end

local function normalizeRoleList(raw)
    local roles = {}
    if type(raw) ~= 'table' then return roles end
    for _, value in pairs(raw) do
        local roleId = nil
        if type(value) == 'table' then
            roleId = value.id or value.roleId or value[1]
        else
            roleId = value
        end
        roleId = tostring(roleId or '')
        if roleId ~= '' then roles[roleId] = true end
    end
    return roles
end

local function evaluateModerationRoleLevel(roles)
    if roleListHas(getModerationRoleIds('AdminRoleIds'), roles) then return 2 end
    if roleListHas(getModerationRoleIds('ModeratorRoleIds'), roles) then return 1 end
    return 0
end

local pushModerationState

local function refreshModerationRoles(src, pushAfter)
    local discordId = getDiscordId(src)
    if not discordId then return end

    local cfg = getDiscordApiConfig()
    if not cfg.enabled or cfg.guildId == '' or cfg.botToken == '' then return end

    local cached = moderationRoleCache[discordId]
    if cached and cached.expiresAt and cached.expiresAt > os.time() then
        if pushAfter then pushModerationState(src) end
        return
    end

    local url = ('https://discord.com/api/v10/guilds/%s/members/%s'):format(cfg.guildId, discordId)
    PerformHttpRequest(url, function(statusCode, body)
        local roles = {}
        if statusCode == 200 and body and body ~= '' then
            local ok, parsed = pcall(json.decode, body)
            if ok and parsed and type(parsed.roles) == 'table' then
                roles = normalizeRoleList(parsed.roles)
            end
        elseif cached and cached.roles then
            roles = cached.roles
        end

        moderationRoleCache[discordId] = {
            roles = roles,
            level = evaluateModerationRoleLevel(roles),
            expiresAt = os.time() + (tonumber(cfg.cacheSeconds) or 300)
        }

        if pushAfter then pushModerationState(src) end
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. cfg.botToken,
        ['Content-Type'] = 'application/json'
    })
end

local function getModerationLevel(src, allowAsync)
    if Config.ChatModeration and Config.ChatModeration.enabled == false then return 0 end
    if src == 0 then return 2 end

    if isAdminByDiscord(src) then return 2 end

    local ace = Config.ChatModeration and Config.ChatModeration.Ace or {}
    if ace.admin and ace.admin ~= '' and IsPlayerAceAllowed(src, ace.admin) then return 2 end
    if ace.mod and ace.mod ~= '' and IsPlayerAceAllowed(src, ace.mod) then return 1 end

    local discordId = getDiscordId(src)
    if discordId then
        local cached = moderationRoleCache[discordId]
        if cached and cached.expiresAt and cached.expiresAt > os.time() then
            return tonumber(cached.level) or 0
        end
        if allowAsync ~= false then
            refreshModerationRoles(src, false)
        end
    end

    return 0
end

local function isChatAdmin(src)
    return getModerationLevel(src, true) >= 2
end

local function isChatModerator(src)
    return getModerationLevel(src, true) >= 1
end

local function moderationLevelName(level)
    return level >= 2 and 'admin' or (level >= 1 and 'mod' or 'user')
end

local function requiredModerationLevel(command)
    if command == 'reply' or command == 'reports' or command == 'help' or command == 'clearchat' then return 0 end
    local cfg = Config.ChatModeration or {}
    local levels = cfg.CommandLevels or {}
    local value = string.lower(tostring(levels[command] or 'admin'))
    if value == 'user' then return 0 end
    if value == 'mod' or value == 'moderator' then return 1 end
    return 2
end

local function hasModerationCommandPermission(src, command)
    return getModerationLevel(src, true) >= requiredModerationLevel(command)
end

pushModerationState = function(src)
    local level = getModerationLevel(src, false)
    TriggerClientEvent('orp-chat:client:setAdminState', src, {
        isAdmin = level >= 2,
        canModerate = level >= 1,
        moderationLevel = level,
        label = moderationLevelName(level),
        slowmode = tonumber(state.moderation and state.moderation.slowmode or 0) or 0,
        frozen = state.moderation and state.moderation.freeze == true
    })
end

local function refreshAllModerationStates()
    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target then pushModerationState(target) end
    end
end

local function resolveTarget(token)
    local id = tonumber(token)
    if id and GetPlayerName(id) then
        return id
    end
    return nil
end

local function getPlayerNameBySource(src)
    return Framework.GetName(src)
end

local function resolveJobIcon(jobName, jobType)
    jobName = string.lower(jobName or 'unemployed')
    jobType = string.lower(jobType or '')

    local configured = Config.JobIcons or {}
    if configured[jobName] then return configured[jobName] end
    if jobType ~= '' and configured[jobType] then return configured[jobType] end

    if jobName:find('police') or jobName:find('bcso') or jobName:find('sheriff') or jobName:find('state') then
        return 'police'
    elseif jobName:find('ambulance') or jobName:find('ems') or jobName:find('hospital') then
        return 'ems'
    elseif jobName:find('fire') then
        return 'fire'
    elseif jobName:find('mechanic') or jobType == 'mechanic' then
        return 'mech'
    elseif jobName:find('construction') or jobName:find('dot') or jobName:find('publicworks') or jobName:find('highway') then
        return 'construction'
    end

    return 'civ'
end

local function getJobInfo(src)
    local job = Framework.GetJob(src) or {}
    local jobName = string.lower(job.name or 'unemployed')
    local label = job.label or 'Civilian'
    local onDuty = job.onduty == true
    local key = resolveJobIcon(jobName, job.type)

    return {
        key = key,
        label = label,
        state = onDuty and 'ON DUTY' or 'OFF DUTY'
    }
end


local makePayload, deliverPayload, checkPublicChatAllowed, sendSystem, isShadowMuted

local function startsWith(value, prefix)
    return type(value) == 'string' and value:sub(1, #prefix) == prefix
end

local function sanitizeHexColor(value, fallback)
    value = trim(value or '')
    if value:match('^#%x%x%x%x%x%x$') then return value end
    if value:match('^%x%x%x%x%x%x$') then return '#' .. value end
    return fallback or (Config.AdBoard and Config.AdBoard.defaultAccent) or '#c084fc'
end

local function sanitizeImageUrl(value)
    value = trim(value or '')
    local lower = value:lower()
    if lower == '' or lower == 'off' or lower == 'none' or lower == 'remove' or lower == 'clear' then return '' end

    local maxLen = (Config.AdBoard and Config.AdBoard.maxImageUrlLength) or 300
    if #value > maxLen then value = value:sub(1, maxLen) end

    
    
    if value:find("[%c%s<>\"']") then return '' end

    lower = value:lower()
    if lower:match('^https://') then
        return value
    end

    
    if lower:match('^nui://') or lower:match('^assets/') or lower:match('^%.?/assets/') then
        return value
    end

    return ''
end

local function registerCustomDiscordRoleStyles()
    if not Config.ChatStyles then return end
    Config.ChatStyles.Options = Config.ChatStyles.Options or {}
    for _, role in ipairs(Config.ChatStyles.CustomDiscordRoleStyles or {}) do
        local roleId = tostring(role.roleId or '')
        local styleId = string.lower(trim(role.styleId or role.style or ''))
        if styleId == '' and roleId ~= '' then styleId = 'role_' .. roleId end
        if styleId ~= '' then
            role.style = styleId
            role.styleId = styleId
            Config.ChatStyles.Options[styleId] = {
                label = role.name or role.label or styleId,
                className = role.className or 'style-supporter',
                accent = role.accent or '#c084fc',
                border = role.border or 'rgba(192,132,252,0.85)',
                glow = role.glow or 'none',
                badge = role.badge or role.name or role.label or '',
                bannerImage = role.bannerImage or '',
                backgroundImage = role.backgroundImage or '',
                priority = tonumber(role.priority) or 0
            }
        end
    end
end

registerCustomDiscordRoleStyles()

local function styleExists(styleId)
    styleId = string.lower(trim(styleId or ''))
    return styleId ~= '' and Config.ChatStyles and Config.ChatStyles.Options and Config.ChatStyles.Options[styleId] ~= nil
end

local function copyStyleOption(styleId)
    styleId = styleExists(styleId) and styleId or ((Config.ChatStyles and Config.ChatStyles.defaultStyle) or 'default')
    local option = (Config.ChatStyles.Options or {})[styleId] or {}
    return {
        id = styleId,
        label = option.label or 'Citizen',
        className = option.className or 'style-default',
        accent = option.accent or '#c084fc',
        border = option.border or 'rgba(168,85,247,0.28)',
        glow = option.glow or 'none',
        badge = option.badge or '',
        bannerImage = sanitizeImageUrl(option.bannerImage or ''),
        backgroundImage = sanitizeImageUrl(option.backgroundImage or ''),
        priority = tonumber(option.priority) or 0
    }
end

local function buildAllowedStylesFromDiscordRoles(roles)
    local allowed = {}
    if type(roles) ~= 'table' then return allowed end

    for _, mapping in ipairs(Config.ChatStyles.DiscordRoleStyles or {}) do
        local roleId = getStyleMappingRoleId(mapping)
        local styleId = string.lower(trim(mapping.style or ''))
        if not isPlaceholderRoleId(roleId) and roles[roleId] == true and styleExists(styleId) then
            allowed[styleId] = true
        end
    end

    for _, mapping in ipairs(Config.ChatStyles.CustomDiscordRoleStyles or {}) do
        local roleId = getStyleMappingRoleId(mapping)
        local styleId = string.lower(trim(mapping.styleId or mapping.style or ''))
        if not isPlaceholderRoleId(roleId) and roles[roleId] == true and styleExists(styleId) then
            allowed[styleId] = true
        end
    end

    return allowed
end

local function refreshDiscordRoleStyles(src, force, callback)
    local discordId = getDiscordId(src)
    if not discordId then
        if callback then callback(false) end
        return
    end

    local cfg = getDiscordApiConfig()
    local cacheSeconds = tonumber(cfg.cacheSeconds) or 300
    local cached = roleCache[discordId]
    if force ~= true and cached and cached.expiresAt and cached.expiresAt > os.time() then
        if callback then callback(true) end
        return
    end

    if not cfg.enabled or cfg.guildId == '' or cfg.botToken == '' then
        if callback then callback(false) end
        return
    end

    local url = ('https://discord.com/api/v10/guilds/%s/members/%s'):format(cfg.guildId, discordId)
    PerformHttpRequest(url, function(statusCode, body)
        local roles = {}
        if statusCode == 200 and body and body ~= '' then
            local ok, parsed = pcall(json.decode, body)
            if ok and parsed and type(parsed.roles) == 'table' then
                roles = normalizeRoleList(parsed.roles)
            end
        elseif cached and cached.allowed then
            roles = cached.roles or {}
        end

        roleCache[discordId] = {
            allowed = buildAllowedStylesFromDiscordRoles(roles),
            roles = roles,
            expiresAt = os.time() + cacheSeconds
        }

        if callback then callback(statusCode == 200) end
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. cfg.botToken,
        ['Content-Type'] = 'application/json'
    })
end

local function getAllowedStyles(src)
    local allowed = { default = true }
    if not Config.ChatStyles or Config.ChatStyles.enabled ~= true then return allowed end

    local key = getPlayerKey(src)
    for styleId, value in pairs(state.chatStyles.grants[key] or {}) do
        if value == true and styleExists(styleId) then allowed[styleId] = true end
    end

    for _, mapping in ipairs(Config.ChatStyles.AceStyles or {}) do
        if mapping.ace and mapping.style and styleExists(mapping.style) and IsPlayerAceAllowed(src, mapping.ace) then
            allowed[string.lower(mapping.style)] = true
        end
    end

    local discordId = getDiscordId(src)
    local cached = discordId and roleCache[discordId]
    if cached and cached.allowed then
        for styleId, value in pairs(cached.allowed) do
            if value == true and styleExists(styleId) then allowed[styleId] = true end
        end
    else
        refreshDiscordRoleStyles(src)
    end

    if Config.ChatStyles.unlockLowerPriorityStyles == true then
        local highestPriority = -1
        for styleId, value in pairs(allowed) do
            if value == true and styleExists(styleId) then
                local option = (Config.ChatStyles.Options or {})[styleId] or {}
                local priority = tonumber(option.priority) or 0
                if priority > highestPriority then highestPriority = priority end
            end
        end

        if highestPriority > 0 then
            for styleId, option in pairs(Config.ChatStyles.Options or {}) do
                local priority = tonumber(option.priority) or 0
                if priority > 0 and priority <= highestPriority then
                    allowed[styleId] = true
                end
            end
        end
    end

    if Config.ChatStyles.allowAdminPreviewAll == true and isAdminByDiscord(src) then
        for styleId in pairs(Config.ChatStyles.Options or {}) do allowed[styleId] = true end
    end

    return allowed
end

local function getAvailableStyleList(src)
    local allowed = getAllowedStyles(src)
    local list = {
        { id = 'auto', label = 'Auto - Highest Role', badge = 'AUTO', className = 'style-default' }
    }
    for styleId, option in pairs(Config.ChatStyles.Options or {}) do
        if allowed[styleId] then
            list[#list + 1] = { id = styleId, label = option.label or styleId, badge = option.badge or '', className = option.className or '' }
        end
    end
    table.sort(list, function(a, b)
        if a.id == 'auto' then return true end
        if b.id == 'auto' then return false end
        if a.id == 'default' then return true end
        if b.id == 'default' then return false end
        return a.label < b.label
    end)
    return list
end

local function getBestUnlockedStyleId(allowed)
    local bestStyle = nil
    local bestPriority = -1
    for styleId, value in pairs(allowed or {}) do
        if value == true and styleId ~= 'default' and styleExists(styleId) then
            local option = (Config.ChatStyles.Options or {})[styleId] or {}
            local priority = tonumber(option.priority) or 0
            
            if priority <= 0 then
                local fallbackPriority = { supporter = 500, rgb = 520, holo = 530, galaxy = 540 }
                priority = fallbackPriority[styleId] or 0
            end
            if priority > bestPriority then
                bestPriority = priority
                bestStyle = styleId
            end
        end
    end
    if bestStyle and bestPriority > 0 then return bestStyle end
    return nil
end

local function getSelectedStyleId(src)
    local key = getPlayerKey(src)
    local selected = string.lower(trim(state.chatStyles.selected[key] or ''))
    local allowed = getAllowedStyles(src)
    local forceHighest = Config.ChatStyles and Config.ChatStyles.forceHighestUnlocked == true
    local allowChoice = not forceHighest and not (Config.ChatStyles and Config.ChatStyles.allowPlayerStyleChoice == false)
    local bestStyle = nil

    if Config.ChatStyles and Config.ChatStyles.autoApplyBestUnlocked == true then
        bestStyle = getBestUnlockedStyleId(allowed)
    end

    if forceHighest or selected == '' or selected == 'auto' then
        return bestStyle or (Config.ChatStyles and Config.ChatStyles.defaultStyle) or 'default'
    end

    if allowChoice and allowed[selected] and styleExists(selected) then
        return selected
    end

    if Config.ChatStyles and Config.ChatStyles.fallbackToHighestIfLocked ~= false then
        return bestStyle or (Config.ChatStyles and Config.ChatStyles.defaultStyle) or 'default'
    end

    return (Config.ChatStyles and Config.ChatStyles.defaultStyle) or 'default'
end

local function setPlayerChatStyleSelection(src, styleId)
    if not Config.ChatStyles or Config.ChatStyles.enabled ~= true then return false, 'disabled' end
    if Config.ChatStyles.forceHighestUnlocked == true then return false, 'forced' end

    local key = getPlayerKey(src)
    styleId = string.lower(trim(styleId or 'auto'))

    if styleId == '' or styleId == 'auto' or styleId == 'highest' then
        state.chatStyles.selected[key] = 'auto'
        return true, 'auto'
    end

    local allowed = getAllowedStyles(src)
    if styleExists(styleId) and allowed[styleId] then
        state.chatStyles.selected[key] = styleId
        return true, styleId
    end

    return false, 'locked'
end

local function getMessageStyle(src, overrides)
    local style = copyStyleOption(getSelectedStyleId(src))
    overrides = overrides or {}
    if overrides.styleId and styleExists(overrides.styleId) then
        local styleId = string.lower(trim(overrides.styleId))
        local allowed = getAllowedStyles(src)
        if allowed[styleId] then
            style = copyStyleOption(styleId)
        end
    end

    
    
    if Config.ChatStyles and Config.ChatStyles.alwaysUseHighestRoleBadge == true then
        local bestStyleId = getBestUnlockedStyleId(getAllowedStyles(src))
        if bestStyleId and styleExists(bestStyleId) then
            local bestStyle = copyStyleOption(bestStyleId)
            if bestStyle.badge and bestStyle.badge ~= '' then style.badge = bestStyle.badge end
            style.roleLabel = bestStyle.label or style.roleLabel
            style.roleStyleId = bestStyleId
        end
    end

    if overrides.accent then style.accent = sanitizeHexColor(overrides.accent, style.accent) end
    if overrides.bannerImage then style.bannerImage = sanitizeImageUrl(overrides.bannerImage) end
    if overrides.backgroundImage then style.backgroundImage = sanitizeImageUrl(overrides.backgroundImage) end
    if overrides.badge and overrides.badge ~= '' then style.badge = sanitizeMessage(overrides.badge):sub(1, 16) end
    return style
end

local function getAdProfile(src)
    local key = getPlayerKey(src)
    local existing = state.adProfiles[key] or {}
    local name = sanitizeMessage(existing.businessName or '')
    if name == '' then name = getPlayerNameBySource(src) end
    local category = sanitizeMessage(existing.category or 'General')
    if category == '' then category = 'General' end

    local selectedStyle = getSelectedStyleId(src)
    local existingStyle = string.lower(trim(existing.styleId or 'auto'))
    local allowed = getAllowedStyles(src)
    local forceAdStyle = Config.AdBoard and Config.AdBoard.forceHighestStyle == true

    if not forceAdStyle and existingStyle ~= '' and existingStyle ~= 'auto' and styleExists(existingStyle) and allowed[existingStyle] then
        selectedStyle = existingStyle
    end

    return {
        businessName = name:sub(1, (Config.AdBoard and Config.AdBoard.maxProfileLength) or 40),
        category = category:sub(1, 24),
        accent = sanitizeHexColor(existing.accent, (Config.AdBoard and Config.AdBoard.defaultAccent) or '#c084fc'),
        bannerImage = sanitizeImageUrl(existing.bannerImage or ''),
        backgroundImage = sanitizeImageUrl(existing.backgroundImage or ''),
        styleId = selectedStyle,
        rawStyleId = (forceAdStyle and 'auto') or (existingStyle ~= '' and existingStyle or 'auto'),
        autoStyleId = getSelectedStyleId(src)
    }
end


local function pruneAds()
    local now = os.time()
    local maxActive = (Config.AdBoard and Config.AdBoard.maxActiveAds) or 45
    for i = #state.ads.items, 1, -1 do
        local ad = state.ads.items[i]
        if (tonumber(ad.expiresAt) or 0) <= now then
            table.remove(state.ads.items, i)
        end
    end
    while #state.ads.items > maxActive do table.remove(state.ads.items) end
end

local function buildAdsSnapshot(src)
    pruneAds()
    local categories = Config.AdBoard and Config.AdBoard.categories or { 'General' }
    return {
        ads = state.ads.items or {},
        profile = getAdProfile(src),
        categories = categories,
        styles = getAvailableStyleList(src),
        isAdmin = isAdminByDiscord(src)
    }
end

local function pushAdsSnapshot(target, openWindow)
    TriggerClientEvent('orp-chat:client:setAdsData', target, buildAdsSnapshot(target), openWindow == true)
end

local function broadcastAdsUpdate()
    pruneAds()
    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target then
            TriggerClientEvent('orp-chat:client:setAdsData', target, buildAdsSnapshot(target), false)
        end
    end
end

local function updateAdProfile(src, data, openWindow)
    local key = getPlayerKey(src)
    local existing = state.adProfiles[key] or {}
    local resolved = getAdProfile(src)
    local current = {
        businessName = resolved.businessName,
        category = resolved.category,
        accent = resolved.accent,
        bannerImage = resolved.bannerImage,
        backgroundImage = resolved.backgroundImage,
        styleId = string.lower(trim(existing.styleId or resolved.rawStyleId or 'auto'))
    }
    data = data or {}

    local businessName = sanitizeMessage(data.businessName or current.businessName)
    if businessName ~= '' then current.businessName = businessName:sub(1, (Config.AdBoard and Config.AdBoard.maxProfileLength) or 40) end

    local category = sanitizeMessage(data.category or current.category)
    if category ~= '' then current.category = category:sub(1, 24) end

    if data.accent ~= nil then current.accent = sanitizeHexColor(data.accent, current.accent) end
    if data.bannerImage ~= nil then current.bannerImage = sanitizeImageUrl(data.bannerImage) end
    if data.backgroundImage ~= nil then current.backgroundImage = sanitizeImageUrl(data.backgroundImage) end

    local forceAdStyle = Config.AdBoard and Config.AdBoard.forceHighestStyle == true
    local styleId = string.lower(trim(data.styleId or current.styleId or 'auto'))
    local allowed = getAllowedStyles(src)
    if forceAdStyle or styleId == '' or styleId == 'auto' or styleId == 'highest' then
        current.styleId = 'auto'
    elseif styleExists(styleId) and allowed[styleId] then
        current.styleId = styleId
    else
        current.styleId = 'auto'
    end

    state.adProfiles[key] = current

    
    
    
    if data.styleId ~= nil and Config.AdBoard and Config.AdBoard.syncStyleToChat == true then
        setPlayerChatStyleSelection(src, current.styleId)
    end

    saveState()
    pushAdsSnapshot(src, openWindow == true)
end

local function sendAd(src, message)
    if not Config.AdBoard or Config.AdBoard.enabled ~= true then
        sendSystem(src, 'Ads are disabled right now.')
        return
    end

    message = sanitizeMessage(message)
    if message == '' then
        sendSystem(src, 'Usage: /ad [message] or TAB to ADS then type the ad.')
        return
    end
    if not checkPublicChatAllowed(src, message) then return end

    local key = getPlayerKey(src)
    local now = os.time()
    local cooldown = tonumber(Config.AdBoard.cooldown) or 60
    local waitLeft = (state.ads.cooldowns[key] or 0) + cooldown - now
    if waitLeft > 0 and not isChatModerator(src) then
        sendSystem(src, ('Wait %s second(s) before posting another ad.'):format(waitLeft))
        return
    end
    state.ads.cooldowns[key] = now

    local profile = getAdProfile(src)
    local style = getMessageStyle(src, {
        styleId = profile.styleId,
        accent = profile.accent,
        bannerImage = profile.bannerImage,
        backgroundImage = profile.backgroundImage,
        badge = 'AD'
    })
    style.className = (style.className or 'style-default') .. ' ad-glass'

    local payload = makePayload(src, 'ad', 'AD', message, nil)
    payload.style = style
    payload.ad = profile

    local ad = {
        id = state.ads.nextId,
        payload = payload,
        sourceId = src,
        businessName = profile.businessName,
        category = profile.category,
        message = message,
        style = style,
        job = getJobInfo(src),
        createdAt = os.date('%Y-%m-%d %H:%M'),
        timestamp = os.date('%H:%M'),
        expiresAt = now + ((tonumber(Config.AdBoard.activeMinutes) or 45) * 60)
    }
    state.ads.nextId = state.ads.nextId + 1
    table.insert(state.ads.items, 1, ad)
    pruneAds()
    saveState()

    if isShadowMuted(src) then
        deliverPayload(src, payload)
    else
        TriggerClientEvent('orp-chat:client:addMessage', -1, payload)
    end
    broadcastAdsUpdate()
end

local function buildAuthor(src)
    local author = getPlayerNameBySource(src)
    if Config.Chat.showPlayerId then
        author = ('%s [%s]'):format(author, src)
    end
    return author
end

local function nextMessageId()
    messageCounter = messageCounter + 1
    return ('msg_%s_%s'):format(os.time(), messageCounter)
end

function makePayload(src, kind, title, message, gifUrl)
    return {
        id = nextMessageId(),
        sourceId = src,
        kind = kind,
        title = title,
        author = buildAuthor(src),
        message = message,
        gifUrl = gifUrl,
        timestamp = os.date('%H:%M'),
        job = getJobInfo(src),
        style = getMessageStyle(src)
    }
end

function sendSystem(target, message)
    TriggerClientEvent('orp-chat:client:addMessage', target, {
        id = nextMessageId(),
        kind = 'system',
        title = 'SYSTEM',
        author = 'Server',
        message = message,
        timestamp = os.date('%H:%M')
    })
end

local function broadcastSystem(message)
    TriggerClientEvent('orp-chat:client:addMessage', -1, {
        id = nextMessageId(),
        kind = 'system',
        title = 'SYSTEM',
        author = 'Server',
        message = message,
        timestamp = os.date('%H:%M')
    })
end

local activeCountdown = nil
local countdownSerial = 0

local function parseCountdownDuration(raw)
    raw = string.lower(trim(raw or ''))
    local amount, unit = raw:match('^(%d+)([smh]?)$')
    amount = tonumber(amount or '')
    if not amount then return nil end
    if unit == 'h' then return amount * 3600 end
    if unit == 'm' then return amount * 60 end
    return amount
end

local function formatCountdownDuration(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local sec = seconds % 60
    if h > 0 then return ('%02d:%02d:%02d'):format(h, m, sec) end
    return ('%02d:%02d'):format(m, sec)
end

local function pushCountdown(target, payload)
    TriggerClientEvent('orp-chat:client:updateCountdown', target, payload)
end

local function startChatCountdown(src, seconds, label)
    local cfg = Config.Countdown or {}
    if cfg.enabled == false then
        sendSystem(src, 'Countdowns are disabled.')
        return
    end

    local minSeconds = tonumber(cfg.minSeconds) or 5
    local maxSeconds = tonumber(cfg.maxSeconds) or 3600
    seconds = math.floor(math.max(minSeconds, math.min(maxSeconds, tonumber(seconds) or 0)))
    label = sanitizeMessage(label or '')
    if label == '' then label = cfg.defaultLabel or 'City countdown' end

    countdownSerial = countdownSerial + 1
    local countdownId = ('countdown_%s_%s'):format(os.time(), countdownSerial)
    local endsAt = os.time() + seconds
    activeCountdown = { id = countdownId, endsAt = endsAt, total = seconds, label = label }

    pushCountdown(-1, {
        id = countdownId,
        title = 'COUNTDOWN',
        author = buildAuthor(src),
        label = label,
        total = seconds,
        endsAt = endsAt,
        active = true,
        timestamp = os.date('%H:%M')
    })
    broadcastSystem(('%s started a countdown: %s (%s)'):format(buildAuthor(src), label, formatCountdownDuration(seconds)))

    CreateThread(function()
        Wait((seconds + 1) * 1000)
        if activeCountdown and activeCountdown.id == countdownId then
            pushCountdown(-1, { id = countdownId, title = 'COUNTDOWN', label = label, total = seconds, endsAt = os.time(), active = false, done = true, timestamp = os.date('%H:%M') })
            broadcastSystem(('Countdown finished: %s'):format(label))
            activeCountdown = nil
        end
    end)
end

local function cancelChatCountdown(src)
    if not activeCountdown then
        sendSystem(src, 'There is no active countdown.')
        return
    end
    local old = activeCountdown
    activeCountdown = nil
    pushCountdown(-1, { id = old.id, title = 'COUNTDOWN', label = old.label, active = false, cancelled = true, timestamp = os.date('%H:%M') })
    broadcastSystem(('%s cancelled the countdown: %s'):format(buildAuthor(src), old.label or 'Countdown'))
end

local function broadcastAutoAnnouncement(message)
    local cfg = Config.AutoAnnouncements or {}
    TriggerClientEvent('orp-chat:client:addMessage', -1, {
        id = nextMessageId(),
        sourceId = 0,
        kind = 'announce',
        title = cfg.title or 'CITY TIP',
        author = cfg.author or 'Palmetto County Roleplay',
        message = sanitizeMessage(message),
        timestamp = os.date('%H:%M'),
        job = { key = 'civ', label = 'Server', state = 'ONLINE' },
        style = copyStyleOption('management_team')
    })
end

local function sendModerationNotice(src, kind, title, info)
    TriggerClientEvent('orp-chat:client:moderationNotice', src, {
        kind = kind,
        title = title,
        info = info
    })
end

local function containsFilteredWord(text)
    local lower = string.lower(text or '')
    for _, word in ipairs(state.moderation.filterWords or {}) do
        local needle = trim(string.lower(word or ''))
        if needle ~= '' and lower:find(needle, 1, true) then
            return needle
        end
    end
    return nil
end

local function isAllowedGifUrl(url)
    if type(url) ~= 'string' or url == '' then return false end
    if not url:match('^https://') then return false end
    local lower = url:lower()
    return lower:find('tenor') or lower:find('giphy') or lower:find('gph%.is')
end

local function isMuted(src)
    local key = getPlayerKey(src)
    local muted = state.moderation.mutes[key]
    if muted == true then
        return true, nil
    end
    if type(muted) == 'number' then
        if os.time() >= muted then
            state.moderation.mutes[key] = nil
            saveState()
            return false, nil
        end
        return true, muted
    end
    return false, nil
end

local function checkTimeout(src)
    local key = getPlayerKey(src)
    local expires = state.timeouts[key]
    if not expires then return false end
    if os.time() >= expires then
        state.timeouts[key] = nil
        saveState()
        return false
    end
    local remaining = math.max(1, math.ceil((expires - os.time()) / 60))
    sendSystem(src, ('You are timed out from chat for %s more minute(s).'):format(remaining))
    return true
end

function isShadowMuted(src)
    return state.moderation.shadowmutes[getPlayerKey(src)] == true
end

function checkPublicChatAllowed(src, text)
    if state.moderation.freeze and not isChatModerator(src) then
        sendSystem(src, 'Chat is currently frozen by staff.')
        return false
    end

    local muted, untilTime = isMuted(src)
    if muted then
        if untilTime then
            local remaining = math.max(1, math.ceil((untilTime - os.time()) / 60))
            sendSystem(src, ('You are muted for %s more minute(s).'):format(remaining))
        else
            sendSystem(src, 'You are muted from chat.')
        end
        return false
    end

    if checkTimeout(src) then
        return false
    end

    if not isChatModerator(src) and (state.moderation.slowmode or 0) > 0 then
        local key = getPlayerKey(src)
        local now = os.time()
        local waitLeft = (lastPublicMessageAt[key] or 0) + state.moderation.slowmode - now
        if waitLeft > 0 then
            sendSystem(src, ('Slowmode is on. Wait %s second(s).'):format(waitLeft))
            return false
        end
        lastPublicMessageAt[key] = now
    end

    local blockedWord = containsFilteredWord(text)
    if blockedWord then
        sendSystem(src, ('Your message was blocked by filter: %s'):format(blockedWord))
        return false
    end

    return true
end

function deliverPayload(target, payload)
    TriggerClientEvent('orp-chat:client:addMessage', target, payload)
end

local function sendLocal(src, message, gifUrl)
    local payload = makePayload(src, 'local', 'LOCAL', message, gifUrl)
    if gifUrl and gifUrl ~= '' then
        state.lastGifMessageId = payload.id
        state.lastGifUrl = gifUrl
        saveState()
    end
    if isShadowMuted(src) then
        deliverPayload(src, payload)
        return
    end
    TriggerClientEvent('orp-chat:client:proximityMessage', -1, src, payload, Config.Chat.localDistance)
end

local function rememberGif(payload, gifUrl)
    if gifUrl and gifUrl ~= '' then
        state.lastGifMessageId = payload.id
        state.lastGifUrl = gifUrl
        saveState()
    end
end

local function sendOoc(src, message, gifUrl)
    local payload = makePayload(src, 'ooc', 'OOC', message, gifUrl)
    rememberGif(payload, gifUrl)
    if isShadowMuted(src) then
        deliverPayload(src, payload)
        return
    end
    TriggerClientEvent('orp-chat:client:addMessage', -1, payload)
end

local function sendMe(src, message)
    local payload = makePayload(src, 'me', 'ME', message, nil)
    if isShadowMuted(src) then
        deliverPayload(src, payload)
        return
    end
    TriggerClientEvent('orp-chat:client:proximityMessage', -1, src, payload, Config.Chat.localDistance)
end

local function sendDo(src, message)
    local payload = makePayload(src, 'do', 'DO', message, nil)
    if isShadowMuted(src) then
        deliverPayload(src, payload)
        return
    end
    TriggerClientEvent('orp-chat:client:proximityMessage', -1, src, payload, Config.Chat.localDistance)
end

local function sendPm(fromSrc, toSrc, message)
    local outgoing = {
        id = nextMessageId(),
        sourceId = fromSrc,
        kind = 'pm',
        title = 'PM',
        author = buildAuthor(fromSrc),
        message = message,
        timestamp = os.date('%H:%M'),
        job = getJobInfo(fromSrc),
        style = getMessageStyle(fromSrc)
    }
    local incoming = {
        id = nextMessageId(),
        sourceId = fromSrc,
        kind = 'pm',
        title = 'PM',
        author = buildAuthor(fromSrc),
        message = message,
        timestamp = os.date('%H:%M'),
        job = getJobInfo(fromSrc),
        style = getMessageStyle(fromSrc)
    }
    TriggerClientEvent('orp-chat:client:addMessage', fromSrc, outgoing)
    if toSrc ~= fromSrc then
        TriggerClientEvent('orp-chat:client:addMessage', toSrc, incoming)
    end
end

local function socialAccountKey(network)
    return network == 'fb' and 'fbAccounts' or 'xAccounts'
end

local function socialPostKey(network)
    return network == 'fb' and 'fbPosts' or 'xPosts'
end

local function getSocialAccount(src, network)
    local key = getPlayerKey(src)
    return (state.social[socialAccountKey(network)] or {})[key]
end

local function buildSocialSnapshot(src, network)
    network = network == 'fb' and 'fb' or 'x'
    local account = getSocialAccount(src, network)
    return {
        network = network,
        viewerName = getPlayerNameBySource(src),
        account = account,
        posts = state.social[socialPostKey(network)] or {},
        isAdmin = isAdminByDiscord(src)
    }
end


local function findSocialPost(network, postId)
    local posts = state.social[socialPostKey(network)] or {}
    for index, post in ipairs(posts) do
        if tostring(post.id) == tostring(postId) then
            return post, index, posts
        end
    end
    return nil, nil, posts
end

local function pushSocialSnapshot(target, network, openWindow)
    TriggerClientEvent('orp-chat:client:setSocialData', target, buildSocialSnapshot(target, network), openWindow == true)
end

local function broadcastSocialUpdate(network)
    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target then
            TriggerClientEvent('orp-chat:client:setSocialData', target, buildSocialSnapshot(target, network), false)
        end
    end
end

local function validateUsername(username)
    username = trim(username)
    if username == '' then return false, 'Username required.' end
    if #username < 3 or #username > 18 then return false, 'Username must be 3-18 characters.' end
    if not username:match('^[%w_%.]+$') then return false, 'Use letters, numbers, underscore, and dot only.' end
    return true, username
end

local function createSocialAccount(src, network, username)
    local ok, result = validateUsername(username)
    if not ok then
        sendSystem(src, result)
        return
    end

    local accountKey = socialAccountKey(network)
    local accounts = state.social[accountKey]

    for existingKey, account in pairs(accounts) do
        if existingKey ~= getPlayerKey(src) and string.lower(account.username or '') == string.lower(result) then
            sendSystem(src, 'That username is already taken on this network.')
            return
        end
    end

    accounts[getPlayerKey(src)] = {
        username = result,
        displayName = getPlayerNameBySource(src),
        createdAt = os.date('%Y-%m-%d %H:%M')
    }
    saveState()
    pushSocialSnapshot(src, network, true)
end

local function createSocialPost(src, network, text, isAd)
    if not checkPublicChatAllowed(src, text) then return end

    local account = getSocialAccount(src, network)
    if not account then
        sendSystem(src, ('You need to sign up for %s first.'):format(network == 'fb' and 'Facebook' or 'X'))
        return
    end

    local clean = sanitizeMessage(text)
    if clean == '' then
        sendSystem(src, 'Post text cannot be empty.')
        return
    end

    local post = {
        id = ('post_%s_%s'):format(network, nextMessageId()),
        sourceId = src,
        ownerKey = getPlayerKey(src),
        username = account.username,
        displayName = getPlayerNameBySource(src),
        text = clean,
        isAd = isAd == true,
        timestamp = os.date('%H:%M'),
        createdAt = os.date('%Y-%m-%d %H:%M'),
        likes = 0,
        shares = 0,
        comments = {},
        likedBy = {},
        job = getJobInfo(src)
    }

    local posts = state.social[socialPostKey(network)]
    table.insert(posts, 1, post)
    while #posts > 80 do
        table.remove(posts)
    end

    saveState()
    broadcastSocialUpdate(network)
end

local function buildReportsSnapshot(src)
    local isAdmin = isAdminByDiscord(src)
    local viewerKey = getPlayerKey(src)
    local reports = {}

    for _, report in ipairs(state.reports.items) do
        if isAdmin or report.reporterKey == viewerKey then
            reports[#reports + 1] = report
        end
    end

    table.sort(reports, function(a, b)
        return (a.updatedAt or '') > (b.updatedAt or '')
    end)

    return {
        isAdmin = isAdmin,
        viewerId = src,
        reports = reports
    }
end

local function pushReportsSnapshot(target, openWindow)
    TriggerClientEvent('orp-chat:client:setReportsData', target, buildReportsSnapshot(target), openWindow == true)
end

local function broadcastReportsUpdate()
    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target then
            TriggerClientEvent('orp-chat:client:setReportsData', target, buildReportsSnapshot(target), false)
        end
    end
end

local function createReport(src, targetId, message)
    local text = sanitizeMessage(message)
    if text == '' then
        sendSystem(src, 'Usage: /report [id] [message]')
        return
    end

    local report = {
        id = state.reports.nextId,
        reporterKey = getPlayerKey(src),
        reporterId = src,
        reporterName = getPlayerNameBySource(src),
        targetId = targetId,
        targetName = targetId and getPlayerNameBySource(targetId) or 'General',
        status = 'open',
        createdAt = os.date('%Y-%m-%d %H:%M'),
        updatedAt = os.date('%Y-%m-%d %H:%M'),
        messages = {
            {
                author = getPlayerNameBySource(src),
                role = 'reporter',
                sourceId = src,
                text = text,
                timestamp = os.date('%H:%M')
            }
        }
    }

    state.reports.nextId = state.reports.nextId + 1
    table.insert(state.reports.items, 1, report)
    saveState()

    sendSystem(src, ('Report #%s submitted.'):format(report.id))
    pushReportsSnapshot(src, true)
    broadcastReportsUpdate()

    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target and isAdminByDiscord(target) then
            sendModerationNotice(target, 'warn', 'NEW REPORT', ('#%s from %s'):format(report.id, report.reporterName))
        end
    end
end

local function appendReportReply(src, reportId, message)
    local text = sanitizeMessage(message)
    if text == '' then
        sendSystem(src, 'Usage: /reply [report id] [message]')
        return
    end

    local targetReport
    for _, report in ipairs(state.reports.items) do
        if tonumber(report.id) == tonumber(reportId) then
            targetReport = report
            break
        end
    end

    if not targetReport then
        sendSystem(src, 'Report not found.')
        return
    end

    local admin = isAdminByDiscord(src)
    if not admin and targetReport.reporterKey ~= getPlayerKey(src) then
        sendSystem(src, 'You cannot reply to that report.')
        return
    end

    table.insert(targetReport.messages, {
        author = getPlayerNameBySource(src),
        role = admin and 'staff' or 'reporter',
        sourceId = src,
        text = text,
        timestamp = os.date('%H:%M')
    })
    targetReport.updatedAt = os.date('%Y-%m-%d %H:%M')
    saveState()
    broadcastReportsUpdate()

    local reporterId = tonumber(targetReport.reporterId)
    if reporterId and GetPlayerName(reporterId) then
        pushReportsSnapshot(reporterId, false)
        if admin then
            sendModerationNotice(reporterId, 'warn', 'REPORT UPDATE', ('Staff replied to report #%s'):format(targetReport.id))
        end
    end

    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target and isAdminByDiscord(target) then
            pushReportsSnapshot(target, false)
        end
    end
end

local HELP_DESCRIPTIONS = {
    say = 'Local chat message to nearby players.',
    l = 'Local chat alias. TAB mode LOCAL also sends nearby-only chat.',
    me = 'Roleplay action text. Example: /me adjusts his jacket.',
    ['do'] = 'Scene description text. Example: /do The door would be locked.',
    ooc = 'Out of character chat to the whole server. GIFs are allowed here.',
    ad = 'Post a city advert using your saved ad profile.',
    ads = 'Open the Los Santos Ad Board.',
    adname = 'Set your ad board business/display name.',
    adbanner = 'Set your ad banner image URL.',
    adbg = 'Set your ad background image URL.',
    adcolor = 'Set your ad accent color.',
    adstyle = 'Pick an unlocked ad style.',
    chatstyle = 'Pick your unlocked donor/role chat border style.',
    x = 'Open the in-city X feed.',
    fb = 'Open the in-city Facebook feed.',
    report = 'Create a player/staff report.',
    reports = 'Open the report center.',
    reply = 'Reply to a report as staff.',
    help = 'Open this full help guide.',
    clearchat = 'Clear only your local chat window.',
    announce = 'Send a server announcement.',
    purge = 'Clear chat for everyone.',
    clearallchat = 'Clear chat for everyone.',
    blocklastgif = 'Remove and block the last posted GIF.',
    warn = 'Warn a player in chat.',
    timeout = 'Timeout a player from talking in chat.',
    mute = 'Mute a player from chat.',
    untimeout = 'Remove a chat timeout.',
    unmute = 'Remove a chat mute.',
    slowmode = 'Set global chat slowmode.',
    freezechat = 'Freeze public chat.',
    unfreezechat = 'Unfreeze public chat.',
    shadowmute = 'Toggle shadowmute on a player.',
    filterword = 'Add/remove blocked chat words.',
    countdown = 'Start a synced chat countdown. Example: /countdown 10s Event starts' 
}

local PLAYER_HELP_SET = {
    say = true, l = true, me = true, ['do'] = true, ooc = true, ad = true, ads = true, adname = true, adbanner = true,
    adbg = true, adcolor = true, adstyle = true, chatstyle = true, x = true, fb = true, report = true, reports = true,
    help = true, clearchat = true
}

local MOD_HELP_SET = {
    purge = true, clearallchat = true, blocklastgif = true, warn = true, timeout = true, mute = true,
    untimeout = true, unmute = true, slowmode = true, freezechat = true, unfreezechat = true, reply = true, countdown = true
}

local ADMIN_HELP_SET = {
    announce = true, shadowmute = true, filterword = true
}

local function helpItem(name, help, link)
    return { name = name, help = help, link = link or '' }
end

local function helpCommand(commandName, help)
    return { name = '/' .. commandName, help = help or HELP_DESCRIPTIONS[commandName] or 'Registered server command.' }
end

local function cleanGuideCommandName(name)
    name = tostring(name or ''):gsub('^/', ''):gsub('%s+', ''):lower()
    return name
end

local function isHiddenGuideCommand(name)
    local guide = Config.CommandGuide or {}
    name = cleanGuideCommandName(name)
    if name == '' then return true end

    local hidden = guide.HiddenCommands or {}
    if hidden[name] or hidden['/' .. name] then return true end

    for _, prefix in ipairs(guide.HiddenPrefixes or {}) do
        prefix = tostring(prefix or ''):lower()
        if prefix ~= '' and name:sub(1, #prefix) == prefix then
            return true
        end
    end

    
    if name:find('[^%w_%-%.]') then return true end
    return false
end

local function getFrameworkCommandMeta(name)
    name = cleanGuideCommandName(name)
    return Framework.GetCommandMeta(name)
end

local function getCommandArgumentUsage(name, meta)
    local usage = '/' .. cleanGuideCommandName(name)
    if type(meta) ~= 'table' or type(meta.arguments) ~= 'table' then
        return usage
    end

    for _, argument in ipairs(meta.arguments) do
        local label = nil
        if type(argument) == 'table' then
            label = argument.name or argument.help or argument[1]
        elseif type(argument) == 'string' then
            label = argument
        end

        label = tostring(label or ''):gsub('[%[%]<>]', ''):gsub('%s+', '_')
        if label ~= '' then
            usage = usage .. ' [' .. label .. ']'
        end
    end

    return usage
end

local function playerHasFrameworkPermission(src, permission)
    return Framework.HasPermission(src, permission)
end

local function canSeeGuideCommand(src, name, meta, registered)
    local guide = Config.CommandGuide or {}
    if guide.HideRestrictedFromPlayers == false then return true end

    name = cleanGuideCommandName(name)
    if name == '' then return false end

    local moderationLevels = Config.ChatModeration and Config.ChatModeration.CommandLevels or {}
    if moderationLevels[name] and not hasModerationCommandPermission(src, name) then
        return false
    end

    if type(meta) == 'table' then
        local permission = meta.permission or meta.perm or meta.group
        if permission and not playerHasFrameworkPermission(src, permission) then
            return false
        end
    end

    if type(registered) == 'table' then
        local restricted = registered.restricted
        if restricted == true or restricted == 1 or restricted == 'true' then
            if src == 0 then return true end
            if IsPlayerAceAllowed(src, ('command.%s'):format(name)) then return true end
            if getModerationLevel(src, false) >= 2 then return true end
            return false
        end
    end

    return true
end

local function commandSort(a, b)
    local ca = tostring(a.category or '')
    local cb = tostring(b.category or '')
    if ca ~= cb then return ca < cb end
    return tostring(a.name or '') < tostring(b.name or '')
end

local function buildCommandSnapshot(src)
    local guide = Config.CommandGuide or {}
    local items = {}
    local seen = {}

    if guide.Enabled == false then
        return { items = {}, count = 0 }
    end

    local function addCommand(name, help, resource, category, permission, source, registered)
        name = cleanGuideCommandName(name)
        if isHiddenGuideCommand(name) or seen[name] then return end

        local meta = getFrameworkCommandMeta(name)
        if not canSeeGuideCommand(src, name, meta, registered) then return end

        local resolvedHelp = help
        if (not resolvedHelp or resolvedHelp == '') and type(meta) == 'table' then
            resolvedHelp = meta.help
        end
        if not resolvedHelp or resolvedHelp == '' then
            resolvedHelp = HELP_DESCRIPTIONS[name] or 'Registered server command.'
        end

        local resolvedPermission = permission
        if (not resolvedPermission or resolvedPermission == '') and type(meta) == 'table' then
            resolvedPermission = meta.permission or meta.perm or meta.group
        end
        resolvedPermission = tostring(resolvedPermission or 'user'):lower()

        local resolvedResource = tostring(resource or '')
        if resolvedResource == '' and type(registered) == 'table' then
            resolvedResource = tostring(registered.resource or registered.resourceName or registered.owner or '')
        end

        seen[name] = true
        items[#items + 1] = {
            name = '/' .. name,
            command = name,
            help = tostring(resolvedHelp),
            link = getCommandArgumentUsage(name, meta),
            category = tostring(category or 'Detected'),
            resource = (guide.ShowResourceName == false) and '' or resolvedResource,
            permission = resolvedPermission,
            source = source or 'auto'
        }
    end

    for _, manual in ipairs(guide.Manual or {}) do
        if type(manual) == 'table' then
            addCommand(manual.command or manual.name, manual.help, manual.resource or RESOURCE_NAME, manual.category or 'Manual', manual.permission, 'manual')
        end
    end

    if guide.AutoDetect ~= false then
        local ok, registeredCommands = pcall(GetRegisteredCommands)
        if ok and type(registeredCommands) == 'table' then
            for _, registered in ipairs(registeredCommands) do
                if #items >= (tonumber(guide.MaxAutoCommands) or 220) then break end

                local name = nil
                local resource = nil

                if type(registered) == 'table' then
                    name = registered.name or registered.command or registered[1]
                    resource = registered.resource or registered.resourceName or registered.owner or registered[2]
                elseif type(registered) == 'string' then
                    name = registered
                end

                name = cleanGuideCommandName(name)
                if name ~= '' then
                    local meta = getFrameworkCommandMeta(name)
                    local help = type(meta) == 'table' and meta.help or nil
                    local permission = type(meta) == 'table' and (meta.permission or meta.perm or meta.group) or nil
                    addCommand(name, help, resource, 'Auto-Detected', permission, 'auto', registered)
                end
            end
        end

        local frameworkList, frameworkLabel = Framework.GetCommandList()
        if type(frameworkList) == 'table' then
            for name, meta in pairs(frameworkList) do
                if #items >= (tonumber(guide.MaxAutoCommands) or 220) then break end
                addCommand(name, type(meta) == 'table' and meta.help or nil, Framework.GetFrameworkName(), frameworkLabel or Framework.GetFrameworkLabel(), type(meta) == 'table' and (meta.permission or meta.perm or meta.group) or nil, 'framework')
            end
        end
    end

    table.sort(items, commandSort)
    return {
        items = items,
        count = #items,
        autoDetect = guide.AutoDetect ~= false
    }
end

local function pushCommandSnapshot(target)
    TriggerClientEvent('orp-chat:client:setCommandRegistry', target, buildCommandSnapshot(target))
end

local function buildHelpSnapshot(src)
    local moderationLevel = getModerationLevel(src, true)
    local isMod = moderationLevel >= 1
    local isAdmin = moderationLevel >= 2

    local sections = {
        start = {
            id = 'start',
            icon = '🌴',
            title = 'Start Here',
            description = 'The fastest way to understand Palmetto County Roleplay and basic framework flow.',
            items = {
                helpItem('Load In / Spawn', 'Choose your character, pick a spawn, and wait for the loading/fade to finish before moving. Use your map and phone once you are fully spawned.'),
                helpItem('Get Legal ID / Basic Items', 'Use your starting items and city shops. Most interactions are through E prompts, target prompts, the phone, or job menus.'),
                helpItem('Use Chat Modes', 'Open chat with T. Press TAB to cycle the left status between LOCAL, OOC, ADS, and ME. TAB should not type slash commands into the box.'),
                helpItem('Ask for Staff Help', 'Use /report [message] for real staff help. Do not spam OOC for support issues if reports are available.')
            }
        },
        jobs = {
            id = 'jobs',
            icon = '🏛️',
            title = 'Jobs & City Hall',
            description = 'How to get legal work and start earning money.',
            items = {
                helpItem('Get a Job at City Hall', 'Go to City Hall / qb-cityhall and pick an available civilian job. Some jobs are whitelist-only and require Discord applications or staff approval.'),
                helpItem('Clock In / Duty', 'Some jobs require going on duty before you get paid or see job actions. Use the job location, boss menu, radial menu, or duty point.'),
                helpItem('Trucking / ATS Job', 'Go to the trucking job, start a route, use the trucking UI, spawn the assigned truck/trailer, follow the route, then return/finish the delivery for payment.'),
                helpItem('Construction / DOT Roadwork', 'Construction workers respond to damaged signs/lights/roadwork alerts, repair the area, and clear the roadwork zone so traffic can flow again.'),
                helpItem('Garbage / Bus / Taxi / Tow', 'These are good starter money jobs. Start them from their job location, follow the route or service call, and finish the task before leaving the job vehicle.')
            }
        },
        money = {
            id = 'money',
            icon = '💵',
            title = 'Money, Stores & Lottery',
            description = 'Everyday player systems for cash, shopping, and the Los Santos lottery.',
            items = {
                helpItem('Banks / ATMs', 'Use ATMs or bank locations to check balances, deposit/withdraw, and move money where your server allows it.'),
                helpItem('Shops', 'Walk up to store points and buy available items. Different shops have different products, and some are job/license locked.'),
                helpItem('Lottery', 'Use /lottery to open the Los Santos-style lottery page. Buy tickets, wait for drawings, and remember lottery/state tax systems can feed public funds.'),
                helpItem('Paychecks and Taxes', 'Paychecks and money flow can be taxed depending on server config. Legal jobs are the safest way to build steady income.')
            }
        },
        chat = {
            id = 'chat',
            icon = '💬',
            title = 'Chat, Ads & Social',
            description = 'Roleplay chat, GIF rules, city ads, reports, and social posting.',
            items = {
                helpCommand('ooc', 'Global out-of-character chat. GIFs work here.'),
                helpCommand('l', 'Nearby local chat. Use for normal in-character speech near you.'),
                helpCommand('me', 'Roleplay action text. Example: /me reaches for his wallet.'),
                helpCommand('do', 'Scene/context description. Example: /do The window would be broken.'),
                helpCommand('ads', 'Open the ad board and customize your city ad profile.'),
                helpCommand('ad', 'Post a city ad from your current ad profile.'),
                helpCommand('chatstyle', 'List or select unlocked donor/role chat styles.'),
                helpCommand('report', 'Send a support report to staff.')
            }
        },
        vehicles = {
            id = 'vehicles',
            icon = '🚗',
            title = 'Vehicles, Keys & Hijacking',
            description = 'Vehicle ownership, lockpicking, hotwiring, and criminal vehicle interactions.',
            items = {
                helpItem('Buy and Store Cars', 'Buy vehicles from dealerships such as PDM/Larrys if enabled. Store them in garages so they save properly.'),
                helpItem('Vehicle Keys', 'Owned vehicles need keys. Some scripts give keys automatically after purchase, after hotwire, or through a key-sharing command/menu.'),
                helpItem('Break Into Parked Cars', 'If you have a lockpick, use the lockpick interaction/minigame to get into locked parked cars. Hotwiring takes time and can fail.'),
                helpItem('Hijack / Force Driver Out', 'SHIFT + F can be used for quick vehicle hijacking where your car break-in resource allows it. This should be fast and should not force the normal lockpick minigame.'),
                helpItem('Police Risk', 'Vehicle crimes can alert police or create 911-style calls depending on witnesses, location, and server config.')
            }
        },
        housing = {
            id = 'housing',
            icon = '🏠',
            title = 'Housing & Real Estate',
            description = 'Buying, selling, listing, and managing player homes.',
            items = {
                helpItem('Find Homes for Sale', 'Use the real estate listing/user page or phone app if enabled to view houses, images, locations, prices, and inquiry options.'),
                helpItem('Inquire About a House', 'Use the listing inquiry button or contact a real estate agent. Agents can help create, sell, or update listings.'),
                helpItem('Real Estate Agents', 'Real estate job members can create listings, add images, edit house info, and manage homes from the agent/admin UI.'),
                helpItem('Managers / Rank 4+', 'High-rank real estate staff can keep a house they created and take it off the market instead of selling it.')
            }
        },
        weapons = {
            id = 'weapons',
            icon = '🔫',
            title = 'Guns, Licenses & Ammu-Nation',
            description = 'How legal weapons and license cooldowns work.',
            items = {
                helpItem('Weapon License', 'Apply/register for a weapon license at supported Ammu-Nation locations. If you were jailed recently, you must wait out the configured cooldown before applying.'),
                helpItem('Buying Weapons', 'Weapon shops can require a valid license for firearms and ammo. Melee/basic items may not require one depending on config.'),
                helpItem('Fingerprints / Evidence', 'Some weapon or police systems use fingerprints/evidence through qb-target or job interactions. Police may use this in investigations.'),
                helpItem('Illegal Weapons', 'Black market/illegal items are separate from legal Ammu-Nation purchases and may carry heavier RP/legal risk.')
            }
        },
        crime = {
            id = 'crime',
            icon = '🧰',
            title = 'Criminal Activities',
            description = 'Robberies and risky systems. Expect police alerts and consequences.',
            items = {
                helpItem('Bank Robbery', 'Banks can include tellers and safes. Bring the required item/weapon/tool, interact at the correct point, complete the action/minigame, and expect police alerts.'),
                helpItem('Cutting Safes', 'Safes can take longer but pay better. Hold the interaction, finish the animation/progress, and leave before police arrive.'),
                helpItem('Vehicle Break-ins', 'Use lockpicks/hotwire systems for parked vehicles, or hijack active drivers where allowed. Criminal actions can trigger calls.'),
                helpItem('Crates', 'Crate events should show an E prompt at the crate location and can send global notifications when active.'),
                helpItem('Black Market Items', 'Items like thermite, cards, drills, USBs, scanners, and advanced lockpicks are usually illegal tools for high-risk jobs.')
            }
        },
        departments = {
            id = 'departments',
            icon = '🚓',
            title = 'Departments & Whitelisted Roles',
            description = 'Basic flow for LEO, EMS, Fire, DOJ, and staff-reviewed roles.',
            items = {
                helpItem('LEO', 'Police/Sheriff/SAHP use duty status, MDT/calls, garages, evidence, cuffs, spike strips, and department-specific tools.'),
                helpItem('EMS / SAFR', 'Medical/fire roles respond to injuries, hospital transport, AI/EMS systems, fire calls, and MDT/call attachments where configured.'),
                helpItem('DOJ / Lawyers', 'Justice roles handle legal RP, court matters, warrants, jail/legal records, and license-related RP when enabled.'),
                helpItem('Applications', 'Whitelisted jobs usually require Discord applications or staff approval before access is granted.')
            }
        },
        player_commands = {
            id = 'player-commands',
            icon = '⌨️',
            title = 'Player Commands',
            description = 'Useful commands available to normal players.',
            items = {}
        },
        social = {
            id = 'social',
            icon = '📱',
            title = 'Social Apps',
            description = 'In-city social and community tools.',
            items = {}
        },
        reports = {
            id = 'reports',
            icon = '📨',
            title = 'Reports & Support',
            description = 'How to contact staff without breaking roleplay.',
            items = {}
        },
        moderation = {
            id = 'moderation',
            icon = '🛡️',
            title = 'Chat Mod Tools',
            description = 'Visible only to chat mods/admins. Use these to control spam, GIF abuse, and OOC issues.',
            items = {}
        },
        admin = {
            id = 'admin',
            icon = '⚙️',
            title = 'Admin Tools',
            description = 'Higher-level chat tools for admins only.',
            items = {}
        }
    }

    local function addCommand(sectionId, name)
        if sections[sectionId] then
            table.insert(sections[sectionId].items, helpCommand(name))
        end
    end

    for name in pairs(PLAYER_HELP_SET) do
        if name == 'x' or name == 'fb' then
            addCommand('social', name)
        elseif name == 'report' or name == 'reports' then
            addCommand('reports', name)
        elseif name ~= 'help' then
            addCommand('player_commands', name)
        end
    end
    addCommand('player_commands', 'help')

    if isMod then
        for name in pairs(MOD_HELP_SET) do
            if hasModerationCommandPermission(src, name) then
                addCommand('moderation', name)
            end
        end
        table.insert(sections.moderation.items, helpItem('Right-click a chat message', 'Open the moderation menu for warn, timeout, mute, PM, remove/block GIF, purge, slowmode, freeze, and other quick actions.'))
        table.insert(sections.moderation.items, helpItem('Slowmode', 'Use /slowmode [seconds]. Use 0 to disable. Good for OOC spam or heated situations.'))
        table.insert(sections.moderation.items, helpItem('Timeouts', 'Use /timeout [id] [minutes] [reason]. Default right-click timeout length comes from config.lua.'))
        table.insert(sections.moderation.items, helpItem('Countdowns', 'Use /countdown 10s, /countdown 1m, or /countdown 1h with an optional label. Everyone sees one live updating chat timer.'))
    end

    if isAdmin then
        for name in pairs(ADMIN_HELP_SET) do
            if hasModerationCommandPermission(src, name) then
                addCommand('admin', name)
            end
        end
        table.insert(sections.admin.items, helpCommand('chatstyle', 'Admins can use /chatstyle grant [id] [style] to grant a style manually.'))
        table.insert(sections.admin.items, helpItem('Role IDs / Permissions', 'Discord role IDs for mods/admins and role-based chat styles are configured in config.lua. ACE fallbacks work without a Discord bot token.'))
    end

    local commandSnapshot = buildCommandSnapshot(src)
    if Config.CommandGuide and Config.CommandGuide.Enabled ~= false then
        sections.detected_commands = {
            id = 'detected-commands',
            icon = '/',
            title = 'All / Commands',
            description = ('%s commands from running resources. Type / in chat to autocomplete.'):format(commandSnapshot.count or 0),
            items = commandSnapshot.items or {}
        }
    end

    for _, section in pairs(sections) do
        table.sort(section.items, function(a, b) return tostring(a.name) < tostring(b.name) end)
    end

    local ordered = {
        sections.start,
        sections.jobs,
        sections.money,
        sections.chat,
        sections.vehicles,
        sections.housing,
        sections.weapons,
        sections.crime,
        sections.departments,
        sections.player_commands,
        sections.detected_commands,
        sections.social,
        sections.reports
    }

    if isMod then ordered[#ordered + 1] = sections.moderation end
    if isAdmin then ordered[#ordered + 1] = sections.admin end

    return {
        isAdmin = isAdmin,
        canModerate = isMod,
        moderationLevel = moderationLevel,
        roleLabel = moderationLevelName(moderationLevel),
        commandCount = commandSnapshot.count or 0,
        commandCatalog = commandSnapshot.items or {},
        sections = ordered
    }
end

local function pushHelpSnapshot(target, openWindow)
    TriggerClientEvent('orp-chat:client:setHelpData', target, buildHelpSnapshot(target), openWindow == true)
end


local function handleAdminCommand(src, command, args)
    if not hasModerationCommandPermission(src, command) then
        if getModerationLevel(src, false) <= 0 then refreshModerationRoles(src, true) end
        sendSystem(src, 'You are not allowed to use that moderation command.')
        return true
    end

    if command == 'countdown' then
        local first = string.lower(trim(args[1] or ''))
        if first == 'cancel' or first == 'stop' or first == 'off' then
            cancelChatCountdown(src)
            return true
        end
        local seconds = parseCountdownDuration(first)
        if not seconds then
            sendSystem(src, 'Usage: /countdown 10s [label], /countdown 1m [label], /countdown 1h [label], or /countdown cancel')
            return true
        end
        local label = table.concat(args, ' ', 2)
        startChatCountdown(src, seconds, label)
        return true
    elseif command == 'announce' then
        local message = sanitizeMessage(table.concat(args, ' '))
        if message ~= '' then
            local payload = makePayload(src, 'announce', 'ANNOUNCEMENT', message, nil)
            TriggerClientEvent('orp-chat:client:addMessage', -1, payload)
        end
        return true
    elseif command == 'purge' or command == 'clearallchat' then
        TriggerClientEvent('orp-chat:client:clear', -1)
        broadcastSystem(('%s purged the chat.'):format(buildAuthor(src)))
        return true
    elseif command == 'blocklastgif' then
        if state.lastGifMessageId then
            TriggerClientEvent('orp-chat:client:removeMessage', -1, state.lastGifMessageId)
        end
        if state.lastGifUrl and state.lastGifUrl ~= '' then
            state.blockedGifUrls[state.lastGifUrl] = true
            saveState()
        end
        broadcastSystem(('%s blocked the last GIF.'):format(buildAuthor(src)))
        return true
    elseif command == 'timeout' then
        local target = resolveTarget(args[1])
        local minutes = tonumber(args[2] or '10') or 10
        local maxMinutes = tonumber(Config.ChatModeration and Config.ChatModeration.Defaults and Config.ChatModeration.Defaults.maxTimeoutMinutes) or 1440
        minutes = math.max(1, math.min(maxMinutes, minutes))
        local reason = sanitizeMessage(table.concat(args, ' ', 3))
        if not target then
            sendSystem(src, 'Usage: /timeout [server id] [minutes] [reason]')
            return true
        end
        state.timeouts[getPlayerKey(target)] = os.time() + math.max(1, minutes) * 60
        saveState()
        local detail = ('%s minute(s)%s'):format(minutes, reason ~= '' and (' • ' .. reason) or '')
        sendModerationNotice(target, 'timeout', 'CHAT TIMEOUT', detail)
        broadcastSystem(('%s timed out %s for %s minute(s).'):format(buildAuthor(src), buildAuthor(target), minutes))
        return true
    elseif command == 'mute' then
        local target = resolveTarget(args[1])
        local reason = sanitizeMessage(table.concat(args, ' ', 2))
        if not target then
            sendSystem(src, 'Usage: /mute [server id] [reason]')
            return true
        end
        state.moderation.mutes[getPlayerKey(target)] = true
        saveState()
        sendModerationNotice(target, 'mute', 'CHAT MUTED', reason ~= '' and reason or 'A staff member muted your chat access.')
        sendSystem(src, ('Muted %s.'):format(buildAuthor(target)))
        return true
    elseif command == 'warn' then
        local target = resolveTarget(args[1])
        local reason = sanitizeMessage(table.concat(args, ' ', 2))
        if not target then
            sendSystem(src, 'Usage: /warn [server id] [reason]')
            return true
        end
        local key = getPlayerKey(target)
        state.warnings[key] = (state.warnings[key] or 0) + 1
        saveState()
        local detail = ('Warning #%s%s'):format(state.warnings[key], reason ~= '' and (' • ' .. reason) or '')
        sendModerationNotice(target, 'warn', 'WARNING', detail)
        sendSystem(src, ('Warned %s. Total warnings: %s'):format(buildAuthor(target), state.warnings[key]))
        return true
    elseif command == 'untimeout' or command == 'unmute' then
        local target = resolveTarget(args[1])
        if not target then
            sendSystem(src, 'Usage: /untimeout [server id]')
            return true
        end
        state.timeouts[getPlayerKey(target)] = nil
        state.moderation.mutes[getPlayerKey(target)] = nil
        saveState()
        sendModerationNotice(target, 'unmute', 'CHAT RESTORED', 'You can chat again.')
        sendSystem(src, ('Restored chat access for %s.'):format(buildAuthor(target)))
        return true
    elseif command == 'slowmode' then
        local seconds = math.max(0, tonumber(args[1] or '0') or 0)
        state.moderation.slowmode = seconds
        saveState()
        refreshAllModerationStates()
        broadcastSystem(seconds > 0 and ('Chat slowmode enabled: %ss'):format(seconds) or 'Chat slowmode disabled.')
        return true
    elseif command == 'freezechat' then
        state.moderation.freeze = true
        saveState()
        refreshAllModerationStates()
        broadcastSystem('Chat has been frozen by staff.')
        return true
    elseif command == 'unfreezechat' then
        state.moderation.freeze = false
        saveState()
        refreshAllModerationStates()
        broadcastSystem('Chat has been unfrozen by staff.')
        return true
    elseif command == 'shadowmute' then
        local target = resolveTarget(args[1])
        if not target then
            sendSystem(src, 'Usage: /shadowmute [server id]')
            return true
        end
        local key = getPlayerKey(target)
        state.moderation.shadowmutes[key] = not state.moderation.shadowmutes[key]
        saveState()
        sendSystem(src, ('Shadowmute for %s: %s'):format(buildAuthor(target), state.moderation.shadowmutes[key] and 'ON' or 'OFF'))
        return true
    elseif command == 'filterword' then
        local action = string.lower(args[1] or '')
        local word = trim(args[2] or '')
        if action ~= 'add' and action ~= 'remove' then
            sendSystem(src, 'Usage: /filterword add/remove [word]')
            return true
        end
        if word == '' then
            sendSystem(src, 'You need to provide a word.')
            return true
        end
        if action == 'add' then
            for _, existing in ipairs(state.moderation.filterWords) do
                if string.lower(existing) == string.lower(word) then
                    sendSystem(src, 'That word is already filtered.')
                    return true
                end
            end
            table.insert(state.moderation.filterWords, word)
            saveState()
            sendSystem(src, ('Added filtered word: %s'):format(word))
        else
            for i = #state.moderation.filterWords, 1, -1 do
                if string.lower(state.moderation.filterWords[i]) == string.lower(word) then
                    table.remove(state.moderation.filterWords, i)
                end
            end
            saveState()
            sendSystem(src, ('Removed filtered word: %s'):format(word))
        end
        return true
    elseif command == 'reply' then
        local reportId = tonumber(args[1] or '0')
        local message = table.concat(args, ' ', 2)
        appendReportReply(src, reportId, message)
        return true
    elseif command == 'reports' then
        pushReportsSnapshot(src, true)
        return true
    elseif command == 'help' then
        pushHelpSnapshot(src, true)
        return true
    end

    return false
end

local function handleChatCommand(src, command, args, gifUrl)
    local message = sanitizeMessage(table.concat(args, ' '))
    gifUrl = trim(gifUrl or '')
    local hasGif = gifUrl ~= ''

    if command == 'me' or command == 'do' or command == 'ooc' or command == 'say' or command == 'local' or command == 'l' then
        if (message ~= '' or hasGif) and not checkPublicChatAllowed(src, message) then return true end
    end

    if command == 'me' then
        if hasGif then sendSystem(src, 'GIFs can only be sent with /ooc or /l.') end
        if message ~= '' then sendMe(src, message) end
        return true
    elseif command == 'do' then
        if hasGif then sendSystem(src, 'GIFs can only be sent with /ooc or /l.') end
        if message ~= '' then sendDo(src, message) end
        return true
    elseif command == 'ooc' then
        if message ~= '' or hasGif then sendOoc(src, message, gifUrl) end
        return true
    elseif command == 'say' or command == 'local' or command == 'l' then
        if message ~= '' or hasGif then sendLocal(src, message, gifUrl) end
        return true
    elseif command == 'ad' then
        if hasGif then sendSystem(src, 'GIFs are for OOC/LOCAL. Ads use your ad banner/background instead.') end
        sendAd(src, message)
        return true
    elseif command == 'ads' then
        pushAdsSnapshot(src, true)
        return true
    elseif command == 'adname' then
        updateAdProfile(src, { businessName = message })
        sendSystem(src, 'Ad business name updated.')
        return true
    elseif command == 'adbanner' then
        updateAdProfile(src, { bannerImage = message })
        sendSystem(src, message == '' and 'Ad banner cleared.' or 'Ad banner updated.')
        return true
    elseif command == 'adbg' then
        updateAdProfile(src, { backgroundImage = message })
        sendSystem(src, message == '' and 'Ad background cleared.' or 'Ad background updated.')
        return true
    elseif command == 'adcolor' then
        updateAdProfile(src, { accent = args[1] or '' })
        sendSystem(src, 'Ad accent updated.')
        return true
    elseif command == 'adstyle' then
        local wantedStyle = string.lower(trim(args[1] or 'auto'))
        updateAdProfile(src, { styleId = wantedStyle })
        if wantedStyle == '' or wantedStyle == 'auto' or wantedStyle == 'highest' then
            sendSystem(src, 'Ad/chat style set to AUTO. It will use your highest unlocked role style live.')
        else
            sendSystem(src, ('Ad/chat style selected: %s'):format(wantedStyle))
        end
        return true
    elseif command == 'chatstyle' then
        local sub = string.lower(trim(args[1] or 'list'))
        if sub == 'list' or sub == '' then
            local labels = {}
            for _, style in ipairs(getAvailableStyleList(src)) do labels[#labels + 1] = style.id .. ' (' .. style.label .. ')' end
            sendSystem(src, 'Available chat styles: ' .. table.concat(labels, ', '))
            return true
        end
        if (sub == 'default' or sub == 'reset' or sub == 'none' or sub == 'auto') then
            state.chatStyles.selected[getPlayerKey(src)] = 'auto'
            saveState()
            sendSystem(src, 'Chat style set to AUTO. It will use your highest unlocked role style live.')
            return true
        end
        if sub == 'adminlist' and isChatAdmin(src) then
            local labels = {}
            for styleId, option in pairs(Config.ChatStyles.Options or {}) do labels[#labels + 1] = styleId .. ' (' .. (option.label or styleId) .. ')' end
            table.sort(labels)
            sendSystem(src, 'All configured chat styles: ' .. table.concat(labels, ', '))
            return true
        end
        if sub == 'grant' and isChatAdmin(src) then
            local target = resolveTarget(args[2])
            local styleId = string.lower(trim(args[3] or ''))
            if not target or not styleExists(styleId) then
                sendSystem(src, 'Usage: /chatstyle grant [id] [style]')
                return true
            end
            local targetKey = getPlayerKey(target)
            state.chatStyles.grants[targetKey] = state.chatStyles.grants[targetKey] or {}
            state.chatStyles.grants[targetKey][styleId] = true
            saveState()
            sendSystem(src, ('Granted %s to %s.'):format(styleId, getPlayerNameBySource(target)))
            sendSystem(target, ('You unlocked chat style: %s'):format(styleId))
            return true
        end
        local allowed = getAllowedStyles(src)
        if styleExists(sub) and allowed[sub] then
            if Config.ChatStyles and Config.ChatStyles.forceHighestUnlocked == true then
                sendSystem(src, ('Auto style is enabled. Your current highest unlocked style is: %s'):format(getSelectedStyleId(src)))
            else
                state.chatStyles.selected[getPlayerKey(src)] = sub
                saveState()
                sendSystem(src, ('Chat style selected: %s'):format(sub))
            end
        else
            sendSystem(src, 'That style is not unlocked. Use /chatstyle list.')
        end
        return true
    elseif command == 'clearchat' then
        TriggerClientEvent('orp-chat:client:clear', src)
        return true
    elseif command == 'report' then
        local target = resolveTarget(args[1])
        local msg = target and table.concat(args, ' ', 2) or table.concat(args, ' ')
        createReport(src, target, msg)
        return true
    elseif command == 'x' or command == 'fb' then
        TriggerClientEvent('orp-chat:client:setSocialData', src, buildSocialSnapshot(src, command), true)
        return true
    elseif command == 'reports' then
        pushReportsSnapshot(src, true)
        return true
    elseif command == 'help' then
        pushHelpSnapshot(src, true)
        return true
    end

    return handleAdminCommand(src, command, args)
end


local REGISTERED_CHAT_COMMANDS = {
    'me', 'do', 'ooc', 'say', 'local', 'l', 'ad', 'ads', 'adname', 'adbanner', 'adbg', 'adcolor', 'adstyle', 'chatstyle',
    'clearchat', 'clearallchat', 'report', 'x', 'fb', 'reports', 'help', 'announce', 'countdown', 'purge', 'blocklastgif', 'warn', 'timeout', 'mute',
    'untimeout', 'unmute', 'slowmode', 'freezechat', 'unfreezechat', 'shadowmute', 'filterword', 'reply'
}

for _, registeredCommand in ipairs(REGISTERED_CHAT_COMMANDS) do
    RegisterCommand(registeredCommand, function(src, args)
        if not src or src <= 0 then return end
        if not handleChatCommand(src, registeredCommand, args or {}, '') then
            sendSystem(src, ('Unknown chat command: /%s'):format(registeredCommand))
        end
    end, false)
end

AddEventHandler('playerJoining', function()
    local src = source
    if src then
        refreshDiscordRoleStyles(src, true, function()
            pushAdsSnapshot(src, false)
        end)
        refreshModerationRoles(src, true)
        if activeCountdown and activeCountdown.endsAt and activeCountdown.endsAt > os.time() then
            pushCountdown(src, {
                id = activeCountdown.id,
                title = 'COUNTDOWN',
                label = activeCountdown.label,
                total = activeCountdown.total,
                endsAt = activeCountdown.endsAt,
                active = true,
                timestamp = os.date('%H:%M')
            })
        end
    end
end)

CreateThread(function()
    Wait(8000)
    while true do
        local discordCfg = getDiscordApiConfig()
        local interval = tonumber(discordCfg.liveRefreshSeconds) or tonumber(discordCfg.cacheSeconds) or 60
        if interval < 20 then interval = 20 end

        local canRefresh = discordCfg.enabled == true and discordCfg.guildId ~= '' and discordCfg.botToken ~= ''
        if canRefresh then
            for _, playerId in ipairs(GetPlayers()) do
                local target = tonumber(playerId)
                if target then
                    refreshDiscordRoleStyles(target, true, function()
                        pushAdsSnapshot(target, false)
                    end)
                    refreshModerationRoles(target, true)
                    if activeCountdown and activeCountdown.endsAt and activeCountdown.endsAt > os.time() then
                        pushCountdown(target, {
                            id = activeCountdown.id,
                            title = 'COUNTDOWN',
                            label = activeCountdown.label,
                            total = activeCountdown.total,
                            endsAt = activeCountdown.endsAt,
                            active = true,
                            timestamp = os.date('%H:%M')
                        })
                    end
                end
            end
        end

        Wait(interval * 1000)
    end
end)

CreateThread(function()
    local cfg = Config.AutoAnnouncements or {}
    if cfg.enabled == false then return end
    local messages = cfg.messages or {}
    if type(messages) ~= 'table' or #messages == 0 then return end
    local delay = tonumber(cfg.startDelaySeconds) or 120
    if delay < 10 then delay = 10 end
    Wait(delay * 1000)
    local index = 0
    while true do
        local interval = math.max(1, tonumber(cfg.intervalMinutes) or 12) * 60000
        local msg
        if cfg.randomize == true then
            msg = messages[math.random(1, #messages)]
        else
            index = (index % #messages) + 1
            msg = messages[index]
        end
        if msg and trim(msg) ~= '' then broadcastAutoAnnouncement(msg) end
        Wait(interval)
    end
end)

RegisterNetEvent('orp-chat:server:submitPayload', function(data)
    local src = source
    local text = sanitizeMessage(data and data.text or '')
    local gifUrl = trim(data and data.gifUrl or '')
    local selectedMode = string.lower(trim(data and data.mode or 'l'))
    if selectedMode == 'local' or selectedMode == 'say' then selectedMode = 'l' end
    if selectedMode ~= 'l' and selectedMode ~= 'ooc' and selectedMode ~= 'me' and selectedMode ~= 'ad' then selectedMode = 'l' end

    if gifUrl ~= '' and (not isAllowedGifUrl(gifUrl) or state.blockedGifUrls[gifUrl]) then
        gifUrl = ''
        sendSystem(src, 'That GIF is blocked.')
    end

    if text == '' and gifUrl == '' then return end

    if text:sub(1, 1) == '/' then
        local raw = trim(text:sub(2))
        if raw == '' then return end
        local args = splitArguments(raw)
        local command = string.lower(table.remove(args, 1) or '')
        if command == '' then return end
        if not handleChatCommand(src, command, args, gifUrl) then
            sendSystem(src, ('Unknown chat command: /%s'):format(command))
        end
        return
    end

    if selectedMode == 'ooc' then
        if not checkPublicChatAllowed(src, text) then return end
        sendOoc(src, text, gifUrl)
        return
    elseif selectedMode == 'ad' then
        if gifUrl ~= '' then sendSystem(src, 'GIFs are for OOC/LOCAL. Ads use your ad banner/background instead.') end
        sendAd(src, text)
        return
    elseif selectedMode == 'me' then
        if gifUrl ~= '' then
            sendSystem(src, 'GIFs can only be sent with OOC or LOCAL.')
            gifUrl = ''
        end
        if text ~= '' and checkPublicChatAllowed(src, text) then sendMe(src, text) end
        return
    end

    if not checkPublicChatAllowed(src, text) then return end
    sendLocal(src, text, gifUrl)
end)

AddEventHandler('__cfx_internal:commandFallback', function(command)
    local src = source
    if not src or src <= 0 then return end
    sendSystem(src, ('Unknown command: /%s'):format(tostring(command or '')))
    CancelEvent()
end)

RegisterNetEvent('orp-chat:server:requestAdminState', function()
    local src = source
    refreshModerationRoles(src, true)
    pushModerationState(src)
end)

RegisterNetEvent('orp-chat:server:requestCommandRegistry', function()
    local src = source
    pushCommandSnapshot(src)
end)

RegisterNetEvent('orp-chat:server:searchGif', function(query)
    local src = source
    query = sanitizeMessage(query)

    if not Config.Integrations.gifs or query == '' then
        TriggerClientEvent('orp-chat:client:gifResults', src, {})
        return
    end

    local provider = (Config.Integrations.provider or 'giphy'):lower()

    if provider == 'giphy' then
        local giphy = Config.Integrations.giphy or {}
        if not giphy.enabled or not giphy.apiKey or giphy.apiKey == '' then
            TriggerClientEvent('orp-chat:client:gifResults', src, {})
            return
        end

        local url = ('https://api.giphy.com/v1/gifs/search?api_key=%s&q=%s&limit=%s&rating=%s')
            :format(urlencode(giphy.apiKey), urlencode(query), tostring(giphy.limit or 8), urlencode(giphy.rating or 'pg-13'))

        PerformHttpRequest(url, function(statusCode, body)
            local mapped = {}
            if statusCode == 200 and body and body ~= '' then
                local ok, parsed = pcall(json.decode, body)
                if ok and parsed and parsed.data then
                    for _, item in ipairs(parsed.data) do
                        local images = item.images or {}
                        local media = images.fixed_height_small or images.fixed_width_small or images.original or {}
                        local urlValue = media.url or ''
                        if urlValue ~= '' then
                            mapped[#mapped + 1] = {
                                url = urlValue,
                                preview = urlValue,
                                title = item.title or 'GIF'
                            }
                        end
                    end
                end
            end
            TriggerClientEvent('orp-chat:client:gifResults', src, mapped)
        end, 'GET', '', { ['Accept'] = 'application/json' })
        return
    end

    local tenor = Config.Integrations.tenor or {}
    if not tenor.enabled or not tenor.apiKey or tenor.apiKey == '' then
        TriggerClientEvent('orp-chat:client:gifResults', src, {})
        return
    end

    local url = ('https://tenor.googleapis.com/v2/search?q=%s&key=%s&client_key=%s&limit=%s&locale=%s&media_filter=%s')
        :format(urlencode(query), urlencode(tenor.apiKey), urlencode(tenor.clientKey or 'orp_chat'), tostring(tenor.limit or 8), urlencode(tenor.locale or 'en_US'), urlencode(tenor.mediaFilter or 'tinygif'))

    PerformHttpRequest(url, function(statusCode, body)
        local mapped = {}
        if statusCode == 200 and body and body ~= '' then
            local ok, parsed = pcall(json.decode, body)
            if ok and parsed and parsed.results then
                for _, item in ipairs(parsed.results) do
                    local formats = item.media_formats or {}
                    local media = formats.tinygif or formats.nanogif or formats.mediumgif or formats.gif
                    if media and media.url then
                        mapped[#mapped + 1] = {
                            url = media.url,
                            preview = media.url,
                            title = item.content_description or item.title or 'GIF'
                        }
                    end
                end
            end
        end
        TriggerClientEvent('orp-chat:client:gifResults', src, mapped)
    end, 'GET', '', { ['Accept'] = 'application/json' })
end)


RegisterNetEvent('orp-chat:server:requestAds', function(openWindow)
    local src = source
    refreshDiscordRoleStyles(src, false, function()
        pushAdsSnapshot(src, openWindow == true)
    end)
end)

RegisterNetEvent('orp-chat:server:postAd', function(data)
    local src = source
    data = data or {}

    
    
    
    if type(data.profile) == 'table' then
        updateAdProfile(src, data.profile, false)
    end

    sendAd(src, tostring(data.message or ''))
end)

RegisterNetEvent('orp-chat:server:updateAdProfile', function(data)
    local src = source
    updateAdProfile(src, data or {}, true)
end)

RegisterNetEvent('orp-chat:server:socialSignup', function(data)
    local src = source
    local network = tostring(data and data.network or 'x')
    local username = tostring(data and data.username or '')
    createSocialAccount(src, network, username)
end)

RegisterNetEvent('orp-chat:server:socialPost', function(data)
    local src = source
    createSocialPost(src, tostring(data and data.network or 'x'), tostring(data and data.text or ''), data and data.isAd == true)
end)

RegisterNetEvent('orp-chat:server:requestSocial', function(network, openWindow)
    local src = source
    pushSocialSnapshot(src, tostring(network or 'x'), openWindow == true)
end)


RegisterNetEvent('orp-chat:server:socialAction', function(data)
    local src = source
    local network = tostring(data and data.network or 'x')
    local action = tostring(data and data.action or '')
    local postId = tostring(data and data.postId or '')
    local textValue = sanitizeMessage(data and data.text or '')

    local post, index, posts = findSocialPost(network, postId)
    if not post then
        sendSystem(src, 'That post no longer exists.')
        return
    end

    local playerKey = getPlayerKey(src)
    post.comments = post.comments or {}
    post.likedBy = post.likedBy or {}

    if action == 'like' then
        if post.likedBy[playerKey] then
            post.likedBy[playerKey] = nil
        else
            post.likedBy[playerKey] = true
        end
        local likes = 0
        for _ in pairs(post.likedBy) do likes = likes + 1 end
        post.likes = likes
        saveState()
        broadcastSocialUpdate(network)
        return
    elseif action == 'share' then
        post.shares = (tonumber(post.shares) or 0) + 1
        saveState()
        broadcastSocialUpdate(network)
        return
    elseif action == 'comment' then
        if textValue == '' then
            sendSystem(src, 'Comment cannot be empty.')
            return
        end
        table.insert(post.comments, {
            author = getPlayerNameBySource(src),
            username = (getSocialAccount(src, network) or {}).username or buildAuthor(src),
            sourceId = src,
            text = textValue,
            timestamp = os.date('%H:%M')
        })
        saveState()
        broadcastSocialUpdate(network)
        return
    elseif action == 'delete' then
        if post.ownerKey ~= playerKey and not isAdminByDiscord(src) then
            sendSystem(src, 'You can only delete your own posts.')
            return
        end
        table.remove(posts, index)
        saveState()
        broadcastSocialUpdate(network)
        return
    end
end)

RegisterNetEvent('orp-chat:server:requestReports', function(openWindow)
    local src = source
    pushReportsSnapshot(src, openWindow == true)
end)


RegisterNetEvent('orp-chat:server:requestHelp', function(openWindow)
    local src = source
    pushHelpSnapshot(src, openWindow == true)
end)

RegisterNetEvent('orp-chat:server:replyReport', function(data)
    local src = source
    appendReportReply(src, tonumber(data and data.reportId or 0), tostring(data and data.message or ''))
end)

RegisterNetEvent('orp-chat:server:playerAction', function(data)
    local src = source
    if not isChatModerator(src) then
        if getModerationLevel(src, false) <= 0 then refreshModerationRoles(src, true) end
        sendSystem(src, 'You are not allowed to use staff actions.')
        return
    end

    local action = tostring(data and data.action or '')
    local message = sanitizeMessage(data and data.message or '')
    local reason = sanitizeMessage(data and data.reason or '')

    if action == 'purge' then
        handleAdminCommand(src, 'purge', {})
        return
    elseif action == 'slowmode' then
        handleAdminCommand(src, 'slowmode', { tostring(tonumber(data and data.seconds or 10) or 10) })
        return
    elseif action == 'slowmodeOff' then
        handleAdminCommand(src, 'slowmode', { '0' })
        return
    elseif action == 'freeze' then
        handleAdminCommand(src, 'freezechat', {})
        return
    elseif action == 'unfreeze' then
        handleAdminCommand(src, 'unfreezechat', {})
        return
    elseif action == 'blocklastgif' then
        handleAdminCommand(src, 'blocklastgif', {})
        return
    end

    local target = resolveTarget(data and data.targetId)
    if not target then
        sendSystem(src, 'That player is no longer online.')
        return
    end

    if action == 'warn' then
        handleAdminCommand(src, 'warn', { tostring(target), reason })
    elseif action == 'timeout' then
        handleAdminCommand(src, 'timeout', { tostring(target), tostring(tonumber(data and data.minutes or 10) or 10), reason })
    elseif action == 'mute' then
        handleAdminCommand(src, 'mute', { tostring(target), reason })
    elseif action == 'unmute' then
        handleAdminCommand(src, 'unmute', { tostring(target) })
    elseif action == 'pm' then
        if message == '' then
            sendSystem(src, 'PM message cannot be empty.')
            return
        end
        sendPm(src, target, message)
    end
end)

RegisterNetEvent('orp-chat:server:updateFrameworkPlayerData', function(data)
    if type(data) ~= 'table' or not next(data) then
        Framework.ClearClientPlayerData(source)
        return
    end
    Framework.CacheClientPlayerData(source, data)
end)

RegisterNetEvent('orp-chat:server:requestClientPlayerData', function()
    local src = source
    TriggerClientEvent('orp-chat:client:setFrameworkPlayerData', src, Framework.GetPublicPlayerData(src))
end)

AddEventHandler('playerDropped', function()
    Framework.ClearClientPlayerData(source)
end)

local function registerCommand(name, help)
    Framework.RegisterCommand(name, help, function(source, args, raw)
        handleChatCommand(source, name, args or {}, raw)
    end)
end

registerCommand('say', 'Local chat message')
registerCommand('local', 'Local chat message')
registerCommand('l', 'Local chat message')
registerCommand('ooc', 'Global out of character chat')
registerCommand('me', 'Local emote text')
registerCommand('do', 'Local scene description')
registerCommand('x', 'Open X feed')
registerCommand('fb', 'Open Facebook feed')
registerCommand('report', 'Create a player report')
registerCommand('reports', 'Open report center')
registerCommand('help', 'Open command guide')
registerCommand('reply', 'Reply to a report')
registerCommand('announce', 'Server announcement')
registerCommand('countdown', 'Start a chat countdown')
registerCommand('clearchat', 'Clear your chat window')
registerCommand('clearallchat', 'Clear chat for everyone')
registerCommand('purge', 'Purge chat for everyone')
registerCommand('blocklastgif', 'Remove and block the last posted gif')
registerCommand('warn', 'Warn a player in chat')
registerCommand('timeout', 'Timeout a player from chat')
registerCommand('mute', 'Mute a player from chat')
registerCommand('untimeout', 'Remove a player chat timeout')
registerCommand('unmute', 'Unmute a player from chat')
registerCommand('slowmode', 'Set chat slowmode')
registerCommand('freezechat', 'Freeze public chat')
registerCommand('unfreezechat', 'Unfreeze public chat')
registerCommand('shadowmute', 'Toggle shadowmute on a player')
registerCommand('filterword', 'Manage blocked chat words')
