AZChatFramework = AZChatFramework or {}

local Framework = AZChatFramework
local currentFramework = nil
local currentResource = nil
local coreObject = nil
local cachedPlayerData = {}
local loadedCallback = nil
local unloadedCallback = nil

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
            return exports['qb-core']:GetCoreObject({ 'Functions' })
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

function Framework.GetFrameworkName()
    local name = Framework.Detect(false)
    return name
end

function Framework.GetFrameworkLabel()
    local name = Framework.Detect(false)
    return displayNames[name] or tostring(name or 'Standalone')
end

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

local function qbxGetPlayerData()
    if not resourceIsReady('qbx_core') then return nil end
    local ok, data = pcall(function()
        return exports.qbx_core:GetPlayerData()
    end)
    if ok and type(data) == 'table' then return data end
    ok, data = pcall(function()
        return exports['qbx_core']:GetPlayerData()
    end)
    if ok and type(data) == 'table' then return data end
    if type(QBX) == 'table' and type(QBX.PlayerData) == 'table' then return QBX.PlayerData end
    return nil
end

local function normalizePlayerData(data)
    local framework = Framework.Detect(false)
    if type(data) ~= 'table' then return {} end
    if data.PlayerData then data = data.PlayerData end
    if framework == 'es_extended' then
        local job = data.job or {}
        return {
            citizenid = data.identifier or data.license,
            identifier = data.identifier or data.license,
            license = data.license,
            name = data.name or '',
            charinfo = makeCharinfo(data),
            job = normalizeJob(job)
        }
    elseif framework == 'ND_Core' then
        local groupName = data.jobName or data.job or data.group or data.department
        if type(groupName) == 'table' then groupName = groupName.name or groupName.id or groupName[1] end
        local label = data.jobLabel or data.groupLabel or groupName or 'Civilian'
        return {
            citizenid = data.id or data.characterId or data.charid or data.identifier or data.license,
            identifier = data.identifier or data.id or data.characterId or data.charid or data.license,
            license = data.license,
            name = data.fullname or data.name or trim(((data.firstname or data.firstName or '') .. ' ' .. (data.lastname or data.lastName or ''))),
            charinfo = makeCharinfo(data),
            job = normalizeJob({ name = groupName, label = label, onduty = true })
        }
    end
    data.job = normalizeJob(data.job or {})
    data.charinfo = makeCharinfo(data)
    data.identifier = data.identifier or data.citizenid or data.license
    data.citizenid = data.citizenid or data.identifier or data.license
    return data
end

function Framework.GetPlayerData()
    local framework, _, core = Framework.Detect(false)
    local data = nil
    if framework == 'qbx_core' then
        data = qbxGetPlayerData() or cachedPlayerData
    elseif framework == 'qb-core' then
        if core and core.Functions and core.Functions.GetPlayerData then
            local ok, result = pcall(function()
                return core.Functions.GetPlayerData()
            end)
            if ok then data = result end
        end
        if type(data) ~= 'table' then
            local ok, result = pcall(function()
                return exports['qb-core']:GetPlayerData()
            end)
            if ok then data = result end
        end
    elseif framework == 'es_extended' then
        data = core and core.PlayerData or ESX and ESX.PlayerData or cachedPlayerData
    elseif framework == 'ND_Core' then
        local ok, result = pcall(function()
            return exports['ND_Core']:getPlayer()
        end)
        if ok then data = result end
        if type(data) ~= 'table' then data = cachedPlayerData end
    else
        data = cachedPlayerData
    end
    data = normalizePlayerData(data or cachedPlayerData or {})
    cachedPlayerData = data
    return data
end

function Framework.PushPlayerDataToServer()
    local data = cachedPlayerData
    if type(data) ~= 'table' or not next(data) then data = Framework.GetPlayerData() end
    TriggerServerEvent('orp-chat:server:updateFrameworkPlayerData', data or {})
end

local function loaded(data)
    cachedPlayerData = normalizePlayerData(data or Framework.GetPlayerData() or {})
    Framework.PushPlayerDataToServer()
    if loadedCallback then loadedCallback(cachedPlayerData) end
end

local function unloaded()
    cachedPlayerData = {}
    TriggerServerEvent('orp-chat:server:updateFrameworkPlayerData', {})
    if unloadedCallback then unloadedCallback() end
end

function Framework.RequestPlayerData()
    Framework.PushPlayerDataToServer()
    TriggerServerEvent('orp-chat:server:requestClientPlayerData')
end

RegisterNetEvent('orp-chat:client:setFrameworkPlayerData', function(data)
    loaded(data or {})
end)

function Framework.RegisterPlayerDataHandlers(onLoaded, onUnloaded)
    loadedCallback = onLoaded
    unloadedCallback = onUnloaded
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        SetTimeout(250, function()
            Framework.RequestPlayerData()
            loaded(Framework.GetPlayerData())
        end)
    end)
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        unloaded()
    end)
    RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
        loaded(data)
    end)
    RegisterNetEvent('QBCore:Client:SetPlayerData', function(data)
        loaded(data)
    end)
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        local data = Framework.GetPlayerData() or {}
        data.job = normalizeJob(job or {})
        loaded(data)
    end)
    RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
        local data = Framework.GetPlayerData() or {}
        data.job = data.job or {}
        data.job.onduty = onDuty == true
        loaded(data)
    end)
    RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
        unloaded()
    end)
    RegisterNetEvent('qbx_core:client:onGroupUpdate', function()
        SetTimeout(250, function()
            Framework.RequestPlayerData()
            loaded(Framework.GetPlayerData())
        end)
    end)
    RegisterNetEvent('qbx_core:client:onPlayerDataChanged', function(key, value)
        local data = Framework.GetPlayerData() or {}
        data[key] = value
        loaded(data)
    end)
    RegisterNetEvent('esx:playerLoaded', function(data)
        loaded(data)
    end)
    RegisterNetEvent('esx:onPlayerLogout', function()
        unloaded()
    end)
    RegisterNetEvent('esx:setJob', function(job)
        local data = Framework.GetPlayerData() or {}
        data.job = normalizeJob(job or {})
        loaded(data)
    end)
    AddEventHandler('ND:characterLoaded', function(character)
        loaded(character)
    end)
    AddEventHandler('ND:updateCharacter', function(character)
        loaded(character)
    end)
    AddEventHandler('ND:characterUnloaded', function()
        unloaded()
    end)
end

Framework.Detect(true)

local function isFrameworkResource(resource)
    resource = tostring(resource or '')
    return resource == 'qbx_core' or resource == 'qb-core' or resource == 'es_extended' or resource == 'ND_Core'
end

AddEventHandler('onClientResourceStart', function(resource)
    if isFrameworkResource(resource) then
        Framework.Detect(true)
        SetTimeout(750, function()
            Framework.RequestPlayerData()
        end)
    end
end)
