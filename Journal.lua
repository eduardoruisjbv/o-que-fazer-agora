local _, J = ...

local function LoadJournal()
    if InCombatLockdown and InCombatLockdown() then
        J.Error("journal", "Read the Encounter Journal out of combat.")
        return false
    end
    if EncounterJournal and EncounterJournal:IsShown() then
        J.Error("journal", "Close the Encounter Journal before querying; its filters will be preserved.")
        return false
    end
    if not EJ_GetInstanceByIndex then
        J.API("C_AddOns", "LoadAddOn", "Blizzard_EncounterJournal")
    end
    if not EJ_GetInstanceByIndex or not EJ_GetNumLoot or not C_EncounterJournal then
        J.Error("journal", "The Encounter Journal is not available in this client yet.")
        return false
    end
    return true
end

local function SaveContext()
    local classID, specID = J.Call("EJ_GetLootFilter", EJ_GetLootFilter)
    return {
        tier = J.Number(J.Call("EJ_GetCurrentTier", EJ_GetCurrentTier)),
        difficulty = J.Number(J.Call("EJ_GetDifficulty", EJ_GetDifficulty)),
        classID = J.Number(classID), specID = J.Number(specID),
        slot = J.Number(J.API("C_EncounterJournal", "GetSlotFilter")),
        instance = EncounterJournal and J.Number(EncounterJournal.instanceID),
        encounter = EncounterJournal and J.Number(EncounterJournal.encounterID),
    }
end

local function RestoreContext(context)
    if context.tier then J.Call("EJ_SelectTier", EJ_SelectTier, context.tier) end
    if context.instance then J.Call("EJ_SelectInstance", EJ_SelectInstance, context.instance) end
    if context.encounter then J.Call("EJ_SelectEncounter", EJ_SelectEncounter, context.encounter) end
    if context.difficulty then J.Call("EJ_SetDifficulty", EJ_SetDifficulty, context.difficulty) end
    if context.classID and context.specID then
        J.Call("EJ_SetLootFilter", EJ_SetLootFilter, context.classID, context.specID)
    end
    if context.slot then J.API("C_EncounterJournal", "SetSlotFilter", context.slot) end
end

local function WithContext(callback)
    if not LoadJournal() then return nil end
    local saved = SaveContext()
    local ok, result = pcall(callback)
    RestoreContext(saved)
    if not ok then J.Error("journal", result); return nil end
    J.errors.journal = nil
    return result
end

function J.DiscoverDungeons()
    local result = WithContext(function()
        local tiers = J.Number(J.Call("EJ_GetNumTiers", EJ_GetNumTiers)) or 0
        -- A new/journeys tier may have no dungeons; query backwards rather than
        -- assigning hardcoded expansion, map, boss, or item IDs.
        for tier = tiers, 1, -1 do
            J.Call("EJ_SelectTier", EJ_SelectTier, tier)
            local dungeons = {}
            for index = 1, 200 do
                local id, name, _, _, _, _, _, _, _, _, mapID =
                    J.Call("EJ_GetInstanceByIndex", EJ_GetInstanceByIndex, index, false)
                if not J.Number(id) then break end
                dungeons[#dungeons + 1] = {id = id, name = J.String(name) or "Dungeon #" .. id,
                    tier = tier, mapID = J.Number(mapID)}
            end
            if #dungeons > 0 then return dungeons end
        end
        return {}
    end)
    if not result then return false end
    J.dungeons, J.dungeonIndex = result, 1
    if #result == 0 then J.Error("journal", "The game returned no dungeons in the queried tiers.") end
    J.Emit("journal")
    return #result > 0
end

