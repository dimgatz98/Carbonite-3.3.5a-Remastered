
-- ============================================================================
-- CustomWaypoints - Phase 5B (patched UI + safer deep fallback)
--
-- PURPOSE
--   This addon extends Carbonite with:
--   - custom waypoint capture from the displayed Carbonite map
--   - a waypoint queue
--   - route sync into Carbonite
--   - a prototype intercontinental routing layer
--   - auto-advance when the player reaches the current waypoint
--
-- IMPORTANT ARCHITECTURAL NOTE
--   Carbonite remains the rendering / map / HUD / travel-guidance layer.
--   This addon adds a custom capture / queue / sync layer and, when needed,
--   builds explicit intermediate route nodes to feed into Carbonite.
--
-- NOTES ABOUT THIS PATCH
--   - safer /cw UI with visible background and extra toggle buttons
--   - UI is created lazily (only when opened) to reduce Carbonite-side UI risk
--   - deep mode keeps current behavior, but cross-continent graph no-path now
--     falls back to an explicit direct destination target instead of failing
--     the whole rebuild
--   - simplified routing still does not use flight masters
-- ============================================================================

local tinsert = table.insert
local tremove = table.remove
local wipe = wipe
local format = string.format
local gsub = string.gsub
local sqrt = math.sqrt
local huge = math.huge
local lower = string.lower
local match = string.match
local band = bit.band

CustomWaypoints = CustomWaypoints or {}
local CW = CustomWaypoints

local TARGET_TYPE_GOTO = "Goto"
local TARGET_TYPE_STRAIGHT = "CW_STRAIGHT"

local STRAIGHT_EDGE_TYPES = {
    boat = true,
    zeppelin = true,
    tram = true,
    portal = true,
    transport = true,
    taxi = true,
}

local TRANSIT_EDGE_TYPES = {
    boat = true,
    zeppelin = true,
    tram = true,
    portal = true,
    taxi = true,
}

local DEFAULTS = {
    destinations = {},
    bindingModifier = "SHIFT",
    bindingButton = "LeftButton",
    fallbackModifier = "CTRL",
    fallbackButton = "RightButton",
    reachDistanceYards = 10,
    debug = false,
    autoSyncToCarbonite = true,
    autoAdvance = true,
    walkYardsPerSecond = 7,
    useIntercontinentalRouting = true,
    useFlightMasters = true,
    hasFlyingMount = false,
    simplifyTransitWaypoints = true,
    showUi = true,
    uiScale = 1,
}

local STATE = {
    db = nil,
    frame = nil,
    hookInstalled = false,
    clearHookInstalled = false,
    lastPulse = 0,
    syncing = false,
    graph = nil,
    expandedRoute = nil,
    suppressClearUntil = 0,
    travelHookInstalled = false,
    originalTravelMap = nil,
    history = {},
    future = {},
    ui = nil,
    uiLog = {},
    maxUiLog = 400,
    outputRecursing = false,
    sclGuardInstalled = false,
    originalSCL = nil,
    bindingsInstalled = false,
    interfacePanel = nil,
    interfaceChecks = nil,
    uiSpecialRegistered = false,
    needLoginQueueSync = false,
    -- Skip auto-advance for a few seconds after capture so nearby clicks / bad coords don't instantly pop.
    lastCaptureTime = 0,
}

local InvalidateRoute
local ClearCarboniteTargets
local SyncQueueToCarbonite
local SlashHandler
local InstallCarboniteSclGuard
local EnsureInterfaceOptionsPanel
local InstallUndoRedoBindings

-- Lua 5.1: closures in InstallUndoRedoBindings must capture these locals, not a later global.
local UndoHistory, RedoHistory
-- EnsureUi Import button closes over this local (WoW Lua resolves nested refs like globals otherwise).
local ImportWaypointsFromText

-- Lexical: must be above InstallUndoRedoBindings if that helper ever calls GetMap at install time.
local function GetMap()
    if not Nx or not Nx.Map or not Nx.Map.GeM then return nil end
    return Nx.Map:GeM(1)
end

local EDGE_COLORS = {
    walk = "|cffffffff",
    connector = "|cffc0c0c0",
    walklink = "|cffc0c0c0",
    boat = "|cff66ccff",
    zeppelin = "|cffff9933",
    tram = "|cffcc66ff",
    portal = "|cff66ffcc",
    transport = "|cffffff66",
    taxi = "|cffffdd55",
    flying = "|cff88ff88",
}

local function ColorizeEdgeName(edgeType, textLabel)
    local color = EDGE_COLORS[edgeType or ""] or "|cffdddddd"
    return color .. tostring(textLabel or edgeType or "route") .. "|r"
end

local function BuildLegendText()
    return ""
end

-- Grow log EditBox with content; optionally scroll frame to bottom and move caret to end (addon log lines).
local function ResizeLogOutputEditor(scrollToEnd)
    local ui = STATE.ui
    if not ui or not ui.output or not ui.scroll then return end
    local edit, scroll = ui.output, ui.scroll
    local text = edit:GetText() or ""
    local _, fh = edit:GetFont()
    if not fh or fh < 8 then fh = 14 end
    local _, n = string.gsub(text, "\n", "\n")
    local lines = n + 1
    local viewH = scroll:GetHeight() or 200
    local minH = math.max(viewH, lines * fh + fh * 2)
    edit:SetHeight(minH)
    if scroll.UpdateScrollChildRect then
        pcall(function() scroll:UpdateScrollChildRect() end)
    end
    if scrollToEnd and scroll.GetVerticalScrollRange and scroll.SetVerticalScroll then
        local ok, range = pcall(function() return scroll:GetVerticalScrollRange() end)
        if ok and type(range) == "number" and range >= 0 then
            pcall(function() scroll:SetVerticalScroll(range) end)
        end
        local len = string.len(text)
        if edit.SetCursorPosition then
            pcall(function() edit:SetCursorPosition(len) end)
        end
    end
end

