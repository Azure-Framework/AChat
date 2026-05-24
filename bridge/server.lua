AZChatFramework = AZChatFramework or {}

local Framework = AZChatFramework
local currentFramework = nil
local currentResource = nil
local coreObject = nil
local clientDataCache = {}

local resourceAliases = {
    ['auto'] = 'auto',
    ['qbx'] = 'qbx_core',
    ['qbox'] = 'qbx_core',
    ['qbx-core'] = 'qbx_core',
    ['qbx_core'] = 'qbx_core',
    ['qb'] = 'qb-core',
    ['qb-core'] = 'qb-core',
    ['qbcore'] = 'qb-core',
    ['esx'] = 'es_extended',
    ['es_extended'] = 'es_extended',
    ['nd'] = 'ND_Core',
    ['ndcore'] = 'ND_Core',
    ['nd-core'] = 'ND_Core',
    ['NDCore'] = 'ND_Core',
    ['ND_Core'] = 'ND_Core',
    ['standalone'] = 'standalone'
}

local displayNames = {
    ['qbx_core'] = 'QBX Core',
    ['qb-core'] = 'QB-Core',
    ['es_extended'] = 'ESX',
    ['ND_Core'] = 'NDCore',
    ['standalone'] = 'Standalone'
}

local function trim(value)
    if type(value) ~= 'string' then return '' end
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function cleanNamePart(value)
    value = trim(tostring(value or ''))
    local lower = value:lower()
    if lower == 'firstname' or lower == 'lastname' or lower == 'unknown' or lower == 'nil' then return '' end
    return value
end

local function resourceIsReady(name)
    if not name or name == '' or name == 'standalone' then return false end
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function normalizeName(name)
    name = tostring(name or 'auto')
    return resourceAliases[name] or resourceAliases[name:lower()] or name
end

local function configuredFramework()
    local cfg = Config.Framework or {}
    return normalizeName(cfg.name or cfg.Name or cfg.framework or cfg.Framework or 'auto')
end

