local _, J = ...
local function API(namespace, method, ...) return J.API(namespace, method, ...) end

function J.WorldPoint(mapID, x, y)
    if not J.Number(mapID) or not J.Number(x) or not J.Number(y) then return nil end
    if x < 0 or x > 1 or y < 0 or y > 1 or not CreateVector2D then return nil end
    local continent, position = API("C_Map", "GetWorldPosFromMapPos", mapID, CreateVector2D(x, y))
    if not position or not J.Number(continent) then return nil end
    local wx, wy = J.Call("Vector2:GetXY", position.GetXY, position)
    if J.Number(wx) and J.Number(wy) then return {continent = continent, x = wx, y = wy} end
end

function J.Position()
    local mapID = J.Number(API("C_Map", "GetBestMapForUnit", "player"))
    if not mapID then return nil end
    local position = API("C_Map", "GetPlayerMapPosition", mapID, "player")
    if not position then return {mapID = mapID} end
    local x, y = J.Call("Vector2:GetXY", position.GetXY, position)
    if not J.Number(x) or not J.Number(y) then return {mapID = mapID} end
    return {mapID = mapID, x = x, y = y, world = J.WorldPoint(mapID, x, y)}
end

function J.Distance(a, b)
    if not a or not b or a.continent ~= b.continent then return nil end
    local dx, dy = b.x - a.x, b.y - a.y
    return math.sqrt(dx * dx + dy * dy)
end

function J.ReadCharacter()
    local state = {position = J.Position()}
    state.level = J.Number(J.Call("UnitLevel", UnitLevel, "player"))
    local expansion = J.Number(J.Call("GetClientDisplayExpansionLevel", GetClientDisplayExpansionLevel))
    if expansion then
        state.maxLevel = J.Number(J.Call("GetMaxLevelForExpansionLevel", GetMaxLevelForExpansionLevel, expansion))
    end
    if not state.maxLevel and GetMaxPlayerLevel then
        state.maxLevel = J.Number(J.Call("GetMaxPlayerLevel", GetMaxPlayerLevel))
    end
    state.atMax = state.level and state.maxLevel and state.level >= state.maxLevel or false
    state.groupSize = math.max(1, J.Number(J.Call("GetNumGroupMembers", GetNumGroupMembers)) or 1)
    local _, _, classID = J.Call("UnitClass", UnitClass, "player")
    state.classID = J.Number(classID)
    local specIndex = J.Number(API("C_SpecializationInfo", "GetSpecialization"))
    if specIndex then
        local id, name = API("C_SpecializationInfo", "GetSpecializationInfo", specIndex)
        state.specID, state.specName = J.Number(id), J.String(name)
    end
    state.inInstance = J.Bool(J.Call("IsInInstance", IsInInstance))
    return state
end

local function IsCampaign(questID, logInfo, line)
    if J.Bool(J.Field(line, "isCampaign")) then return true end
    local campaignID = J.Number(J.Field(logInfo, "campaignID"))
    if campaignID and campaignID > 0 then return true end
    local ns = C_CampaignInfo
    if ns and ns.IsCampaignQuest and J.Bool(API("C_CampaignInfo", "IsCampaignQuest", questID)) then return true end
    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
        local classification = API("C_QuestInfoSystem", "GetQuestClassification", questID)
        return J.Number(classification) == (Enum and Enum.QuestClassification and Enum.QuestClassification.Campaign or 2)
    end
    return false
end

