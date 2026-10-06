# Just do it — interview decisions

Final name: **Just do it**. Target: WoW Retail 12.x / Midnight. Lua.

## Principles

- Focus only on the character using the addon. No group-benefit calculations, inter-player protocols, or installation requirements for other players.
- Use actual game state and API discovery; no hand-maintained content catalog. Enumeration/difficulty IDs and behavior parameters are not quest/item catalogs.
- One main activity, with one open-world secondary activity on the compass. Queues and group formation can run in parallel.
- Minimap panel, no surprise popup, and no automatic queue entry.
- Auto starts enabled by default. Semi-auto keeps automatic readings, suggestions, and guidance, without changing the tracker or native arrow/pin.
- Accepting, selecting, completing, or collecting quest rewards is always a player action in both modes.

## Leveling

- Campaign progress takes priority, even when it awards little or no XP.
- Consider accepted, started, and available campaigns. Choose the next action by proximity; an accepted quest breaks ties.
- The next action may be completing an objective, turning in a quest, or accepting one; do not confuse the final chapter reward with the next step.
- If the campaign or its next step cannot be identified reliably, use current-map quests as a heuristic and mark the uncertainty.
- A distant campaign remains in the panel and on the compass. Do not arbitrarily suggest a new zone.
- Secondary quests fall within a corridor between the player and the campaign destination.
- An incomplete secondary quest may become primary if it is in the corridor, within a short radius, and much closer than the campaign.
- A turn-in at this exceptional proximity may become primary even outside the corridor.
- Reevaluate continuously, but switch only for a clear advantage that persists for several seconds.
- A group of two or more may receive a random dungeon as a secondary activity. Any active XP bonus allows it to replace the campaign as primary.
- If random queueing is unavailable, choose a specific dungeon by the largest confirmed XP reward; lower level requirement breaks ties. Availability discovery needs validation in 12.x.

## Max-level gear

- PvE-only niche for the MVP. Check slots from weakest to strongest until an available upgrade is found.
- Use the active specialization, regardless of loot specialization.
- Class/spec compatibility and item level are the MVP criteria; no stat, effect, or set weighting.
- An upgrade requires **more than +3 item levels**, not an inclusive +3.
- Compare against the achievable upgrade level of the equipped item using resources actually available; the track's theoretical maximum is not the same as a funded upgrade.
- Read loot through the Encounter Journal and actual game rewards. Item level by difficulty requires validation; do not invent missing values.
- Among activities that upgrade the same slot, choose the fastest; item-level gain breaks ties. This final decision gives duration precedence over expected gain discussed earlier.
- Without history, open-world content wins over an instance when both improve the slot. Among options of the same type, prefer the greater item-level gain.
- Crests can motivate content that enables upgrades; do not suggest going to spend crests at an NPC.
- Read lockouts, weekly activities, and Great Vault. Track boss and difficulty when the distinction is needed.
- Vault is an alternative after direct upgrades are exhausted. Prefer the highest item level within allowed progression; lower effort breaks ties.

## Content type and difficulty

- 1–2 players: quests and Delves.
- 3–5 players: dungeons and Mythic+.
- 6 or more: raids.
- These ranges are strict limits. Use Group Finder to fill an organized group for content requiring three or more players.
- Normal/Heroic dungeons use automatic queueing when available. Raid Finder is the queued raid difficulty; Normal/Heroic/Mythic require an organized group.
- History guides difficulty. Without history, start at the entry difficulty: Normal, LFR, or the first available Delve tier.
- Advance when the current difficulty is complete and offers no eligible upgrade in any slot, including drops/crests.
- Reuse history in new seasons, limited to content/difficulties that are available. Old completions do not imply current availability.

## Parallel activity and history

- Measure total duration from accepting a suggestion through completion: travel, queue, group formation, and the activity itself.
- A queue can run while the character does open-world content. Record parallel activities without treating one as abandonment of the other.
- While waiting, guide campaign progress. At most, complete available current-expansion campaign steps that can be done in the open world.
- After those steps, prioritize quests that improve gear; then choose other quests by proximity.
- Highlight the open-world quest in the panel, with the instance shown as a smaller **queued** item.
- Entering an instance pauses the open-world compass; leaving resumes it after reevaluation.
- With no direct upgrades or useful Vault progress, suggest repeatable entertainment and state that no upgrade is expected. Proximity/duration come first; completion frequency breaks ties.

## Tracking, arrow, and consent

- Horizontal compass, muted blue-gray primary marker, soft bronze secondary marker. P/S also distinguish roles without relying on color alone.
- Auto adds both suggestions to the tracker while preserving all manual choices. If there is no room, use the compass only.
- When suggestions change, remove only old marks owned by the addon. If the player takes ownership of a mark, preserve it.
- In Auto, a pin and the native indicator complement the compass and point to the primary suggestion automatically. A custom point can identify the addon on the map; the ability to change the native arrow's label/icon needs verification.
- Do not replace a manual point until **Follow Suggestion** is selected. A new manual point returns arrow control to the player; choosing Follow again allows the addon to resume.
- Semi-auto selects/updates objectives automatically but does not change the tracker or arrow.
- Auto does not select, accept, or turn in quests during NPC conversations. The conversation and quest actions remain with the player.
- Automatic reward selection requires separate permission, disabled by default. When enabled, choose the highest item level compatible with the active specialization, even if it is not an upgrade; ties remain manual.
- **Another Suggestion** ignores only the exact activity/difficulty for 45 minutes.
- Settings ship in the MVP with both modes. Future options appear when their features are implemented.

## Feasibility proof

1. Read the current campaign, list current-map quests with coordinates, and inspect one dungeon's loot.
2. After confirming those reads in a real client, validate the compass, automation, and gear/progression data before declaring the MVP complete.

Investigate alternatives for API-restricted functions; do not claim they work based only on compilation or mocks.

Initial adjustable prototype parameters: 180 m corridor, 150 m short radius, 35% relative proximity, 15% switch margin, and 4 s persistence. These are calibration values chosen for the first run, not content data or user-approved final decisions.

## Outside the MVP

- Configurable PvP and Mixed modes; weakest slot first, with events as tie-breakers in PvP.
- Direct gold when no item-level gain is available; confirmed rewards above a configurable threshold, initially 800 gold. No Auction House estimates.
- Reputation, achievements, and collectibles as long-term progression fallbacks.
