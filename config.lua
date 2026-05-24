Config = {}

Config.Framework = {
    name = 'auto',
    detectionOrder = { 'qbx_core', 'qb-core', 'es_extended', 'ND_Core' }
}

Config.Theme = {
    resourceName = 'AChat',
    primary = '#b8c0cc',
    primarySoft = 'rgba(163, 170, 182, 0.14)',
    secondary = '#e5e7eb',
    background = 'rgba(7, 9, 12, 0.46)',
    surface = 'rgba(14, 16, 20, 0.60)',
    border = 'rgba(180, 186, 195, 0.20)',
    text = '#f3f4f6',
    muted = 'rgba(209, 213, 219, 0.74)'
}

Config.Layout = {
    width = 520,
    top = 24,
    left = 24,
    maxMessages = 120,
    messageLifetime = 18000
}

Config.Chat = {
    openKeyDescription = 'Open smoke chat',
    openKeyDefault = 't',
    localDistance = 20.0,
    maxLength = 320,
    showPlayerId = true,
    defaultPlaceholder = 'Type your message... TAB switches the left chat status, not the input.',
    modes = {
        { command = 'l', label = 'LOCAL', placeholder = 'Local chat nearby players...' },
        { command = 'ooc', label = 'OOC', placeholder = 'Out of character chat to everyone...' },
        { command = 'ad', label = 'ADS', placeholder = 'Post a city ad using your ad profile...' },
        { command = 'me', label = 'ME', placeholder = 'Roleplay action, example: smiles...' }
    }
}

Config.Commands = {
    ooc = true,
    ad = true,
    ads = true,
    adname = true,
    adbanner = true,
    adbg = true,
    adcolor = true,
    adstyle = true,
    chatstyle = true,
    countdown = true,
    purge = true,
    slowmode = true,
    timeout = true,
    mute = true,
    unmute = true,
    warn = true,
    blocklastgif = true,
    freezechat = true,
    unfreezechat = true,
    shadowmute = true,
    filterword = true,
    me = true,
    ['do'] = true,
    announce = true,
    clearchat = true,
    clearallchat = true
}

Config.Permissions = {
    announce = 'admin',
    clearallchat = 'admin'
}


Config.CommandGuide = {
    
    Enabled = true,

    
    AutoDetect = true,

    
    
    RefreshOnRequest = true,

    
    HideRestrictedFromPlayers = true,

    
    ShowResourceName = true,

    
    MaxAutoCommands = 220,

    
    HiddenCommands = {
        ['+achat_open'] = true,
        ['-achat_open'] = true,
        ['achat_cycle'] = true,
        ['chatvis'] = true,
        ['toggleChat'] = true,
        ['chatMessageEntered'] = true
    },

    HiddenPrefixes = {
        '+', '-', '_', 'command.', 'ensure', 'restart', 'stop', 'start', 'refresh'
    },

    
    
    Manual = {
        { command = 'help', category = 'Chat', help = 'Open the full city guide with searchable commands and server systems.' },
        { command = 'ooc', category = 'Chat', help = 'Global out-of-character chat.' },
        { command = 'l', category = 'Chat', help = 'Nearby local chat.' },
        { command = 'me', category = 'Chat', help = 'Roleplay action text.' },
        { command = 'do', category = 'Chat', help = 'Scene or environment description.' },
        { command = 'ads', category = 'Ads', help = 'Open the Los Santos Ad Board.' },
        { command = 'ad', category = 'Ads', help = 'Post an ad using your saved ad profile.' },
        { command = 'chatstyle', category = 'Chat Styles', help = 'Pick or view unlocked chat border styles.' },
        { command = 'report', category = 'Support', help = 'Send a staff support report.' },
        { command = 'reports', category = 'Support', help = 'Open the report center.' },
        { command = 'x', category = 'Social', help = 'Open the in-city X feed.' },
        { command = 'fb', category = 'Social', help = 'Open the in-city Facebook feed.' },
        { command = 'clearchat', category = 'Chat', help = 'Clear only your chat window.' },
        { command = 'countdown', category = 'Staff', help = 'Start or stop a synced chat countdown.' },
        { command = 'announce', category = 'Staff', help = 'Send a server announcement.' },
        { command = 'purge', category = 'Staff', help = 'Clear chat for everyone.' },
        { command = 'slowmode', category = 'Staff', help = 'Set global chat slowmode.' },
        { command = 'freezechat', category = 'Staff', help = 'Freeze public chat.' },
        { command = 'unfreezechat', category = 'Staff', help = 'Unfreeze public chat.' },
        { command = 'warn', category = 'Staff', help = 'Warn a player.' },
        { command = 'timeout', category = 'Staff', help = 'Timeout a player from chat.' },
        { command = 'mute', category = 'Staff', help = 'Mute a player from chat.' },
        { command = 'unmute', category = 'Staff', help = 'Unmute a player.' }
    }
}