local function detectionOrder()
    local cfg = Config.Framework or {}
    local order = cfg.detectionOrder or cfg.DetectionOrder or cfg.priority or cfg.Priority
    if type(order) ~= 'table' then
        order = { 'qbx_core', 'qb-core', 'es_extended', 'ND_Core' }
    end
    local mapped = {}
    for _, name in ipairs(order) do
        mapped[#mapped + 1] = normalizeName(name)
    end
    return mapped
end

local function tryGetCore(resource)
    if resource == 'qb-core' then
        local ok, obj = pcall(function()
            return exports['qb-core']:GetCoreObject({ 'Functions', 'Commands', 'Shared' })
        end)
        if ok and obj then return obj end
        ok, obj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok and obj then return obj end
    elseif resource == 'es_extended' then
        local ok, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok and obj then return obj end
        local obj = nil
        pcall(function()
            TriggerEvent('esx:getSharedObject', function(shared)
                obj = shared
            end)
        end)
        if obj then return obj end
    elseif resource == 'ND_Core' then
        local ok, obj = pcall(function()
            return exports['ND_Core']
        end)
        if ok and obj then return obj end
    elseif resource == 'qbx_core' then
        local ok, obj = pcall(function()
            return exports.qbx_core
        end)
        if ok and obj then return obj end
    end
    return nil
end

function Framework.Detect(refresh)
    if currentFramework and not refresh then
        if currentFramework == 'standalone' then
            refresh = true
        elseif currentResource and not resourceIsReady(currentResource) then
            refresh = true
        else
            return currentFramework, currentResource, coreObject
        end
    end
    local wanted = configuredFramework()
    if wanted ~= 'auto' and wanted ~= 'standalone' then
        if resourceIsReady(wanted) then
            currentFramework = wanted
            currentResource = wanted
            coreObject = tryGetCore(wanted)
            return currentFramework, currentResource, coreObject
        end
    elseif wanted == 'standalone' then
        currentFramework = 'standalone'
        currentResource = 'standalone'
        coreObject = nil
        return currentFramework, currentResource, coreObject
    end
    for _, resource in ipairs(detectionOrder()) do
        if resourceIsReady(resource) then
            currentFramework = resource
            currentResource = resource
            coreObject = tryGetCore(resource)
            return currentFramework, currentResource, coreObject
        end
    end
    currentFramework = 'standalone'
    currentResource = 'standalone'
    coreObject = nil
    return currentFramework, currentResource, coreObject
end

function Framework.GetFramework()
    return Framework.Detect(false)
end

function Framework.GetFrameworkName()
    local name = Framework.Detect(false)
    return name
end

function Framework.GetFrameworkLabel()
    local name = Framework.Detect(false)
    return displayNames[name] or tostring(name or 'Standalone')
end

local function callMethod(target, method, ...)
    if not target or not method then return nil end
    local fn = target[method]
    if type(fn) ~= 'function' then return nil end
    local ok, result = pcall(fn, target, ...)
    if ok then return result end
    ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function normalizeJob(job, fallbackName, fallbackLabel)
    job = type(job) == 'table' and job or {}
    local grade = job.grade
    local gradeLabel = nil
    if type(grade) == 'table' then gradeLabel = grade.name or grade.label end
    local name = job.name or job.id or job.job or fallbackName or 'unemployed'
    local label = job.label or job.displayName or job.grade_label or gradeLabel or fallbackLabel or name or 'Civilian'
    local onDuty = job.onduty
    if onDuty == nil then onDuty = job.onDuty end
    if onDuty == nil then onDuty = job.duty end
    if onDuty == nil then onDuty = name ~= 'unemployed' and name ~= 'none' end
    return {
        name = tostring(name or 'unemployed'),
        label = tostring(label or 'Civilian'),
        type = job.type or job.category or job.name or fallbackName or '',
        onduty = onDuty == true,
        grade = type(grade) == 'table' and grade or { level = tonumber(grade) or 0 }
    }
end

local function makeCharinfo(data)
    data = type(data) == 'table' and data or {}
    local charinfo = type(data.charinfo) == 'table' and data.charinfo or type(data.charInfo) == 'table' and data.charInfo or type(data.character) == 'table' and data.character or type(data.char) == 'table' and data.char or {}
    local first = cleanNamePart(charinfo.firstname or charinfo.firstName or charinfo.first_name or charinfo.first or data.firstname or data.firstName or data.first_name or data.first)
    local last = cleanNamePart(charinfo.lastname or charinfo.lastName or charinfo.last_name or charinfo.last or data.lastname or data.lastName or data.last_name or data.last)
    local displayName = trim(tostring(data.fullname or data.fullName or data.name or ''))
    if first == '' and last == '' and displayName ~= '' then
        local splitFirst, splitLast = displayName:match('^(%S+)%s+(.+)$')
        first = cleanNamePart(splitFirst or displayName)
        last = cleanNamePart(splitLast or '')
    end
    return {
        firstname = first,
        lastname = last
    }
end

local function normalizePlayerData(src, player)
    local framework = Framework.Detect(false)
    if type(player) ~= 'table' then return nil end
    local data = player.PlayerData or player
    if type(data) ~= 'table' then return nil end
    if framework == 'es_extended' and not player.PlayerData then
        local job = player.job or callMethod(player, 'getJob') or {}
        local first = player.firstName or player.firstname or player.first_name or callMethod(player, 'get', 'firstName') or callMethod(player, 'get', 'firstname') or ''
        local last = player.lastName or player.lastname or player.last_name or callMethod(player, 'get', 'lastName') or callMethod(player, 'get', 'lastname') or ''
        local displayName = player.name or callMethod(player, 'getName') or GetPlayerName(src) or ''
        local charinfo = makeCharinfo({ firstname = first, lastname = last, name = displayName })
        return {
            source = src,
            identifier = player.identifier or player.license,
            citizenid = player.identifier or player.license,
            license = player.license,
            name = displayName,
            charinfo = charinfo,
            job = normalizeJob(job)
        }
    end
    if framework == 'ND_Core' and not player.PlayerData then
        local groups = type(player.groups) == 'table' and player.groups or type(player.job) == 'table' and player.job or {}
        local groupName = player.jobName or player.job or player.group or player.department
        local groupGrade = nil
        if type(groupName) == 'table' then
            groupGrade = groupName.grade or groupName.rank
            groupName = groupName.name or groupName.id or groupName[1]
        end
        if not groupName and next(groups) then
            for key, value in pairs(groups) do
                groupName = key
                groupGrade = value
                break
            end
        end
        local label = player.jobLabel or player.groupLabel or groupName or 'Civilian'
        return {
            source = src,
            identifier = player.id or player.characterId or player.charid or player.identifier or player.license,
            citizenid = player.id or player.characterId or player.charid or player.identifier or player.license,
            license = player.license,
            name = player.fullname or player.name or trim(((player.firstname or player.firstName or '') .. ' ' .. (player.lastname or player.lastName or ''))),
            charinfo = makeCharinfo(player),
            job = normalizeJob({ name = groupName, label = label, grade = groupGrade, onduty = true })
        }
    end
    data.source = data.source or src
    data.identifier = data.identifier or data.citizenid or data.license
    data.citizenid = data.citizenid or data.identifier or data.license
    data.charinfo = makeCharinfo(data)
    data.job = normalizeJob(data.job or {})
    return data
end

local function qbxGetPlayer(src)
    if not resourceIsReady('qbx_core') then return nil end
    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(src)
    end)
    if ok and type(player) == 'table' then return player end
    ok, player = pcall(function()
        return exports['qbx_core']:GetPlayer(src)
    end)
    if ok and type(player) == 'table' then return player end
    ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(tostring(src))
    end)
    if ok and type(player) == 'table' then return player end
    local players = nil
    ok, players = pcall(function()
        return exports.qbx_core:GetQBPlayers()
    end)
    if ok and type(players) == 'table' then
        return players[src] or players[tostring(src)]
    end
    return nil
