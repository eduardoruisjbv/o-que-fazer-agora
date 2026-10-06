local _, J = ...

function J.AutoEnabled()
    return J.db and J.db.settings.mode == "auto"
end

local function Mutate(callback)
    local previous = J.autoMutation
    J.autoMutation = true
    local ok, result = pcall(callback)
    J.autoMutation = previous
    if not ok then J.Error("automation", result); return nil end
    return result
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function ClearOwnedDirection()
    if J.nativeKey then
        J.API("C_SuperTrack", "SetSuperTrackedUserWaypoint", false)
        J.API("C_Map", "ClearUserWaypoint")
        J.nativeKey, J.db.nativeWaypointKey = nil, nil
    end
    if J.nativeQuestID then
        if J.Number(J.API("C_SuperTrack", "GetSuperTrackedQuestID")) == J.nativeQuestID then
            J.API("C_SuperTrack", "SetSuperTrackedQuestID", 0)
        end
        J.nativeQuestID = nil
    end
end

function J.SetMode(mode)
    if mode ~= "auto" and mode ~= "semi" then return end
    J.db.settings.mode = mode
    if mode == "auto" then
        -- Auto itself authorizes navigation. Keep an existing manual pin intact.
        J.directionGranted = J.nativeKey ~= nil or not J.Bool(J.API("C_Map", "HasUserWaypoint"))
    end
    if mode == "semi" then
        -- Clear only a point still controlled by us. A manual pin/quest change
        -- relinquishes this permission through the secure hooks below.
        if J.directionGranted and not InCombat() then
            Mutate(ClearOwnedDirection)
        end
        J.directionGranted, J.nativeKey, J.rewardPending = nil, nil, nil
    end
    J.SyncAutomation()
    J.Emit("mode")
end

StaticPopupDialogs.JUSTDOIT_REWARDS = {
    text = "Allow automatic reward selection in Auto mode?\n\n"
        .. "Just do it will choose the highest item-level item compatible with your active specialization, "
        .. "even if it does not improve your gear.\n\n"
        .. "Ties, incomplete data, and currency choices remain manual.",
    button1 = "Allow", button2 = "Cancel", timeout = 0,
    whileDead = true, hideOnEscape = true, preferredIndex = 3,
    OnAccept = function(_, settings)
        if not J.AutoEnabled() or J.db.settings ~= settings then return end
        settings.autoRewards = true
        J.Emit("mode")
    end,
    OnCancel = function() J.Emit("mode") end,
    OnHide = function() J.Emit("mode") end,
}

function J.RequestMode(mode)
    if mode == "semi" then
        StaticPopup_Hide("JUSTDOIT_REWARDS")
        J.SetMode("semi")
    elseif mode == "auto" then
        J.SetMode("auto")
    end
end

function J.RequestAutoRewards(enabled)
    if not enabled then
        J.db.settings.autoRewards = false
        J.rewardPending = nil
        StaticPopup_Hide("JUSTDOIT_REWARDS")
    elseif J.AutoEnabled() then
        StaticPopup_Show("JUSTDOIT_REWARDS", nil, nil, J.db.settings)
    end
    J.Emit("mode")
end

local function IsWatched(id, kind)
    if J.API("C_QuestLog", "GetQuestWatchType", id) ~= nil then return true end
    if kind == "world" then
        local count = J.Number(J.API("C_QuestLog", "GetNumWorldQuestWatches")) or 0
        for index = 1, count do
            if J.Number(J.API("C_QuestLog", "GetQuestIDForWorldQuestWatchIndex", index)) == id then return true end
        end
    end
    return false
end

local function RemoveOwnedWatch(id, kind)
    local removed = Mutate(function()
        return J.API("C_QuestLog", kind == "world" and "RemoveWorldQuestWatch" or "RemoveQuestWatch", id)
    end)
    if J.Bool(removed) or not IsWatched(id, kind) then
        J.db.ownedWatches[id] = nil
    end
end