Config.ChatModeration = {
    enabled = true,

    
    
    AdminDiscordIds = Config.AdminDiscordIds or {},

    
    
    
    AdminRoleIds = {
        '1495483437665095713', 
        '1495483437665095710', 
        '1495483437640056960', 
        '1495483437640056958', 
        '1495483437640056952', 
        '1495483437610434760', 
        '1495483437610434759'  
    },
    ModeratorRoleIds = {
        '1495483437597987047', 
        '1495483437577142460'  
    },


    
    Ace = {
        admin = 'achat.mod.admin',
        mod = 'achat.mod'
    },

    
    

    
    CommandLevels = {
        announce = 'admin',
        purge = 'mod',
        clearallchat = 'mod',
        blocklastgif = 'mod',
        warn = 'mod',
        timeout = 'mod',
        mute = 'mod',
        untimeout = 'mod',
        unmute = 'mod',
        slowmode = 'mod',
        freezechat = 'mod',
        unfreezechat = 'mod',
        shadowmute = 'admin',
        filterword = 'admin',
        countdown = 'mod'
    },

    Defaults = {
        rightClickTimeoutMinutes = 10,
        slowmodeSeconds = 10,
        maxTimeoutMinutes = 1440,
        announceModerationActions = true
    }
}

Config.Visibility = {
    defaultMode = 1,
    cycleKeyDescription = 'Cycle chat visibility',
    cycleKeyDefault = 'SEMICOLON'
}


Config.InputBlock = {
    
    enabled = true,

    
    
    enforceFocusEveryFrame = true,

    
    blockOxInventory = true,

    
    
    exposeStateBag = true,
    stateBagName = 'achatInputOpen'
}


Config.Countdown = {
    enabled = true,
    permission = 'mod', 
    minSeconds = 5,
    maxSeconds = 3600,
    defaultLabel = 'City countdown'
}

Config.AutoAnnouncements = {
    enabled = true,
    intervalMinutes = 12,
    randomize = true,
    startDelaySeconds = 120,
    title = 'CITY TIP',
    author = 'Palmetto County Roleplay',
    messages = {
        'Lost or new? Use /help for the full city guide, jobs, crime, housing, lottery, and chat commands.',
        'Have you checked the latest server changes? Use /updates to see the newest systems and fixes.',
        'Remember to claim your daily reward when the daily reward system is active.',
        'Need legal work? Visit City Hall and use qb-cityhall to choose a job or apply for city services.',
        'Want to haul freight? Start trucking and follow the ATS-style route UI for payouts.',
        'Construction workers can repair road signs, traffic lights, and DOT calls around Los Santos.',
        'Looking for a home? Contact Real Estate or check housing listings for available properties.',
        'Want a weapon license? Register through Ammu-Nation-style license locations if your jail cooldown is clear.',
        'Criminal RP reminder: robberies, hijacking, and safes can alert police. Plan before you act.',
        'Use TAB while chat is open to switch LOCAL, OOC, ADS, and ME without typing slash commands.',
        'Open the ad board with /ads to customize city advertisements, banners, and business posts.',
        'Need staff help? Use /report with details and a player ID if needed.'
    }
}




Config.JobIcons = {
    unemployed = 'civ',
    construction = 'construction',
    bus = 'bus',
    judge = 'justice',
    lawyer = 'lawyer',
    express1 = 'gas',
    express2 = 'gas',
    express3 = 'gas',
    taco = 'food',
    reporter = 'reporter',
    trucker = 'trucker',
    tow = 'tow',
    garbage = 'garbage',
    vineyard = 'vineyard',
    hotdog = 'food',
    police = 'police',
    ambulance = 'ems',
    realestate = 'realestate',
    taxi = 'taxi',
    cardealer = 'cardealer',
    mechanic = 'mech',
    mechanic2 = 'mech',
    mechanic3 = 'mech',
    beeker = 'mech',
    bennys = 'mech',

    
    leo = 'police',
    ems = 'ems',
    doj = 'justice'
}


