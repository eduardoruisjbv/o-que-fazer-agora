local addonName, J = ...
local events = CreateFrame("Frame")

function J.ScheduleReadings()
    if not J.initialized or J.readingScheduled then return end
    J.readingScheduled = true
    C_Timer.After(0.5, function()
        J.readingScheduled = nil
        if J.initialized then J.RefreshReadings() end
    end)
end

function J.Initialize()
    if J.initialized then return end
    if type(J.InitAutomation) ~= "function" then
        J.Print("Reinicie o WoW para carregar o novo módulo do modo Auto; a lista de arquivos não foi atualizada neste /reload.")
        return
    end
    J.InitDB()
    J.InitAutomation()
    J.CreateUI()
    J.CreateCompass()
    J.CreateMinimapButton()
    J.SetupMapPins()
    J.On("plan", J.UpdateUI)
    J.On("readings", J.UpdateUI)
    J.On("journal", J.UpdateUI)
    J.On("mode", J.UpdateUI)
    J.initialized = true
    J.ScheduleReadings()
    C_Timer.After(2, J.ScheduleReadings)
    -- Quest reads are event-driven/debounced. This ticker recomputes distances
    -- against cached quest points only; the HUD animates at half game FPS.
    J.ticker = C_Timer.NewTicker(1, function()
        local inInstance = J.Bool(J.Call("IsInInstance", IsInInstance))
        if J.compass then
            if J.compass.inInstance ~= inInstance then J.compass.positionElapsed = 0.1 end
            J.compass.inInstance = inInstance
            J.compass:SetShown(J.db.settings.compass)
        end
        if not J.db.settings.compass and not J.ui:IsShown() then return end
        local position = J.Position()
        if not position then return end
        local state = J.readings.state
        if not state then J.ScheduleReadings(); return end
        if not state.position or position.mapID ~= state.position.mapID then
            J.ScheduleReadings()
        else
            state.position = position
            J.Replan(false)
        end
    end)
end

events:SetScript("OnEvent", function(_, event, ...)
    if J.initialized then J.HandleAutomationEvent(event, ...) end
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded == addonName and IsLoggedIn() then J.Initialize() end
        if loaded == "Blizzard_WorldMap" then J.SetupMapPins() end
    elseif event == "PLAYER_LOGIN" then J.Initialize()
    elseif not J.initialized then return
    elseif event == "QUESTLINE_UPDATE" then
        -- true asks for new map data; false means the asynchronous data is ready.
        if J.Bool(...) then J.requestedMap = nil end
        J.ScheduleReadings()
    elseif event == "QUEST_TURNED_IN" then
        local id = ...
        if J.Number(id) then J.FinishActivity(id) end
        J.ScheduleReadings()
    elseif event == "PLAYER_LOGOUT" then
        -- Discard unfinished samples; logout time is not activity duration.
        if J.db then J.Report() end
    else
        J.ScheduleReadings()
    end
end)

for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_LOGOUT", "QUEST_LOG_UPDATE",
    "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "QUEST_POI_UPDATE", "QUEST_DATA_LOAD_RESULT", "QUESTLINE_UPDATE", "SUPER_TRACKING_PATH_UPDATED",
    "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP",
    "PLAYER_SPECIALIZATION_CHANGED", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED",
    "GOSSIP_SHOW", "GOSSIP_CLOSED", "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_FINISHED"}) do
    J.Call("RegisterEvent:" .. event, events.RegisterEvent, events, event)
end

SLASH_JUSTDOIT1, SLASH_JUSTDOIT2 = "/jdi", "/justdoit"
SlashCmdList.JUSTDOIT = function(input)
    if not J.initialized then return end
    input = string.lower(strtrim(input or ""))
    if input == "probe" or input == "leituras" then J.ShowPage("readings"); J.Probe()
    elseif input == "report" or input == "relatorio" then J.ShowReport()
    elseif input == "config" then J.ShowPage("settings")
    elseif input == "compass" or input == "bussola" then
        J.db.settings.compass = not J.db.settings.compass
        J.LayoutCompass()
    elseif input == "skip" or input == "outra" then J.Ignore(J.plan and J.plan.primary)
    elseif input == "follow" or input == "seguir" then J.FollowSuggestion()
    elseif input == "help" or input == "ajuda" then
        J.Print("/jdi · /jdi probe · /jdi report · /jdi config · /jdi bussola · /jdi outra · /jdi seguir")
    elseif input ~= "" then J.Print("Comando desconhecido. Use /jdi ajuda.")
    elseif J.ui:IsShown() then J.ui:Hide() else J.ShowPage("now") end
end
