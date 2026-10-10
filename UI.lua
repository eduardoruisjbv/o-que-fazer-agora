local _, J = ...
local function Text(parent, template, point, x, y, width, text)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    label:SetPoint(point or "TOPLEFT", x or 0, y or 0)
    if width then label:SetWidth(width) end
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text or "")
    return label
end

local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 140, 26)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

local function Box(parent, x, y, width, height)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetPoint("TOPLEFT", x, y)
    box:SetSize(width, height)
    box:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12})
    box:SetBackdropColor(0.045, 0.055, 0.065, 0.95)
    box:SetBackdropBorderColor(0.25, 0.3, 0.34)
    return box
end

local function CandidateCard(parent, x, y, heading, color)
    local box = Box(parent, x, y, 620, 118)
    box.heading = Text(box, "GameFontNormalSmall", "TOPLEFT", 14, -12, 590, heading)
    box.heading:SetTextColor(unpack(color))
    box.title = Text(box, "GameFontHighlightLarge", "TOPLEFT", 14, -35, 590)
    box.detail = Text(box, "GameFontHighlight", "TOPLEFT", 14, -77, 590)
    return box
end

function J.OpenInstanceSuggestion()
    local q = J.plan and J.plan.instanced
    if not q then return end
    if InCombatLockdown and InCombatLockdown() then
        J.Print("Open Group Finder after combat.")
        return
    end
    if C_AddOns and C_AddOns.LoadAddOn then J.API("C_AddOns", "LoadAddOn", "Blizzard_GroupFinder") end
    local activityID = J.Number(J.API("C_LFGList", "GetActivityIDForQuestID", q.questID))
    -- Open the native quest search only when a mapping exists and no listing
    -- would need removal. Opening this panel never queues or forms a group.
    if activityID and activityID > 0 and LFGListUtil_FindQuestGroup
        and not J.Bool(J.API("C_LFGList", "HasActiveEntryInfo")) then
        J.Call("LFGListUtil_FindQuestGroup", LFGListUtil_FindQuestGroup, q.questID, false)
    elseif PVEFrame_ShowFrame then
        J.Call("PVEFrame_ShowFrame", PVEFrame_ShowFrame, "GroupFinderFrame", LFGListPVEStub)
        J.Print("Choose content in Group Finder: " .. q.title)
    else
        J.Print("Group Finder is unavailable in this context.")
    end
end

function J.UpdateUI()
    local ui = J.ui
    if not ui then return end
    local state, plan = J.readings.state or {}, J.plan or {}
    ui.state:SetText(string.format("Level %s/%s  ·  %s  ·  Group %d  ·  Map %s",
        state.level or "?", state.maxLevel or "?", state.specName or "specialization unknown",
        state.groupSize or 1, state.position and state.position.mapID or "?"))
    local function Card(box, q, empty)
        box.title:SetText(q and q.title or empty)
        box.detail:SetText(q and ((q.waypointText and (q.waypointText .. "\n") or "") .. q.action .. " · " .. J.DistanceText(q.distance)
            .. (q.mapID and string.format(" · %.1f, %.1f", q.x * 100, q.y * 100) or " · no coordinates")) or "")
    end
    Card(ui.main, plan.primary, "No objective found in this context")
    Card(ui.side, plan.secondary, "No secondary objective on the route")
    ui.instance:SetShown(plan.instanced ~= nil)
    ui.instance:SetText(plan.instanced and ("Instance · " .. plan.instanced.title .. " — Find group") or "")
    local reason = plan.reason or "Waiting for character data."
    if state.atMax then
        reason = "Open-world preview. Gear-based PvE selection is planned for stage 2."
    elseif plan.heuristic then
        reason = "Campaign not confirmed: using the nearby-quest heuristic."
    end
    ui.reason:SetText(reason)
    ui.follow:SetEnabled(plan.primary ~= nil)
    ui.skip:SetEnabled(plan.primary ~= nil)
    J.UpdatePvPUI()
    J.UpdateModeUI()
    if ui.pages.readings:IsShown() then J.UpdateReadingsUI() end
end

