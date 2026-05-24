local Framework = AZChatFramework

local playerData = {}
local chatOpen = false
local socialOpen = false
local reportsOpen = false
local helpOpen = false
local adsOpen = false
local isAdmin = false
local canModerate = false
local moderationState = { moderationLevel = 0, label = 'user', slowmode = 0, frozen = false }
local resourceName = GetCurrentResourceName()
local visibilityMode = tonumber(GetResourceKvpString('orp_chat_visibility_mode')) or Config.Visibility.defaultMode or 1

local inputBlockActive = false
local previousOxInvBusy = nil
local setOxInvBusy = false

local defaultInputBlock = {
    enabled = true,
    enforceFocusEveryFrame = true,
    blockOxInventory = true,
    exposeStateBag = true,
    stateBagName = 'achatInputOpen',
    
    
    controls = {
        14, 15, 16, 17, 24, 25, 37, 45, 68, 69, 70, 75, 80, 81, 82, 83, 84, 85,
        86, 99, 106, 114, 140, 141, 142, 143, 157, 158, 159, 160, 161, 162, 163,
        164, 165, 166, 167, 168, 169, 170, 172, 173, 174, 175, 176, 177, 178, 199,
        200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 241, 242, 243, 244,
        245, 246, 249, 261, 262, 288, 289, 311, 344
    }
}

local function inputBlockConfig()
    local configured = Config.InputBlock
    if type(configured) ~= 'table' then return defaultInputBlock end
    for key, value in pairs(defaultInputBlock) do
        if configured[key] == nil then configured[key] = value end
    end
    return configured
end

local function setLocalState(name, value, replicated)
    if not LocalPlayer or not LocalPlayer.state or not LocalPlayer.state.set then return end
    LocalPlayer.state:set(name, value, replicated == true)
end

local function setInputBlockState(blocked)
    local blockConfig = inputBlockConfig()
    if blockConfig.enabled == false then return end
    if inputBlockActive == blocked then return end

    inputBlockActive = blocked

    if blockConfig.exposeStateBag ~= false then
        setLocalState(blockConfig.stateBagName or 'achatInputOpen', blocked, true)
    end

    
    
    if blockConfig.blockOxInventory ~= false and LocalPlayer and LocalPlayer.state then
        if blocked then
            previousOxInvBusy = LocalPlayer.state.invBusy == true
            setOxInvBusy = true
            setLocalState('invBusy', true, false)
        elseif setOxInvBusy then
            if not previousOxInvBusy then
                setLocalState('invBusy', false, false)
            end
            setOxInvBusy = false
            previousOxInvBusy = nil
        end
    end
end

local function blockControlsThisFrame()
    local blockConfig = inputBlockConfig()
    if blockConfig.enabled == false then return end

    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)
    DisableFrontendThisFrame()
    DisablePlayerFiring(PlayerId(), true)

    for _, control in ipairs(blockConfig.controls or defaultInputBlock.controls) do
        DisableControlAction(0, control, true)
        DisableControlAction(1, control, true)
        DisableControlAction(2, control, true)
    end

    if blockConfig.enforceFocusEveryFrame ~= false then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end
end

local function trim(value)
    if type(value) ~= 'string' then return '' end
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function getCharacterName()
    local charinfo = playerData.charinfo or {}
    local first = charinfo.firstname or ''
    local last = charinfo.lastname or ''
    local full = trim((first .. ' ' .. last))
    if full ~= '' then return full end
    return GetPlayerName(PlayerId()) or 'Citizen'
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

local function getJobDisplay()
    local job = playerData.job or {}
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

local function getModeLabel(mode)
    if mode == 1 then return 'ALWAYS' end
    if mode == 2 then return 'ACTIVE' end
    return 'DISABLED'
end

local function cleanCommandGuideName(name)
    name = tostring(name or ''):gsub('^/', ''):gsub('%s+', ''):lower()
    return name
end

local function isHiddenCommandGuideName(name)
    local guide = Config.CommandGuide or {}
    name = cleanCommandGuideName(name)
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