function J.SyncAutomation()
    if not J.db or InCombat() then return end
    local desired = {}
    if J.AutoEnabled() then
        local plan = J.plan or {}
        for _, q in pairs({plan.primary, plan.secondary, plan.instanced}) do
            if q.questID and (q.accepted or q.worldQuest) then
                desired[q.questID] = q.worldQuest and "world" or "quest"
            end
        end
    end
    for id, kind in pairs(J.db.ownedWatches) do
        if not desired[id] then RemoveOwnedWatch(id, kind) end
    end
    if not J.AutoEnabled() then return end
    local noRoom = false
    for id, kind in pairs(desired) do
        if not J.manualExcluded[id] and not IsWatched(id, kind) then
            local added = Mutate(function()
                if kind == "world" then
                    local manual = Enum and Enum.QuestWatchType and Enum.QuestWatchType.Manual or 1
                    return J.API("C_QuestLog", "AddWorldQuestWatch", id, manual)
                end
                return J.API("C_QuestLog", "AddQuestWatch", id)
            end)
            if J.Bool(added) then J.db.ownedWatches[id] = kind else noRoom = true end
        end
    end
    J.autoStatus = noRoom and "Tracking unavailable or full; compass guidance remains active." or nil
    if not J.directionGranted then return end
    local q = J.plan and J.plan.primary
    if not q or (q.instanced and not q.turnIn) or J.Bool(J.Call("IsInInstance", IsInInstance)) then
        Mutate(ClearOwnedDirection)
        return
    end
    if q.accepted and q.questID and (not q.waypointText or not q.mapID or not q.x or not q.y) then
        -- Let Blizzard follow changing objectives/turn-in POIs for accepted quests.
        if J.nativeQuestID == q.questID
            and J.Number(J.API("C_SuperTrack", "GetSuperTrackedQuestID")) == q.questID then return end
        Mutate(function()
            ClearOwnedDirection()
            J.API("C_SuperTrack", "SetSuperTrackedQuestID", q.questID)
            if J.Number(J.API("C_SuperTrack", "GetSuperTrackedQuestID")) == q.questID then
                J.nativeQuestID = q.questID
            end
        end)
        return
    end
    if not q.mapID or not q.x or not q.y then return end
    local key = string.format("%d:%.6f:%.6f", q.mapID, q.x, q.y)
    if key == J.nativeKey then return end
    if not J.Bool(J.API("C_Map", "CanSetUserWaypointOnMap", q.mapID)) then return end
    if not UiMapPoint or not UiMapPoint.CreateFromCoordinates then return end
    local wasSet = Mutate(function()
        if J.nativeQuestID then ClearOwnedDirection() end
        local point = UiMapPoint.CreateFromCoordinates(q.mapID, q.x, q.y)
        local result = J.API("C_Map", "SetUserWaypoint", point)
        if J.Bool(result) then J.API("C_SuperTrack", "SetSuperTrackedUserWaypoint", true) end
        return result
    end)
    if J.Bool(wasSet) then J.nativeKey, J.db.nativeWaypointKey = key, key end
end