function J.UpdatePvPUI()
    local panel = J.ui and J.ui.pvp
    if not panel then return end

    local maxQueues = J.Number(J.Call("GetMaxBattlefieldID", GetMaxBattlefieldID)) or 0
    local queue
    for index = 1, math.min(maxQueues, 20) do
        local status, mapName = J.Call("GetBattlefieldStatus", GetBattlefieldStatus, index)
        status = J.String(status)
        if status == "queued" or status == "confirm" or status == "active" then
            queue = {status = status, mapName = J.String(mapName)}
            break
        end
    end

    if not queue then
        panel:Hide()
        return
    end

    local labels = {
        queued = "Na fila",
        confirm = "Convite disponível · entre na partida",
        active = "Em partida",
    }
    local detail = queue.mapName and (queue.mapName .. " · " .. labels[queue.status]) or labels[queue.status]
    panel.status:SetText(detail)
    panel:Show()
end

function J.UpdateModeUI()
    local ui = J.ui
    if not ui or not ui.semiMode then return end
    local automatic = J.AutoEnabled()
    ui.semiMode:SetText(automatic and "Semi-auto" or "Semi-auto (ativo)")
    ui.autoMode:SetText(automatic and "Auto (ativo)" or "Auto")
    ui.modeQuick:SetText(automatic and "Mode: Auto" or "Mode: Semi-auto")
    ui.modeHelp:SetText(automatic
        and "Tracks suggestions and automatically uses Blizzard’s waypoint and indicator. Preserves manual pins; accepting and turning in quests is always up to you."
        or "Selects objectives and provides compass guidance while preserving your tracker and arrow. Quest interactions are always up to you.")
    local detail = automatic and "Auto active · manual marks preserved." or "Semi-auto · automatic compass guidance."
    ui.hint:SetText(detail .. (J.autoStatus and ("\n" .. J.autoStatus) or "")
        .. "\nShift-drag moves the compass. Another suggestion skips this activity for 45 minutes.")
end

