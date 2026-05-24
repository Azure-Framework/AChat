function resolveResourceName() {
    if (typeof GetParentResourceName === 'function') {
        const parent = GetParentResourceName();
        if (parent && parent.length > 0) return parent;
    }
    const host = window.location?.hostname || '';
    return host.startsWith('cfx-nui-') ? host.replace('cfx-nui-', '') : host;
}

function lineIcon(key) {
    const icons = {
        police: '<svg viewBox="0 0 24 24"><path d="M12 3l7 3v5c0 5-3.5 8.5-7 10-3.5-1.5-7-5-7-10V6l7-3z"/></svg>',
        ems: '<svg viewBox="0 0 24 24"><path d="M10 4h4v5h5v4h-5v7h-4v-7H5V9h5z"/></svg>',
        fire: '<svg viewBox="0 0 24 24"><path d="M12 3s3 3.5 3 6.5c0 1.5-1 2.5-2 3.5 0-2.5-2-4-2-4s-2 2.2-2 5c0 3 2 5 5 5s5-2 5-5c0-4.5-3-7-7-11z"/></svg>',
        mech: '<svg viewBox="0 0 24 24"><path d="M14.7 6.3a4 4 0 0 0 3.6 5.4l-7.6 7.6a2 2 0 1 1-2.8-2.8l7.6-7.6a4 4 0 0 0 5.4-3.6l-3 1-2-2 1-3z"/></svg>',
        construction: '<svg viewBox="0 0 24 24"><path d="M4 20h16"/><path d="M6 20l2-9h8l2 9"/><path d="M9 11V7h6v4"/><path d="M8 15h8"/></svg>',
        dot: '<svg viewBox="0 0 24 24"><path d="M3 16l4-8h10l4 8"/><path d="M5 16h14"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg>',
        bus: '<svg viewBox="0 0 24 24"><rect x="5" y="4" width="14" height="14" rx="2"/><path d="M8 18v2M16 18v2M7 8h10M7 13h10"/></svg>',
        justice: '<svg viewBox="0 0 24 24"><path d="M12 3v18M6 7h12M7 7l-3 6h6L7 7zm10 0l-3 6h6l-3-6z"/></svg>',
        lawyer: '<svg viewBox="0 0 24 24"><path d="M9 7V5h6v2"/><rect x="4" y="7" width="16" height="12" rx="2"/><path d="M4 12h16M10 12v2h4v-2"/></svg>',
        gas: '<svg viewBox="0 0 24 24"><path d="M6 20V5a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v15"/><path d="M8 8h6M16 7l3 3v7a2 2 0 0 0 2 2"/></svg>',
        food: '<svg viewBox="0 0 24 24"><path d="M7 3v8M10 3v8M7 7h3M17 3v18M14 3c3 2 3 6 0 8"/></svg>',
        reporter: '<svg viewBox="0 0 24 24"><rect x="4" y="5" width="16" height="14" rx="2"/><path d="M8 9h8M8 13h8M8 17h4"/></svg>',
        trucker: '<svg viewBox="0 0 24 24"><path d="M3 7h11v10H3zM14 11h4l3 3v3h-7"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg>',
        tow: '<svg viewBox="0 0 24 24"><path d="M4 16h9V6h4l3 5v5"/><path d="M13 9H8l-3 7"/><circle cx="7" cy="18" r="2"/><circle cx="18" cy="18" r="2"/></svg>',
        garbage: '<svg viewBox="0 0 24 24"><path d="M4 7h16M9 7V5h6v2M7 7l1 13h8l1-13M10 11v5M14 11v5"/></svg>',
        vineyard: '<svg viewBox="0 0 24 24"><path d="M12 3v6M8 9h8"/><circle cx="9" cy="12" r="2"/><circle cx="15" cy="12" r="2"/><circle cx="12" cy="16" r="2"/><path d="M12 18c-1.5 1.5-3 2-5 2"/></svg>',
        taxi: '<svg viewBox="0 0 24 24"><path d="M5 16l2-6h10l2 6"/><path d="M8 10V7h8v3M6 16h12"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg>',
        cardealer: '<svg viewBox="0 0 24 24"><path d="M3 15l3-6h12l3 6"/><path d="M5 15h14M8 9l1-3h6l1 3"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg>',
        realestate: '<svg viewBox="0 0 24 24"><path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/><path d="M10 20v-6h4v6"/></svg>',
        civ: '<svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M6 20c1.5-3 4-4 6-4s4.5 1 6 4"/></svg>',
        default: '<svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M6 20c1.5-3 4-4 6-4s4.5 1 6 4"/></svg>'
    };
    return icons[key] || icons.default;
}

function moderationIcon(kind) {
    if (kind === 'warn') return '⚠';
    if (kind === 'timeout' || kind === 'mute') return '🔇';
    if (kind === 'unmute') return '🔔';
    return '⚠';
}

function escapeHtml(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function avatarLetter(value) {
    return (String(value || '?').trim()[0] || '?').toUpperCase();
}

function hashColor(value) {
    const colors = ['#8b5cf6', '#3b82f6', '#06b6d4', '#ec4899', '#ef4444', '#22c55e'];
    let hash = 0;
    const text = String(value || '');
    for (let i = 0; i < text.length; i++) hash = text.charCodeAt(i) + ((hash << 5) - hash);
    return colors[Math.abs(hash) % colors.length];
}

const EMOJIS = ['😀','😁','😂','🤣','😊','😍','😘','😎','🤔','😴','😭','😡','👍','👎','🙏','👏','💀','🔥','❤️','💜','✅','❌','👀','🎉'];
const resourceName = resolveResourceName();

const moderationNotice = document.getElementById('moderation-notice');
const hoverCard = document.getElementById('hover-card');
const nameMenu = document.getElementById('name-menu');
const nameMenuTitle = document.getElementById('name-menu-title');
const nameMenuPm = document.getElementById('name-menu-pm');
const nameMenuPmSend = document.getElementById('name-menu-pm-send');

const root = document.getElementById('chat-root');
const messageList = document.getElementById('message-list');
const inputShell = document.getElementById('input-shell');
const chatInput = document.getElementById('chat-input');
const playerLine = document.getElementById('player-line');
const jobBadge = document.getElementById('job-badge');
const modeBadge = document.getElementById('mode-badge');
const chatModeBadge = document.getElementById('chat-mode-badge');
const hintLine = document.getElementById('hint-line');
const stateToast = document.getElementById('state-toast');
const emojiToggle = document.getElementById('emoji-toggle');
const gifToggle = document.getElementById('gif-toggle');
const emojiPanel = document.getElementById('emoji-panel');
const gifPanel = document.getElementById('gif-panel');
const emojiGrid = document.getElementById('emoji-grid');
const gifSearchInput = document.getElementById('gif-search-input');
const gifSearchBtn = document.getElementById('gif-search-btn');
const gifResults = document.getElementById('gif-results');
const gifChip = document.getElementById('gif-chip');
const adsToggle = document.getElementById('ads-toggle');

const adsModal = document.getElementById('ads-modal');
const adsRefresh = document.getElementById('ads-refresh');
const adsClose = document.getElementById('ads-close');
const adBusinessName = document.getElementById('ad-business-name');
const adCategory = document.getElementById('ad-category');
const adAccent = document.getElementById('ad-accent');
const adBanner = document.getElementById('ad-banner');
const adBackground = document.getElementById('ad-background');
const adStyle = document.getElementById('ad-style');
const adStyleAuto = document.getElementById('ad-style-auto');
const adProfileSave = document.getElementById('ad-profile-save');
const adMessage = document.getElementById('ad-message');
const adPostBtn = document.getElementById('ad-post-btn');
const adsList = document.getElementById('ads-list');

const socialModal = document.getElementById('social-modal');
const socialBrand = document.getElementById('social-brand');
const socialSubtitle = document.getElementById('social-subtitle');
const socialRefresh = document.getElementById('social-refresh');
const socialClose = document.getElementById('social-close');
const socialSignup = document.getElementById('social-signup');
const socialSignupTitle = document.getElementById('social-signup-title');
const socialSignupPrefix = document.getElementById('social-signup-prefix');
const socialUsername = document.getElementById('social-username');
const socialSignupBtn = document.getElementById('social-signup-btn');
const socialLeftBrand = document.getElementById('social-left-brand');
const socialLeftNav = document.getElementById('social-left-nav');
const socialPrimaryPost = document.getElementById('social-primary-post');
const socialAccountLine = document.getElementById('social-account-line');
const socialPostInput = document.getElementById('social-post-input');
const socialIsAd = document.getElementById('social-is-ad');
const socialPostBtn = document.getElementById('social-post-btn');
const socialFeed = document.getElementById('social-feed');
const socialRightTrends = document.getElementById('social-right-trends');
const socialRightFollow = document.getElementById('social-right-follow');

const reportsModal = document.getElementById('reports-modal');
const reportsRefresh = document.getElementById('reports-refresh');
const reportsClose = document.getElementById('reports-close');
const reportList = document.getElementById('report-list');
const reportThreadHeader = document.getElementById('report-thread-header');
const reportThread = document.getElementById('report-thread');
const reportReplyRow = document.getElementById('report-reply-row');
const reportReplyInput = document.getElementById('report-reply-input');
const reportReplySend = document.getElementById('report-reply-send');


const helpModal = document.getElementById('help-modal');
const helpRefresh = document.getElementById('help-refresh');
const helpClose = document.getElementById('help-close');
const helpSearch = document.getElementById('help-search');
const helpSections = document.getElementById('help-sections');
const helpContent = document.getElementById('help-content');
const commandSuggestions = document.getElementById('command-suggestions');

let maxMessages = 120;
let visibilityMode = 1;
let toastTimer = null;
let noticeTimer = null;
let activeTimer = null;
let selectedGif = '';
let sentHistory = [];
let historyIndex = 0;
let isAdmin = false;
let canModerate = false;
let moderationState = { level: 0, label: 'user', slowmode: 0, frozen: false };
let chatOpen = false;
let adsState = { ads: [], profile: {}, categories: [], styles: [], isAdmin: false };
let socialState = { network: 'x', account: null, posts: [], isAdmin: false, viewerName: '' };
let reportsState = { isAdmin: false, reports: [], selectedId: null };
let audioCtx = null;
let nameMenuTarget = null;
let currentPlayerId = 0;
let helpState = { sections: [], isAdmin: false, canModerate: false, roleLabel: 'user' };
let activeHelpSectionId = null;
let commandCatalog = [];
let commandSuggestionIndex = 0;
let chatModes = [
    { command: 'l', label: 'LOCAL', placeholder: 'Local chat nearby players...' },
    { command: 'ooc', label: 'OOC', placeholder: 'Out of character chat to everyone...' },
    { command: 'me', label: 'ME', placeholder: 'Roleplay action, example: smiles...' }
];
let chatModeIndex = 0;
const CHAT_MODE_ALIASES = { local: 'l', say: 'l' };

function nui(endpoint, payload = {}) {
    if (!resourceName) return Promise.resolve(null);
    return fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    }).catch(() => null);
}

