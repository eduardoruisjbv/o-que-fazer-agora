# References and validation limits

API signatures were checked on 2026-10-05 against Blizzard UI documentation and client-extracted UI source mirrored on the `live` branch of [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source). The branch may change; the addon report records the client build on which it actually ran.

## Campaign and map

- [WarCampaignDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/WarCampaignDocumentation.lua): `C_CampaignInfo.GetAvailableCampaigns`, `GetCampaignInfo`, `GetCurrentChapterID`, `GetCampaignChapterInfo`, `GetState`, `GetFailureReason`, `IsCampaignQuest`. `rewardQuestID` identifies a chapter reward; it is not an API for the next objective.
- [QuestLogDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua): quest log, `GetQuestsOnMap`, `GetNextWaypoint`, `ReadyForTurnIn`, titles, and completion.
- [QuestLineInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLineInfoDocumentation.lua): `C_QuestLine.GetAvailableQuestLines`, `RequestQuestLinesForMap`, `QuestLineInfo.isCampaign`, `GetForceVisibleQuests`, `GetQuestLineInfo`, `x`, `y`. Points use the requested map, as the native provider does; `startMapID` identifies the starting point, which may be on a child map.
- [QuestTaskInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestTaskInfoDocumentation.lua): world quests/map objectives through `C_TaskQuest.GetQuestsOnMap`.
- [MapDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua): player position and conversion to world coordinates. Conversion may not return a position on some maps.
- [ExpansionDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ExpansionDocumentation.lua): the **global** functions `GetClientDisplayExpansionLevel` and `GetMaxLevelForExpansionLevel`, without a `C_Expansion` namespace.

## Loot

- [EncounterJournalDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/EncounterJournalDocumentation.lua): `C_EncounterJournal.GetLootInfoByIndex`, item fields, and slot filtering.
- [Blizzard_EncounterJournal.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_EncounterJournal/Mainline/Blizzard_EncounterJournal.lua): discovery through `EJ_GetInstanceByIndex`, tier/instance/difficulty selection, and specialization filtering.
- [ItemDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua): `C_Item.GetDetailedItemLevelInfo` and asynchronous item loading.

The displayed item level is the value returned for the hyperlink from the Journal. Compare it in game at the same difficulty and specialization before using it for recommendations. Without a hyperlink or item level, the prototype marks the value **pending** rather than substituting an invented table.

## Stage 2 dependencies

- [ItemUpgradeDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemUpgradeDocumentation.lua): costs per item level in the upgrade context. `C_Item.GetItemUpgradeInfo.maxItemLevel` alone is a track ceiling, not an upgrade that can be funded with current crests.
- [WeeklyRewardsDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/WeeklyRewardsDocumentation.lua): activities, thresholds, and reward hyperlinks.
- [SuperTrackManagerDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SuperTrackManagerDocumentation.lua): quest/user waypoint selection. Auto uses it for the main suggestion when there is no manual pin; hooks return control after manual actions.
- [UnitAuraDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua): aura access has secret-value restrictions; do not treat an unknown buff as a confirmed XP bonus.

LuaJIT compilation and geometry tests do not validate frames, real coordinates, content availability, taint, or protected-action restrictions in the client. Stage 1 is complete only after comparing results in WoW.

## Minimap icon and mask

The [WoW-extracted listfile](https://github.com/wowdev/wow-listfile/blob/master/parts/interface.csv) identifies `4635196` as `INV_10_DungeonJewelry_Explorer_Trinket_1Compass_Color1`, `3528314` as `Interface/Masks/CircleMask.BLP`, and `136477` as the minimap button highlight. The icon was visually inspected before selection. These are native game files; no external image needs to be distributed.

## Quest actions

In both modes, selecting an NPC quest, accepting it, completing it, and choosing or collecting its rewards remain player actions. The addon automates only tracking and navigation described below. The native NPC interaction flow is implemented in Blizzard's [QuestFrame.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestFrame.lua) and [QuestInfo.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestInfo.lua), which expose `AcceptQuest`, `CompleteQuest`, `GetQuestReward`, and reward choice metadata; this addon does not invoke those quest actions. Item metadata read for the Encounter Journal uses a session cache; pending data is never replaced with an invented estimate.

`C_QuestLog.AddQuestWatch` / `AddWorldQuestWatch` and removal are tracked with persisted ownership of the marks. Safe hooks treat outside changes as player choices and suspend control of the arrow. This needs confirmation with the native tracker, installed tracker addons, manual changes, combat, and reload in the real client.

## Available quests (0.2.1)

The reading follows `QUESTLINE_UPDATE`, including a refresh request when its payload is true. It includes forced offers in addition to quest lines, following [QuestOfferDataProvider.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedMapDataProviders/QuestOfferDataProvider.lua). Trivial campaign quests remain eligible. Classification checks both the campaign and `C_QuestInfoSystem.GetQuestClassification`; a negative result from the first source does not block the second. Compass markers appear without requiring Follow; since 0.2.2, Auto also enables native automatic navigation while preserving manual pins.

## Automatic navigation (0.2.2)

Auto sets the main destination with `C_Map.SetUserWaypoint` and enables `C_SuperTrack.SetSuperTrackedUserWaypoint(true)` after confirming success. It updates only when coordinates change; changes during combat wait until combat ends. A pin that exists at startup/reload or is set manually suspends automatic native navigation while keeping the compass; Follow Suggestion lets it resume.

## Accepted quests and instanced steps (0.2.3)

Unaccepted quests use a waypoint; accepted open-world quests use `C_SuperTrack.SetSuperTrackedQuestID`, confirmed through `GetSuperTrackedQuestID`. The addon's waypoint is removed when switching to the quest. Waypoint ownership is persisted so it can resume after reload; manual pins remain untouched. Instanced steps detected through available tags receive subtle text below the compass; external markers are hidden inside instances. Classification depends on data exposed by the API and needs in-client confirmation.

## Travel instructions and group finder (0.2.4)

`GetNextWaypointText` provides travel instructions; `GetNextWaypointForMap` can use a local route step when the destination is on another map. Portal positions are not invented when data is unavailable. Group search uses the actual mapping from `C_LFGList.GetActivityIDForQuestID` and `LFGListUtil_FindQuestGroup`, documented in Blizzard's [LFGList.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_GroupFinder/Mainline/LFGList.lua). Without a mapping or with an active listing, it opens only the panel; it does not remove listings or join queues.