function J.ReadLoot(dungeon, difficulty, attempt, generation)
    if not dungeon then return end
    attempt = attempt or 1
    if not generation then
        J.journalGeneration = (J.journalGeneration or 0) + 1
        generation = J.journalGeneration
    elseif generation ~= J.journalGeneration then return end
    difficulty = difficulty or 1
    local result = WithContext(function()
        J.Call("EJ_SelectTier", EJ_SelectTier, dungeon.tier)
        J.Call("EJ_SelectInstance", EJ_SelectInstance, dungeon.id)
        local valid = J.Call("EJ_IsValidInstanceDifficulty", EJ_IsValidInstanceDifficulty, difficulty)
        if not J.Bool(valid) then
            return {dungeon = dungeon, difficulty = difficulty, items = {},
                message = "This difficulty is unavailable for the selected dungeon."}
        end
        J.Call("EJ_SetDifficulty", EJ_SetDifficulty, difficulty)
        local state = J.readings.state or J.ReadCharacter()
        if state.classID and state.specID then
            J.Call("EJ_SetLootFilter", EJ_SetLootFilter, state.classID, state.specID)
        end
        local allSlots = Enum and Enum.ItemSlotFilterType and Enum.ItemSlotFilterType.NoFilter or 0
        J.API("C_EncounterJournal", "SetSlotFilter", allSlots)
        local items, pending = {}, 0
        local count = J.Number(J.Call("EJ_GetNumLoot", EJ_GetNumLoot)) or 0
        for index = 1, math.min(count, 500) do
            local info = J.API("C_EncounterJournal", "GetLootInfoByIndex", index)
            local id = J.Number(J.Field(info, "itemID"))
            if id then
                local link = J.String(J.Field(info, "link"))
                local ilvl = link and J.Number(J.CachedItemAPI("GetDetailedItemLevelInfo", link))
                local item = {id = id, link = link, ilvl = ilvl,
                    name = J.String(J.Field(info, "name")),
                    slot = J.String(J.Field(info, "slot")),
                    encounterID = J.Number(J.Field(info, "encounterID")),
                    icon = J.Number(J.Field(info, "icon"))}
                if not link or not item.name or not ilvl then
                    pending = pending + 1
                    J.API("C_Item", "RequestLoadItemDataByID", id)
                end
                items[#items + 1] = item
            else pending = pending + 1 end
        end
        return {dungeon = dungeon, difficulty = difficulty, items = items, count = count,
            pending = pending, attempt = attempt, specID = state.specID, specName = state.specName,
            captured = J.Timestamp()}
    end)
    if not result then J.Emit("journal"); return end
    J.loot = result
    J.Emit("journal")
    -- Loot/link data are asynchronous. Retry with a bounded budget, preserving
    -- EJ context on EVERY pass; never leave its filters selected between ticks.
    if not result.message and (result.count == 0 or result.pending > 0) and attempt < 6 then
        C_Timer.After(0.8, function()
            if generation == J.journalGeneration then J.ReadLoot(dungeon, difficulty, attempt + 1, generation) end
        end)
    end
end

function J.Probe()
    J.RefreshReadings()
    if not J.dungeons or #J.dungeons == 0 then J.DiscoverDungeons() end
    local dungeon = J.dungeons and J.dungeons[J.dungeonIndex or 1]
    if dungeon then J.ReadLoot(dungeon, J.journalDifficulty or 1) end
end

local function Value(value)
    if value == nil then return "unavailable" end
    if type(value) == "boolean" then return value and "yes" or "no" end
    return tostring(value)
end

function J.Report()
    local r, lines = J.readings, {}
    local function Add(...) local a = {...}; for i, v in ipairs(a) do a[i] = Value(v) end; lines[#lines + 1] = table.concat(a, " ") end
    local version, build, _, interface = J.Call("GetBuildInfo", GetBuildInfo)
    Add("Just do it", J.version, "— feasibility report")
    Add("Client:", version or "?", "build", build or "?", "interface", interface or "?")
    Add("Captured:", r.captured or 0, "(epoch; no character name/GUID)")
    local state = r.state or {}
    Add("Level:", state.level or "?", "/", state.maxLevel or "?", "Group:", state.groupSize or 1)
    Add("Active specialization:", state.specName or "?", state.specID or "?")
    Add("Map:", state.position and state.position.mapID or "?")
    Add("Mode:", J.db.settings.mode, "consent", J.db.settings.autoConsent,
        "automatic rewards", J.db.settings.autoRewards)
    Add("")
    Add("CAMPAIGNS —", #(r.campaigns or {}), "returned")
    for _, c in ipairs(r.campaigns or {}) do
        Add("Campaign", c.id, c.name, "state", c.state or "?", "chapter", c.chapterID or "?", c.chapter or "")
        Add("  chapter reward:", c.rewardQuestID or "?", "(not assumed to be the next quest)")
        if c.reason then Add("  blocker:", c.reason, "quest", c.blockedQuestID or "?") end
    end
    if #(r.campaigns or {}) == 0 then Add("No campaigns returned in this context; this does not prove the API is blocked.") end
    Add("")
    local s = r.sources or {}
    Add("QUESTS — log", s.log or 0, "map", s.map or 0, "lines", s.lines or 0, "tasks", s.tasks or 0)
    for _, q in ipairs(r.quests or {}) do
        Add("Quest", q.questID, q.title, "campaign", q.campaign, "accepted", q.accepted, "action", q.action)
        if q.mapID then Add("  map", q.mapID, "x", string.format("%.5f", q.x), "y", string.format("%.5f", q.y), J.DistanceText(q.distance))
        else Add("  next coordinate is not exposed in this context") end
    end
    Add("")
    Add("LOOT — manual query; active specialization filter")
    if J.loot then
        local loot = J.loot
        Add("Dungeon:", loot.dungeon.id, loot.dungeon.name, "tier", loot.dungeon.tier, "difficulty", loot.difficulty)
        Add("Entries:", loot.count or 0, "pending data:", loot.pending or 0, "attempt", loot.attempt or 1)
        if loot.message then Add(loot.message) end
        for _, item in ipairs(loot.items) do
            Add("Item", item.id, item.name or "(carregando)", "slot", item.slot or "?", "ilvl", item.ilvl or "?", "boss", item.encounterID or "?")
            if item.link then Add("  ", item.link) end
        end
    else Add("Not queried. Click Run readings out of combat with the Journal closed.") end
    Add("")
    Add("ERRORS / RESTRICTIONS")
    local keys = {}; for key in pairs(J.errors) do keys[#keys + 1] = key end
    table.sort(keys)
    if #keys == 0 then Add("No errors captured; absence of an error does not equal in-client validation.") end
    for _, key in ipairs(keys) do Add(key .. ":", J.errors[key]) end
    Add("")
    Add("Pending: slot-by-slot gear, actual upgrade/crest costs, lockouts, Great Vault, XP, and difficulty data. Automation requires in-client confirmation.")
    local text = table.concat(lines, "\n")
    J.db.lastReport = text
    return text
end