function beep() {
    try {
        audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
        const oscillator = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        oscillator.type = 'sine';
        oscillator.frequency.value = 880;
        gain.gain.value = 0.05;
        oscillator.connect(gain);
        gain.connect(audioCtx.destination);
        oscillator.start();
        oscillator.stop(audioCtx.currentTime + 0.12);
    } catch (_) {}
}

function showModerationNotice(payload) {
    moderationNotice.innerHTML = `
        <div class="moderation-notice-title"><span>${moderationIcon(payload.kind)}</span><span>${escapeHtml(payload.title || 'NOTICE')}</span></div>
        <div class="moderation-notice-info">${escapeHtml(payload.info || '')}</div>
    `;
    moderationNotice.classList.remove('hidden');
    beep();
    clearTimeout(noticeTimer);
    noticeTimer = setTimeout(() => moderationNotice.classList.add('hidden'), 4500);
}

function setTheme(theme = {}, layout = {}) {
    const styleRoot = document.documentElement;
    if (theme.primary) styleRoot.style.setProperty('--primary', theme.primary);
    if (theme.primarySoft) styleRoot.style.setProperty('--primary-soft', theme.primarySoft);
    if (theme.secondary) styleRoot.style.setProperty('--secondary', theme.secondary);
    if (theme.background) styleRoot.style.setProperty('--bg', theme.background);
    if (theme.surface) styleRoot.style.setProperty('--surface', theme.surface);
    if (theme.border) styleRoot.style.setProperty('--border', theme.border);
    if (theme.text) styleRoot.style.setProperty('--text', theme.text);
    if (theme.muted) styleRoot.style.setProperty('--muted', theme.muted);
    if (layout.width) styleRoot.style.setProperty('--width', `${layout.width}px`);
    if (layout.top !== undefined) styleRoot.style.setProperty('--top', `${layout.top}px`);
    if (layout.left !== undefined) styleRoot.style.setProperty('--left', `${layout.left}px`);
    if (layout.maxMessages) maxMessages = layout.maxMessages;
}

function removeOverflow() {
    while (messageList.children.length > maxMessages) messageList.removeChild(messageList.firstElementChild);
}

function stabilizeMessageLayout(node) {
    if (!node) return;
    requestAnimationFrame(() => {
        if (!node.isConnected) return;
        node.style.height = 'auto';
        node.style.minHeight = Math.max(38, Math.ceil(node.scrollHeight)) + 'px';
        messageList.style.height = 'auto';
    });
}

function stabilizeAllMessageLayouts() {
    Array.from(messageList.children).forEach(stabilizeMessageLayout);
}

function scheduleActiveHide() {
    if (visibilityMode !== 2 || chatOpen) return;
    clearTimeout(activeTimer);
    activeTimer = setTimeout(() => messageList.classList.add('hidden-by-activity'), 5000);
}

function showMessageListTemporarily() {
    if (visibilityMode !== 2) return;
    messageList.classList.remove('hidden-by-activity');
    scheduleActiveHide();
}

function setVisibilityMode(mode) {
    visibilityMode = Number(mode || 1);
    root.classList.remove('mode-always', 'mode-active', 'mode-hidden');
    messageList.classList.remove('hidden-by-activity');
    clearTimeout(activeTimer);
    if (visibilityMode === 1) {
        root.classList.add('mode-always');
        modeBadge.textContent = 'ALWAYS';
    } else if (visibilityMode === 2) {
        root.classList.add('mode-active');
        modeBadge.textContent = 'ACTIVE';
        scheduleActiveHide();
    } else {
        root.classList.add('mode-hidden');
        modeBadge.textContent = 'DISABLED';
    }
}

