-- Behavioral regression checks for consent and player-owned state.
-- Does not certify Blizzard API/taint behavior: run in the real client too.
local J, hooks = {}, {}
StaticPopupDialogs = {}
StaticPopup_Show = function() end
StaticPopup_Hide = function() end
GetTime = function() return 1 end
GetServerTime = function() return 100 end
InCombatLockdown = function() return false end
Enum = {QuestWatchType = {Manual = 1}}
hooksecurefunc = function(object, name, fn)
    hooks[object] = hooks[object] or {}
    hooks[object][name] = fn
end
local function Hook(object, name, ...)
    if hooks[object] and hooks[object][name] then hooks[object][name](...) end
end
local watched, capacity = {[99] = "quest"}, 3
local function Add(id, kind, name)
    local count = 0; for _ in pairs(watched) do count = count + 1 end
    local result = watched[id] ~= nil or count < capacity
    if result then watched[id] = kind end
    Hook(C_QuestLog, name, id)
    return result
end
local function Remove(id, name)
    local result = watched[id] ~= nil
    watched[id] = nil
    Hook(C_QuestLog, name, id)
    return result
end
C_QuestLog = {
    GetQuestWatchType = function(id) if watched[id] == "quest" then return 1 end end,
    AddQuestWatch = function(id) return Add(id, "quest", "AddQuestWatch") end,
    AddWorldQuestWatch = function(id) return Add(id, "world", "AddWorldQuestWatch") end,
    RemoveQuestWatch = function(id) return Remove(id, "RemoveQuestWatch") end,
    RemoveWorldQuestWatch = function(id) return Remove(id, "RemoveWorldQuestWatch") end,
    GetNumWorldQuestWatches = function()
        local n = 0; for _, kind in pairs(watched) do if kind == "world" then n = n + 1 end end; return n
    end,
    GetQuestIDForWorldQuestWatchIndex = function(index)
        local n = 0; for id, kind in pairs(watched) do if kind == "world" then n = n + 1; if n == index then return id end end end
    end,
}
local pin, pinWrites, cleared = nil, 0, 0
C_Map = {
    CanSetUserWaypointOnMap = function() return true end,
    SetUserWaypoint = function(point)
        pin, pinWrites = point, pinWrites + 1; Hook(C_Map, "SetUserWaypoint", point); return true
    end,
    ClearUserWaypoint = function() pin, cleared = nil, cleared + 1; Hook(C_Map, "ClearUserWaypoint") end,
}
C_SuperTrack = {
    SetSuperTrackedUserWaypoint = function() end,
    SetSuperTrackedQuestID = function(id) Hook(C_SuperTrack, "SetSuperTrackedQuestID", id) end,
}
UiMapPoint = {CreateFromCoordinates = function(mapID, x, y) return {mapID = mapID, x = x, y = y} end}
assert(loadfile("JustDoIt/Core.lua"))("JustDoIt", J)
assert(loadfile("JustDoIt/Automation.lua"))("JustDoIt", J)
J.InitDB()
J.InitAutomation()
local passed = 0
local function Check(condition, message) assert(condition, message); passed = passed + 1 end
local function Quest(id, world)
    return {questID = id, accepted = not world, worldQuest = world, mapID = 10, x = 0.3, y = 0.4}
end
J.plan = {primary = Quest(1), secondary = Quest(2)}
J.SyncAutomation()
Check(not watched[1] and watched[99], "initial auto mode waits for tracking setup")
J.SetMode("auto")
Check(J.AutoEnabled() and watched[1] and watched[2], "auto is enabled by default and tracks suggestions")
Check(watched[99] and not J.db.ownedWatches[99], "pre-existing manual mark stays player-owned")
Check(not J.db.settings.autoRewards, "quest rewards remain player-controlled")
Check(pinWrites == 0, "auto activation does not overwrite player's pin")
J.plan = {primary = Quest(3), secondary = Quest(4)}
J.SyncAutomation()
Check(not watched[1] and not watched[2] and watched[3] and watched[4], "replace only previous addon marks")
Check(watched[99], "manual mark survives suggestion rotation")
C_QuestLog.AddQuestWatch(3)
Check(not J.db.ownedWatches[3], "player can assume an addon mark")
J.plan = {primary = Quest(5), secondary = Quest(4)}
J.SyncAutomation()
Check(watched[3] and watched[99] and not watched[5], "never evict manual marks to make room")
Check(J.autoStatus ~= nil, "full tracker leaves compass fallback")
J.SetMode("semi")
Check(watched[3] and watched[99] and not watched[4], "disabling auto removes only owned marks")
capacity = 10
J.SetMode("auto")
C_QuestLog.RemoveQuestWatch(5)
J.SyncAutomation()
Check(not watched[5], "respect explicit player untracking")