local function pushLocalCommandRegistry()
    local guide = Config.CommandGuide or {}
    if guide.Enabled == false or guide.AutoDetect == false then return end

    local ok, registeredCommands = pcall(GetRegisteredCommands)
    if not ok or type(registeredCommands) ~= 'table' then return end

    local items = {}
    local seen = {}
    local maxCommands = tonumber(guide.MaxAutoCommands) or 220

    for _, registered in ipairs(registeredCommands) do
        if #items >= maxCommands then break end

        local name = nil
        local resource = nil
        if type(registered) == 'table' then
            name = registered.name or registered.command or registered[1]
            resource = registered.resource or registered.resourceName or registered.owner or registered[2]
        elseif type(registered) == 'string' then
            name = registered
        end

        name = cleanCommandGuideName(name)
        if name ~= '' and not seen[name] and not isHiddenCommandGuideName(name) then
            seen[name] = true
            items[#items + 1] = {
                name = '/' .. name,
                command = name,
                help = 'Client command registered by a running resource.',
                link = '/' .. name,
                category = 'Client',
                resource = (guide.ShowResourceName == false) and '' or tostring(resource or ''),
                permission = 'user',
                source = 'client'
            }
        end
    end

    SendNUIMessage({ action = 'setCommandRegistry', payload = { items = items, merge = true } })
end

local function anyUiOpen()
    return chatOpen or socialOpen or reportsOpen or helpOpen or adsOpen
end

local function applyFocus()
    local focused = anyUiOpen()
    SetNuiFocus(focused, focused)
    SetNuiFocusKeepInput(false)
    setInputBlockState(focused)
end

local function pushIdentity()
    SendNUIMessage({
        action = 'setIdentity',
        identity = {
            player = getCharacterName(),
            playerId = GetPlayerServerId(PlayerId()),
            placeholder = Config.Chat.defaultPlaceholder,
            hint = 'TAB = LOCAL/OOC/ADS/ME • Enter = send • Esc = close • ; = visibility',
            theme = Config.Theme,
            layout = Config.Layout,
            job = getJobDisplay(),
            mode = getModeLabel(visibilityMode),
            integrations = {
                emoji = Config.Integrations.emoji,
                gifs = Config.Integrations.gifs
            },
            chatModes = Config.Chat.modes,
            isAdmin = isAdmin,
            canModerate = canModerate,
            moderation = moderationState
        }
    })

    SendNUIMessage({ action = 'setVisibilityMode', mode = visibilityMode })
end

local function addMessage(payload)
    SendNUIMessage({ action = 'addMessage', payload = payload })
end

local function showToast(text)
    SendNUIMessage({ action = 'stateToast', text = text })
end

local function canOpenChat()
    return visibilityMode ~= 3
end

local function openChat()
    if chatOpen or socialOpen or reportsOpen or helpOpen or adsOpen then return end
    if not canOpenChat() then
        showToast('Chat disabled • press ; to change mode')
        return
    end
    pushIdentity()
    TriggerServerEvent('orp-chat:server:requestCommandRegistry')
    pushLocalCommandRegistry()
    chatOpen = true
    applyFocus()
    SendNUIMessage({ action = 'open' })
end

local function closeChat()
    if not chatOpen then return end
    chatOpen = false
    applyFocus()
    SendNUIMessage({ action = 'close' })
end

local function setVisibilityMode(mode, announce)
    visibilityMode = mode
    SetResourceKvp('orp_chat_visibility_mode', tostring(mode))
    pushIdentity()

    if visibilityMode == 3 then
        closeChat()
    end

    if announce then
        showToast(('Chat visibility: %s'):format(getModeLabel(visibilityMode)))
    end
end

local function cycleVisibilityMode()
    local nextMode = visibilityMode + 1
    if nextMode > 3 then nextMode = 1 end
    setVisibilityMode(nextMode, true)
end

RegisterCommand('+achat_open', function()
    openChat()
end, false)

RegisterCommand('-achat_open', function() end, false)
RegisterKeyMapping('+achat_open', Config.Chat.openKeyDescription, 'keyboard', Config.Chat.openKeyDefault)

RegisterCommand('achat_cycle', function()
    cycleVisibilityMode()
end, false)
RegisterCommand('chatvis', function()
    cycleVisibilityMode()
end, false)
RegisterKeyMapping('achat_cycle', Config.Visibility.cycleKeyDescription, 'keyboard', Config.Visibility.cycleKeyDefault)
RegisterKeyMapping('chatvis', 'Cycle chat visibility (semicolon alt)', 'keyboard', 'OEM_1')

exports('IsChatInputOpen', function()
    return anyUiOpen()
end)


RegisterNUICallback('close', function(_, cb)
    closeChat()
    cb('ok')
end)