function normalizeModeCommand(command) {
    const raw = String(command || '').replace(/^\//, '').trim().toLowerCase();
    return CHAT_MODE_ALIASES[raw] || raw;
}

function modeIndexForCommand(command) {
    const normalized = normalizeModeCommand(command);
    return chatModes.findIndex((mode) => normalizeModeCommand(mode.command) === normalized);
}

function activeChatMode() {
    return chatModes[chatModeIndex] || chatModes[0];
}

function setChatModes(modes) {
    if (!Array.isArray(modes) || !modes.length) return;
    const clean = modes
        .map((mode) => ({
            command: normalizeModeCommand(mode.command || mode.name || ''),
            label: String(mode.label || mode.command || '').toUpperCase(),
            placeholder: String(mode.placeholder || '')
        }))
        .filter((mode) => mode.command);
    if (!clean.length) return;
    chatModes = clean;
    if (chatModeIndex >= chatModes.length) chatModeIndex = 0;
}

function extractModePrefix(value) {
    const input = String(value || '');
    const match = input.match(/^\s*\/([a-zA-Z]+)(?:\s+|$)([\s\S]*)$/);
    if (!match) return { hasMode: false, index: -1, body: input };
    const index = modeIndexForCommand(match[1]);
    if (index === -1) return { hasMode: false, index: -1, body: input, hasSlash: true };
    return { hasMode: true, index, body: match[2] || '' };
}

function updateChatModeBadge() {
    const mode = activeChatMode();
    if (chatModeBadge) chatModeBadge.textContent = String(mode.label || mode.command || 'LOCAL').toUpperCase();
    if (chatInput && mode.placeholder) chatInput.placeholder = mode.placeholder;
}

function applyChatModeStatus() {
    updateChatModeBadge();
}

function cycleChatMode(direction = 1) {
    chatModeIndex += direction;
    if (chatModeIndex >= chatModes.length) chatModeIndex = 0;
    if (chatModeIndex < 0) chatModeIndex = chatModes.length - 1;
    applyChatModeStatus();
    showToast(`Chat mode: ${String(activeChatMode().label || activeChatMode().command || 'LOCAL').toUpperCase()}`);
}

function syncChatModeFromInput() {
    const parsed = extractModePrefix(chatInput.value || '');
    if (!parsed.hasMode) return;
    chatModeIndex = parsed.index;
    updateChatModeBadge();
}

function normalizeCommandCatalogItem(item) {
    const rawCommand = String(item?.command || item?.name || '').replace(/^\//, '').trim().toLowerCase();
    if (!rawCommand) return null;

    return {
        command: rawCommand,
        name: `/${rawCommand}`,
        help: String(item?.help || 'Registered server command.'),
        category: String(item?.category || 'Detected'),
        resource: String(item?.resource || ''),
        permission: String(item?.permission || 'user'),
        link: String(item?.link || `/${rawCommand}`)
    };
}

function setCommandRegistry(payload = {}) {
    const incoming = Array.isArray(payload) ? payload : (Array.isArray(payload.items) ? payload.items : []);
    const shouldMerge = payload && payload.merge === true;
    const base = shouldMerge ? commandCatalog : [];
    const seen = new Set();
    commandCatalog = [...base, ...incoming]
        .map(normalizeCommandCatalogItem)
        .filter(Boolean)
        .filter((item) => {
            if (seen.has(item.command)) return false;
            seen.add(item.command);
            return true;
        })
        .sort((a, b) => a.command.localeCompare(b.command));

    renderCommandSuggestions();
}

function commandSearchInfo() {
    const value = String(chatInput?.value || '');
    const match = value.match(/^\s*\/([a-zA-Z0-9_.-]*)$/);
    if (!match) return null;
    return { query: String(match[1] || '').toLowerCase() };
}

function matchingCommandSuggestions() {
    const info = commandSearchInfo();
    if (!info) return [];
    const query = info.query;
    const matches = commandCatalog.filter((item) => {
        if (!query) return true;
        return item.command.includes(query) || item.help.toLowerCase().includes(query) || item.category.toLowerCase().includes(query);
    });
    return matches.slice(0, 8);
}

function commandSuggestionsVisible() {
    return commandSuggestions && !commandSuggestions.classList.contains('hidden');
}

function hideCommandSuggestions() {
    if (!commandSuggestions) return;
    commandSuggestions.classList.add('hidden');
    commandSuggestions.innerHTML = '';
}

function renderCommandSuggestions() {
    if (!commandSuggestions || !chatOpen) return hideCommandSuggestions();

    const info = commandSearchInfo();
    if (!info) return hideCommandSuggestions();

    const matches = matchingCommandSuggestions();
    commandSuggestionIndex = Math.max(0, Math.min(commandSuggestionIndex, Math.max(0, matches.length - 1)));

    if (!matches.length) {
        commandSuggestions.classList.remove('hidden');
        commandSuggestions.innerHTML = `
            <div class="command-suggestion-empty">
                <strong>No matching commands</strong>
                <span>Try /help to see the guide.</span>
            </div>
        `;
        return;
    }

    commandSuggestions.classList.remove('hidden');
    commandSuggestions.innerHTML = matches.map((item, index) => `
        <button type="button" class="command-suggestion ${index === commandSuggestionIndex ? 'active' : ''}" data-command="${escapeHtml(item.command)}">
            <span class="command-suggestion-name">${escapeHtml(item.name)}</span>
            <span class="command-suggestion-help">${escapeHtml(item.help)}</span>
            <span class="command-suggestion-meta">
                <em>${escapeHtml(item.category)}</em>
                ${item.resource ? `<em>${escapeHtml(item.resource)}</em>` : ''}
                ${item.permission && item.permission !== 'user' ? `<em>${escapeHtml(item.permission)}</em>` : ''}
            </span>
        </button>
    `).join('');
}

function applyCommandSuggestion(command) {
    const clean = String(command || '').replace(/^\//, '').trim();
    if (!clean) return;
    chatInput.value = `/${clean} `;
    syncChatModeFromInput();
    hideCommandSuggestions();
    requestAnimationFrame(() => {
        chatInput.focus();
        chatInput.setSelectionRange(chatInput.value.length, chatInput.value.length);
    });
}

function moveCommandSuggestion(delta) {
    const matches = matchingCommandSuggestions();
    if (!matches.length) return;
    commandSuggestionIndex += delta;
    if (commandSuggestionIndex < 0) commandSuggestionIndex = matches.length - 1;
    if (commandSuggestionIndex >= matches.length) commandSuggestionIndex = 0;
    renderCommandSuggestions();
}

function acceptSelectedCommandSuggestion() {
    const matches = matchingCommandSuggestions();
    if (!matches.length) return false;
    applyCommandSuggestion(matches[commandSuggestionIndex]?.command);
    return true;
}

function renderHelpMeta(item = {}) {
    const badges = [];
    if (item.category) badges.push(item.category);
    if (item.resource) badges.push(item.resource);
    if (item.permission && item.permission !== 'user') badges.push(item.permission);
    if (!badges.length) return '';
    return `<div class="help-item-meta">${badges.map((badge) => `<span>${escapeHtml(badge)}</span>`).join('')}</div>`;
}

function renderJobBadge(job) {
    return `${lineIcon(job.key || 'civ')}<span>${escapeHtml(job.label || 'Civilian')} • ${escapeHtml(job.state || 'OFF DUTY')}</span>`;
}

function renderAuthorJob(job) {
    return `${lineIcon(job.key || 'civ')}<span>${escapeHtml(job.label || 'Civilian')} • ${escapeHtml(job.state || 'OFF DUTY')}</span>`;
}

function renderGifChip() {
    if (!selectedGif) {
        gifChip.classList.add('hidden');
        gifChip.innerHTML = '';
        return;
    }
    gifChip.classList.remove('hidden');
    gifChip.innerHTML = `<img src="${escapeHtml(selectedGif)}" alt="Selected GIF"><button class="gif-clear-btn" type="button">Remove GIF</button>`;
    gifChip.querySelector('.gif-clear-btn').addEventListener('click', () => {
        selectedGif = '';
        renderGifChip();
    });
}

function cssCustomValue(value) {
    return String(value ?? '').replace(/[;{}<>]/g, '').trim();
}

function cssUrlValue(value) {
    const url = String(value ?? '').trim();
    if (!url) return '';
    if (/[<>"'\\\r\n]/.test(url)) return '';
    return `url("${url.replace(/\(/g, '%28').replace(/\)/g, '%29')}")`;
}

function styleVars(style = {}) {
    const vars = [];
    if (style.accent) vars.push(`--style-accent:${cssCustomValue(style.accent)}`);
    if (style.border) vars.push(`--style-border:${cssCustomValue(style.border)}`);
    if (style.glow) vars.push(`--style-glow:${cssCustomValue(style.glow)}`);
    if (style.bannerImage) {
        const banner = cssUrlValue(style.bannerImage);
        if (banner) vars.push(`--style-banner:${banner}`);
    }
    if (style.backgroundImage) {
        const bg = cssUrlValue(style.backgroundImage);
        if (bg) vars.push(`--style-bg-image:${bg}`);
    }
    return vars.join(';');
}

function styleAttr(style = {}) {
    return escapeHtml(styleVars(style));
}

let activeCountdownInterval = null;

function formatCountdownSeconds(total) {
    total = Math.max(0, Math.floor(Number(total) || 0));
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    const seconds = total % 60;
    const pad = (n) => String(n).padStart(2, '0');
    return hours > 0 ? `${pad(hours)}:${pad(minutes)}:${pad(seconds)}` : `${pad(minutes)}:${pad(seconds)}`;
}

function updateCountdown(payload = {}) {
    const id = payload.id || 'active-countdown';
    let node = messageList.querySelector(`[data-countdown-id="${id}"]`);
    if (!node) {
        node = document.createElement('div');
        node.className = 'message countdown style-command';
        node.dataset.countdownId = id;
        messageList.appendChild(node);
        removeOverflow();
    }

    const render = () => {
        const now = Math.floor(Date.now() / 1000);
        const remaining = Math.max(0, Math.ceil(Number(payload.endsAt || now) - now));
        const total = Math.max(1, Number(payload.total || remaining || 1));
        const percent = payload.cancelled ? 0 : Math.max(0, Math.min(100, (remaining / total) * 100));
        const done = payload.done || (!payload.active && !payload.cancelled) || remaining <= 0;
        const status = payload.cancelled ? 'CANCELLED' : (done ? 'FINISHED' : 'LIVE');
        const timeText = payload.cancelled ? '--:--' : (done ? '00:00' : formatCountdownSeconds(remaining));
        node.innerHTML = `
            <div class="message-top countdown-top">
                <span class="badge">${escapeHtml(payload.title || 'COUNTDOWN')}</span>
                <span class="style-badge">${status}</span>
                <span class="author">${escapeHtml(payload.author || 'Server')}</span>
                <span class="time">${escapeHtml(payload.timestamp || '')}</span>
            </div>
            <div class="countdown-body">
                <div class="countdown-label">${escapeHtml(payload.label || 'City countdown')}</div>
                <div class="countdown-time">${timeText}</div>
                <div class="countdown-track"><div class="countdown-fill" style="width:${percent}%"></div></div>
            </div>
        `;
        stabilizeMessageLayout(node);
        if (done || payload.cancelled) {
            if (activeCountdownInterval) {
                clearInterval(activeCountdownInterval);
                activeCountdownInterval = null;
            }
        }
    };

    if (activeCountdownInterval) {
        clearInterval(activeCountdownInterval);
        activeCountdownInterval = null;
    }

    render();
    if (payload.active && !payload.cancelled && !payload.done) {
        activeCountdownInterval = setInterval(render, 1000);
    }

    requestAnimationFrame(() => {
        messageList.scrollTop = messageList.scrollHeight;
        stabilizeAllMessageLayouts();
    });
    showMessageListTemporarily();
}

function addMessage(payload) {
    if (visibilityMode === 3) return;
    const job = payload.job || {};
    const style = payload.style || {};
    const className = String(style.className || 'style-default').replace(/[^a-zA-Z0-9_\-\s]/g, '');
    const node = document.createElement('div');
    node.className = `message ${payload.kind || 'local'} ${className} enter`;
    node.setAttribute('style', styleVars(style));
    if (payload.id) node.dataset.messageId = payload.id;
    node.dataset.sourceId = payload.sourceId || '';
    node.dataset.author = payload.author || 'Unknown';
    node.dataset.job = job.label || 'Civilian';
    node.dataset.state = job.state || 'OFF DUTY';
    node.dataset.timestamp = payload.timestamp || '';
    const authorHtml = canModerate && payload.sourceId
        ? `<button type="button" class="author-btn" data-source-id="${payload.sourceId}" data-author="${escapeHtml(payload.author || 'Unknown')}">${escapeHtml(payload.author || 'Unknown')}</button>`
        : `<span class="author">${escapeHtml(payload.author || 'Unknown')}</span>`;
    const gifMarkup = payload.gifUrl ? `<img class="gif-message" src="${escapeHtml(payload.gifUrl)}" alt="GIF">` : '';
    const styleBadge = style.badge ? `<span class="style-badge">${escapeHtml(style.badge)}</span>` : '';
    const bannerMarkup = style.bannerImage ? '<div class="message-banner"></div>' : '';
    const ad = payload.ad || {};
    const adMarkup = payload.kind === 'ad'
        ? `<div class="ad-mini-head"><span>${escapeHtml(ad.category || 'General')}</span><strong>${escapeHtml(ad.businessName || 'City Ad')}</strong></div>`
        : '';
    node.innerHTML = `
        ${bannerMarkup}
        ${adMarkup}
        <div class="message-top">
            <span class="badge">${escapeHtml(payload.title || 'CHAT')}</span>
            ${styleBadge}
            ${authorHtml}
            <span class="author-job">${renderAuthorJob(job)}</span>
            <span class="time">${escapeHtml(payload.timestamp || '')}</span>
        </div>
        ${payload.message ? `<div class="content">${escapeHtml(payload.message)}</div>` : ''}
        ${gifMarkup}
    `;
    messageList.appendChild(node);
    node.querySelectorAll('img').forEach((img) => {
        img.addEventListener('load', () => stabilizeMessageLayout(node), { once: true });
        img.addEventListener('error', () => stabilizeMessageLayout(node), { once: true });
    });
    requestAnimationFrame(() => {
        stabilizeMessageLayout(node);
        node.classList.add('in');
        messageList.scrollTop = messageList.scrollHeight;
    });
    removeOverflow();
    stabilizeAllMessageLayouts();
    showMessageListTemporarily();
}

function clearMessages() {
    messageList.innerHTML = '';
}

function focusChatInput() {
    if (!chatOpen) return;
    try { chatInput.focus({ preventScroll: true }); } catch (_) { chatInput.focus(); }
}

function openInput() {
    chatOpen = true;
    historyIndex = sentHistory.length;
    inputShell.classList.remove('hidden');
    emojiPanel.classList.add('hidden');
    gifPanel.classList.add('hidden');
    messageList.classList.remove('hidden-by-activity');
    updateChatModeBadge();
    renderCommandSuggestions();
    requestAnimationFrame(focusChatInput);
    setTimeout(focusChatInput, 0);
    setTimeout(focusChatInput, 50);
}

function closeInput() {
    chatOpen = false;
    inputShell.classList.add('hidden');
    emojiPanel.classList.add('hidden');
    gifPanel.classList.add('hidden');
    chatInput.value = '';
    selectedGif = '';
    renderGifChip();
    hideCommandSuggestions();
    nameMenu.classList.add('hidden');
    scheduleActiveHide();
}

function showToast(text) {
    stateToast.textContent = text;
    stateToast.classList.remove('hidden');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => stateToast.classList.add('hidden'), 1800);
}

function insertAtCursor(text) {
    const start = chatInput.selectionStart || chatInput.value.length;
    const end = chatInput.selectionEnd || chatInput.value.length;
    chatInput.value = `${chatInput.value.slice(0, start)}${text}${chatInput.value.slice(end)}`;
    const pos = start + text.length;
    chatInput.setSelectionRange(pos, pos);
    chatInput.focus();
}

function renderEmojiGrid() {
    emojiGrid.innerHTML = '';
    EMOJIS.forEach((emoji) => {
        const button = document.createElement('button');
        button.className = 'emoji-item';
        button.type = 'button';
        button.textContent = emoji;
        button.addEventListener('click', () => insertAtCursor(emoji));
        emojiGrid.appendChild(button);
    });
}

function renderGifResults(results = []) {
    gifResults.innerHTML = '';
    if (!results.length) {
        gifResults.innerHTML = '<div class="content">No GIFs found.</div>';
        return;
    }
    results.forEach((item) => {
        const card = document.createElement('button');
        card.type = 'button';
        card.className = 'gif-card';
        card.innerHTML = `<img src="${item.preview || item.url}" alt="${escapeHtml(item.title || 'GIF')}">`;
        card.addEventListener('click', () => {
            selectedGif = item.url;
            renderGifChip();
            gifPanel.classList.add('hidden');
            chatInput.focus();
        });
        gifResults.appendChild(card);
    });
}

function showHoverCard(target, event) {
    const sourceId = target.dataset.sourceId;
    if (!sourceId) return;
    hoverCard.innerHTML = `
        <div class="hover-card-title">${escapeHtml(target.dataset.author || 'Unknown')}</div>
        <div class="hover-card-line">ID: ${escapeHtml(sourceId)}</div>
        <div class="hover-card-line">Job: ${escapeHtml(target.dataset.job || 'Civilian')}</div>
        <div class="hover-card-line">Duty: ${escapeHtml(target.dataset.state || 'OFF DUTY')}</div>
        <div class="hover-card-line">Time: ${escapeHtml(target.dataset.timestamp || '')}</div>
    `;
    hoverCard.style.left = `${event.clientX + 16}px`;
    hoverCard.style.top = `${event.clientY + 16}px`;
    hoverCard.classList.remove('hidden');
}

function hideHoverCard() {
    hoverCard.classList.add('hidden');
}

function placeNameMenu(event) {
    const menuWidth = 280;
    const menuHeight = 330;
    const x = Math.min(event.clientX + 10, window.innerWidth - menuWidth - 12);
    const y = Math.min(event.clientY + 10, window.innerHeight - menuHeight - 12);
    nameMenu.style.left = `${Math.max(12, x)}px`;
    nameMenu.style.top = `${Math.max(12, y)}px`;
}

function openNameMenuFromTarget(target, event) {
    if (!canModerate) return;
    nameMenuTarget = target && target.id ? { id: String(target.id), author: target.author || 'Player' } : null;
    nameMenuTitle.textContent = nameMenuTarget ? `${nameMenuTarget.author} • ID ${nameMenuTarget.id}` : 'Chat Moderation';
    nameMenuPm.value = '';
    nameMenu.classList.toggle('no-target', !nameMenuTarget);
    placeNameMenu(event);
    nameMenu.classList.remove('hidden');
}

function openNameMenu(button, event) {
    openNameMenuFromTarget({ id: button.dataset.sourceId, author: button.dataset.author || 'Player' }, event);
}

function openNameMenuFromMessage(node, event) {
    if (!node) return;
    const sourceId = node.dataset.sourceId || '';
    const author = node.dataset.author || 'Player';
    if (sourceId) {
        openNameMenuFromTarget({ id: sourceId, author }, event);
    } else {
        openNameMenuFromTarget(null, event);
    }
}

function sendPlayerAction(action, extra = {}) {
    const globalActions = ['purge', 'slowmode', 'slowmodeOff', 'freeze', 'unfreeze', 'blocklastgif'];
    if (!nameMenuTarget && !globalActions.includes(action)) return;
    nui('playerAction', {
        action,
        targetId: nameMenuTarget?.id || '',
        ...extra
    });
    if (action !== 'pm') nameMenu.classList.add('hidden');
}

function closeSocial(clearForm = true) {
    socialModal.classList.add('hidden');
    if (clearForm) socialPostInput.value = '';
}

function closeReports() {
    reportsModal.classList.add('hidden');
}

function networkMeta(network) {
    return network === 'fb'
        ? {
            brand: 'Facebook',
            subtitle: 'Social feed for friends, ads, and community updates',
            leftBrand: 'f',
            signupTitle: 'Join Facebook',
            prefix: '',
            nav: ['Home', 'Watch', 'Friends', 'Memories', 'Profile'],
            trendsTitle: 'Sponsored',
            trends: ['City Event Tonight', 'Best Hidden Trails', 'Weekend Trips'],
            followTitle: 'Contacts',
            follow: ['Dispatch Board', 'Downtown Market', 'Sandy EMS']
        }
        : {
            brand: 'X',
            subtitle: 'For you • Following • in-city social chatter',
            leftBrand: 'X',
            signupTitle: 'Join X',
            prefix: '@',
            nav: ['Home', 'Explore', 'Notifications', 'Messages', 'Profile'],
            trendsTitle: `What's happening`,
            trends: ['#ORP', 'Server Restart', 'Police Activity', 'Mechanic Deals'],
            followTitle: 'Who to follow',
            follow: ['City Hall', 'Fire Dispatch', 'ORP News']
        };
}

function renderSocialSidebars(meta) {
    socialBrand.textContent = meta.brand;
    socialSubtitle.textContent = meta.subtitle;
    socialLeftBrand.textContent = meta.leftBrand;
    socialSignupTitle.textContent = meta.signupTitle;
    socialSignupPrefix.textContent = meta.prefix || '@';
    socialLeftNav.innerHTML = meta.nav.map(item => `<div class="social-nav-item">${escapeHtml(item)}</div>`).join('');
    socialRightTrends.innerHTML = `<div class="modal-title" style="font-size:18px">${escapeHtml(meta.trendsTitle)}</div>${meta.trends.map(v => `<div class="hover-card-line">${escapeHtml(v)}</div>`).join('')}`;
    socialRightFollow.innerHTML = `<div class="modal-title" style="font-size:18px">${escapeHtml(meta.followTitle)}</div>${meta.follow.map(v => `<div class="hover-card-line">${escapeHtml(v)}</div>`).join('')}`;
}

function renderSocialFeed() {
    const network = socialState.network || 'x';
    const meta = networkMeta(network);
    socialModal.classList.toggle('network-fb', network === 'fb');
    socialModal.classList.toggle('network-x', network !== 'fb');
    renderSocialSidebars(meta);
    socialSignup.classList.toggle('hidden', !!socialState.account);
    socialAccountLine.textContent = socialState.account
        ? `${socialState.account.displayName} • ${network === 'fb' ? socialState.account.username : `@${socialState.account.username}`}`
        : 'Not signed up yet';
    socialFeed.innerHTML = '';
    const posts = socialState.posts || [];
    if (!posts.length) {
        socialFeed.innerHTML = '<div class="social-post-card"><div class="social-post-body">No posts yet. Be the first.</div></div>';
        return;
    }
    posts.forEach((post) => {
        const card = document.createElement('div');
        card.className = 'social-post-card';
        card.dataset.postId = post.id;
        const avatarStyle = `style="background:${hashColor(post.username || post.displayName)}"`;
        const handle = network === 'fb' ? post.displayName : `@${post.username}`;
        const comments = Array.isArray(post.comments) ? post.comments : [];
        const canDelete = Number(post.sourceId || 0) === Number(currentPlayerId || 0) || socialState.isAdmin === true;
        card.innerHTML = `
            <div class="social-post-head">
                <div class="social-avatar" ${avatarStyle}>${avatarLetter(post.displayName || post.username)}</div>
                <div style="flex:1">
                    <div class="social-post-name">${escapeHtml(post.displayName || 'Unknown')}</div>
                    <div class="social-post-meta">${escapeHtml(handle)} • ${escapeHtml(post.timestamp || '')}</div>
                    <div class="social-post-body">${escapeHtml(post.text || '')}</div>
                    ${post.isAd ? '<div class="social-post-ad">ADVERTISEMENT</div>' : ''}
                    <div class="social-post-actions">
                        <button type="button" class="social-action-btn" data-post-action="like">♥ ${Number(post.likes || 0)}</button>
                        <button type="button" class="social-action-btn" data-post-action="share">↺ ${Number(post.shares || 0)}</button>
                        <button type="button" class="social-action-btn" data-post-action="comment">💬 ${comments.length}</button>
                        ${canDelete ? '<button type="button" class="social-action-btn" data-post-action="delete">Delete</button>' : ''}
                    </div>
                    <div class="social-comment-row">
                        <input class="social-comment-input" type="text" maxlength="180" placeholder="Reply to this post..." />
                        <button type="button" class="social-action-btn" data-post-action="commentSend">Send</button>
                    </div>
                    <div class="social-comments">${comments.map(comment => `<div class="social-comment"><span class="social-comment-author">${escapeHtml(comment.author || 'Unknown')}</span><span class="social-comment-text">${escapeHtml(comment.text || '')}</span><span class="social-comment-time">${escapeHtml(comment.timestamp || '')}</span></div>`).join('')}</div>
                </div>
            </div>
        `;
        socialFeed.appendChild(card);
    });
}

function openSocial(payload) {
    socialState = {
        network: 'x',
        account: null,
        posts: [],
        isAdmin: false,
        viewerName: '',
        ...(payload || {})
    };
    socialUsername.value = '';
    renderSocialFeed();
    socialModal.classList.remove('hidden');
    requestAnimationFrame(() => socialState.account ? socialPostInput.focus() : socialUsername.focus());
}

function setSocialData(payload) {
    socialState = {
        network: socialState.network || 'x',
        account: null,
        posts: [],
        isAdmin: false,
        viewerName: socialState.viewerName || '',
        ...(payload || {})
    };
    if (!socialModal.classList.contains('hidden') && socialState.network === (payload?.network || socialState.network)) {
        renderSocialFeed();
    }
}

function renderReports() {
    const reports = reportsState.reports || [];
    const selectedId = reportsState.selectedId || (reports[0] && reports[0].id);
    reportsState.selectedId = selectedId;
    reportList.innerHTML = '';
    if (!reports.length) {
        reportList.innerHTML = '<div class="report-item"><div class="report-item-title">No reports yet</div><div class="report-item-meta">Use /report [id] [message]</div></div>';
        reportThreadHeader.textContent = 'No report selected';
        reportThread.innerHTML = '';
        reportReplyRow.classList.add('hidden');
        return;
    }
    reports.forEach((report) => {
        const item = document.createElement('div');
        item.className = `report-item ${report.id === selectedId ? 'active' : ''}`;
        item.innerHTML = `
            <div class="report-item-title">#${report.id} • ${escapeHtml(report.reporterName || 'Reporter')}</div>
            <div class="report-item-meta">Target: ${escapeHtml(report.targetName || 'General')} • ${escapeHtml(report.updatedAt || '')}</div>
        `;
        item.addEventListener('click', () => {
            reportsState.selectedId = report.id;
            renderReports();
        });
        reportList.appendChild(item);
    });
    const current = reports.find(r => r.id === selectedId) || reports[0];
    reportThreadHeader.textContent = `Report #${current.id} • ${current.reporterName} → ${current.targetName}`;
    reportThread.innerHTML = current.messages.map(msg => `
        <div class="report-bubble ${msg.role === 'staff' ? 'staff' : ''}">
            <div class="report-bubble-author">${escapeHtml(msg.author || 'Unknown')}</div>
            <div class="report-bubble-text">${escapeHtml(msg.text || '')}</div>
            <div class="report-bubble-time">${escapeHtml(msg.timestamp || '')}</div>
        </div>
    `).join('');
    reportThread.scrollTop = reportThread.scrollHeight;
    reportReplyRow.classList.remove('hidden');
}

function openReports(payload) {
    reportsState = { ...reportsState, ...(payload || {}) };
    reportsState.selectedId = reportsState.selectedId || (reportsState.reports[0] && reportsState.reports[0].id);
    renderReports();
    reportsModal.classList.remove('hidden');
    requestAnimationFrame(() => reportReplyInput.focus());
}

function setReportsData(payload) {
    reportsState = { ...reportsState, ...(payload || {}) };
    if (!reportsModal.classList.contains('hidden')) renderReports();
}

function renderHelp() {
    const query = (helpSearch.value || '').trim().toLowerCase();
    const roleLine = document.getElementById('help-roleline');
    const heroTitle = document.getElementById('help-hero-title');
    const heroText = document.getElementById('help-hero-text');
    const sectionCount = document.getElementById('help-section-count');

    let sections = Array.isArray(helpState.sections) ? helpState.sections : [];
    const roleLabel = String(helpState.roleLabel || (helpState.isAdmin ? 'admin' : (helpState.canModerate ? 'mod' : 'player'))).toUpperCase();
    if (roleLine) roleLine.textContent = helpState.canModerate ? `Player guide + ${roleLabel} moderation tools.` : 'Player guide, server systems, and common commands.';
    if (sectionCount) sectionCount.textContent = String(sections.length || 0);

    const sectionMatches = (section) => {
        if (!query) return true;
        const haystack = [
            section.title || '',
            section.description || '',
            ...(section.items || []).flatMap((item) => [item.name || '', item.help || '', item.link || ''])
        ].join(' ').toLowerCase();
        return haystack.includes(query);
    };

    sections = sections.filter(sectionMatches);
    if (!sections.length) {
        helpSections.innerHTML = '';
        helpContent.innerHTML = `
            <div class="help-empty">
                <div class="help-empty-icon">🔎</div>
                <strong>No help results</strong>
                <span>Try searching for job, rob, gun, lottery, truck, house, mod, timeout, or chat.</span>
            </div>
        `;
        if (heroTitle) heroTitle.textContent = 'No Results';
        if (heroText) heroText.textContent = 'Try a different search term.';
        return;
    }

    if (!activeHelpSectionId || !sections.some(section => section.id === activeHelpSectionId)) {
        activeHelpSectionId = sections[0].id;
    }

    const activeSection = sections.find(section => section.id === activeHelpSectionId) || sections[0];
    if (heroTitle) heroTitle.textContent = activeSection.title || 'City Help Guide';
    if (heroText) heroText.textContent = activeSection.description || 'Select a section on the left.';

    helpSections.innerHTML = '';
    sections.forEach((section) => {
        const count = Array.isArray(section.items) ? section.items.length : 0;
        const btn = document.createElement('button');
        btn.className = `help-section-btn ${section.id === activeHelpSectionId ? 'active' : ''}`;
        btn.type = 'button';
        btn.innerHTML = `
            <span class="help-section-icon">${escapeHtml(section.icon || '•')}</span>
            <span class="help-section-copy">
                <strong>${escapeHtml(section.title || 'Section')}</strong>
                <em>${count} ${count === 1 ? 'item' : 'items'}</em>
            </span>
        `;
        btn.addEventListener('click', () => {
            activeHelpSectionId = section.id;
            renderHelp();
        });
        helpSections.appendChild(btn);
    });

    const items = (activeSection.items || []).filter((item) => {
        if (!query) return true;
        return [item.name || '', item.help || '', item.link || ''].join(' ').toLowerCase().includes(query);
    });

    helpContent.innerHTML = `
        <div class="help-article-header">
            <div class="help-article-icon">${escapeHtml(activeSection.icon || '📘')}</div>
            <div>
                <div class="help-article-kicker">HELP CATEGORY</div>
                <h3>${escapeHtml(activeSection.title || 'Section')}</h3>
                <p>${escapeHtml(activeSection.description || '')}</p>
            </div>
        </div>
        <div class="help-article-list">
            ${items.map(item => `
                <div class="help-list-item">
                    <span class="help-dot"></span>
                    <div>
                        <strong>${escapeHtml(item.name || '')}</strong>
                        <p>${escapeHtml(item.help || '')}</p>
                        ${renderHelpMeta(item)}
                        ${item.link ? `<span class="help-command-link">${escapeHtml(item.link)}</span>` : ''}
                    </div>
                </div>
            `).join('')}
        </div>
    `;

    if (!items.length) {
        helpContent.querySelector('.help-article-list').innerHTML = `
            <div class="help-empty small">
                <strong>No items in this section match.</strong>
                <span>Try clearing the search box.</span>
            </div>
        `;
    }
}


function renderAdOptions() {
    const categories = Array.isArray(adsState.categories) && adsState.categories.length ? adsState.categories : ['General'];
    adCategory.innerHTML = categories.map((category) => `<option value="${escapeHtml(category)}">${escapeHtml(category)}</option>`).join('');

    const incomingStyles = Array.isArray(adsState.styles) && adsState.styles.length ? adsState.styles : [{ id: 'default', label: 'Citizen' }];
    const seen = new Set();
    const styles = [];
    incomingStyles.forEach((style) => {
        const id = String(style.id || '').toLowerCase();
        if (!id || seen.has(id)) return;
        seen.add(id);
        styles.push({ ...style, id });
    });
    if (!seen.has('auto')) styles.unshift({ id: 'auto', label: 'Auto - Highest Role', badge: 'AUTO' });

    adStyle.innerHTML = styles.map((style) => {
        const badge = style.badge ? ` [${style.badge}]` : '';
        return `<option value="${escapeHtml(style.id)}">${escapeHtml((style.label || style.id) + badge)}</option>`;
    }).join('');
}

function renderAds() {
    renderAdOptions();
    const profile = adsState.profile || {};
    adBusinessName.value = profile.businessName || '';
    adCategory.value = profile.category || 'General';
    adAccent.value = profile.accent || '#c084fc';
    adBanner.value = profile.bannerImage || '';
    adBackground.value = profile.backgroundImage || '';
    const rawStyleId = String(profile.rawStyleId || profile.savedStyleId || 'auto').toLowerCase();
    const resolvedStyleId = String(profile.styleId || profile.autoStyleId || 'default').toLowerCase();
    adStyle.disabled = false;
    adStyle.value = Array.from(adStyle.options).some((option) => option.value === rawStyleId) ? rawStyleId : 'auto';
    const resolved = Array.from(adStyle.options).find((option) => option.value === resolvedStyleId);
    const selected = Array.from(adStyle.options).find((option) => option.value === adStyle.value);
    if (adStyleAuto) {
        if (adStyle.value === 'auto') {
            adStyleAuto.textContent = `Auto mode: chat + ads use highest unlocked role style${resolved ? ` (${resolved.textContent})` : ''}.`;
        } else {
            adStyleAuto.textContent = `Selected cosmetic: ${selected ? selected.textContent : adStyle.value}. Applies to chat + ads; highest role badge still wins.`;
        }
    }

    const ads = Array.isArray(adsState.ads) ? adsState.ads : [];
    if (!ads.length) {
        adsList.innerHTML = '<div class="empty-card">No active ads yet. Be the first business on the board.</div>';
        return;
    }

    adsList.innerHTML = ads.map((ad) => {
        const style = ad.style || {};
        const payload = ad.payload || {};
        const job = ad.job || payload.job || {};
        const vars = styleAttr(style);
        const banner = style.bannerImage ? '<div class="message-banner"></div>' : '';
        return `
            <article class="ad-board-card ${escapeHtml(style.className || '')}" style="${vars}">
                ${banner}
                <div class="ad-board-top">
                    <span>${escapeHtml(ad.category || 'General')}</span>
                    <b>${escapeHtml(ad.businessName || 'City Ad')}</b>
                    <small>${escapeHtml(ad.timestamp || '')}</small>
                </div>
                <div class="ad-board-message">${escapeHtml(ad.message || payload.message || '')}</div>
                <div class="ad-board-foot">${renderAuthorJob(job)}</div>
            </article>
        `;
    }).join('');
}

function openAds(payload) {
    adsState = { ads: [], profile: {}, categories: [], styles: [], isAdmin: false, ...(payload || {}) };
    renderAds();
    adsModal.classList.remove('hidden');
    requestAnimationFrame(() => adMessage.focus());
}

function setAdsData(payload) {
    adsState = { ads: [], profile: {}, categories: [], styles: [], isAdmin: false, ...(payload || {}) };
    if (!adsModal.classList.contains('hidden')) renderAds();
}

function closeAds() {
    adsModal.classList.add('hidden');
}

function openHelp(payload) {
    helpState = { sections: [], isAdmin: false, ...(payload || {}) };
    if (Array.isArray(helpState.commandCatalog)) setCommandRegistry({ items: helpState.commandCatalog, merge: true });
    renderHelp();
    helpModal.classList.remove('hidden');
    requestAnimationFrame(() => helpSearch.focus());
}

function setHelpData(payload) {
    helpState = { sections: [], isAdmin: false, ...(payload || {}) };
    if (Array.isArray(helpState.commandCatalog)) setCommandRegistry({ items: helpState.commandCatalog, merge: true });
    if (!helpModal.classList.contains('hidden')) renderHelp();
}

emojiToggle.addEventListener('click', () => {
    gifPanel.classList.add('hidden');
    emojiPanel.classList.toggle('hidden');
});

gifToggle.addEventListener('click', () => {
    emojiPanel.classList.add('hidden');
    gifPanel.classList.toggle('hidden');
    gifSearchInput.focus();
});

adsToggle.addEventListener('click', () => nui('requestAds', { openWindow: true }));

adsRefresh.addEventListener('click', () => nui('requestAds', { openWindow: false }));
adsClose.addEventListener('click', () => { closeAds(); nui('adsClose'); });

adStyle.addEventListener('change', () => {
    const selected = Array.from(adStyle.options).find((option) => option.value === adStyle.value);
    const profile = adsState.profile || {};
    const resolvedStyleId = String(profile.styleId || profile.autoStyleId || 'default').toLowerCase();
    const resolved = Array.from(adStyle.options).find((option) => option.value === resolvedStyleId);
    if (!adStyleAuto) return;
    if (adStyle.value === 'auto') {
        adStyleAuto.textContent = `Auto mode: chat + ads use highest unlocked role style${resolved ? ` (${resolved.textContent})` : ''}.`;
    } else {
        adStyleAuto.textContent = `Selected cosmetic: ${selected ? selected.textContent : adStyle.value}. Applies to chat + ads; highest role badge still wins.`;
    }


    nui('updateAdProfile', currentAdProfilePayload());
});

function currentAdProfilePayload() {
    return {
        businessName: adBusinessName.value.trim(),
        category: adCategory.value,
        accent: adAccent.value.trim(),
        bannerImage: adBanner.value.trim(),
        backgroundImage: adBackground.value.trim(),
        styleId: adStyle.value
    };
}

adProfileSave.addEventListener('click', () => {
    nui('updateAdProfile', currentAdProfilePayload());
});
adPostBtn.addEventListener('click', () => {
    const message = adMessage.value.trim();
    if (!message) return;
    nui('postAd', { message, profile: currentAdProfilePayload() });
    adMessage.value = '';
});

gifSearchBtn.addEventListener('click', () => {
    const query = gifSearchInput.value.trim();
    if (!query) return;
    gifResults.innerHTML = '<div class="content">Searching...</div>';
    nui('searchGif', { query });
});


const typingElements = [chatInput, gifSearchInput, adMessage, adBusinessName, adAccent, adBanner, adBackground, socialUsername, socialPostInput, reportReplyInput, helpSearch, nameMenuPm].filter(Boolean);
const allowGlobalInputKeys = new Set(['Escape', 'Enter', 'Tab', 'ArrowUp', 'ArrowDown', 'PageUp', 'PageDown']);
typingElements.forEach((element) => {
    ['keydown', 'keyup', 'keypress'].forEach((type) => {
        element.addEventListener(type, (event) => {
            if (!allowGlobalInputKeys.has(event.key)) {
                event.stopPropagation();
            }
        });
    });
});

gifSearchInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
        event.preventDefault();
        gifSearchBtn.click();
    }
});

chatInput.addEventListener('input', () => {
    syncChatModeFromInput();
    commandSuggestionIndex = 0;
    renderCommandSuggestions();
});

socialRefresh.addEventListener('click', () => nui('requestSocial', { network: socialState.network || 'x', openWindow: false }));
socialClose.addEventListener('click', () => { closeSocial(false); nui('socialClose'); });
socialSignupBtn.addEventListener('click', () => {
    nui('socialSignup', { network: socialState.network || 'x', username: socialUsername.value.trim() });
});
socialPrimaryPost.addEventListener('click', () => socialPostInput.focus());
socialPostBtn.addEventListener('click', () => {
    nui('socialPost', { network: socialState.network || 'x', text: socialPostInput.value.trim(), isAd: socialIsAd.checked });
    socialPostInput.value = '';
    socialIsAd.checked = false;
});

reportsRefresh.addEventListener('click', () => nui('requestReports', { openWindow: false }));
reportsClose.addEventListener('click', () => { closeReports(); nui('reportsClose'); });
reportReplySend.addEventListener('click', () => {
    if (!reportsState.selectedId || !reportReplyInput.value.trim()) return;
    nui('replyReport', { reportId: reportsState.selectedId, message: reportReplyInput.value.trim() });
    reportReplyInput.value = '';
});


helpRefresh.addEventListener('click', () => nui('requestHelp', { openWindow: false }));
helpClose.addEventListener('click', () => { helpModal.classList.add('hidden'); nui('helpClose'); });
helpSearch.addEventListener('input', renderHelp);

if (commandSuggestions) {
    commandSuggestions.addEventListener('mousedown', (event) => {
        event.preventDefault();
        const button = event.target.closest('[data-command]');
        if (!button) return;
        applyCommandSuggestion(button.dataset.command);
    });
}

nameMenu.addEventListener('click', (event) => {
    const button = event.target.closest('[data-menu-action]');
    if (!button) return;
    const action = button.dataset.menuAction;
    if (action === 'copyId') {
        if (nameMenuTarget?.id) {
            navigator.clipboard?.writeText(String(nameMenuTarget.id));
            showToast(`Copied ID ${nameMenuTarget.id}`);
        }
        nameMenu.classList.add('hidden');
        return;
    }
    if (action === 'warn') return sendPlayerAction('warn', { reason: 'Chat moderation warning' });
    if (action === 'timeout') return sendPlayerAction('timeout', { minutes: 10, reason: 'Chat timeout' });
    if (action === 'timeout30') return sendPlayerAction('timeout', { minutes: 30, reason: 'Chat timeout' });
    if (action === 'mute') return sendPlayerAction('mute', { reason: 'Chat mute' });
    if (action === 'unmute') return sendPlayerAction('unmute', {});
    if (action === 'purge') return sendPlayerAction('purge', {});
    if (action === 'slow10') return sendPlayerAction('slowmode', { seconds: 10 });
    if (action === 'slow30') return sendPlayerAction('slowmode', { seconds: 30 });
    if (action === 'slowOff') return sendPlayerAction('slowmodeOff', {});
    if (action === 'freeze') return sendPlayerAction('freeze', {});
    if (action === 'unfreeze') return sendPlayerAction('unfreeze', {});
});

nameMenuPmSend.addEventListener('click', () => {
    const text = nameMenuPm.value.trim();
    if (!text) return;
    sendPlayerAction('pm', { message: text });
    nameMenu.classList.add('hidden');
});

messageList.addEventListener('click', (event) => {
    const btn = event.target.closest('.author-btn');
    if (!btn) return;
    openNameMenu(btn, event);
});

messageList.addEventListener('contextmenu', (event) => {
    const node = event.target.closest('.message');
    if (!node || !canModerate) return;
    event.preventDefault();
    event.stopPropagation();
    openNameMenuFromMessage(node, event);
});

messageList.addEventListener('mouseover', (event) => {
    const node = event.target.closest('.message');
    if (node) showHoverCard(node, event);
});

messageList.addEventListener('mousemove', (event) => {
    const node = event.target.closest('.message');
    if (node && !hoverCard.classList.contains('hidden')) {
        hoverCard.style.left = `${event.clientX + 16}px`;
        hoverCard.style.top = `${event.clientY + 16}px`;
    }
});

messageList.addEventListener('mouseout', (event) => {
    if (!event.relatedTarget || !event.relatedTarget.closest('.message')) hideHoverCard();
});

document.addEventListener('click', (event) => {
    if (!nameMenu.contains(event.target) && !event.target.closest('.author-btn')) {
        nameMenu.classList.add('hidden');
    }
});

socialFeed.addEventListener('click', (event) => {
    const button = event.target.closest('[data-post-action]');
    if (!button) return;
    const card = button.closest('.social-post-card');
    if (!card) return;
    const postId = card.dataset.postId;
    const action = button.dataset.postAction;
    if (action === 'comment') {
        card.querySelector('.social-comment-input')?.focus();
        return;
    }
    if (action === 'commentSend') {
        const input = card.querySelector('.social-comment-input');
        const text = input?.value?.trim() || '';
        if (!text) return;
        nui('socialAction', { network: socialState.network || 'x', action: 'comment', postId, text });
        input.value = '';
        return;
    }
    nui('socialAction', { network: socialState.network || 'x', action, postId });
});

[socialFeed, reportList, reportThread, helpContent, adsList].forEach((el) => {
    el.addEventListener('wheel', (event) => {
        event.stopPropagation();
        el.scrollTop += event.deltaY;
    }, { passive: true });
});

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') return openInput();
    if (data.action === 'close') return closeInput();
    if (data.action === 'addMessage') return addMessage(data.payload || {});
    if (data.action === 'updateCountdown') return updateCountdown(data.payload || {});
    if (data.action === 'clear') return clearMessages();
    if (data.action === 'removeMessage') {
        const target = messageList.querySelector(`[data-message-id="${data.messageId}"]`);
        if (target) target.remove();
        return;
    }
    if (data.action === 'gifResults') return renderGifResults(data.results || []);
    if (data.action === 'moderationNotice') return showModerationNotice(data.payload || {});
    if (data.action === 'setIdentity') {
        const identity = data.identity || {};
        currentPlayerId = Number(identity.playerId || 0);
        playerLine.textContent = `${identity.player || 'Citizen'} [${identity.playerId || 0}]`;
        jobBadge.innerHTML = renderJobBadge(identity.job || {});
        hintLine.textContent = identity.hint || 'T = chat • Enter = send • Esc = close • ; = visibility';
        setChatModes(identity.chatModes);
        chatInput.placeholder = identity.placeholder || activeChatMode().placeholder || 'Type to chat locally...';
        updateChatModeBadge();
        setTheme(identity.theme, identity.layout);
        modeBadge.textContent = identity.mode || modeBadge.textContent;
        isAdmin = identity.isAdmin === true;
        canModerate = identity.canModerate === true || isAdmin;
        if (identity.moderation) moderationState = { ...moderationState, ...identity.moderation };
        emojiToggle.style.display = identity.integrations?.emoji ? 'inline-flex' : 'none';
        gifToggle.style.display = identity.integrations?.gifs ? 'inline-flex' : 'none';
        return;
    }
    if (data.action === 'setAdminState') {
        if (typeof data.state === 'boolean') {
            isAdmin = data.state === true;
            canModerate = isAdmin;
        } else {
            const state = data.state || {};
            isAdmin = state.isAdmin === true;
            canModerate = state.canModerate === true || isAdmin;
            moderationState = { ...moderationState, ...state };
        }
        return;
    }
    if (data.action === 'setVisibilityMode') return setVisibilityMode(data.mode || 1);
    if (data.action === 'stateToast') return showToast(data.text || 'Chat updated');
    if (data.action === 'openAds') return openAds(data.payload || {});
    if (data.action === 'setAdsData') return setAdsData(data.payload || {});
    if (data.action === 'openSocial') return openSocial(data.payload || {});
    if (data.action === 'setSocialData') return setSocialData(data.payload || {});
    if (data.action === 'openReports') return openReports(data.payload || {});
    if (data.action === 'setReportsData') return setReportsData(data.payload || {});
    if (data.action === 'openHelp') return openHelp(data.payload || {});
    if (data.action === 'setHelpData') return setHelpData(data.payload || {});
    if (data.action === 'setCommandRegistry') return setCommandRegistry(data.payload || {});
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        event.preventDefault();
        if (!socialModal.classList.contains('hidden')) {
            closeSocial(false);
            nui('socialClose');
            return;
        }
        if (!reportsModal.classList.contains('hidden')) {
            closeReports();
            nui('reportsClose');
            return;
        }
        if (!helpModal.classList.contains('hidden')) {
            helpModal.classList.add('hidden');
            nui('helpClose');
            return;
        }
        if (!adsModal.classList.contains('hidden')) {
            closeAds();
            nui('adsClose');
            return;
        }
        nui('close');
        return;
    }
    if (event.target === chatInput && commandSuggestionsVisible()) {
        if (event.key === 'ArrowDown') {
            event.preventDefault();
            moveCommandSuggestion(1);
            return;
        }
        if (event.key === 'ArrowUp') {
            event.preventDefault();
            moveCommandSuggestion(-1);
            return;
        }
        if (event.key === 'Tab') {
            event.preventDefault();
            acceptSelectedCommandSuggestion();
            return;
        }
    }
    if (event.key === 'Tab' && chatOpen && event.target === chatInput) {
        event.preventDefault();
        cycleChatMode(event.shiftKey ? -1 : 1);
        return;
    }
    if (event.key === 'ArrowUp' && event.target === chatInput) {
        event.preventDefault();
        if (sentHistory.length > 0) {
            historyIndex = Math.max(0, historyIndex - 1);
            chatInput.value = sentHistory[historyIndex] || '';
            requestAnimationFrame(() => chatInput.setSelectionRange(chatInput.value.length, chatInput.value.length));
        }
        return;
    }
    if (event.key === 'ArrowDown' && event.target === chatInput) {
        event.preventDefault();
        if (sentHistory.length > 0) {
            historyIndex = Math.min(sentHistory.length, historyIndex + 1);
            chatInput.value = historyIndex >= sentHistory.length ? '' : (sentHistory[historyIndex] || '');
            requestAnimationFrame(() => chatInput.setSelectionRange(chatInput.value.length, chatInput.value.length));
        }
        return;
    }
    if (event.key === 'PageUp' && chatOpen) {
        event.preventDefault();
        messageList.scrollTop -= 140;
        return;
    }
    if (event.key === 'PageDown' && chatOpen) {
        event.preventDefault();
        messageList.scrollTop += 140;
        return;
    }
    if (event.key === 'Enter' && event.target === chatInput) {
        event.preventDefault();
        const outgoing = chatInput.value.trim();
        if (outgoing !== '') {
            sentHistory.push(outgoing);
            if (sentHistory.length > 50) sentHistory.shift();
            historyIndex = sentHistory.length;
        }
        nui('submit', { text: chatInput.value, gifUrl: selectedGif, mode: activeChatMode().command || 'l' });
        return;
    }
    if (event.key === 'Enter' && event.target === adMessage && (event.ctrlKey || event.metaKey)) {
        event.preventDefault();
        adPostBtn.click();
        return;
    }
    if (event.key === 'Enter' && event.target === socialPostInput && (event.ctrlKey || event.metaKey)) {
        event.preventDefault();
        socialPostBtn.click();
        return;
    }
    if (event.key === 'Enter' && event.target === socialUsername) {
        event.preventDefault();
        socialSignupBtn.click();
        return;
    }
    if (event.key === 'Enter' && event.target.classList?.contains('social-comment-input')) {
        event.preventDefault();
        event.target.closest('.social-post-card')?.querySelector('[data-post-action="commentSend"]')?.click();
        return;
    }
    if (event.key === 'Enter' && event.target === reportReplyInput) {
        event.preventDefault();
        reportReplySend.click();
        return;
    }
    if (event.key === 'Enter' && event.target === nameMenuPm) {
        event.preventDefault();
        nameMenuPmSend.click();
    }
});

window.addEventListener('wheel', (event) => {
    if (!chatOpen) return;
    messageList.scrollTop += event.deltaY;
});

window.addEventListener('load', () => {
    renderEmojiGrid();
    renderGifChip();
    nui('ready');
});