J.directionGranted = true
J.SyncAutomation()
Check(pinWrites == 1 and pin.mapID == 10, "map mutation requires follow grant")
J.SyncAutomation()
Check(pinWrites == 1, "stable destination does not rewrite map pin")
local manualPin = {mapID = 20, x = 0.8, y = 0.1}
C_Map.SetUserWaypoint(manualPin)
J.SyncAutomation()
Check(pin == manualPin and not J.directionGranted, "manual pin revokes addon direction control")
J.SetMode("semi")
Check(pin == manualPin and cleared == 0, "semi-auto cannot clear the replacement manual pin")

J.SetMode("auto")
J.plan = {primary = Quest(7, true), secondary = Quest(8)}
watched[7] = "world"
J.SyncAutomation()
Check(not J.db.ownedWatches[7], "existing world quest stays manually owned even without quest watch type")
J.db.settings.autoRewards = true -- Simulate an old saved setting.
J.InitDB()
Check(not J.db.settings.autoRewards, "obsolete automatic reward permission is cleared")
J.RequestAutoRewards(false)
Check(not J.db.settings.autoRewards, "reward permission can be revoked")

local data = {one = {ilvl = 200, specs = {1}}, two = {ilvl = 220, specs = {1}}, wrong = {ilvl = 999, specs = {2}}}
local choices = {"one", "two", "wrong"}
GetQuestItemInfoLootType = function() return 0 end
GetQuestItemLink = function(_, index) return choices[index] end
C_Item = {
    GetDetailedItemLevelInfo = function(link) return data[link] and data[link].ilvl end,
    GetItemSpecInfo = function(link) return data[link] and data[link].specs end,
}
Check(J.RewardChoice(3, 1) == 2, "highest ilvl only among active-spec-compatible items")
choices = {"two", "two"}
Check(J.RewardChoice(2, 1) == nil, "reward ties remain manual")
choices = {"one", "pending"}
local choice, loading = J.RewardChoice(2, 1)
Check(choice == nil and loading, "incomplete rewards cannot be chosen prematurely")
GetQuestItemInfoLootType = function() return 1 end
Check(J.RewardChoice(1, 1) == nil, "currency choices remain manual")

local rewarded, accepted = 0, 0
local npc = nil
UnitGUID = function() return npc end
GetQuestID = function() return 10 end
GetQuestMoneyToGet = function() return 0 end
GetNumQuestChoices = function() return 0 end
GetQuestReward = function() rewarded = rewarded + 1 end
AcceptQuest = function() accepted = accepted + 1 end
J.HandleAutomationEvent("QUEST_DETAIL")
J.HandleAutomationEvent("QUEST_COMPLETE")
Check(rewarded == 0 and accepted == 0, "no NPC context produces no quest actions")
npc = "npc-test"
J.HandleAutomationEvent("QUEST_DETAIL")
J.HandleAutomationEvent("QUEST_COMPLETE")
Check(rewarded == 0 and accepted == 0, "auto leaves quest acceptance and delivery to the player")
GetNumQuestChoices = function() return 1 end
J.HandleAutomationEvent("QUEST_COMPLETE")
Check(rewarded == 0, "auto never selects or claims quest rewards")
GetNumQuestChoices = function() return 0 end
GetQuestMoneyToGet = function() return 100 end
J.HandleAutomationEvent("QUEST_COMPLETE")
Check(rewarded == 0, "quest completion remains a player action even when gold is required")
J.SetMode("semi")
J.HandleAutomationEvent("QUEST_DETAIL")
Check(accepted == 0, "semi-auto leaves quests to the player too")

print(passed .. " automation behavior checks passed. Real client validation remains required.")