function J.InitAutomation()
    J.manualExcluded = {}
    J.On("plan", J.SyncAutomation)
    local function Added(id)
        if not J.db or J.autoMutation or not J.Number(id) then return end
        -- Existing marks and changes made outside this addon belong to player.
        J.db.ownedWatches[id], J.manualExcluded[id] = nil, nil
    end
    local function Removed(id)
        if not J.db or J.autoMutation or not J.Number(id) then return end
        J.db.ownedWatches[id], J.manualExcluded[id] = nil, true
    end
    if hooksecurefunc and C_QuestLog then
        for _, name in ipairs({"AddQuestWatch", "AddWorldQuestWatch"}) do
            if C_QuestLog[name] then hooksecurefunc(C_QuestLog, name, Added) end
        end
        for _, name in ipairs({"RemoveQuestWatch", "RemoveWorldQuestWatch"}) do
            if C_QuestLog[name] then hooksecurefunc(C_QuestLog, name, Removed) end
        end
    end
    if hooksecurefunc and C_Map and C_Map.SetUserWaypoint then
        hooksecurefunc(C_Map, "SetUserWaypoint", function()
            if not J.autoMutation then
                J.directionGranted, J.nativeKey, J.nativeQuestID = nil, nil, nil
                J.db.nativeWaypointKey = nil
            end
        end)
    end
    if hooksecurefunc and C_Map and C_Map.ClearUserWaypoint then
        hooksecurefunc(C_Map, "ClearUserWaypoint", function()
            if not J.autoMutation then
                J.directionGranted, J.nativeKey, J.nativeQuestID = nil, nil, nil
                J.db.nativeWaypointKey = nil
            end
        end)
    end
    if hooksecurefunc and C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
        hooksecurefunc(C_SuperTrack, "SetSuperTrackedQuestID", function(id)
            if J.autoMutation then return end
            local questID = J.Number(id)
            -- Blizzard clears supertracking (ID 0) on turn-in/watch removal.
            -- This is progression, not a request to suspend Auto navigation.
            if not questID or questID <= 0 then
                J.nativeQuestID = nil
                return
            end
            local primary = J.plan and J.plan.primary
            if primary and primary.questID == questID then return end
            -- Accepting a quest can also auto-select it before our event runs.
            local knownAccepted = false
            for _, q in ipairs(J.readings.quests or {}) do
                if q.questID == questID and q.accepted then knownAccepted = true; break end
            end
            if not knownAccepted and J.Bool(J.API("C_QuestLog", "IsOnQuest", questID)) then
                J.ScheduleReadings()
                return
            end
            J.directionGranted, J.nativeKey, J.nativeQuestID = nil, nil, nil
            J.db.nativeWaypointKey = nil
            J.db.ownedWatches[questID] = nil
        end)
    end
    -- Recognize our saved pin after reload; preserve all other existing pins.
    local existing = J.API("C_Map", "GetUserWaypoint")
    local position = J.Field(existing, "position")
    local mapID = J.Number(J.Field(existing, "uiMapID"))
    local x, y
    if position then x, y = J.Call("Waypoint:GetXY", position.GetXY, position) end
    local key = mapID and J.Number(x) and J.Number(y) and string.format("%d:%.6f:%.6f", mapID, x, y)
    if key and key == J.db.nativeWaypointKey then J.nativeKey = key end
    J.directionGranted = J.AutoEnabled() and (J.nativeKey ~= nil
        or not J.Bool(J.API("C_Map", "HasUserWaypoint"))) or nil
end

local function NPC()
    return J.String(J.Call("UnitGUID:npc", UnitGUID, "npc"))
end

function J.SelectNPCQuest()
    -- NPC quest selection is always a player action.
end

function J.SelectLegacyNPCQuest()
    -- Legacy NPC quest selection is always a player action.
end

function J.RewardChoice(count, specID)
    if not specID then return nil end
    local winner, best, tied
    for index = 1, count do
        local lootType = J.Number(J.Call("GetQuestItemInfoLootType", GetQuestItemInfoLootType, "choice", index))
        if lootType ~= 0 then return nil end
        local link = J.String(J.Call("GetQuestItemLink", GetQuestItemLink, "choice", index))
        if not link then return nil, true end
        local ilvl = J.Number(J.API("C_Item", "GetDetailedItemLevelInfo", link))
        local specs = J.Table(J.API("C_Item", "GetItemSpecInfo", link))
        if not ilvl or not specs then return nil, true end
        local compatible = false
        for _, id in ipairs(specs) do if J.Number(id) == specID then compatible = true; break end end
        if compatible then
            if not best or ilvl > best then winner, best, tied = index, ilvl, false
            elseif ilvl == best then tied = true end
        end
    end
    if not tied then return winner end
end

function J.TryQuestReward(attempt, pending)
    -- Quest rewards are always selected and accepted by the player.
end

function J.HandleAutomationEvent(event)
    if event == "PLAYER_REGEN_ENABLED" then J.SyncAutomation(); return end
    if event == "QUEST_FINISHED" or event == "GOSSIP_CLOSED" then J.rewardPending = nil; return end
    -- Keep all quest offers, completions, and rewards under player control.
end