RegisterNUICallback('submit', function(data, cb)
    local text = trim(data.text or '')
    local gifUrl = trim(data.gifUrl or '')
    closeChat()

    if text == '' and gifUrl == '' then
        cb('ok')
        return
    end

    if text:sub(1, 1) == '/' and gifUrl == '' then
        local raw = trim(text:sub(2))
        if raw ~= '' then
            ExecuteCommand(raw)
        end
        cb('ok')
        return
    end

    if Framework.PushPlayerDataToServer then
        Framework.PushPlayerDataToServer()
    end

    TriggerServerEvent('orp-chat:server:submitPayload', {
        text = text,
        gifUrl = gifUrl,
        mode = trim(data.mode or 'l')
    })
    cb('ok')
end)

RegisterNUICallback('searchGif', function(data, cb)
    TriggerServerEvent('orp-chat:server:searchGif', trim(data.query or ''))
    cb('ok')
end)

RegisterNUICallback('adsClose', function(_, cb)
    adsOpen = false
    applyFocus()
    cb('ok')
end)

RegisterNUICallback('requestAds', function(data, cb)
    TriggerServerEvent('orp-chat:server:requestAds', data and data.openWindow == true)
    cb('ok')
end)

RegisterNUICallback('postAd', function(data, cb)
    TriggerServerEvent('orp-chat:server:postAd', data or {})
    cb('ok')
end)

RegisterNUICallback('updateAdProfile', function(data, cb)
    TriggerServerEvent('orp-chat:server:updateAdProfile', data or {})
    cb('ok')
end)

RegisterNUICallback('socialClose', function(_, cb)
    socialOpen = false
    applyFocus()
    cb('ok')
end)

RegisterNUICallback('requestSocial', function(data, cb)
    TriggerServerEvent('orp-chat:server:requestSocial', data and data.network or 'x', data and data.openWindow == true)
    cb('ok')
end)

RegisterNUICallback('socialSignup', function(data, cb)
    TriggerServerEvent('orp-chat:server:socialSignup', data or {})
    cb('ok')
end)

RegisterNUICallback('socialPost', function(data, cb)
    TriggerServerEvent('orp-chat:server:socialPost', data or {})
    cb('ok')
end)

RegisterNUICallback('socialAction', function(data, cb)
    TriggerServerEvent('orp-chat:server:socialAction', data or {})
    cb('ok')
end)

RegisterNUICallback('requestReports', function(data, cb)
    TriggerServerEvent('orp-chat:server:requestReports', data and data.openWindow == true)
    cb('ok')
end)

RegisterNUICallback('requestHelp', function(data, cb)
    TriggerServerEvent('orp-chat:server:requestHelp', data and data.openWindow == true)
    cb('ok')
end)

RegisterNUICallback('helpClose', function(_, cb)
    helpOpen = false
    applyFocus()
    cb('ok')
end)

RegisterNUICallback('reportsClose', function(_, cb)
    reportsOpen = false
    applyFocus()
    cb('ok')
end)

RegisterNUICallback('replyReport', function(data, cb)
    TriggerServerEvent('orp-chat:server:replyReport', data or {})
    cb('ok')
end)

RegisterNUICallback('playerAction', function(data, cb)
    TriggerServerEvent('orp-chat:server:playerAction', data or {})
    cb('ok')
end)

RegisterNUICallback('ready', function(_, cb)
    pushIdentity()
    TriggerServerEvent('orp-chat:server:requestAdminState')
    TriggerServerEvent('orp-chat:server:requestCommandRegistry')
    pushLocalCommandRegistry()
    cb('ok')
end)

RegisterNetEvent('orp-chat:client:addMessage', function(payload)
    addMessage(payload)
end)

RegisterNetEvent('orp-chat:client:clear', function()
    SendNUIMessage({ action = 'clear' })
end)

RegisterNetEvent('orp-chat:client:gifResults', function(results)
    SendNUIMessage({ action = 'gifResults', results = results or {} })
end)

RegisterNetEvent('orp-chat:client:setAdminState', function(state)
    if type(state) == 'table' then
        isAdmin = state.isAdmin == true
        canModerate = state.canModerate == true or isAdmin
        moderationState = state
    else
        isAdmin = state == true
        canModerate = isAdmin
        moderationState = { moderationLevel = isAdmin and 2 or 0, label = isAdmin and 'admin' or 'user' }
    end
    pushIdentity()
    SendNUIMessage({ action = 'setAdminState', state = moderationState })
end)

RegisterNetEvent('orp-chat:client:removeMessage', function(messageId)
    SendNUIMessage({ action = 'removeMessage', messageId = messageId })
end)

RegisterNetEvent('orp-chat:client:moderationNotice', function(payload)
    SendNUIMessage({ action = 'moderationNotice', payload = payload or {} })
end)