local function AppendUiLogLine(line)
    if STATE.outputRecursing then return end
    local log = STATE.uiLog
    log[#log + 1] = tostring(line)
    local maxLines = STATE.maxUiLog or 400
    while #log > maxLines do
        tremove(log, 1)
    end

    if STATE.ui and STATE.ui.output then
        STATE.outputRecursing = true
        STATE.ui.output:SetText(table.concat(log, "\n"))
        ResizeLogOutputEditor(true)
        STATE.outputRecursing = false
    end
end

local function RefreshUiHeader()
    local db = STATE.db or {}
    if STATE.ui and STATE.ui.header then
        STATE.ui.header:SetText(string.format(
            "CW options | autosync=%s autoadvance=%s flying=%s deep=%s flightmasters=%s",
            tostring(db.autoSyncToCarbonite),
            tostring(db.autoAdvance),
            tostring(db.hasFlyingMount),
            tostring(not db.simplifyTransitWaypoints),
            tostring(db.useFlightMasters)
        ))
        if STATE.ui.legend then
            STATE.ui.legend:Hide()
        end
        if STATE.ui.checks then
            if STATE.ui.checks.flying and STATE.ui.checks.flying.SetChecked then STATE.ui.checks.flying:SetChecked(db.hasFlyingMount and true or false) end
            if STATE.ui.checks.autosync and STATE.ui.checks.autosync.SetChecked then STATE.ui.checks.autosync:SetChecked(db.autoSyncToCarbonite and true or false) end
            if STATE.ui.checks.autoadvance and STATE.ui.checks.autoadvance.SetChecked then STATE.ui.checks.autoadvance:SetChecked(db.autoAdvance and true or false) end
            if STATE.ui.checks.flightmasters and STATE.ui.checks.flightmasters.SetChecked then STATE.ui.checks.flightmasters:SetChecked(db.useFlightMasters and true or false) end
            if STATE.ui.checks.deep and STATE.ui.checks.deep.SetChecked then STATE.ui.checks.deep:SetChecked((not db.simplifyTransitWaypoints) and true or false) end
        end
    end
    if STATE.interfaceChecks then
        if STATE.interfaceChecks.flying and STATE.interfaceChecks.flying.SetChecked then STATE.interfaceChecks.flying:SetChecked(db.hasFlyingMount and true or false) end
        if STATE.interfaceChecks.autosync and STATE.interfaceChecks.autosync.SetChecked then STATE.interfaceChecks.autosync:SetChecked(db.autoSyncToCarbonite and true or false) end
        if STATE.interfaceChecks.autoadvance and STATE.interfaceChecks.autoadvance.SetChecked then STATE.interfaceChecks.autoadvance:SetChecked(db.autoAdvance and true or false) end
        if STATE.interfaceChecks.flightmasters and STATE.interfaceChecks.flightmasters.SetChecked then STATE.interfaceChecks.flightmasters:SetChecked(db.useFlightMasters and true or false) end
        if STATE.interfaceChecks.deep and STATE.interfaceChecks.deep.SetChecked then STATE.interfaceChecks.deep:SetChecked((not db.simplifyTransitWaypoints) and true or false) end
        if STATE.interfaceChecks.debug and STATE.interfaceChecks.debug.SetChecked then STATE.interfaceChecks.debug:SetChecked(db.debug and true or false) end
    end
end

local function EnsureUi()
    if STATE.ui and STATE.ui.frame then
        RefreshUiHeader()
        return STATE.ui
    end

    local f = CreateFrame("Frame", "CustomWaypointsMainFrame", UIParent)
    f:SetWidth(760)
    f:SetHeight(508)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetScale((STATE.db and STATE.db.uiScale) or 1)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetScript("OnShow", function(self)
        if self.EnableKeyboard then self:EnableKeyboard(true) end
    end)
    f:SetScript("OnHide", function(self)
        if self.EnableKeyboard then self:EnableKeyboard(false) end
    end)
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            if self.EnableKeyboard then self:EnableKeyboard(false) end
        end
    end)
    if UISpecialFrames and not STATE.uiSpecialRegistered then
        tinsert(UISpecialFrames, "CustomWaypointsMainFrame")
        STATE.uiSpecialRegistered = true
    end

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetTexture(0, 0, 0, 0.78)

    local borderTop = f:CreateTexture(nil, "BORDER")
    borderTop:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetTexture(1, 1, 1, 0.20)

    local borderBottom = f:CreateTexture(nil, "BORDER")
    borderBottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetTexture(1, 1, 1, 0.20)

    local borderLeft = f:CreateTexture(nil, "BORDER")
    borderLeft:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    borderLeft:SetWidth(1)
    borderLeft:SetTexture(1, 1, 1, 0.20)

    local borderRight = f:CreateTexture(nil, "BORDER")
    borderRight:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    borderRight:SetWidth(1)
    borderRight:SetTexture(1, 1, 1, 0.20)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)
    title:SetText("CustomWaypoints")

    local header = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    header:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    header:SetWidth(720)
    header:SetJustifyH("LEFT")


    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        f:Hide()
    end)

    local function MakeButton(textLabel, x, y, command)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetWidth(78)
        b:SetHeight(22)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
        b:SetText(textLabel)
        b:SetScript("OnClick", function()
            SlashHandler(command)
            RefreshUiHeader()
        end)
        return b
    end

    MakeButton("Help",     12, -72,  "help")
    MakeButton("Sync",     94, -72,  "sync")
    MakeButton("Route",   176, -72,  "route")
    MakeButton("Graph",   258, -72,  "graph")
    MakeButton("List",    340, -72,  "list")
    MakeButton("Undo",    422, -72,  "undo")
    MakeButton("Redo",    504, -72,  "redo")
    MakeButton("Clear",   586, -72,  "clear")
    MakeButton("Pop",     668, -72,  "pop")

    MakeButton("Probe",    12, -98,  "probe")
    MakeButton("Export",   94, -98,  "export")
    local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    importBtn:SetWidth(78)
    importBtn:SetHeight(22)
    importBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 176, -98)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        local box = STATE.ui and STATE.ui.importBox
        if box then
            box:ClearFocus()
        end
        local raw = box and box:GetText()
        ImportWaypointsFromText(raw ~= nil and tostring(raw) or "")
        RefreshUiHeader()
    end)

    local function MakeCheckbox(textLabel, x, y, onClick)
        local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
        local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", cb, "RIGHT", 2, 1)
        fs:SetText(textLabel)
        cb:SetHitRectInsets(0, -80, 0, 0)
        cb:SetScript("OnClick", function(self)
            onClick(self)
            RefreshUiHeader()
        end)
        return cb
    end

    local checks = {}
    checks.flying = MakeCheckbox("Flying", 270, -98, function() SlashHandler("hasflying") end)
    checks.autosync = MakeCheckbox("AutoSync", 370, -98, function() SlashHandler("autosync") end)
    checks.autoadvance = MakeCheckbox("AutoAdvance", 490, -98, function() SlashHandler("autoadvance") end)
    checks.flightmasters = MakeCheckbox("FlightMasters", 620, -98, function() SlashHandler("flightmasters") end)
    checks.deep = MakeCheckbox("Deep", 270, -122, function(self)
        if self:GetChecked() then SlashHandler("deep") else SlashHandler("minimal") end
    end)

    local commands = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    commands:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -142)
    commands:SetWidth(720)
    commands:SetJustifyH("LEFT")
    commands:SetText("\n/cw help | ui | options | probe | add | list | export | import | sync | route | graph | clear | pop | undo | redo | autosync | autoadvance | hasflying | flightmasters | deep | minimal | debug | simplify | legend")

    local importLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    importLabel:SetPoint("TOPLEFT", commands, "BOTTOMLEFT", 0, -6)
    importLabel:SetText("Import — paste lines from export (markers optional), then click Import:")

    local importBox = CreateFrame("EditBox", "CustomWaypointsImportBox", f)
    importBox:SetMultiLine(true)
    importBox:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -4)
    importBox:SetSize(686, 86)
    importBox:SetFontObject(GameFontHighlightSmall)
    importBox:SetAutoFocus(false)
    importBox:EnableMouse(true)
    if importBox.EnableKeyboard then importBox:EnableKeyboard(true) end
    importBox:SetTextInsets(4, 4, 4, 4)
    importBox:SetJustifyH("LEFT")
    if importBox.SetMaxLetters then importBox:SetMaxLetters(16384) end
    importBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local ibg = importBox:CreateTexture(nil, "BACKGROUND")
    ibg:SetTexture(0.08, 0.08, 0.1, 0.9)
    ibg:SetPoint("TOPLEFT", -3, 3)
    ibg:SetPoint("BOTTOMRIGHT", 3, -3)

    local scroll = CreateFrame("ScrollFrame", "CustomWaypointsScrollFrame", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -266)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 12)

    local output = CreateFrame("EditBox", "CustomWaypointsScrollChild", scroll)
    output:SetMultiLine(true)
    output:SetAutoFocus(false)
    output:EnableMouse(true)
    -- Allow typing notes, selection, Ctrl+C copy when focused (chat log still refreshed by addon).
    if output.EnableKeyboard then output:EnableKeyboard(true) end
    output:SetFontObject(ChatFontNormal)
    output:SetWidth(690)
    output:SetHeight(200)
    output:SetJustifyH("LEFT")
    if output.SetMaxLetters then output:SetMaxLetters(120000) end
    output:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    output:SetScript("OnTextChanged", function(self)
        if STATE.outputRecursing then
            local parent = self:GetParent()
            if parent and parent.UpdateScrollChildRect then
                pcall(function() parent:UpdateScrollChildRect() end)
            end
            return
        end
        -- Typing / paste: expand height; keep scroll position (addon path uses outputRecursing + ResizeLogOutputEditor(true)).
        ResizeLogOutputEditor(false)
    end)
    scroll:SetScrollChild(output)

    STATE.ui = {
        frame = f,
        title = title,
        header = header,
        scroll = scroll,
        output = output,
        commands = commands,
        importBox = importBox,
        checks = checks,
    }

    RefreshUiHeader()
    AppendUiLogLine("CW UI ready. Undo steps back add/clear/pop (snapshot stack). Redo: /cw redo or Ctrl+Shift+Y if unbound.")
    f:Hide()
    return STATE.ui
end

local function EnsureInterfaceOptionsPanel()
    if STATE.interfacePanel then
        RefreshUiHeader()
        return STATE.interfacePanel
    end
    if not InterfaceOptions_AddCategory then return nil end

    local panel = CreateFrame("Frame", "CWPhase5BInterfaceOptions", UIParent)
    panel.name = "CustomWaypoints"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("CustomWaypoints")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetWidth(500)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetJustifyV("TOP")
    if subtitle.SetNonSpaceWrap then subtitle:SetNonSpaceWrap(true) end
    subtitle:SetText("Deep routing + flight masters (defaults). Undo/redo = step through queue history\n (add/clear/pop). /cw undo | redo; Ctrl+Shift+Z | Y if free. Escape closes.")

    local function MakePanelCheckbox(textLabel, x, y, onClick)
        local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
        local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", cb, "RIGHT", 2, 1)
        fs:SetText(textLabel)
        cb:SetHitRectInsets(0, -200, 0, 0)
        cb:SetScript("OnClick", function(self)
            onClick(self)
            RefreshUiHeader()
        end)
        return cb
    end

    local checks = {}
    checks.autosync = MakePanelCheckbox("Auto sync to Carbonite", 16, -70, function() SlashHandler("autosync") end)
    checks.autoadvance = MakePanelCheckbox("Auto advance on reach", 16, -100, function() SlashHandler("autoadvance") end)
    checks.flying = MakePanelCheckbox("Has flying mount", 16, -130, function() SlashHandler("hasflying") end)
    checks.flightmasters = MakePanelCheckbox("Use flight masters in deep mode", 16, -160, function() SlashHandler("flightmasters") end)
    checks.deep = MakePanelCheckbox("Deep routing mode", 16, -190, function(self)
        if self:GetChecked() then SlashHandler("deep") else SlashHandler("minimal") end
    end)
    checks.debug = MakePanelCheckbox("Debug chat/log output", 16, -220, function() SlashHandler("debug") end)

    local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openBtn:SetWidth(160)
    openBtn:SetHeight(24)
    openBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -275)
    openBtn:SetText("Open CW Window")
    openBtn:SetScript("OnClick", function()
        if SlashCmdList and SlashCmdList.CUSTOMWAYPOINTS then
            SlashCmdList.CUSTOMWAYPOINTS("ui")
        end
    end)

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -12)
    note:SetWidth(500)
    note:SetJustifyH("LEFT")
    note:SetJustifyV("TOP")
    if note.SetNonSpaceWrap then note:SetNonSpaceWrap(true) end
    note:SetText("This panel controls CustomWaypoints planning, sync, \ndeep/minimal routing, flight-master usage, and flying-mount behavior.")

    InterfaceOptions_AddCategory(panel)
    STATE.interfacePanel = panel
    STATE.interfaceChecks = checks
    RefreshUiHeader()
    return panel
end

local function InstallUndoRedoBindings()
    if STATE.bindingsInstalled then return end

    if not _G.CWPhase5BUndoHotkeyButton then
        local b = CreateFrame("Button", "CWPhase5BUndoHotkeyButton", UIParent)
        b:SetScript("OnClick", function()
            UndoHistory()
        end)
        b:Hide()
    end
    if not _G.CWPhase5BRedoHotkeyButton then
        local b = CreateFrame("Button", "CWPhase5BRedoHotkeyButton", UIParent)
        b:SetScript("OnClick", function()
            RedoHistory()
        end)
        b:Hide()
    end

    local undoClick = "CLICK CWPhase5BUndoHotkeyButton:LeftButton"
    local redoClick = "CLICK CWPhase5BRedoHotkeyButton:LeftButton"
    local bindChanged = false

    local function CanAssignKey(key, boundTo)
        if not GetBindingAction then return true end
        local a = GetBindingAction(key)
        return (not a or a == "" or a == boundTo)
    end

    if CanAssignKey("CTRL-SHIFT-Z", undoClick) then
        if SetBindingClick then
            SetBindingClick("CTRL-SHIFT-Z", "CWPhase5BUndoHotkeyButton", "LeftButton")
            bindChanged = true
        elseif SetBinding then
            SetBinding("CTRL-SHIFT-Z", undoClick)
            bindChanged = true
        end
    end

    if CanAssignKey("CTRL-SHIFT-Y", redoClick) then
        if SetBindingClick then
            SetBindingClick("CTRL-SHIFT-Y", "CWPhase5BRedoHotkeyButton", "LeftButton")
            bindChanged = true
        elseif SetBinding then
            SetBinding("CTRL-SHIFT-Y", redoClick)
            bindChanged = true
        end
    end

    if bindChanged and SaveBindings and GetCurrentBindingSet then
        pcall(SaveBindings, GetCurrentBindingSet())
    end

    STATE.bindingsInstalled = true
end

local function ToggleUi()
    EnsureUi()
    if STATE.ui.frame:IsShown() then
        STATE.ui.frame:Hide()
    else
        RefreshUiHeader()
        STATE.ui.frame:Show()
    end
end