end

local function qbxGetPlayerData(src)
    local player = qbxGetPlayer(src)
    if type(player) == 'table' and type(player.PlayerData) == 'table' then return player.PlayerData end
    local ok, data = pcall(function()
        return exports.qbx_core:GetPlayersData()
    end)
    if ok and type(data) == 'table' then
        for _, item in pairs(data) do
            if type(item) == 'table' and tonumber(item.source) == tonumber(src) then return item end
        end
    end
    return nil
end

function Framework.GetPlayer(src)
    local name, _, core = Framework.Detect(false)
    src = tonumber(src)
    if not src then return nil end
    if name == 'qbx_core' then
        return qbxGetPlayer(src)
    elseif name == 'qb-core' then
        if core and core.Functions and core.Functions.GetPlayer then
            local ok, player = pcall(function()
                return core.Functions.GetPlayer(src)
            end)
            if ok and player then return player end
        end
    elseif name == 'es_extended' then
        if core and core.GetPlayerFromId then
            local ok, player = pcall(function()
                return core.GetPlayerFromId(src)
            end)
            if ok and player then return player end
        end
    elseif name == 'ND_Core' then
        local ok, player = pcall(function()
            return exports['ND_Core']:getPlayer(src)
        end)
        if ok and player then return player end
    end
    return nil
end

local function sanitizeClientData(src, data)
    if type(data) ~= 'table' then return nil end
    local clean = {
        source = tonumber(src),
        citizenid = data.citizenid or data.identifier or data.license,
        identifier = data.identifier or data.citizenid or data.license,
        license = data.license,
        name = trim(tostring(data.name or data.fullname or data.fullName or '')),
        charinfo = makeCharinfo(data),
        job = normalizeJob(data.job or {})
    }
    if clean.name:len() > 64 then clean.name = clean.name:sub(1, 64) end
    if clean.charinfo.firstname:len() > 32 then clean.charinfo.firstname = clean.charinfo.firstname:sub(1, 32) end
    if clean.charinfo.lastname:len() > 32 then clean.charinfo.lastname = clean.charinfo.lastname:sub(1, 32) end
    return clean
end

function Framework.CacheClientPlayerData(src, data)
    src = tonumber(src)
    if not src then return end
    local clean = sanitizeClientData(src, data)
    if clean then clientDataCache[src] = clean end
end

function Framework.ClearClientPlayerData(src)
    src = tonumber(src)
    if not src then return end
    clientDataCache[src] = nil
end

function Framework.GetPlayerData(src)
    src = tonumber(src)
    if not src then return nil end
    local framework = Framework.Detect(false)
    if framework == 'qbx_core' then
        local data = normalizePlayerData(src, qbxGetPlayerData(src))
        if data then return data end
    end
    local player = Framework.GetPlayer(src)
    local data = normalizePlayerData(src, player)
    if data then return data end
    return clientDataCache[src]
end

function Framework.GetPublicPlayerData(src)
    local data = Framework.GetPlayerData(src) or {}
    return {
        citizenid = data.citizenid or data.identifier or data.license,
        identifier = data.identifier or data.citizenid or data.license,
        charinfo = data.charinfo or makeCharinfo(data),
        name = data.name,
        job = normalizeJob(data.job or {})
    }
end

function Framework.GetIdentifier(src)
    local data = Framework.GetPlayerData(src) or {}
    local value = data.citizenid or data.identifier or data.license or data.ssn or data.id
    if value and tostring(value) ~= '' then return tostring(value) end
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'license:' then return identifier end
    end
    return ('src:%s'):format(src)
end