function J.ReadQuests(state)
    local currentMap = state.position and state.position.mapID
    local byID, log, campaigns, sources = {}, {}, {}, {log = 0, map = 0, lines = 0, tasks = 0}
    local entries = J.Number(API("C_QuestLog", "GetNumQuestLogEntries")) or 0
    for index = 1, entries do
        local info = API("C_QuestLog", "GetInfo", index)
        local id = J.Number(J.Field(info, "questID"))
        if id and id > 0 and not J.Bool(J.Field(info, "isHeader"))
            and not J.Bool(J.Field(info, "isHidden")) then
            log[id] = info
            sources.log = sources.log + 1
            local campaignID = J.Number(J.Field(info, "campaignID"))
            if campaignID and campaignID > 0 then campaigns[campaignID] = true end
        end
    end

    local function Add(id, point, line)
        if not J.Number(id) or id <= 0 then return end
        local info = log[id]
        if not info and J.Bool(API("C_QuestLog", "IsQuestFlaggedCompleted", id))
            and not (C_TaskQuest and J.Bool(API("C_TaskQuest", "IsActive", id))) then return end
        local q = byID[id] or {key = "quest:" .. id, questID = id, kind = "quest"}
        local title = J.String(J.Field(info, "title")) or J.String(J.Field(line, "questName"))
            or J.String(API("C_QuestLog", "GetTitleForQuestID", id))
        q.title = title or "Missão #" .. id
        q.accepted = info ~= nil
        q.worldQuest = C_QuestLog and C_QuestLog.IsWorldQuest
            and J.Bool(API("C_QuestLog", "IsWorldQuest", id)) or false
        q.campaign = q.campaign or IsCampaign(id, info, line)
        q.campaignID = J.Number(J.Field(info, "campaignID"))
        q.turnIn = q.accepted and J.Bool(API("C_QuestLog", "ReadyForTurnIn", id))
        q.action = q.turnIn and "Entregar" or (q.accepted and "Cumprir objetivo" or "Aceitar")
        local tag = API("C_QuestLog", "GetQuestTagInfo", id)
        local tagID = J.Number(J.Field(tag, "tagID"))
        q.instanced = tagID == 81 or tagID == 62 or tagID == 88
        local mapID = J.Number(J.Field(point, "mapID")) or currentMap
        local x, y = J.Number(J.Field(point, "x")), J.Number(J.Field(point, "y"))
        if q.accepted then
            local nextMap, nextX, nextY = API("C_QuestLog", "GetNextWaypoint", id)
            if J.Number(nextMap) and J.Number(nextX) and J.Number(nextY) then
                mapID, x, y = nextMap, nextX, nextY
            end
        end
        if mapID and x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
            q.mapID, q.x, q.y = mapID, x, y
            q.world = J.WorldPoint(mapID, x, y)
        end
        byID[id] = q
    end

    if currentMap then
        local mapQuests = API("C_QuestLog", "GetQuestsOnMap", currentMap)
        for _, point in ipairs(J.Table(mapQuests) or {}) do
            sources.map = sources.map + 1
            Add(J.Number(J.Field(point, "questID")), point)
        end
        local function AddLine(line)
            if not J.Table(line) then return end
            -- Campaign starts remain useful even if their level makes them trivial.
            if not J.Bool(J.Field(line, "isHidden")) or IsCampaign(J.Field(line, "questID"), nil, line) then
                sources.lines = sources.lines + 1
                -- Like Blizzard's QuestOfferPin, x/y belong to the requested map.
                -- startMapID identifies the origin and can be a child map.
                Add(J.Number(J.Field(line, "questID")), {
                    mapID = currentMap,
                    x = J.Field(line, "x"), y = J.Field(line, "y"),
                }, line)
            end
        end
        local lines = API("C_QuestLine", "GetAvailableQuestLines", currentMap)
        for _, line in ipairs(J.Table(lines) or {}) do AddLine(line) end
        -- The native map also includes forced quest offers outside the list above.
        if C_QuestLine and C_QuestLine.GetForceVisibleQuests and C_QuestLine.GetQuestLineInfo then
            for _, id in ipairs(J.Table(API("C_QuestLine", "GetForceVisibleQuests", currentMap)) or {}) do
                if J.Number(id) then AddLine(API("C_QuestLine", "GetQuestLineInfo", id, currentMap)) end
            end
        end
        if C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
            for _, point in ipairs(J.Table(API("C_TaskQuest", "GetQuestsOnMap", currentMap)) or {}) do
                sources.tasks = sources.tasks + 1
                Add(J.Number(J.Field(point, "questID")), point)
            end
        end
    end
    for id in pairs(log) do Add(id) end

    local quests = {}
    for _, q in pairs(byID) do
        q.distance = J.Distance(state.position and state.position.world, q.world)
        quests[#quests + 1] = q
    end
    table.sort(quests, function(a, b)
        local ad, bd = a.distance or math.huge, b.distance or math.huge
        if ad ~= bd then return ad < bd end
        return a.questID < b.questID
    end)
    return quests, campaigns, sources
end

function J.ReadCampaigns(logCampaigns)
    local ids = {}
    for id in pairs(logCampaigns) do ids[id] = true end
    for _, id in ipairs(J.Table(API("C_CampaignInfo", "GetAvailableCampaigns")) or {}) do
        if J.Number(id) and id > 0 then ids[id] = true end
    end
    local campaigns = {}
    for id in pairs(ids) do
        local info = API("C_CampaignInfo", "GetCampaignInfo", id)
        local chapterID = J.Number(API("C_CampaignInfo", "GetCurrentChapterID", id))
        local chapter = chapterID and API("C_CampaignInfo", "GetCampaignChapterInfo", chapterID)
        local reason = API("C_CampaignInfo", "GetFailureReason", id)
        campaigns[#campaigns + 1] = {
            id = id, name = J.String(J.Field(info, "name")) or "Campanha #" .. id,
            state = J.Number(API("C_CampaignInfo", "GetState", id)),
            chapterID = chapterID, chapter = J.String(J.Field(chapter, "name")),
            rewardQuestID = J.Number(J.Field(chapter, "rewardQuestID")),
            reason = J.String(J.Field(reason, "text")),
            blockedQuestID = J.Number(J.Field(reason, "questID")),
        }
    end
    table.sort(campaigns, function(a, b) return a.id < b.id end)
    return campaigns
end

function J.RefreshReadings()
    local state = J.ReadCharacter()
    if not state.position or not state.position.mapID then
        J.readings = {state = state, quests = {}, campaigns = {}, sources = {}, captured = J.Timestamp()}
        J.Error("map", "Localização indisponível agora. Aguardando o mapa do personagem.")
        J.Replan(true)
        return
    end
    J.errors.map = nil
    local mapID = state.position.mapID
    if J.requestedMap ~= mapID then
        J.requestedMap = mapID
        API("C_QuestLine", "RequestQuestLinesForMap", mapID)
    end
    local quests, logCampaigns, sources = J.ReadQuests(state)
    J.readings = {state = state, quests = quests, campaigns = J.ReadCampaigns(logCampaigns),
        sources = sources, captured = J.Timestamp()}
    J.Replan(false)
    J.Emit("readings")
end