local function pr(msg)
    local line = "CWPhase5B: " .. tostring(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff80ff80CWPhase5B:|r " .. tostring(msg))
    AppendUiLogLine(line)
end

local function dbg(msg)
    if STATE.db and STATE.db.debug == true then
        pr(msg)
    end
end

local function CoerceSavedBoolean(v, defaultVal)
    if v == true or v == 1 then return true end
    if v == false or v == 0 then return false end
    if type(v) == "string" then
        local s = lower(v:gsub("^%s+", ""):gsub("%s+$", ""))
        if s == "true" or s == "1" or s == "yes" or s == "on" then return true end
        if s == "false" or s == "0" or s == "no" or s == "off" or s == "" then return false end
    end
    if v == nil then return defaultVal end
    return defaultVal
end

local function EnsureDb()
    CustomWaypointsDB = CustomWaypointsDB or {}
    STATE.db = CustomWaypointsDB
    for k, v in pairs(DEFAULTS) do
        if STATE.db[k] == nil then
            if type(v) == "table" then
                STATE.db[k] = {}
            else
                STATE.db[k] = v
            end
        end
    end
    STATE.db.destinations = STATE.db.destinations or {}
    STATE.db.debug = CoerceSavedBoolean(STATE.db.debug, DEFAULTS.debug)
end

local function Dist(wx1, wy1, wx2, wy2)
    local dx = wx1 - wx2
    local dy = wy1 - wy2
    return sqrt(dx * dx + dy * dy)
end

local function WorldToYards(d)
    return d * 4.575
end

local function WalkCostSeconds(wx1, wy1, wx2, wy2)
    local yardsPerSecond = (STATE.db and STATE.db.walkYardsPerSecond) or 7
    if yardsPerSecond <= 0 then yardsPerSecond = 7 end
    return WorldToYards(Dist(wx1, wy1, wx2, wy2)) / yardsPerSecond
end

local function IsModifierDown(name)
    name = name or "SHIFT"
    if name == "SHIFT" then return IsShiftKeyDown() end
    if name == "CTRL" then return IsControlKeyDown() end
    if name == "ALT" then return IsAltKeyDown() end
    return false
end

local function GetContinentId(map, maI)
    if not map or not maI or not map.ITCZ then return nil end
    local ok, co = pcall(map.ITCZ, map, maI)
    if ok then return co end
    return nil
end

local function GetDisplayedCapture(map)
    map = map or GetMap()
    if not map then return nil, "no-map" end
    if not map.GCMI or not map.FPTWP or not map.GZP then
        return nil, "missing-carbonite-methods"
    end

    if map.CaC3 then
        pcall(map.CaC3, map)
    end

    if not map.CFX or not map.CFY or map.CFX == -1 or map.CFY == -1 then
        return nil, "no-cursor"
    end

    local mx, my = map.CFX, map.CFY

    if map.Frm then
        local fw = map.Frm:GetWidth() or 0
        local fh = map.Frm:GetHeight() or 0
        if fw > 0 then
            if mx < 0 then mx = 0 elseif mx > fw then mx = fw end
        end
        if fh > 0 then
            if my < 0 then my = 0 elseif my > fh then my = fh end
        end
    end

    local maI = map:GCMI()
    if not maI or maI <= 0 then
        return nil, "bad-gcmi"
    end

    local wx, wy = map:FPTWP(mx, my)
    if not wx or not wy then
        return nil, "bad-fptwp"
    end

    local zx, zy = map:GZP(maI, wx, wy)
    local name = map.ITN and map:ITN(maI) or ("Map " .. tostring(maI))

    return {
        maI = maI,
        wx = wx,
        wy = wy,
        zx = zx,
        zy = zy,
        mapName = name,
        ts = date("%Y-%m-%d %H:%M:%S"),
    }
end

local function GetPlayerWorldPos()
    local map = GetMap()
    if not map or not Nx or not Nx.Map or not Nx.Map.CZ2I then return nil end

    local oldCont = GetCurrentMapContinent and GetCurrentMapContinent() or nil
    local oldZone = GetCurrentMapZone and GetCurrentMapZone() or nil

    SetMapToCurrentZone()
    local continent = GetCurrentMapContinent()
    local zone = GetCurrentMapZone()
    if not continent or continent <= 0 or not zone or zone <= 0 then
        return nil
    end
    if not Nx.Map.CZ2I[continent] then
        return nil
    end

    local maI = Nx.Map.CZ2I[continent][zone]
    if not maI then return nil end

    local px, py = GetPlayerMapPosition("player")

    if oldCont and oldZone and SetMapZoom then
        pcall(SetMapZoom, oldCont, oldZone)
    end
    if not px or not py then return nil end
    -- WoW returns (0,0) when the current map has no valid player position (loading, wrong map, some interiors).
    -- Using that for distance checks makes AutoAdvance think we're "on top of" arbitrary waypoints.
    if px == 0 and py == 0 then return nil end

    local wx, wy = map:GWP(maI, px * 100, py * 100)
    return {
        maI = maI,
        wx = wx,
        wy = wy,
        zx = px * 100,
        zy = py * 100,
        mapName = map.ITN and map:ITN(maI) or ("Map " .. tostring(maI)),
        continent = GetContinentId(map, maI),
    }
end

local function SanitizeCarboniteLabel(s)
    if not s then return "" end
    s = tostring(s)
    s = s:gsub("[%%%^%$%(%)%.%[%]%*%+%-%?]", " ")
    s = s:gsub("%s+", " ")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    return s
end

local function UseStraightLineForEdge(edgeType)
    return edgeType and STRAIGHT_EDGE_TYPES[edgeType] or false
end

local function GetTargetTypeForRoutePoint(pt)
    if not pt then
        return TARGET_TYPE_GOTO
    end

    if pt.forceStraight then
        return TARGET_TYPE_STRAIGHT
    end

    if STATE.db and not STATE.db.simplifyTransitWaypoints then
        return TARGET_TYPE_STRAIGHT
    end

    if UseStraightLineForEdge(pt.edgeType) then
        return TARGET_TYPE_STRAIGHT
    end

    if STATE.db and STATE.db.hasFlyingMount then
        if pt.edgeType == "walk" or pt.edgeType == "connector" or pt.edgeType == "walklink" or pt.edgeType == "transport-to-goal" or pt.edgeType == "walk-to-transport" or pt.edgeType == "goal-to-node" then
            return TARGET_TYPE_STRAIGHT
        end

        if pt.isQueueStop then
            return TARGET_TYPE_STRAIGHT
        end
    end

    return TARGET_TYPE_GOTO
end

local function BuildSyncLabel(idx, pt)
    local mapName = pt.mapName or ("Map " .. tostring(pt.maI))
    local edgeType = pt.edgeType or "node"
    local detail

    if edgeType == "walk-to-transport" then
        detail = "Walk to transport"
    elseif edgeType == "transport-to-goal" then
        detail = "Walk to destination"
    elseif edgeType == "walk" then
        detail = "Walk"
    elseif edgeType == "connector" or edgeType == "walklink" then
        detail = "Passage"
    elseif edgeType == "tram" then
        detail = "Tram"
    elseif edgeType == "zeppelin" then
        detail = "Zeppelin"
    elseif edgeType == "boat" then
        detail = "Boat"
    elseif edgeType == "portal" then
        detail = "Portal"
    elseif edgeType == "transport" then
        detail = "Transport"
    elseif edgeType == "taxi" then
        detail = "Flight Master"
    elseif edgeType == "fallback" then
        detail = "Fallback"
    else
        detail = tostring(pt.label or edgeType)
    end

    return SanitizeCarboniteLabel(format("%d %s - %s", idx, mapName, detail))
end


local function InstallCarboniteSclGuard()
    if not Nx or not Nx.Map or type(Nx.Map.SCL) ~= "function" then return end

    local function SafeSCL(self, frm, lvl, seen)
        if not frm then return end
        lvl = lvl or 1
        if lvl > 120 then return end

        seen = seen or {}
        if seen[frm] then return end
        seen[frm] = true

        local ok, children = pcall(function()
            return { frm:GetChildren() }
        end)
        if not ok or type(children) ~= "table" then return end

        for _, chf in ipairs(children) do
            if chf and not seen[chf] then
                if chf.SetFrameLevel then
                    pcall(chf.SetFrameLevel, chf, lvl)
                end
                local okKids, nKids = pcall(function() return chf.GetNumChildren and chf:GetNumChildren() or 0 end)
                if okKids and nKids and nKids > 0 then
                    SafeSCL(self, chf, lvl + 1, seen)
                end
            end
        end
    end

    if not STATE.originalSCL then
        STATE.originalSCL = Nx.Map.SCL
    end
    Nx.Map.SCL = SafeSCL
    local map = GetMap()
    if map then
        map.SCL = SafeSCL
    end

    STATE.sclGuardInstalled = true
end

local function InstallCarboniteTravelHook()
    if STATE.travelHookInstalled then return end
    if not Nx or not Nx.Tra or type(Nx.Tra.MaP) ~= "function" then return end

    STATE.originalTravelMap = Nx.Tra.MaP
    Nx.Tra.MaP = function(self, tra2, sMI, srX, srY, dMI, dsX, dsY, taT1)
        if taT1 == TARGET_TYPE_STRAIGHT then
            return
        end
        return STATE.originalTravelMap(self, tra2, sMI, srX, srY, dMI, dsX, dsY, taT1)
    end

    STATE.travelHookInstalled = true
    dbg("Carbonite travel expansion hook installed")
end

local function CloneDestinations(src)
    local out = {}
    for i, dest in ipairs(src or {}) do
        out[i] = {}
        for k, v in pairs(dest) do
            out[i][k] = v
        end
    end
    return out
end

local function PushHistorySnapshot(reason)
    STATE.history = STATE.history or {}
    STATE.future = STATE.future or {}
    STATE.history[#STATE.history + 1] = {
        reason = reason or "snapshot",
        destinations = CloneDestinations(STATE.db and STATE.db.destinations or {}),
    }
    while #STATE.history > 100 do
        tremove(STATE.history, 1)
    end
    wipe(STATE.future)
end

local function RestoreSnapshot(snapshot, reason)
    if not snapshot or not STATE.db then return false end
    STATE.db.destinations = CloneDestinations(snapshot.destinations or {})
    InvalidateRoute(reason or snapshot.reason or "snapshot-restored")
    if STATE.db.autoSyncToCarbonite then
        SyncQueueToCarbonite()
    else
        ClearCarboniteTargets()
    end
    return true
end

-- Undo / redo use the same snapshot stack as add / clear / pop:
-- each action calls PushHistorySnapshot *before* changing destinations, so undo = restore previous queue.
UndoHistory = function()
    if not STATE.db then return end
    local hist = STATE.history or {}
    if #hist == 0 then
        -- After /reload, snapshots are gone but SavedVariables may still have a queue.
        -- First "nothing to undo" with a non-empty queue = clear all stops (redo can restore).
        local d = STATE.db.destinations
        if #(d or {}) == 0 then
            pr("undo: nothing to undo")
            return
        end
        STATE.future = STATE.future or {}
        STATE.future[#STATE.future + 1] = {
            reason = "redo-after-reload-clear",
            destinations = CloneDestinations(d),
        }
        wipe(d)
        InvalidateRoute("undo-fallback-clear-no-history")
        if STATE.db.autoSyncToCarbonite then
            SyncQueueToCarbonite()
        else
            ClearCarboniteTargets()
        end
        pr("undo: cleared queue (no session history — e.g. after /reload); use redo to restore")
        RefreshUiHeader()
        return
    end
    STATE.future = STATE.future or {}
    STATE.future[#STATE.future + 1] = {
        reason = "redo",
        destinations = CloneDestinations(STATE.db.destinations),
    }
    local snapshot = tremove(hist)
    RestoreSnapshot(snapshot, "undo")
    pr(format("undo: restored queue (%d stop(s))", #(STATE.db.destinations or {})))
    RefreshUiHeader()
end

RedoHistory = function()
    if not STATE.db then return end
    local fut = STATE.future or {}
    if #fut == 0 then
        pr("redo: nothing to redo")
        return
    end
    STATE.history = STATE.history or {}
    STATE.history[#STATE.history + 1] = {
        reason = "undo-after-redo",
        destinations = CloneDestinations(STATE.db.destinations),
    }
    local snapshot = tremove(fut)
    RestoreSnapshot(snapshot, "redo")
    pr(format("redo: restored queue (%d stop(s))", #(STATE.db.destinations or {})))
    RefreshUiHeader()
end

ClearCarboniteTargets = function(map)
    map = map or GetMap()
    if not map then return end

    STATE.suppressClearUntil = (GetTime() or 0) + 0.75

    STATE.syncing = true
    if map.ClT1 then
        map:ClT1()
    else
        map.Tar = {}
        map.Tra1 = {}
    end
    STATE.syncing = false

    if map.GOp then
        map.GOp["MapRouteUse"] = true
    end
end

InvalidateRoute = function(reason)
    STATE.expandedRoute = nil
    STATE.graph = nil
    if reason then
        dbg("route invalidated: " .. tostring(reason))
    end
end

local function InferTransportType(name1, name2)
    local s = lower((name1 or "") .. " " .. (name2 or ""))
    if match(s, "zeppelin") then return "zeppelin" end
    if match(s, "boat") then return "boat" end
    if match(s, "tram") then return "tram" end
    if match(s, "portal") then return "portal" end
    return "transport"
end

local function TransportCostSeconds(transportType, wx1, wy1, wx2, wy2)
    local travel = WalkCostSeconds(wx1, wy1, wx2, wy2)
    if transportType == "portal" then
        return 8
    elseif transportType == "tram" then
        return 45 + travel * 0.2
    elseif transportType == "zeppelin" then
        return 75 + travel * 0.2
    elseif transportType == "boat" then
        return 90 + travel * 0.2
    end
    return 60 + travel * 0.3
end

local function IsRealTransportType(edgeType)
    return edgeType and STRAIGHT_EDGE_TYPES[edgeType] or false
end

local function IsTransitEdgeType(edgeType)
    return edgeType and TRANSIT_EDGE_TYPES[edgeType] or false
end

local function InferConnectorEdgeType(coT, name1, name2)
    if coT == 1 then
        return "connector"
    end
    return InferTransportType(name1, name2)
end

local function ConnectorCostSeconds(edgeType, wx1, wy1, wx2, wy2)
    if edgeType == "connector" then
        return WalkCostSeconds(wx1, wy1, wx2, wy2)
    end
    return TransportCostSeconds(edgeType, wx1, wy1, wx2, wy2)
end

local function NormalizeTaxiKey(name)
    if not name then return nil end
    name = tostring(name)
    name = gsub(name, "^%s+", "")
    name = gsub(name, "%s+$", "")
    return lower(name)
end

local function BuildKnownTaxiLookup()
    if not NxCData or type(NxCData["Taxi"]) ~= "table" then return {} end
    local out = {}
    for taxiName, known in pairs(NxCData["Taxi"]) do
        if known then
            out[NormalizeTaxiKey(taxiName)] = taxiName
        end
    end
    return out
end

local function BuildKnownTaxiNodes(map)
    if not (STATE.db and STATE.db.useFlightMasters) then return {} end
    if STATE.db and STATE.db.simplifyTransitWaypoints then return {} end
    if not Nx or not Nx.Tra or not Nx.Map or not Nx.Map.Gui or type(Nx.Map.Gui.FiT2) ~= "function" then
        return {}
    end

    local knownLookup = BuildKnownTaxiLookup()
    if not next(knownLookup) then return {} end

    local out = {}
    local seen = {}

    local function addKnownTaxi(name)
        local key = NormalizeTaxiKey(name)
        if not key or not knownLookup[key] or seen[key] then return end
        local npcName, wx, wy = Nx.Map.Gui:FiT2(knownLookup[key])
        if not (wx and wy) then return end

        local bestMapId, bestZX, bestZY, bestDist2 = nil, nil, nil, nil
        for maI = 1, 5000 do
            local ok, zx, zy = pcall(map.GZP, map, maI, wx, wy)
            if ok and zx and zy and zx >= 0 and zx <= 100 and zy >= 0 and zy <= 100 then
                local dx = zx - 50
                local dy = zy - 50
                local dist2 = dx * dx + dy * dy
                if not bestDist2 or dist2 < bestDist2 then
                    bestMapId, bestZX, bestZY, bestDist2 = maI, zx, zy, dist2
                end
            end
        end

        if bestMapId then
            seen[key] = true
            out[#out + 1] = {
                taxiName = knownLookup[key],
                npcName = npcName or knownLookup[key],
                maI = bestMapId,
                wx = wx,
                wy = wy,
                zx = bestZX,
                zy = bestZY,
            }
        end
    end

    if type(Nx.Tra.Tra) == "table" then
        for _, list in pairs(Nx.Tra.Tra) do
            if type(list) == "table" then
                for _, nod in ipairs(list) do
                    if type(nod) == "table" and nod.LoN then
                        addKnownTaxi(nod.LoN)
                    end
                end
            end
        end
    end

    for taxiName in pairs(knownLookup) do
        addKnownTaxi(taxiName)
    end

    return out
end

local function EnsureGraph()
    if STATE.graph then return STATE.graph end

    local map = GetMap()
    if not map or not Nx or not Nx.ZoC then
        return nil, "carbonite-data-not-ready"
    end

    local graph = {
        nodes = {},
        links = {},
        nodeCount = 0,
        edgeCount = 0,
    }

    local nodeIndex = {}

    local function makeNodeKey(maI, wx, wy, nodeType, label)
        return table.concat({ tostring(maI or "?"), format("%.3f", wx or 0), format("%.3f", wy or 0), tostring(nodeType or "?"), tostring(label or "") }, "|")
    end

    local function addNode(maI, wx, wy, label, nodeType)
        local key = makeNodeKey(maI, wx, wy, nodeType, label)
        if nodeIndex[key] then
            return nodeIndex[key]
        end

        graph.nodeCount = graph.nodeCount + 1
        local id = graph.nodeCount
        graph.nodes[id] = {
            id = id,
            maI = maI,
            wx = wx,
            wy = wy,
            label = label,
            type = nodeType,
            continent = GetContinentId(map, maI),
            edges = {},
        }
        nodeIndex[key] = id
        return id
    end

    local function addEdge(a, b, cost, edgeType, label, bidirectional)
        if not graph.nodes[a] or not graph.nodes[b] then return end
        tinsert(graph.nodes[a].edges, {
            to = b,
            cost = cost,
            type = edgeType,
            label = label,
        })
        graph.edgeCount = graph.edgeCount + 1
        if bidirectional then
            tinsert(graph.nodes[b].edges, {
                to = a,
                cost = cost,
                type = edgeType,
                label = label,
            })
            graph.edgeCount = graph.edgeCount + 1
        end
    end

    local function addPassageEdgesFromMWI()
        if not map.MWI then return end
        for maI, win1 in pairs(map.MWI) do
            if type(win1) == "table" and type(win1.Con1) == "table" then
                for destMaI, zco1 in pairs(win1.Con1) do
                    if type(zco1) == "table" then
                        for _, con in ipairs(zco1) do
                            if type(con) == "table" and con.StX and con.StY and con.EnX and con.EnY then
                                local fromName = map.ITN and map:ITN(con.SMI or maI) or tostring(con.SMI or maI)
                                local toName = map.ITN and map:ITN(con.EMI1 or destMaI) or tostring(con.EMI1 or destMaI)
                                local n1 = addNode(con.SMI or maI, con.StX, con.StY, fromName, "connector")
                                local n2 = addNode(con.EMI1 or destMaI, con.EnX, con.EnY, toName, "connector")
                                addEdge(n1, n2, con.Dis or WalkCostSeconds(con.StX, con.StY, con.EnX, con.EnY), "connector", format("Passage: %s -> %s", tostring(fromName), tostring(toName)), true)
                                graph.links[#graph.links + 1] = { a = n1, b = n2, type = "connector" }
                            end
                        end
                    end
                end
            end
        end
    end

    addPassageEdgesFromMWI()

    for _, str in ipairs(Nx.ZoC) do
        local fla, coT, mI1, x1, y1, mI2, x2, y2, na11, na21 = map:CoU(str)
        if mI1 and mI2 and x1 and y1 and x2 and y2 and x1 ~= 0 and y1 ~= 0 and x2 ~= 0 and y2 ~= 0 then
            local wx1, wy1 = map:GWP(mI1, x1, y1)
            local wx2, wy2 = map:GWP(mI2, x2, y2)
            local edgeType = InferConnectorEdgeType(coT, na11, na21)
            local fromName = (na11 and na11 ~= "") and na11 or (map.ITN and map:ITN(mI1) or tostring(mI1))
            local toName = (na21 and na21 ~= "") and na21 or (map.ITN and map:ITN(mI2) or tostring(mI2))
            local n1 = addNode(mI1, wx1, wy1, fromName, edgeType == "connector" and "connector" or "transport")
            local n2 = addNode(mI2, wx2, wy2, toName, edgeType == "connector" and "connector" or "transport")
            local bidi = band(fla or 0, 1) == 1
            local edgeLabel
            if edgeType == "connector" then
                edgeLabel = format("Walk connection: %s -> %s", tostring(map.ITN and map:ITN(mI1) or mI1), tostring(map.ITN and map:ITN(mI2) or mI2))
            else
                edgeLabel = (edgeType:gsub("^%l", string.upper)) .. ": " .. tostring(map.ITN and map:ITN(mI1) or mI1) .. " -> " .. tostring(map.ITN and map:ITN(mI2) or mI2)
            end
            addEdge(n1, n2, ConnectorCostSeconds(edgeType, wx1, wy1, wx2, wy2), edgeType, edgeLabel, bidi)
            graph.links[#graph.links + 1] = {a = n1, b = n2, type = edgeType}
        end
    end

    local taxiNodes = BuildKnownTaxiNodes(map)
    local taxiNodeIds = {}
    if #taxiNodes > 1 and Nx and Nx.Tra and type(Nx.Tra.TFCT) == "function" then
        for _, taxi in ipairs(taxiNodes) do
            local nodeId = addNode(taxi.maI, taxi.wx, taxi.wy, taxi.taxiName, "transport")
            taxiNodeIds[#taxiNodeIds + 1] = { id = nodeId, taxiName = taxi.taxiName, npcName = taxi.npcName, maI = taxi.maI, wx = taxi.wx, wy = taxi.wy }
        end

        for i = 1, #taxiNodeIds do
            local a = taxiNodeIds[i]
            for j = 1, #taxiNodeIds do
                if i ~= j then
                    local b = taxiNodeIds[j]
                    local ok, directCost = pcall(Nx.Tra.TFCT, Nx.Tra, a.taxiName, b.taxiName)
                    if ok and directCost and directCost > 0 then
                        addEdge(a.id, b.id, directCost, "taxi", format("Flight Master: %s -> %s", tostring(a.taxiName), tostring(b.taxiName)), false)
                        graph.links[#graph.links + 1] = {a = a.id, b = b.id, type = "taxi"}
                    end
                end
            end
        end
    end

    local walkRadius = 325
    local walkNeighbors = 3
    local forcedWalkPenalty = 900
    local function IsTravelNodeType(t)
        return t == "connector" or t == "transport"
    end
    for i = 1, graph.nodeCount do
        local ni = graph.nodes[i]
        local sameMap = {}
        for j = 1, graph.nodeCount do
            if i ~= j then
                local nj = graph.nodes[j]
                if ni.maI == nj.maI then
                    local baseCost = WalkCostSeconds(ni.wx, ni.wy, nj.wx, nj.wy)
                    if baseCost <= walkRadius then
                        sameMap[#sameMap + 1] = { id = j, cost = baseCost, forced = false }
                    elseif IsTravelNodeType(ni.type) and IsTravelNodeType(nj.type) then
                        sameMap[#sameMap + 1] = { id = j, cost = baseCost + forcedWalkPenalty, forced = true }
                    end
                end
            end
        end
        table.sort(sameMap, function(a, b) return a.cost < b.cost end)
        local added = 0
        local forcedAdded = 0
        for _, cand in ipairs(sameMap) do
            if not cand.forced then
                if added < walkNeighbors then
                    addEdge(i, cand.id, cand.cost, "walk", "walk", false)
                    added = added + 1
                end
            elseif added == 0 and forcedAdded < 1 then
                addEdge(i, cand.id, cand.cost, "walk", "walk-penalized", false)
                forcedAdded = forcedAdded + 1
            end
        end
    end

    STATE.graph = graph
    return graph
end

local function HeuristicCost(a, b)
    return 0
end

local function FindPathAStar(nodes, startId, goalId)
    local open = {[startId] = true}
    local openList = {startId}
    local came = {}
    local cameEdge = {}
    local gScore = {[startId] = 0}
    local fScore = {[startId] = HeuristicCost(nodes[startId], nodes[goalId])}
    local explored = 0

    while #openList > 0 do
        local bestIndex, current, bestF = 1, openList[1], fScore[openList[1]] or huge
        for i = 2, #openList do
            local nid = openList[i]
            local f = fScore[nid] or huge
            if f < bestF then
                bestIndex, current, bestF = i, nid, f
            end
        end

        tremove(openList, bestIndex)
        open[current] = nil
        explored = explored + 1

        if current == goalId then
            local path = {current}
            while came[current] do
                current = came[current]
                tinsert(path, 1, current)
            end
            return path, cameEdge, gScore[goalId] or 0, explored
        end

        local node = nodes[current]
        if node and node.edges then
            for _, edge in ipairs(node.edges) do
                local tentative = (gScore[current] or huge) + (edge.cost or huge)
                if tentative < (gScore[edge.to] or huge) then
                    came[edge.to] = current
                    cameEdge[edge.to] = edge
                    gScore[edge.to] = tentative
                    fScore[edge.to] = tentative + HeuristicCost(nodes[edge.to], nodes[goalId])
                    if not open[edge.to] then
                        open[edge.to] = true
                        tinsert(openList, edge.to)
                    end
                end
            end
        end
    end

    return nil, nil, nil, explored
end

local function BuildTransportLeg(startPoint, destPoint)
    local baseGraph, why = EnsureGraph()
    if not baseGraph then
        return nil, "graph-unavailable:" .. tostring(why)
    end

    local nodes = {}
    for id, n in pairs(baseGraph.nodes) do
        local copyEdges = {}
        for _, e in ipairs(n.edges) do
            copyEdges[#copyEdges + 1] = {to = e.to, cost = e.cost, type = e.type, label = e.label}
        end
        nodes[id] = {
            id = n.id,
            maI = n.maI,
            wx = n.wx,
            wy = n.wy,
            label = n.label,
            type = n.type,
            continent = n.continent,
            edges = copyEdges,
        }
    end

    local nextId = baseGraph.nodeCount

    local function addQueryNode(pt, nodeType, label)
        nextId = nextId + 1
        nodes[nextId] = {
            id = nextId,
            maI = pt.maI,
            wx = pt.wx,
            wy = pt.wy,
            label = label,
            type = nodeType,
            continent = GetContinentId(GetMap(), pt.maI),
            edges = {},
        }
        return nextId
    end

    local function connectBidirectional(a, b, cost, edgeType, label)
        tinsert(nodes[a].edges, {to = b, cost = cost, type = edgeType, label = label})
        tinsert(nodes[b].edges, {to = a, cost = cost, type = edgeType, label = label})
    end

    local function attachQueryNode(queryId, preferMapId, preferContinent, outwardLabel)
        local sameMap = {}
        local sameContinent = {}
        for id, n in pairs(nodes) do
            if id ~= queryId then
                local d = WalkCostSeconds(nodes[queryId].wx, nodes[queryId].wy, n.wx, n.wy)
                if n.maI == preferMapId then
                    sameMap[#sameMap + 1] = {id = id, cost = d, type = n.type}
                elseif n.continent and preferContinent and n.continent == preferContinent and n.type == "connector" then
                    sameContinent[#sameContinent + 1] = {id = id, cost = d + 600, type = n.type}
                end
            end
        end

        table.sort(sameMap, function(a, b) return a.cost < b.cost end)
        table.sort(sameContinent, function(a, b) return a.cost < b.cost end)

        local attached = 0
        local limit = 16
        local radius = 1800
        local used = {}

        local function attachCandidate(candidate)
            if not candidate or used[candidate.id] or attached >= limit then return end
            connectBidirectional(queryId, candidate.id, candidate.cost, "walk", outwardLabel)
            used[candidate.id] = true
            attached = attached + 1
        end

        for i = 1, #sameMap do
            if sameMap[i].cost <= radius then
                attachCandidate(sameMap[i])
                if attached >= limit then return attached end
            end
        end

        if attached == 0 then
            for i = 1, math.min(8, #sameMap) do
                attachCandidate(sameMap[i])
                if attached >= limit then return attached end
            end
        end

        for i = 1, math.min(8, #sameContinent) do
            attachCandidate(sameContinent[i])
            if attached >= limit then return attached end
        end

        if attached == 0 then
            for i = 1, math.min(16, #sameMap) do
                attachCandidate(sameMap[i])
                if attached >= limit then return attached end
            end
        end

        return attached
    end

    local startId = addQueryNode(startPoint, "start", "start")
    local goalId = addQueryNode(destPoint, "goal", "goal")

    attachQueryNode(startId, startPoint.maI, nodes[startId].continent, "walk-to-node")
    attachQueryNode(goalId, destPoint.maI, nodes[goalId].continent, "node-to-goal")

    local path, cameEdge, totalCost, explored = FindPathAStar(nodes, startId, goalId)
    if not path then
        return nil, format("no-path explored=%d", explored or -1)
    end

    local route = {
        totalCost = totalCost,
        explored = explored,
        transportUsed = false,
        points = {},
    }

    local map = GetMap()
    for idx = 1, #path do
        local nodeId = path[idx]
        local n = nodes[nodeId]
        local edge = idx > 1 and cameEdge[nodeId] or nil
        if edge and IsRealTransportType(edge.type) then
            route.transportUsed = true
        end
        local zx, zy = map:GZP(n.maI, n.wx, n.wy)
        tinsert(route.points, {
            maI = n.maI,
            wx = n.wx,
            wy = n.wy,
            zx = zx,
            zy = zy,
            mapName = map.ITN and map:ITN(n.maI) or ("Map " .. tostring(n.maI)),
            edgeType = edge and edge.type or "start",
            label = edge and edge.label or n.label or n.type,
            cost = edge and edge.cost or 0,
        })
    end

    return route
end

local function BuildDirectFallbackLeg(startPoint, destPoint, why, crossContinent)
    local directCost = WalkCostSeconds(startPoint.wx, startPoint.wy, destPoint.wx, destPoint.wy)
    dbg("using explicit fallback target: " .. tostring(why))
    return {
        totalCost = directCost,
        explored = 1,
        fallbackDirect = true,
        points = {
            {
                maI = startPoint.maI,
                wx = startPoint.wx,
                wy = startPoint.wy,
                zx = startPoint.zx,
                zy = startPoint.zy,
                mapName = startPoint.mapName,
                edgeType = "start",
                label = "Start",
                cost = 0,
            },
            {
                maI = destPoint.maI,
                wx = destPoint.wx,
                wy = destPoint.wy,
                zx = destPoint.zx,
                zy = destPoint.zy,
                mapName = destPoint.mapName,
                edgeType = crossContinent and "fallback" or "walk",
                label = crossContinent and "Cross-continent fallback" or "Direct destination",
                cost = directCost,
                forceStraight = true,
            }
        },
    }
end

local function BuildRouteLeg(startPoint, destPoint)
    if not startPoint or not destPoint then
        return nil, "missing-leg-endpoint"
    end

    local map = GetMap()
    if not map then return nil, "no-map" end

    if startPoint.maI == destPoint.maI then
        local directCost = WalkCostSeconds(startPoint.wx, startPoint.wy, destPoint.wx, destPoint.wy)
        return {
            totalCost = directCost,
            explored = 1,
            points = {
                {
                    maI = startPoint.maI,
                    wx = startPoint.wx,
                    wy = startPoint.wy,
                    zx = startPoint.zx,
                    zy = startPoint.zy,
                    mapName = startPoint.mapName,
                    edgeType = "start",
                    label = "Start",
                    cost = 0,
                },
                {
                    maI = destPoint.maI,
                    wx = destPoint.wx,
                    wy = destPoint.wy,
                    zx = destPoint.zx,
                    zy = destPoint.zy,
                    mapName = destPoint.mapName,
                    edgeType = "walk",
                    label = "Walk",
                    cost = directCost,
                }
            },
        }
    end

    if STATE.db and STATE.db.useIntercontinentalRouting then
        local route, why = BuildTransportLeg(startPoint, destPoint)
        if route then
            return route
        end

        local startCont = startPoint.continent or GetContinentId(map, startPoint.maI)
        local destCont = destPoint.continent or GetContinentId(map, destPoint.maI)
        local crossContinent = startCont and destCont and startCont ~= destCont

        if crossContinent then
            return BuildDirectFallbackLeg(startPoint, destPoint, why, true)
        end

        if STATE.db and not STATE.db.simplifyTransitWaypoints then
            return nil, "deep-graph-failed:" .. tostring(why)
        end

        dbg("graph leg fallback to direct walk: " .. tostring(why))
    end

    local directCost = WalkCostSeconds(startPoint.wx, startPoint.wy, destPoint.wx, destPoint.wy)
    return {
        totalCost = directCost,
        explored = 1,
        fallbackDirect = startPoint.maI ~= destPoint.maI,
        points = {
            {
                maI = startPoint.maI,
                wx = startPoint.wx,
                wy = startPoint.wy,
                zx = startPoint.zx,
                zy = startPoint.zy,
                mapName = startPoint.mapName,
                edgeType = "start",
                label = "Start",
                cost = 0,
            },
            {
                maI = destPoint.maI,
                wx = destPoint.wx,
                wy = destPoint.wy,
                zx = destPoint.zx,
                zy = destPoint.zy,
                mapName = destPoint.mapName,
                edgeType = "walk",
                label = startPoint.maI ~= destPoint.maI and "Direct destination" or "Walk",
                cost = directCost,
                forceStraight = startPoint.maI ~= destPoint.maI,
            }
        },
    }
end

local function BuildExpandedRoute()
    local map = GetMap()
    if not map then return nil, "no-map" end

    if #STATE.db.destinations == 0 then
        STATE.expandedRoute = nil
        return {points = {}, summary = "empty"}
    end

    local current = GetPlayerWorldPos()
    if not current then return nil, "no-player-pos" end

    local route = {
        totalCost = 0,
        explored = 0,
        points = {},
    }

    for q = 1, #STATE.db.destinations do
        local dest = STATE.db.destinations[q]
        local leg, why = BuildRouteLeg(current, dest)
        if not leg then
            return nil, format("leg %d failed: %s", q, tostring(why))
        end

        route.totalCost = route.totalCost + (leg.totalCost or 0)
        route.explored = route.explored + (leg.explored or 0)

        for i, pt in ipairs(leg.points or {}) do
            if not (q > 1 and i == 1) then
                local copy = {}
                for k, v in pairs(pt) do
                    copy[k] = v
                end

                if i == #leg.points then
                    copy.isQueueStop = true
                    copy.queueIndex = q
                end

                tinsert(route.points, copy)
            end
        end

        current = dest
    end

    STATE.expandedRoute = route
    return route
end

local function IsSyncAnchorPoint(routePoints, idx)
    local pt = routePoints[idx]
    if not pt or pt.edgeType == "start" then return false end

    local nextPt = routePoints[idx + 1]

    if idx == #routePoints then return true end
    if pt.isQueueStop then return true end
    if pt.forceStraight then return true end

    if IsTransitEdgeType(pt.edgeType) then return true end
    if nextPt and IsTransitEdgeType(nextPt.edgeType) then return true end

    return false
end

local function ShouldKeepRoutePointForSync(routePoints, idx)
    local pt = routePoints[idx]
    if not pt or pt.edgeType == "start" then return false end

    local prev = routePoints[idx - 1]
    local nextPt = routePoints[idx + 1]

    if not STATE.db or not STATE.db.simplifyTransitWaypoints then
        return true
    end

    return IsSyncAnchorPoint(routePoints, idx)
end

local function CollapseConsecutiveSyncPoints(points)
    local out = {}
    for _, pt in ipairs(points or {}) do
        local prev = out[#out]
        local keep = true
        if prev and prev.maI == pt.maI then
            local d = Dist(prev.wx or 0, prev.wy or 0, pt.wx or 0, pt.wy or 0)
            if d < 3 then
                keep = false
            elseif prev.edgeType == pt.edgeType and d < 2 then
                keep = false
            end
        end
        if keep then
            out[#out + 1] = pt
        end
    end
    return out
end

local function BuildSyncPoints(routePoints)
    local out = {}
    for i = 1, #(routePoints or {}) do
        if ShouldKeepRoutePointForSync(routePoints, i) then
            out[#out + 1] = routePoints[i]
        end
    end
    return CollapseConsecutiveSyncPoints(out)
end

SyncQueueToCarbonite = function()
    local map = GetMap()
    if not map then
        pr("sync failed: Carbonite map not ready")
        return false
    end

    local route, why = BuildExpandedRoute()
    if not route then
        pr("route rebuild failed: " .. tostring(why))
        return false
    end

    InstallCarboniteTravelHook()
    ClearCarboniteTargets(map)

    local syncPoints = BuildSyncPoints(route.points or {})
    local synced = 0
    STATE.syncing = true
    for i, pt in ipairs(syncPoints) do
        local ok, err = pcall(function()
            local label = BuildSyncLabel(i, pt)
            local targetType = GetTargetTypeForRoutePoint(pt)
            map:SeT3(targetType, pt.wx, pt.wy, pt.wx, pt.wy, nil, nil, label, true, pt.maI)
        end)
        if ok then
            synced = synced + 1
        else
            dbg("sync point failed: " .. tostring(err))
        end
    end
    STATE.syncing = false
    STATE.suppressClearUntil = (GetTime() or 0) + 0.75

    if synced == 0 then
        dbg("sync skipped: no route points")
        return true
    end

    dbg(format("synced %d expanded route node(s) into Carbonite", synced))
    return true
end

local function AddCurrentCursorWaypoint()
    local map = GetMap()
    local dest, why = GetDisplayedCapture(map)
    if not dest then
        pr("capture failed: " .. tostring(why))
        return
    end

    PushHistorySnapshot("add-waypoint")
    STATE.lastCaptureTime = GetTime() or 0
    tinsert(STATE.db.destinations, dest)
    dbg(format("saved #%d => GCMI=%d (%s) zx=%.1f zy=%.1f wx=%.3f wy=%.3f",
        #STATE.db.destinations, dest.maI, dest.mapName or "?", dest.zx or -1, dest.zy or -1, dest.wx or -1, dest.wy or -1))

    InvalidateRoute("waypoint added")
    if STATE.db.autoSyncToCarbonite then
        SyncQueueToCarbonite()
    end
end

local function ListWaypoints()
    if #STATE.db.destinations == 0 then
        pr("queue empty")
        return
    end
    for i, dest in ipairs(STATE.db.destinations) do
        pr(format("%d) %s | maI=%d | zx=%.1f zy=%.1f | wx=%.3f wy=%.3f | ts=%s",
            i,
            dest.mapName or ("Map " .. tostring(dest.maI)),
            dest.maI or -1,
            dest.zx or -1,
            dest.zy or -1,
            dest.wx or -1,
            dest.wy or -1,
            dest.ts or "?"
        ))
    end
end

local function ExportWaypoints()
    local n = #STATE.db.destinations
    if n == 0 then
        pr("export: queue empty")
        return
    end
    local lines = {}
    lines[#lines + 1] = "----- COPY FROM HERE -----"
    for i, dest in ipairs(STATE.db.destinations) do
        local pname = dest.mapName or "?"
        pname = gsub(pname, "|", "/")
        lines[#lines + 1] = format("%d|%d|%s|%.3f|%.3f|%.6f|%.6f|%s",
            i,
            dest.maI or -1,
            pname,
            dest.zx or -1,
            dest.zy or -1,
            dest.wx or -1,
            dest.wy or -1,
            dest.ts or "?"
        )
    end
    lines[#lines + 1] = "----- COPY TO HERE -----"
    local blob = table.concat(lines, "\n")
    AppendUiLogLine(blob)
    dbg(blob)
    pr(format("export: %d waypoint(s) in block (%d data lines). Select all in CW log, copy, paste into Import.", n, n))
    for i = 1, n do
        dbg(lines[1 + i])
    end
end

local function SplitExportFields(line)
    local parts = {}
    local i = 1
    local s = line
    local len = #s
    while i <= len do
        local bar = string.find(s, "|", i, true)
        if not bar then
            parts[#parts + 1] = string.sub(s, i)
            break
        end
        parts[#parts + 1] = string.sub(s, i, bar - 1)
        i = bar + 1
    end
    return parts
end

local function TrimField(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Paste from Notepad/browser may add UTF-8 BOM; breaks ^%d+ match and tonumber(idx/maI).
local function StripLeadingBomAndBidi(s)
    if type(s) ~= "string" or s == "" then return s end
    while true do
        if #s >= 3 and string.sub(s, 1, 3) == "\239\187\191" then
            s = string.sub(s, 4)
        else
            break
        end
    end
    return s
end

local function ToNumberField(s)
    if s == nil then return nil end
    s = StripLeadingBomAndBidi(TrimField(tostring(s)))
    if s == "" then return nil end
    s = gsub(s, "\194\160", "")
    s = gsub(s, "\226\128\139", "")
    s = gsub(s, "\226\128\140", "")
    s = gsub(s, "\226\128\141", "")
    s = gsub(s, ",", ".")
    s = gsub(gsub(s, "^%s+", ""), "%s+$", "")
    local num = tonumber(s)
    if num ~= nil then return num end
    if string.find(s, "%s") then
        return nil
    end
    local a, b = string.find(s, "%-?%d+%.?%d*")
    if a and b then
        num = tonumber(string.sub(s, a, b))
        if num ~= nil then return num end
    end
    a, b = string.find(s, "%-?%.%d+")
    if a and b then
        num = tonumber(string.sub(s, a, b))
        if num ~= nil then return num end
    end
    return nil
end

-- Split pasted blob into lines (handles missing final newline, \r, embedded NUL).
local function SplitLines(raw)
    local out = {}
    raw = gsub(gsub(gsub(tostring(raw or ""), "\r\n", "\n"), "\r", "\n"), "\0", "")
    raw = StripLeadingBomAndBidi(raw)
    local i, len = 1, #raw
    while i <= len do
        local j = string.find(raw, "\n", i, true)
        if not j then
            out[#out + 1] = string.sub(raw, i)
            break
        end
        out[#out + 1] = string.sub(raw, i, j - 1)
        i = j + 1
    end
    return out
end

local function NormalizeImportLine(line)
    if type(line) ~= "string" then return "" end
    line = line:gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")
    line = StripLeadingBomAndBidi(line)
    -- Fullwidth pipe (U+FF5C) sometimes appears when pasting from rich text
    line = line:gsub("\239\189\156", "|")
    if line == "" then return line end
    -- Paste from chat log: strip leading |cAARRGGBB ... |r color blocks (repeat).
    while true do
        local s, e = string.find(line, "^|c%x%x%x%x%x%x%x%x.-|r%s*", 1)
        if not s then break end
        line = string.sub(line, e + 1):gsub("^%s+", "")
    end
    -- "CWPhase5B: 1|2020|..." only; never split rows that already look like export (digit|digit|...).
    if not string.match(line, "^%d+|%d+|") then
        local prefix, rest = string.match(line, "^([^|]-):%s*(.+)$")
        if prefix and rest and not string.find(prefix, "|", 1, true) and #prefix < 64 and #prefix > 0 then
            line = rest:gsub("^%s+", ""):gsub("%s+$", "")
        end
    end
    line = gsub(line, "%s*|%s*", "|")
    while true do
        local prev = line
        line = gsub(line, "||", "|")
        if line == prev then break end
    end
    line = gsub(line, "^%|+", "")
    line = gsub(line, "%|+$", "")
    return line
end

local function ParseExportLine(line)
    if type(line) ~= "string" then return nil, "notstring" end
    line = line:gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")
    line = StripLeadingBomAndBidi(line)
    if line == "" then return nil, "empty" end
    if string.find(line, "COPY FROM HERE", 1, true) or string.find(line, "COPY TO HERE", 1, true) then
        return nil, "marker"
    end
    line = NormalizeImportLine(line)
    if line == "" then return nil, "empty" end
    local parts = SplitExportFields(line)
    for i = 1, #parts do
        parts[i] = StripLeadingBomAndBidi(TrimField(parts[i]))
    end
    local n = #parts
    if n < 7 then return nil, format("short(n=%d)", n) end
    local idx = ToNumberField(parts[1])
    local maI = ToNumberField(parts[2])
    if idx == nil or maI == nil then
        return nil, format("badidx(%s,%s)", tostring(parts[1]), tostring(parts[2]))
    end

    -- 7 fields: index|maI|mapName|zx|zy|wx|wy (timestamp optional from export)
    if n == 7 then
        local mapName = parts[3]
        local zx = ToNumberField(parts[4])
        local zy = ToNumberField(parts[5])
        local wx = ToNumberField(parts[6])
        local wy = ToNumberField(parts[7])
        if zx == nil or zy == nil or wx == nil or wy == nil then
            return nil, format("badpos7 zx=%s zy=%s wx=%s wy=%s", tostring(zx), tostring(zy), tostring(wx), tostring(wy))
        end
        if mapName == "" or mapName == "?" then
            mapName = nil
        end
        return {
            _importOrder = idx,
            maI = maI,
            mapName = mapName,
            zx = zx,
            zy = zy,
            wx = wx,
            wy = wy,
            ts = nil,
        }
    end

    local ts = parts[n]
    local wy = ToNumberField(parts[n - 1])
    local wx = ToNumberField(parts[n - 2])
    local zy = ToNumberField(parts[n - 3])
    local zx = ToNumberField(parts[n - 4])
    if zx == nil or zy == nil or wx == nil or wy == nil then
        return nil, format("badposN n=%d zx=%s zy=%s wx=%s wy=%s", n, tostring(zx), tostring(zy), tostring(wx), tostring(wy))
    end
    local nameChunks = {}
    for p = 3, n - 5 do
        nameChunks[#nameChunks + 1] = parts[p]
    end
    local mapName = table.concat(nameChunks, "|")
    if mapName == "" or mapName == "?" then
        mapName = nil
    end
    return {
        _importOrder = idx,
        maI = maI,
        mapName = mapName,
        zx = zx,
        zy = zy,
        wx = wx,
        wy = wy,
        ts = (ts and ts ~= "" and ts ~= "?") and ts or nil,
    }
end

ImportWaypointsFromText = function(text)
    EnsureDb()
    if not STATE.db then return end
    text = gsub(tostring(text or ""), "\0", "")
    text = StripLeadingBomAndBidi(text)
    if text:match("^%s*$") then
        pr("import: paste text from /cw export into the Import box (or /cw import <one line>).")
        return
    end
    local parsed = {}
    local bad = 0
    local lines = SplitLines(text)
    for _, line in ipairs(lines) do
        local dest, why = ParseExportLine(line)
        if dest then
            parsed[#parsed + 1] = dest
        elseif why and why ~= "empty" and why ~= "marker" then
            bad = bad + 1
        end
    end
    if #parsed == 0 then
        for _, L in ipairs(lines) do
            if string.find(L, "|", 1, true) and string.find(L, "%S")
                and not string.find(L, "COPY FROM HERE", 1, true)
                and not string.find(L, "COPY TO HERE", 1, true) then
                local _, why = ParseExportLine(L)
                local sample = string.sub(L, 1, 120)
                pr("import: rejected (" .. tostring(why or "?") .. "): " .. sample .. (#L > 120 and " …" or ""))
                dbg("import full line bytes=" .. tostring(#L) .. " : " .. L)
                break
            end
        end
        pr("import: no valid rows — paste full block from CW log (every queue row is one line).")
        return
    end
    table.sort(parsed, function(a, b)
        return (a._importOrder or 0) < (b._importOrder or 0)
    end)
    PushHistorySnapshot("import-waypoints")
    wipe(STATE.db.destinations)
    for _, d in ipairs(parsed) do
        d._importOrder = nil
        tinsert(STATE.db.destinations, d)
    end
    InvalidateRoute("import-waypoints")
    if STATE.db.autoSyncToCarbonite then
        SyncQueueToCarbonite()
    else
        ClearCarboniteTargets()
    end
    if bad > 0 then
        pr(format("import: loaded %d waypoint(s), skipped %d bad line(s)", #parsed, bad))
    else
        pr(format("import: loaded %d waypoint(s)", #parsed))
    end
end

local function InternalClearWaypoints(silent)
    PushHistorySnapshot("clear-waypoints")
    wipe(STATE.db.destinations)
    InvalidateRoute("queue cleared")
    ClearCarboniteTargets()
    if not silent then
        pr("cleared")
    end
end

local function ClearWaypoints()
    InternalClearWaypoints(false)
end

local function RemoveFirstWaypoint(reason)
    if #STATE.db.destinations == 0 then return end
    if reason == "manual-pop" or reason == "undoable-pop" then
        PushHistorySnapshot("pop-waypoint")
    end
    local first = tremove(STATE.db.destinations, 1)
    pr(format("completed #1 => %s (reason=%s)", first.mapName or ("Map " .. tostring(first.maI)), reason or "reach"))
    InvalidateRoute("advanced queue")
    SyncQueueToCarbonite()
end

-- Seconds to wait after adding a waypoint before AutoAdvance may remove #1 (avoids "vanished" right after click).
local GRACE_AFTER_CAPTURE_SEC = 4

local function PulseAutoAdvance()
    if not STATE.db.autoAdvance then return end
    if #STATE.db.destinations == 0 then return end

    local now = GetTime()
    if now - STATE.lastPulse < 0.25 then return end
    STATE.lastPulse = now

    if STATE.lastCaptureTime > 0 and (now - STATE.lastCaptureTime) < GRACE_AFTER_CAPTURE_SEC then
        return
    end

    local player = GetPlayerWorldPos()
    if not player then return end

    local first = STATE.db.destinations[1]
    if not first or not first.wx or not first.wy then return end
    if player.maI ~= first.maI then return end

    local yards = WorldToYards(Dist(player.wx, player.wy, first.wx, first.wy))
    if yards <= (STATE.db.reachDistanceYards or 10) then
        RemoveFirstWaypoint(format("%.1f yards", yards))
    end
end

local function Probe()
    local map = GetMap()
    if not map then
        pr("probe failed: no Carbonite map")
        return
    end
    if map.CaC3 then pcall(map.CaC3, map) end

    dbg(format("CFX=%.3f CFY=%.3f", map.CFX or -1, map.CFY or -1))
    if map.GCMI then
        local g = map:GCMI()
        dbg(format("GCMI=%s (%s)", tostring(g), (map.ITN and map:ITN(g)) or "?"))
    end
    do
        local n, itn = map.MaI, map.ITN
        dbg(format("MaI=%s (%s)", tostring(n), (n and itn and map:ITN(n)) or "?"))
    end
    if map.GRMI then
        local g = map:GRMI()
        dbg(format("GRMI=%s (%s)", tostring(g), (g and map.ITN and map:ITN(g)) or "?"))
    end
    if map.RMI then
        local r = map.RMI
        dbg(format("RMI=%s (%s)", tostring(r), (r and map.ITN and map:ITN(r)) or "?"))
    end
    if map.FPTWP then
        local wx, wy = map:FPTWP(map.CFX or -1, map.CFY or -1)
        dbg(format("FPTWP=%.6f,%.6f", wx or -1, wy or -1))
    end
end

local function RouteSummary()
    local map = GetMap()
    if not map then
        pr("no Carbonite map")
        return
    end

    local route, why = BuildExpandedRoute()
    if not route then
        pr("no built route summary: " .. tostring(why))
        return
    end

    local tar = map.Tar or {}
    local syncPoints = BuildSyncPoints(route.points or {})
    dbg(format("queue=%d carboniteTargets=%d expandedRoute=%d syncPoints=%d totalCost=%.1f sec explored=%d hasFlyingMount=%s simplifyTransit=%s useFlightMasters=%s",
        #STATE.db.destinations, #tar, #route.points, #syncPoints, route.totalCost or -1, route.explored or -1, tostring(STATE.db.hasFlyingMount), tostring(STATE.db.simplifyTransitWaypoints), tostring(STATE.db.useFlightMasters)))

    pr(format("route: %d queue stop(s), %d point(s), ~%.0fs", #STATE.db.destinations, #route.points, route.totalCost or 0))

    for i, pt in ipairs(route.points) do
        dbg(format("route %d: maI=%d (%s) zx=%.1f zy=%.1f wx=%.3f wy=%.3f edge=%s cost=%.1f label=%s",
            i,
            pt.maI or -1,
            pt.mapName or "?",
            pt.zx or -1,
            pt.zy or -1,
            pt.wx or -1,
            pt.wy or -1,
            ColorizeEdgeName(pt.edgeType, tostring(pt.edgeType)),
            pt.cost or -1,
            tostring(pt.label)
        ))
    end
end

local function GraphSummary()
    local graph, why = EnsureGraph()
    if not graph then
        pr("graph build failed: " .. tostring(why))
        return
    end
    pr(format("graph: %d nodes, %d edges", graph.nodeCount or 0, graph.edgeCount or 0))
    dbg(format("graph nodes=%d edges=%d transportLinks=%d", graph.nodeCount or 0, graph.edgeCount or 0, #(graph.links or {})))
end

local function HookMapClicks()
    if STATE.hookInstalled then return end
    local map = GetMap()
    if not map or not map.Frm then return end

    map.Frm:HookScript("OnMouseDown", function(_, button)
        if STATE.syncing then return end

        local primary = (button == (STATE.db.bindingButton or "LeftButton") and IsModifierDown(STATE.db.bindingModifier or "SHIFT"))
        local fallback = (button == (STATE.db.fallbackButton or "RightButton") and IsModifierDown(STATE.db.fallbackModifier or "CTRL"))

        if primary or fallback then
            AddCurrentCursorWaypoint()
        end
    end)

    STATE.hookInstalled = true
    dbg("mouse hook installed (Shift+LeftClick primary, Ctrl+RightClick fallback)")
end

local function HookCarboniteClear()
    if STATE.clearHookInstalled then return end
    if not Nx or not Nx.Map or not Nx.Map.ClT1 then return end

    hooksecurefunc(Nx.Map, "ClT1", function(self)
        if STATE.syncing then return end
        if not STATE.db then return end
        if #STATE.db.destinations == 0 then return end

        local now = GetTime() or 0
        if now < (STATE.suppressClearUntil or 0) then
            dbg("ignored Carbonite clear during CW sync window")
            return
        end

        wipe(STATE.db.destinations)
        InvalidateRoute("Carbonite clear")
        pr("queue cleared (Carbonite Goto / targets were cleared in-game)")
        dbg("queue cleared because Carbonite ClT1 ran (user or addon cleared targets)")
    end)

    STATE.clearHookInstalled = true
    dbg("Carbonite clear hook installed")
end

SlashHandler = function(msg)
    msg = string.lower((msg or ""):gsub("^%s+", ""):gsub("%s+$", ""))

    if msg == "" or msg == "help" then
        pr("commands: /cw ui | options | help | probe | add | list | export | import | sync | route | graph | clear | pop | undo | redo | autosync | autoadvance | hasflying | flightmasters | deep | minimal | debug | simplify | legend")
        return
    elseif msg == "ui" or msg == "panel" or msg == "window" then
        EnsureUi()
        ToggleUi()
    elseif msg == "options" or msg == "config" then
        EnsureInterfaceOptionsPanel()
        if STATE.interfacePanel then
            local ok = pcall(function()
                if InterfaceOptionsFrame_OpenToFrame then
                    InterfaceOptionsFrame_OpenToFrame(STATE.interfacePanel)
                elseif InterfaceOptionsFrame_OpenToCategory then
                    InterfaceOptionsFrame_OpenToCategory(STATE.interfacePanel)
                end
            end)
            if not ok then
                pr("options: open manually → Interface → AddOns → CustomWaypoints")
            end
        else
            pr("options: not available (no InterfaceOptions in this client)")
        end
    elseif msg == "probe" then
        Probe()
    elseif msg == "add" then
        AddCurrentCursorWaypoint()
    elseif msg == "list" then
        ListWaypoints()
    elseif msg == "export" then
        ExportWaypoints()
    elseif msg:match("^import%s+") then
        local payload = msg:match("^import%s+(.+)$")
        ImportWaypointsFromText(payload or "")
    elseif msg == "import" then
        EnsureUi()
        if STATE.ui and STATE.ui.frame then
            STATE.ui.frame:Show()
            if STATE.ui.importBox then
                STATE.ui.importBox:SetFocus()
            end
        end
        pr("import: paste export lines into the Import box, then click Import (or /cw import <single line>).")
    elseif msg == "sync" then
        SyncQueueToCarbonite()
    elseif msg == "route" then
        RouteSummary()
    elseif msg == "graph" then
        GraphSummary()
    elseif msg == "clear" then
        ClearWaypoints()
    elseif msg == "pop" then
        RemoveFirstWaypoint("manual-pop")
    elseif msg == "undo" then
        UndoHistory()
    elseif msg == "redo" then
        RedoHistory()
    elseif msg == "autosync" then
        STATE.db.autoSyncToCarbonite = not STATE.db.autoSyncToCarbonite
        pr("autoSyncToCarbonite=" .. tostring(STATE.db.autoSyncToCarbonite))
        RefreshUiHeader()
        if STATE.db.autoSyncToCarbonite then
            SyncQueueToCarbonite()
        end
    elseif msg == "autoadvance" then
        STATE.db.autoAdvance = not STATE.db.autoAdvance
        pr("autoAdvance=" .. tostring(STATE.db.autoAdvance))
        RefreshUiHeader()
    elseif msg == "hasflying" or msg == "toggleflying" or msg == "flymode" then
        STATE.db.hasFlyingMount = not STATE.db.hasFlyingMount
        InvalidateRoute("hasFlyingMount toggled")
        pr("hasFlyingMount=" .. tostring(STATE.db.hasFlyingMount))
        RefreshUiHeader()
        if STATE.db.autoSyncToCarbonite then
            SyncQueueToCarbonite()
        end
    elseif msg == "flightmasters" or msg == "taxi" then
        STATE.db.useFlightMasters = not STATE.db.useFlightMasters
        STATE.graph = nil
        InvalidateRoute("flight masters toggled")
        pr("useFlightMasters=" .. tostring(STATE.db.useFlightMasters))
        RefreshUiHeader()
        if STATE.db.autoSyncToCarbonite then SyncQueueToCarbonite() end
    elseif msg == "deep" then
        STATE.db.simplifyTransitWaypoints = false
        InvalidateRoute("deep mode")
        pr("simplifyTransitWaypoints=false (deep critical routing mode)")
        RefreshUiHeader()
        if STATE.db.autoSyncToCarbonite then SyncQueueToCarbonite() end
    elseif msg == "minimal" then
        STATE.db.simplifyTransitWaypoints = true
        InvalidateRoute("minimal mode")
        pr("simplifyTransitWaypoints=true (minimal transition routing mode)")
        RefreshUiHeader()
        if STATE.db.autoSyncToCarbonite then SyncQueueToCarbonite() end
    elseif msg == "legend" then
        STATE.db.showLegend = not STATE.db.showLegend
        EnsureUi()
        RefreshUiHeader()
        pr("showLegend=" .. tostring(STATE.db.showLegend))
    elseif msg == "debug" then
        EnsureDb()
        STATE.db.debug = not STATE.db.debug
        pr("debug=" .. tostring(STATE.db.debug))
        RefreshUiHeader()
    elseif msg == "simplify" or msg == "simplifytransit" then
        STATE.db.simplifyTransitWaypoints = not STATE.db.simplifyTransitWaypoints
        InvalidateRoute("simplifyTransitWaypoints toggled")
        pr("simplifyTransitWaypoints=" .. tostring(STATE.db.simplifyTransitWaypoints))
        RefreshUiHeader()
        if STATE.db.autoSyncToCarbonite then
            SyncQueueToCarbonite()
        end
    else
        pr("unknown command: " .. tostring(msg))
    end
end

local function ScheduleLoginQueueSyncIfNeeded()
    EnsureDb()
    if not STATE.db or #(STATE.db.destinations or {}) == 0 then return end
    STATE.needLoginQueueSync = true
end

local function TryPendingLoginQueueSync()
    if not STATE.needLoginQueueSync then return end
    EnsureDb()
    if not STATE.db or #(STATE.db.destinations or {}) == 0 then
        STATE.needLoginQueueSync = false
        return
    end
    if not GetMap() then return end
    STATE.needLoginQueueSync = false
    SyncQueueToCarbonite()
    dbg("login: auto-synced non-empty queue to Carbonite")
end

local function OnEvent(_, event)
    if event == "PLAYER_LOGIN" then
        EnsureDb()
        HookMapClicks()
        HookCarboniteClear()
        InstallCarboniteTravelHook()
        InstallCarboniteSclGuard()
        InstallUndoRedoBindings()
        EnsureInterfaceOptionsPanel()
        ScheduleLoginQueueSyncIfNeeded()
        dbg("loaded (Phase 5B patched: UI/options/bindings + safer deep fallback + SCL guard)")
    elseif event == "PLAYER_ENTERING_WORLD" then
        EnsureDb()
        HookMapClicks()
        HookCarboniteClear()
        InstallCarboniteTravelHook()
        InstallCarboniteSclGuard()
        InstallUndoRedoBindings()
        EnsureInterfaceOptionsPanel()
        ScheduleLoginQueueSyncIfNeeded()
    end
end

local function OnUpdate()
    TryPendingLoginQueueSync()
    PulseAutoAdvance()
    if not STATE.hookInstalled then
        HookMapClicks()
    end
    if not STATE.clearHookInstalled then
        HookCarboniteClear()
    end
    if not STATE.travelHookInstalled then
        InstallCarboniteTravelHook()
    end
    if not STATE.sclGuardInstalled then
        InstallCarboniteSclGuard()
    else
        local map = GetMap()
        if map and Nx and Nx.Map and Nx.Map.SCL and map.SCL ~= Nx.Map.SCL then
            map.SCL = Nx.Map.SCL
        end
    end
    if not STATE.bindingsInstalled then
        InstallUndoRedoBindings()
    end
end

local frame = CreateFrame("Frame")
STATE.frame = frame
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", OnEvent)
frame:SetScript("OnUpdate", OnUpdate)

SLASH_CUSTOMWAYPOINTS1 = "/cw"
SlashCmdList.CUSTOMWAYPOINTS = SlashHandler

CW._STATE = STATE
CW.AddCurrentCursorWaypoint = AddCurrentCursorWaypoint
CW.SyncQueueToCarbonite = SyncQueueToCarbonite
CW.ClearWaypoints = ClearWaypoints
CW.ImportWaypointsFromText = ImportWaypointsFromText

CW.EnsureUi = EnsureUi
CW.ToggleUi = ToggleUi