function Framework.GetName(src)
    local data = Framework.GetPlayerData(src) or {}
    local charinfo = data.charinfo or makeCharinfo(data)
    local first = cleanNamePart(charinfo.firstname or data.firstname or data.firstName or '')
    local last = cleanNamePart(charinfo.lastname or data.lastname or data.lastName or '')
    local full = trim((tostring(first or '') .. ' ' .. tostring(last or '')))
    if full ~= '' then return full end
    if data.name and trim(tostring(data.name)) ~= '' then return trim(tostring(data.name)) end
    return GetPlayerName(src) or ('Player ' .. tostring(src))
end

function Framework.GetJob(src)
    local data = Framework.GetPlayerData(src) or {}
    return normalizeJob(data.job or {})
end

local permissionRank = {
    user = 0,
    player = 0,
    citizen = 0,
    mod = 1,
    moderator = 1,
    admin = 2,
    god = 3,
    superadmin = 3,
    owner = 4
}

local function permissionAllows(current, required)
    current = tostring(current or 'user'):lower()
    required = tostring(required or 'user'):lower()
    return (permissionRank[current] or 0) >= (permissionRank[required] or 0)
end

function Framework.HasPermission(src, permission)
    permission = tostring(permission or ''):lower()
    if permission == '' or permission == 'user' or permission == 'all' or permission == 'player' or permission == 'citizen' then return true end
    if src == 0 then return true end
    if IsPlayerAceAllowed(src, permission) or IsPlayerAceAllowed(src, 'group.' .. permission) or IsPlayerAceAllowed(src, 'achat.' .. permission) then return true end
    local name, _, core = Framework.Detect(false)
    if name == 'qbx_core' then
        local ok, allowed = pcall(function()
            return exports.qbx_core:HasPermission(src, permission)
        end)
        if ok and allowed == true then return true end
        ok, allowed = pcall(function()
            return exports.qbx_core:HasGroup(src, permission)
        end)
        if ok and allowed == true then return true end
    elseif name == 'qb-core' then
        if core and core.Functions and core.Functions.HasPermission then
            local ok, allowed = pcall(function()
                return core.Functions.HasPermission(src, permission)
            end)
            if ok and allowed == true then return true end
        end
    elseif name == 'es_extended' then
        local player = Framework.GetPlayer(src)
        local group = player and (callMethod(player, 'getGroup') or player.group)
        if permissionAllows(group, permission) then return true end
    elseif name == 'ND_Core' then
        local player = Framework.GetPlayer(src)
        if player and type(player.groups) == 'table' then
            if player.groups[permission] then return true end
            for groupName in pairs(player.groups) do
                if tostring(groupName):lower() == permission then return true end
            end
        end
    end
    return false
end

function Framework.GetCommandMeta(name)
    name = tostring(name or ''):gsub('^/', ''):lower()
    local framework, _, core = Framework.Detect(false)
    if framework == 'qb-core' and core and core.Commands and type(core.Commands.List) == 'table' then
        return core.Commands.List[name] or core.Commands.List[string.lower(name)]
    end
    if framework == 'es_extended' and core and type(core.RegisteredCommands) == 'table' then
        return core.RegisteredCommands[name] or core.RegisteredCommands[string.lower(name)]
    end
    return nil
end

function Framework.GetCommandList()
    local framework, _, core = Framework.Detect(false)
    if framework == 'qbx_core' then
        return nil, 'QBX Core'
    end
    if framework == 'qb-core' and core and core.Commands and type(core.Commands.List) == 'table' then
        return core.Commands.List, 'QB-Core'
    end
    if framework == 'es_extended' and core and type(core.RegisteredCommands) == 'table' then
        return core.RegisteredCommands, 'ESX'
    end
    return nil, Framework.GetFrameworkLabel()
end

function Framework.RegisterCommand(name, help, handler)
    name = tostring(name or ''):gsub('^/', ''):lower()
    if name == '' then return end
    local framework, _, core = Framework.Detect(false)
    if framework == 'qbx_core' and type(lib) == 'table' and type(lib.addCommand) == 'function' then
        lib.addCommand(name, { help = help or name }, function(source, args, raw)
            handler(source, args or {}, raw)
        end)
        return
    end
    if framework == 'qb-core' and core and core.Commands and core.Commands.Add then
        core.Commands.Add(name, help or name, {}, false, function(source, args, raw)
            handler(source, args or {}, raw)
        end, 'user')
        return
    end
    RegisterCommand(name, function(source, args, raw)
        handler(source, args or {}, raw)
    end, false)
end

Framework.Detect(true)

local function isFrameworkResource(resource)
    resource = tostring(resource or '')
    return resource == 'qbx_core' or resource == 'qb-core' or resource == 'es_extended' or resource == 'ND_Core'
end

AddEventHandler('onResourceStart', function(resource)
    if isFrameworkResource(resource) then
        Framework.Detect(true)
    end
end)