function J.UpdateReadingsUI()
    local ui, r = J.ui, J.readings
    if not ui then return end
    local campaignCount = #(r.campaigns or {})
    local coordinates = 0
    for _, q in ipairs(r.quests or {}) do if q.mapID then coordinates = coordinates + 1 end end
    local s = r.sources or {}
    ui.summary:SetText(string.format("Campaigns: %d  ·  Quests: %d  ·  With coordinates: %d\nSources: log %d / map %d / lines %d / tasks %d",
        campaignCount, #(r.quests or {}), coordinates, s.log or 0, s.map or 0, s.lines or 0, s.tasks or 0))
    local dungeon = J.dungeons and J.dungeons[J.dungeonIndex or 1]
    local labels = {[1] = "Normal", [2] = "Heroic", [23] = "Mythic"}
    ui.dungeon:SetText(dungeon and dungeon.name or "Run readings to discover dungeons.")
    ui.difficulty:SetText("Difficulty: " .. (labels[J.journalDifficulty or 1] or "?"))
    local lines = {}
    for _, c in ipairs(r.campaigns or {}) do
        lines[#lines + 1] = string.format("Campaign #%d: %s\n   %s", c.id, c.name, c.chapter or "No chapter returned")
    end
    if #lines == 0 then lines[#lines + 1] = "No campaigns returned in this context." end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "QUESTS AND NEXT ACTIONS"
    for _, q in ipairs(r.quests or {}) do
        local coords = q.mapID and string.format("map %d · %.1f, %.1f", q.mapID, q.x * 100, q.y * 100) or "no coordinates"
        lines[#lines + 1] = string.format("%s%s — %s\n   %s · %s", q.campaign and "[Campaign] " or "", q.title, q.action, coords, J.DistanceText(q.distance))
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "DUNGEON LOOT"
    if J.loot then
        local loot = J.loot
        lines[#lines + 1] = loot.dungeon.name .. " · " .. (labels[loot.difficulty] or tostring(loot.difficulty))
        if loot.message then lines[#lines + 1] = loot.message end
        lines[#lines + 1] = string.format("Items: %d · pending data: %d · specialization: %s",
            #(loot.items or {}), loot.pending or 0, loot.specName or "unknown")
        for _, item in ipairs(loot.items or {}) do
            lines[#lines + 1] = string.format("%s · %s · ilvl %s", item.name or ("Item #" .. item.id), item.slot or "slot pending", item.ilvl or "pending")
        end
    else lines[#lines + 1] = "Not queried yet. Run readings out of combat." end
    local keys = {}; for key in pairs(J.errors) do keys[#keys + 1] = key end
    if #keys > 0 then
        table.sort(keys)
        lines[#lines + 1] = ""
        lines[#lines + 1] = "UNAVAILABLE READINGS"
        for _, key in ipairs(keys) do lines[#lines + 1] = key .. ": " .. J.errors[key] end
    end
    ui.details:SetText(table.concat(lines, "\n"))
    ui.details:SetHeight(math.max(230, ui.details:GetStringHeight() + 24))
    ui.detailsContainer:SetHeight(math.max(235, ui.details:GetHeight()))
end

function J.ShowPage(name)
    if not J.ui then return end
    for key, page in pairs(J.ui.pages) do page:SetShown(key == name) end
    J.ui:Show()
    J.UpdateUI()
end

function J.ShowReport()
    if not J.reportFrame then
        local frame = CreateFrame("Frame", "JustDoItReport", UIParent, "BackdropTemplate")
        frame:SetSize(650, 490)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16})
        frame:SetBackdropColor(0.025, 0.03, 0.04, 1)
        Text(frame, "GameFontNormalLarge", "TOPLEFT", 18, -18, 570, "Feasibility report · Just do it")
        Text(frame, "GameFontHighlightSmall", "TOPLEFT", 18, -47, 605, "Press Ctrl+A and Ctrl+C to copy. The report does not include the character name or GUID.")
        local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 0, 0)
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 18, -78)
        scroll:SetPoint("BOTTOMRIGHT", -35, 18)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(590)
        edit:SetHeight(370)
        edit:SetMaxLetters(0)
        edit:SetScript("OnEscapePressed", function() frame:Hide() end)
        edit:SetScript("OnTextChanged", function(self) scroll:UpdateScrollChildRect() end)
        scroll:SetScrollChild(edit)
        frame.edit = edit
        J.reportFrame = frame
        table.insert(UISpecialFrames, "JustDoItReport")
    end
    J.reportFrame.edit:SetText(J.Report())
    J.reportFrame.edit:SetCursorPosition(0)
    J.reportFrame.edit:HighlightText()
    J.reportFrame:Show()
    J.reportFrame.edit:SetFocus()
end

local sliderID = 0
local function Slider(parent, title, key, minimum, maximum, step, y, format)
    sliderID = sliderID + 1
    local name = "JustDoItSetting" .. sliderID
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 35, y)
    slider:SetSize(330, 18)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    local text = slider.Text or _G[name .. "Text"]
    local low, high = slider.Low or _G[name .. "Low"], slider.High or _G[name .. "High"]
    low:SetText(minimum); high:SetText(maximum)
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        J.db.settings[key] = value
        text:SetText(title .. ": " .. string.format(format or "%d", value))
        J.LayoutCompass()
        if J.readings.state then J.Replan(true) end
    end)
    slider:SetValue(J.db.settings[key])
end

local function Checkbox(parent, title, key, y, callback)
    local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    box:SetPoint("TOPLEFT", 25, y)
    box:SetChecked(J.db.settings[key])
    local label = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", box, "RIGHT", 2, 0)
    label:SetText(title)
    box:SetScript("OnClick", function(self)
        J.db.settings[key] = self:GetChecked() and true or false
        if callback then callback() end
    end)
end

function J.CreateUI()
    local frame = CreateFrame("Frame", "JustDoItPanel", UIParent, "BackdropTemplate")
    frame:SetSize(660, 570)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16})
    frame:SetBackdropColor(0.02, 0.03, 0.04, 0.98)
    frame:SetBackdropBorderColor(0.25, 0.35, 0.37)
    local title = Text(frame, "GameFontNormalHuge", "TOPLEFT", 20, -20, 440, "Just do it")
    title:SetTextColor(unpack(J.primaryColor))
    Text(frame, "GameFontHighlightSmall", "TOPLEFT", 21, -55, 605, "One direction for your next activity.")
    frame.state = Text(frame, "GameFontHighlightSmall", "TOPLEFT", 21, -80, 615)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)
    frame.modeQuick = Button(frame, "Mode: Semi-auto", 440, -25, 175, function(owner)
        if MenuUtil and MenuUtil.CreateContextMenu then
            MenuUtil.CreateContextMenu(owner, function(_, root)
                root:CreateTitle("Guidance mode")
                root:CreateRadio("Semi-auto", function() return not J.AutoEnabled() end,
                    function() J.RequestMode("semi") end)
                root:CreateRadio("Auto", function() return J.AutoEnabled() end,
                    function() J.RequestMode("auto") end)
            end)
        else J.ShowPage("settings") end
    end)
    Button(frame, "Now", 20, -110, 100, function() J.ShowPage("now") end)
    Button(frame, "Readings", 128, -110, 100, function() J.ShowPage("readings") end)
    Button(frame, "Settings", 236, -110, 125, function() J.ShowPage("settings") end)
    frame.pages = {}
    for _, name in ipairs({"now", "readings", "settings"}) do
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", 0, -150)
        page:SetPoint("BOTTOMRIGHT", 0, 0)
        frame.pages[name] = page
        page:Hide()
    end
    local now = frame.pages.now
    frame.main = CandidateCard(now, 20, 0, "P · PRIMARY", J.primaryColor)
    frame.side = CandidateCard(now, 20, -130, "S · SECONDARY", J.secondaryColor)
    frame.instance = Button(now, "", 20, -258, 620, J.OpenInstanceSuggestion)
    frame.reason = Text(now, "GameFontHighlightSmall", "TOPLEFT", 24, -291, 610)
    frame.follow = Button(now, "Follow suggestion", 20, -324, 150, J.FollowSuggestion)
    frame.skip = Button(now, "Another suggestion", 180, -324, 150, function() J.Ignore(J.plan and J.plan.primary) end)
    Button(now, "Refresh", 340, -324, 110, J.RefreshReadings)
    frame.hint = Text(now, "GameFontDisableSmall", "TOPLEFT", 24, -361, 605)
    frame.pvp = Box(now, 20, -389, 620, 30)
    frame.pvp:SetBackdropBorderColor(0.19, 0.24, 0.26)
    frame.pvp.label = Text(frame.pvp, "GameFontNormalSmall", "LEFT", 12, 0, 38, "PvP")
    frame.pvp.label:SetTextColor(unpack(J.primaryColor))
    frame.pvp.status = Text(frame.pvp, "GameFontHighlightSmall", "LEFT", 48, 0, 550)
    frame.pvp:Hide()
    local readings = frame.pages.readings
    frame.summary = Text(readings, "GameFontHighlight", "TOPLEFT", 24, -2, 610)
    Button(readings, "Run readings", 20, -50, 150, J.Probe)
    Button(readings, "Copy report", 180, -50, 150, J.ShowReport)
    frame.dungeon = Text(readings, "GameFontNormal", "TOPLEFT", 24, -94, 430)
    Button(readings, "<", 515, -86, 40, function()
        if J.dungeons and #J.dungeons > 0 then
            J.dungeonIndex = ((J.dungeonIndex or 1) - 2) % #J.dungeons + 1
            J.ReadLoot(J.dungeons[J.dungeonIndex], J.journalDifficulty or 1)
        end
    end)
    Button(readings, ">", 565, -86, 40, function()
        if J.dungeons and #J.dungeons > 0 then
            J.dungeonIndex = (J.dungeonIndex or 1) % #J.dungeons + 1
            J.ReadLoot(J.dungeons[J.dungeonIndex], J.journalDifficulty or 1)
        end
    end)
    frame.difficulty = Text(readings, "GameFontHighlightSmall", "TOPLEFT", 24, -127, 250)
    for index, difficulty in ipairs({1, 2, 23}) do
        local selected = difficulty
        Button(readings, ({"Normal", "Heroic", "Mythic"})[index], 300 + (index - 1) * 102, -118, 96, function()
            J.journalDifficulty = selected
            local dungeon = J.dungeons and J.dungeons[J.dungeonIndex or 1]
            if dungeon then J.ReadLoot(dungeon, selected) else J.UpdateReadingsUI() end
        end)
    end
    local scroll = CreateFrame("ScrollFrame", nil, readings, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 24, -165)
    scroll:SetPoint("BOTTOMRIGHT", -45, 20)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(580, 235)
    scroll:SetScrollChild(child)
    frame.details = Text(child, "GameFontHighlightSmall", "TOPLEFT", 0, 0, 570)
    frame.details:SetSpacing(3)
    frame.detailsContainer = child
    local configScroll = CreateFrame("ScrollFrame", nil, frame.pages.settings, "UIPanelScrollFrameTemplate")
    configScroll:SetPoint("TOPLEFT", 0, -3)
    configScroll:SetPoint("BOTTOMRIGHT", -30, 20)
    local settings = CreateFrame("Frame", nil, configScroll)
    settings:SetSize(620, 570)
    configScroll:SetScrollChild(settings)
    Text(settings, "GameFontNormalLarge", "TOPLEFT", 24, -3, 580, "Guidance mode")
    frame.semiMode = Button(settings, "Semi-auto", 24, -34, 175, function() J.RequestMode("semi") end)
    frame.autoMode = Button(settings, "Auto", 210, -34, 175, function() J.RequestMode("auto") end)
    frame.modeHelp = Text(settings, "GameFontHighlightSmall", "TOPLEFT", 24, -75, 560)
    Checkbox(settings, "Show compass", "compass", -145, J.LayoutCompass)
    Checkbox(settings, "Show minimap button", "minimap", -175, function()
        if J.minimap then J.minimap:SetShown(J.db.settings.minimap) end
    end)
    Checkbox(settings, "Show Blizzard zone indicators (top)", "showZoneIndicators", -205,
        J.UpdateBlizzardWidgetLayout)
    Slider(settings, "Corridor width (m)", "corridor", 25, 600, 25, -268)
    Slider(settings, "Very close radius (m)", "closeRadius", 25, 500, 25, -330)
    Slider(settings, "Distance relative to campaign", "closeRatio", 0.1, 0.8, 0.05, -392, "%.2f")
    Slider(settings, "Stability before switching (s)", "switchSeconds", 1, 15, 1, -454)
    J.ui = frame
    J.UpdateModeUI()
    frame.pages.now:Show()
    frame:Hide()
    frame:SetScript("OnShow", function() J.RefreshReadings(); J.UpdateUI() end)
    table.insert(UISpecialFrames, "JustDoItPanel")
end

function J.CreateMinimapButton()
    if not Minimap then return end
    local button = CreateFrame("Button", "JustDoItMinimapButton", Minimap)
    button:SetSize(30, 30)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    local function Circle(texture, size)
        texture:SetSize(size, size)
        texture:SetPoint("CENTER")
        local mask = button:CreateMaskTexture()
        mask:SetTexture(3528314, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetSize(size, size)
        mask:SetPoint("CENTER")
        texture:AddMaskTexture(mask)
    end
    local rim = button:CreateTexture(nil, "BACKGROUND", nil, 0)
    rim:SetColorTexture(0.62, 0.51, 0.30, 1)
    Circle(rim, 28)
    local background = button:CreateTexture(nil, "BACKGROUND", nil, 1)
    background:SetColorTexture(0.06, 0.07, 0.075, 1)
    Circle(background, 26)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(J.icon)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    Circle(icon, 23)
    button:SetHighlightTexture(136477)
    local function Position(angle)
        local radians = math.rad(angle)
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * (Minimap:GetWidth() / 2 + 5),
            math.sin(radians) * (Minimap:GetHeight() / 2 + 5))
    end
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local centerX, centerY = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            local angle = math.deg(math.atan2(y / scale - centerY, x / scale - centerX)) % 360
            J.db.settings.minimapAngle = angle
            Position(angle)
        end)
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then J.ShowPage("settings")
        elseif J.ui:IsShown() then J.ui:Hide() else J.ShowPage("now") end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Just do it", unpack(J.primaryColor))
        GameTooltip:AddLine("Click: panel · Right-click: settings", 1, 1, 1)
        GameTooltip:AddLine("Drag to move around the minimap.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Position(J.db.settings.minimapAngle)
    button:SetShown(J.db.settings.minimap)
    J.minimap = button
end
