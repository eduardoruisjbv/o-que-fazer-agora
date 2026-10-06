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

function J.UpdateUI()
    local ui = J.ui
    if not ui then return end
    local state, plan = J.readings.state or {}, J.plan or {}
    ui.state:SetText(string.format("Nível %s/%s  ·  %s  ·  Grupo %d  ·  Mapa %s",
        state.level or "?", state.maxLevel or "?", state.specName or "especialização não informada",
        state.groupSize or 1, state.position and state.position.mapID or "?"))
    local function Card(box, q, empty)
        box.title:SetText(q and q.title or empty)
        box.detail:SetText(q and (q.action .. " · " .. J.DistanceText(q.distance)
            .. (q.mapID and string.format(" · %.1f, %.1f", q.x * 100, q.y * 100) or " · sem coordenadas")) or "")
    end
    Card(ui.main, plan.primary, "Nenhum objetivo encontrado neste contexto")
    Card(ui.side, plan.secondary, "Sem secundária no trajeto")
    local reason = plan.reason or "Aguardando os dados do personagem."
    if state.atMax then
        reason = "Prévia de mundo aberto. A escolha PvE por equipamento pertence à etapa 2."
    elseif plan.heuristic then
        reason = "Campanha não confirmada: usando a heurística de missões próximas."
    end
    ui.reason:SetText(reason)
    ui.follow:SetEnabled(plan.primary ~= nil)
    ui.skip:SetEnabled(plan.primary ~= nil)
    J.UpdateModeUI()
    if ui.pages.readings:IsShown() then J.UpdateReadingsUI() end
end

function J.UpdateModeUI()
    local ui = J.ui
    if not ui or not ui.semiMode then return end
    local automatic = J.AutoEnabled()
    ui.semiMode:SetText(automatic and "Semi-auto" or "Semi-auto (ativo)")
    ui.autoMode:SetText(automatic and "Auto (ativo)" or "Auto")
    ui.modeQuick:SetText(automatic and "Modo: Auto" or "Modo: Semi-auto")
    ui.modeHelp:SetText(automatic
        and "Rastreia as sugestões e usa o pin e o indicador da Blizzard automaticamente. Preserva pins manuais e aceita/entrega missões ao conversar com um NPC."
        or "Escolhe os objetivos e orienta pela bússola, preservando seu rastreamento e sua seta.")
    ui.rewardPermission:SetChecked(J.db.settings.autoRewards)
    ui.rewardPermission:SetEnabled(automatic)
    ui.rewardPermission.label:SetTextColor(automatic and 0.8 or 0.45, automatic and 0.8 or 0.45, automatic and 0.8 or 0.45)
    local detail = automatic and "Auto ativo · marcações manuais preservadas." or "Semi-auto · orientação apenas pela bússola."
    ui.hint:SetText(detail .. (J.autoStatus and ("\n" .. J.autoStatus) or "")
        .. "\nShift + arrastar move a bússola. Outra sugestão ignora a atividade por 45 minutos.")
end