Config.AdBoard = {
    enabled = true,
    
    
    forceHighestStyle = false,
    allowStyleChoice = true,
    cooldown = 60, 
    maxActiveAds = 45,
    activeMinutes = 45,
    maxProfileLength = 40,
    maxImageUrlLength = 300,
    categories = { 'General', 'Business', 'Vehicles', 'Real Estate', 'Jobs', 'Events', 'Services' },
    defaultAccent = '#c084fc',
    allowBackgroundImages = true,
    allowBannerImages = true,

    
    
    
    syncStyleToChat = true
}

Config.ChatStyles = {
    enabled = true,
    defaultStyle = 'default',

    
    
    
    autoApplyBestUnlocked = true,
    allowAdminPreviewAll = false,
    
    
    forceHighestUnlocked = false,
    allowPlayerStyleChoice = true,
    alwaysUseHighestRoleBadge = true,
    fallbackToHighestIfLocked = true,
    
    
    unlockLowerPriorityStyles = true,

    
    

    
    
    
    
    AceStyles = {
        
        { ace = 'achat.style.supporter', style = 'supporter' },
        { ace = 'achat.style.rgb', style = 'rgb' },
        { ace = 'achat.style.holo', style = 'holo' },
        { ace = 'achat.style.galaxy', style = 'galaxy' },

        
        
        { ace = 'achat.role.founder', style = 'founder' },
        { ace = 'achat.role.coowner', style = 'coowner' },
        { ace = 'achat.role.director', style = 'community_director' },
        { ace = 'achat.role.management', style = 'management_team' },
        { ace = 'achat.role.headadmin', style = 'head_admin' },
        { ace = 'achat.role.sradmin', style = 'sr_admin' },
        { ace = 'achat.role.admin', style = 'administrator' },
        { ace = 'achat.role.jradmin', style = 'jr_admin' },
        { ace = 'achat.role.moderator', style = 'moderator' },
        { ace = 'achat.role.staff', style = 'staff' },
        { ace = 'achat.role.dev', style = 'developer' },
        { ace = 'achat.role.leo_command', style = 'leo_command' },
        { ace = 'achat.role.bcso', style = 'bcso' },
        { ace = 'achat.role.lssd', style = 'lssd' },
        { ace = 'achat.role.lspd', style = 'lspd' },
        { ace = 'achat.role.sahp', style = 'sahp' },
        { ace = 'achat.role.safr', style = 'safr' },
        { ace = 'achat.role.iaa', style = 'iaa' },
        { ace = 'achat.role.vip', style = 'vip' },
        { ace = 'achat.role.premiumvip', style = 'premium_vip' },
        { ace = 'achat.role.ultimatevip', style = 'ultimate_vip' },
        { ace = 'achat.role.donator', style = 'donator' },
        { ace = 'achat.role.contentcreator', style = 'content_creator' }
    },

    
    
    DiscordRoleStyles = {
        
        
        
    },

    
    
    
    CustomDiscordRoleStyles = {
        
        

        
        { serverRoleKey = 'founder', roleId = '1495483437665095713', styleId = 'founder', name = 'PCR | Founder', badge = 'FOUNDER', className = 'style-founder', accent = '#f3f4f6', border = 'rgba(243, 244, 246, 0.88)', glow = '0 0 18px rgba(148, 163, 184, 0.24)', priority = 1000 },
        { serverRoleKey = 'coowner', roleId = '1495483437665095710', styleId = 'coowner', name = 'PCR | Co-Owner', badge = 'CO-OWNER', className = 'style-founder', accent = '#e5e7eb', border = 'rgba(229, 231, 235, 0.82)', glow = '0 0 16px rgba(148, 163, 184, 0.20)', priority = 990 },
        { serverRoleKey = 'community_director', roleId = '1495483437640056960', styleId = 'community_director', name = 'PCR | Community Director', badge = 'DIRECTOR', className = 'style-command', accent = '#d1d5db', border = 'rgba(209, 213, 219, 0.74)', glow = '0 0 14px rgba(107, 114, 128, 0.18)', priority = 950 },
        { serverRoleKey = 'management_team', roleId = '1495483437640056958', styleId = 'management_team', name = 'PCR | Management Team', badge = 'MGMT', className = 'style-command', accent = '#cbd5e1', border = 'rgba(203, 213, 225, 0.68)', glow = '0 0 12px rgba(100, 116, 139, 0.16)', priority = 900 },

        
        { serverRoleKey = 'head_admin', roleId = '1495483437640056952', styleId = 'head_admin', name = 'PCR | Head Administrator', badge = 'HEAD ADMIN', className = 'style-admin-red', accent = '#ef4444', border = 'rgba(239,68,68,0.90)', glow = '0 0 20px rgba(239,68,68,0.34)', priority = 850 },
        { serverRoleKey = 'sr_admin', roleId = '1495483437610434760', styleId = 'sr_admin', name = 'PCR | Sr. Administrator', badge = 'SR ADMIN', className = 'style-admin-red', accent = '#f87171', border = 'rgba(248,113,113,0.82)', glow = '0 0 18px rgba(248,113,113,0.28)', priority = 830 },
        { serverRoleKey = 'administrator', roleId = '1495483437610434759', styleId = 'administrator', name = 'PCR | Administrator', badge = 'ADMIN', className = 'style-admin', accent = '#ef4444', border = 'rgba(239,68,68,0.76)', glow = '0 0 15px rgba(239,68,68,0.22)', priority = 800 },
        { serverRoleKey = 'jr_admin', roleId = '1495483437610434759', styleId = 'jr_admin', name = 'PCR | Jr. Administrator', badge = 'JR ADMIN', className = 'style-admin', accent = '#fb7185', border = 'rgba(251,113,133,0.72)', glow = '0 0 14px rgba(251,113,133,0.18)', priority = 780 },
        { serverRoleKey = 'moderator', roleId = '1495483437597987047', styleId = 'moderator', name = 'PCR | Moderator / Chat Overseer', badge = 'MOD', className = 'style-moderator', accent = '#22d3ee', border = 'rgba(34,211,238,0.76)', glow = '0 0 15px rgba(34,211,238,0.22)', priority = 760 },
        { serverRoleKey = 'staff', roleId = '1495483437577142460', styleId = 'staff', name = 'PCR | Staff', badge = 'STAFF', className = 'style-staff', accent = '#22c55e', border = 'rgba(34,197,94,0.70)', glow = '0 0 14px rgba(34,197,94,0.18)', priority = 700 },

        
        { serverRoleKey = 'developer', roleId = '1495483437568491620', styleId = 'developer', name = 'PCR | Developer', badge = 'DEV', className = 'style-dev', accent = '#22c55e', border = 'rgba(34,197,94,0.88)', glow = '0 0 22px rgba(34,197,94,0.32)', priority = 820 },
        { serverRoleKey = 'vehicle_dev', roleId = '1495483437568491617', styleId = 'vehicle_dev', name = 'PCR | Vehicle Developer', badge = 'VEH DEV', className = 'style-dev', accent = '#4ade80', border = 'rgba(74,222,128,0.82)', glow = '0 0 20px rgba(74,222,128,0.28)', priority = 810 },
        { serverRoleKey = 'general_dev', roleId = '1495483437568491616', styleId = 'general_dev', name = 'PCR | General Developer', badge = 'GEN DEV', className = 'style-dev', accent = '#86efac', border = 'rgba(134,239,172,0.78)', glow = '0 0 18px rgba(134,239,172,0.24)', priority = 805 },

        
        { serverRoleKey = 'leo_command', roleId = '1495483437556044013', styleId = 'leo_command', name = 'LEO | Command', badge = 'LEO CMD', className = 'style-dept-blue', accent = '#3b82f6', border = 'rgba(59,130,246,0.78)', glow = '0 0 16px rgba(59,130,246,0.22)', priority = 680 },
        { serverRoleKey = 'bcso', roleId = '1495483437568491615', styleId = 'bcso', name = 'BCSO', badge = 'BCSO', className = 'style-dept-green', accent = '#22c55e', border = 'rgba(34,197,94,0.72)', glow = '0 0 13px rgba(34,197,94,0.18)', priority = 640 },
        { serverRoleKey = 'lssd', roleId = '1495483437568491614', styleId = 'lssd', name = 'LSSD', badge = 'LSSD', className = 'style-dept-gold', accent = '#d6a84f', border = 'rgba(214,168,79,0.72)', glow = '0 0 13px rgba(214,168,79,0.18)', priority = 635 },
        { serverRoleKey = 'lspd', roleId = '1495483437568491613', styleId = 'lspd', name = 'LSPD', badge = 'LSPD', className = 'style-dept-blue', accent = '#0ea5e9', border = 'rgba(14,165,233,0.72)', glow = '0 0 13px rgba(14,165,233,0.18)', priority = 635 },
        { serverRoleKey = 'sahp', roleId = '1495483437568491612', styleId = 'sahp', name = 'SAHP', badge = 'SAHP', className = 'style-dept-gold', accent = '#f59e0b', border = 'rgba(245,158,11,0.76)', glow = '0 0 14px rgba(245,158,11,0.20)', priority = 635 },
        { serverRoleKey = 'safr', roleId = '1495483437543587994', styleId = 'safr', name = 'SAFR', badge = 'SAFR', className = 'style-dept-red', accent = '#ef4444', border = 'rgba(239,68,68,0.76)', glow = '0 0 14px rgba(239,68,68,0.20)', priority = 650 },
        { serverRoleKey = 'iaa', roleId = '1495483437610434754', styleId = 'iaa', name = 'IAA', badge = 'IAA', className = 'style-iaa', accent = '#0891b2', border = 'rgba(8,145,178,0.74)', glow = '0 0 14px rgba(8,145,178,0.20)', priority = 650 },

        
        { serverRoleKey = 'content_creator', roleId = '1495483437535068169', styleId = 'content_creator', name = 'PCR | Content Creator', badge = 'CREATOR', className = 'style-creator', accent = '#d1d5db', border = 'rgba(209, 213, 219, 0.70)', glow = '0 0 14px rgba(107, 114, 128, 0.16)', priority = 620 },
        { serverRoleKey = 'ultimate_vip', roleId = '1495483437535068168', styleId = 'ultimate_vip', name = 'PCR | Ultimate VIP', badge = 'ULT VIP', className = 'style-vip-ultimate', accent = '#fde047', border = 'rgba(253,224,71,0.86)', glow = '0 0 22px rgba(253,224,71,0.32)', priority = 600 },
        { serverRoleKey = 'premium_vip', roleId = '1495483437535068167', styleId = 'premium_vip', name = 'PCR | Premium VIP', badge = 'PREMIUM', className = 'style-vip-premium', accent = '#facc15', border = 'rgba(250,204,21,0.78)', glow = '0 0 18px rgba(250,204,21,0.24)', priority = 590 },
        { serverRoleKey = 'vip', roleId = '1495483437535068166', styleId = 'vip', name = 'PCR | VIP', badge = 'VIP', className = 'style-vip', accent = '#eab308', border = 'rgba(234,179,8,0.72)', glow = '0 0 15px rgba(234,179,8,0.20)', priority = 580 },
        { serverRoleKey = 'donator', roleId = '1495483437535068164', styleId = 'donator', name = 'PCR | Donator', badge = 'DONATOR', className = 'style-donator', accent = '#22c55e', border = 'rgba(34,197,94,0.70)', glow = '0 0 14px rgba(34,197,94,0.18)', priority = 560 }
    },

    Options = {
        default = {
            label = 'Citizen',
            className = 'style-default',
            accent = '#c084fc',
            border = 'rgba(168,85,247,0.28)',
            glow = 'none',
            badge = '',
            priority = 0
        },
        supporter = {
            label = 'Supporter',
            className = 'style-supporter',
            accent = '#f5d06f',
            border = 'rgba(245,208,111,0.78)',
            glow = '0 0 18px rgba(245,208,111,0.38)',
            badge = 'SUPPORTER',
            priority = 500
        },
        rgb = {
            label = 'RGB Donator',
            className = 'style-rgb',
            accent = '#67e8f9',
            border = 'rgba(103,232,249,0.86)',
            glow = '0 0 20px rgba(103,232,249,0.34)',
            badge = 'RGB',
            priority = 520
        },
        holo = {
            label = 'Holographic',
            className = 'style-holo',
            accent = '#f0abfc',
            border = 'rgba(240,171,252,0.85)',
            glow = '0 0 22px rgba(240,171,252,0.35)',
            badge = 'HOLO',
            priority = 530
        },
        galaxy = {
            label = 'Galaxy',
            className = 'style-galaxy',
            accent = '#93c5fd',
            border = 'rgba(147,197,253,0.85)',
            glow = '0 0 22px rgba(147,197,253,0.34)',
            badge = 'GALAXY',
            priority = 540
        }
    }
}

Config.Integrations = {
    emoji = true,
    gifs = true,
    provider = 'giphy',
    giphy = {
        enabled = true,
        apiKey = 'Zu2CHl5qrJZi0lzixPeyVnPhB0kuNQvS',
        rating = 'pg-13',
        limit = 8
    },
    tenor = {
        enabled = false,
        apiKey = '',
        clientKey = 'orp_chat',
        locale = 'en_US',
        limit = 8,
        mediaFilter = 'tinygif'
    }
}

Config.AdminDiscordIds = {
   '982768967275921408',
   '1190073514296869014',
   '1147328427381235773'
}