RegisterNetEvent('orp-chat:client:proximityMessage', function(sourceId, payload, distance)
    if visibilityMode == 3 then return end

    local myServerId = GetPlayerServerId(PlayerId())
    if sourceId == myServerId then
        addMessage(payload)
        return
    end

    local targetPlayer = GetPlayerFromServerId(sourceId)
    if targetPlayer == -1 then return end

    local myPed = PlayerPedId()
    local targetPed = GetPlayerPed(targetPlayer)
    if myPed == 0 or targetPed == 0 then return end

    local myCoords = GetEntityCoords(myPed)
    local targetCoords = GetEntityCoords(targetPed)
    local dist = #(myCoords - targetCoords)

    if dist <= (distance or Config.Chat.localDistance) then
        addMessage(payload)
    end
end)

RegisterNetEvent('orp-chat:client:setAdsData', function(snapshot, openWindow)
    if openWindow then
        adsOpen = true
        socialOpen = false
        reportsOpen = false
        helpOpen = false
    end
    applyFocus()
    SendNUIMessage({ action = openWindow and 'openAds' or 'setAdsData', payload = snapshot or {} })
end)

RegisterNetEvent('orp-chat:client:setSocialData', function(snapshot, openWindow)
    if openWindow then
        socialOpen = true
        reportsOpen = false
        adsOpen = false
        helpOpen = false
    end
    applyFocus()
    SendNUIMessage({ action = openWindow and 'openSocial' or 'setSocialData', payload = snapshot or {} })
end)

RegisterNetEvent('orp-chat:client:setReportsData', function(snapshot, openWindow)
    if openWindow then
        reportsOpen = true
        socialOpen = false
        adsOpen = false
        helpOpen = false
    end
    applyFocus()
    SendNUIMessage({ action = openWindow and 'openReports' or 'setReportsData', payload = snapshot or {} })
end)


RegisterNetEvent('orp-chat:client:setHelpData', function(snapshot, openWindow)
    if openWindow then
        helpOpen = true
        socialOpen = false
        reportsOpen = false
        adsOpen = false
    end
    applyFocus()
    SendNUIMessage({ action = openWindow and 'openHelp' or 'setHelpData', payload = snapshot or {} })
    if snapshot and snapshot.commandCatalog then
        SendNUIMessage({ action = 'setCommandRegistry', payload = { items = snapshot.commandCatalog, count = snapshot.commandCount or 0, merge = true } })
    end
end)

RegisterNetEvent('orp-chat:client:setCommandRegistry', function(snapshot)
    snapshot = snapshot or {}
    SendNUIMessage({ action = 'setCommandRegistry', payload = { items = snapshot.items or {}, count = snapshot.count or 0, merge = true } })
end)

CreateThread(function()
    while true do
        Wait(0)
        DisableControlAction(0, 245, true)
        DisableControlAction(1, 245, true)
        DisableControlAction(2, 245, true)
        DisableMultiplayerChat(true)

        if anyUiOpen() then
            blockControlsThisFrame()
        else
            setInputBlockState(false)
            if not IsPauseMenuActive() and IsDisabledControlJustPressed(0, 245) then
                openChat()
            end
        end
    end
end)

CreateThread(function()
    Wait(0)
    SetTextChatEnabled(false)
    DisableMultiplayerChat(true)
    SetNuiFocusKeepInput(false)
    pushIdentity()
end)

AddEventHandler('onClientResourceStop', function(stoppedResource)
    if stoppedResource ~= resourceName then return end
    chatOpen = false
    socialOpen = false
    reportsOpen = false
    helpOpen = false
    adsOpen = false
    setInputBlockState(false)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SetTextChatEnabled(true)
    DisableMultiplayerChat(false)
end)

local function refreshFrameworkPlayerData()
    playerData = Framework.GetPlayerData() or {}
    if Framework.PushPlayerDataToServer then
        Framework.PushPlayerDataToServer()
    end
    pushIdentity()
    TriggerServerEvent('orp-chat:server:requestAdminState')
    Framework.RequestPlayerData()
end

Framework.RegisterPlayerDataHandlers(function(data)
    playerData = data or Framework.GetPlayerData() or {}
    pushIdentity()
    TriggerServerEvent('orp-chat:server:requestAdminState')
end, function()
    playerData = {}
    pushIdentity()
    closeChat()
end)

CreateThread(function()
    Wait(1000)
    refreshFrameworkPlayerData()
end)

AddEventHandler('onClientResourceStart', function(startedResource)
    if startedResource ~= resourceName then return end
    Wait(500)
    refreshFrameworkPlayerData()
end)