function J.UpdateReadingsUI()
    local ui, r = J.ui, J.readings
    if not ui then return end
    local campaignCount = #(r.campaigns or {})
    local coordinates = 0
    for _, q in ipairs(r.quests or {}) do if q.mapID then coordinates = coordinates + 1 end end
    local s = r.sources or {}
    ui.summary:SetText(string.format("Campanhas: %d  ·  Missões: %d  ·  Com coordenadas: %d\nFontes: log %d / mapa %d / linhas %d / tarefas %d",
        campaignCount, #(r.quests or {}), coordinates, s.log or 0, s.map or 0, s.lines or 0, s.tasks or 0))
    local dungeon = J.dungeons and J.dungeons[J.dungeonIndex or 1]
    local labels = {[1] = "Normal", [2] = "Heroica", [23] = "Mítica"}
    ui.dungeon:SetText(dungeon and dungeon.name or "Execute as leituras para descobrir as masmorras.")
    ui.difficulty:SetText("Dificuldade: " .. (labels[J.journalDifficulty or 1] or "?"))
    local lines = {}
    for _, c in ipairs(r.campaigns or {}) do
        lines[#lines + 1] = string.format("Campanha #%d: %s\n   %s", c.id, c.name, c.chapter or "Sem capítulo retornado")
    end
    if #lines == 0 then lines[#lines + 1] = "Nenhuma campanha retornada neste contexto." end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "MISSÕES E PRÓXIMAS AÇÕES"
    for _, q in ipairs(r.quests or {}) do
        local coords = q.mapID and string.format("mapa %d · %.1f, %.1f", q.mapID, q.x * 100, q.y * 100) or "sem coordenadas"
        lines[#lines + 1] = string.format("%s%s — %s\n   %s · %s", q.campaign and "[Campanha] " or "", q.title, q.action, coords, J.DistanceText(q.distance))
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "LOOT DA MASMORRA"
    if J.loot then
        local loot = J.loot
        lines[#lines + 1] = loot.dungeon.name .. " · " .. (labels[loot.difficulty] or tostring(loot.difficulty))
        if loot.message then lines[#lines + 1] = loot.message end
        lines[#lines + 1] = string.format("Itens: %d · dados pendentes: %d · especialização: %s",
            #(loot.items or {}), loot.pending or 0, loot.specName or "não informada")
        for _, item in ipairs(loot.items or {}) do
            lines[#lines + 1] = string.format("%s · %s · ilvl %s", item.name or ("Item #" .. item.id), item.slot or "slot pendente", item.ilvl or "pendente")
        end
    else lines[#lines + 1] = "Ainda não consultado. Execute as leituras fora de combate." end
    local keys = {}; for key in pairs(J.errors) do keys[#keys + 1] = key end
    if #keys > 0 then
        table.sort(keys)
        lines[#lines + 1] = ""
        lines[#lines + 1] = "LEITURAS INDISPONÍVEIS"
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
        Text(frame, "GameFontNormalLarge", "TOPLEFT", 18, -18, 570, "Relatório de viabilidade · Just do it")
        Text(frame, "GameFontHighlightSmall", "TOPLEFT", 18, -47, 605, "Ctrl+A e Ctrl+C para copiar. O relatório não inclui nome nem GUID do personagem.")
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
    Text(frame, "GameFontHighlightSmall", "TOPLEFT", 21, -55, 605, "Uma direção para sua próxima atividade.")
    frame.state = Text(frame, "GameFontHighlightSmall", "TOPLEFT", 21, -80, 615)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)
    frame.modeQuick = Button(frame, "Modo: Semi-auto", 440, -25, 175, function(owner)
        if MenuUtil and MenuUtil.CreateContextMenu then
            MenuUtil.CreateContextMenu(owner, function(_, root)
                root:CreateTitle("Modo de orientação")
                root:CreateRadio("Semi-auto", function() return not J.AutoEnabled() end,
                    function() J.RequestMode("semi") end)
                root:CreateRadio("Auto", function() return J.AutoEnabled() end,
                    function() J.RequestMode("auto") end)
            end)
        else J.ShowPage("settings") end
    end)
    Button(frame, "Agora", 20, -110, 100, function() J.ShowPage("now") end)
    Button(frame, "Leituras", 128, -110, 100, function() J.ShowPage("readings") end)
    Button(frame, "Configuração", 236, -110, 125, function() J.ShowPage("settings") end)
    frame.pages = {}
    for _, name in ipairs({"now", "readings", "settings"}) do
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", 0, -150)
        page:SetPoint("BOTTOMRIGHT", 0, 0)
        frame.pages[name] = page
        page:Hide()
    end
    local now = frame.pages.now
    frame.main = CandidateCard(now, 20, 0, "P · PRINCIPAL", J.primaryColor)
    frame.side = CandidateCard(now, 20, -130, "S · SECUNDÁRIA", J.secondaryColor)
    frame.reason = Text(now, "GameFontHighlightSmall", "TOPLEFT", 24, -267, 610)
    frame.follow = Button(now, "Seguir sugestão", 20, -308, 150, J.FollowSuggestion)
    frame.skip = Button(now, "Outra sugestão", 180, -308, 150, function() J.Ignore(J.plan and J.plan.primary) end)
    Button(now, "Atualizar", 340, -308, 110, J.RefreshReadings)
    frame.hint = Text(now, "GameFontDisableSmall", "TOPLEFT", 24, -355, 605)
    local readings = frame.pages.readings
    frame.summary = Text(readings, "GameFontHighlight", "TOPLEFT", 24, -2, 610)
    Button(readings, "Executar leituras", 20, -50, 150, J.Probe)
    Button(readings, "Copiar relatório", 180, -50, 150, J.ShowReport)
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
        Button(readings, ({"Normal", "Heroica", "Mítica"})[index], 300 + (index - 1) * 102, -118, 96, function()
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
    Text(settings, "GameFontNormalLarge", "TOPLEFT", 24, -3, 580, "Modo de orientação")
    frame.semiMode = Button(settings, "Semi-auto", 24, -34, 175, function() J.RequestMode("semi") end)
    frame.autoMode = Button(settings, "Auto", 210, -34, 175, function() J.RequestMode("auto") end)
    frame.modeHelp = Text(settings, "GameFontHighlightSmall", "TOPLEFT", 24, -75, 560)
    local permission = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    permission:SetPoint("TOPLEFT", 25, -130)
    permission.label = permission:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    permission.label:SetPoint("LEFT", permission, "RIGHT", 2, 0)
    permission.label:SetText("Escolher recompensa automaticamente")
    permission:SetScript("OnClick", function(self)
        local enabled = self:GetChecked() and true or false
        self:SetChecked(J.db.settings.autoRewards)
        J.RequestAutoRewards(enabled)
    end)
    frame.rewardPermission = permission
    Checkbox(settings, "Mostrar bússola", "compass", -177, J.LayoutCompass)
    Checkbox(settings, "Mostrar botão no minimapa", "minimap", -207, function()
        if J.minimap then J.minimap:SetShown(J.db.settings.minimap) end
    end)
    Slider(settings, "Largura do corredor (m)", "corridor", 25, 600, 25, -270)
    Slider(settings, "Raio muito próximo (m)", "closeRadius", 25, 500, 25, -332)
    Slider(settings, "Distância relativa à campanha", "closeRatio", 0.1, 0.8, 0.05, -394, "%.2f")
    Slider(settings, "Estabilidade antes de trocar (s)", "switchSeconds", 1, 15, 1, -456)
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
        GameTooltip:AddLine("Clique: painel · Botão direito: configuração", 1, 1, 1)
        GameTooltip:AddLine("Arraste para mover no minimapa.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Position(J.db.settings.minimapAngle)
    button:SetShown(J.db.settings.minimap)
    J.minimap = button
end
