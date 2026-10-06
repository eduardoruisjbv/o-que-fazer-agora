# Just do it 0.2.9 — Optional zone indicators

- Hide Blizzard's top-centre zone indicators by default, preserving their native/AzeriteUI position.
- Add a settings checkbox to restore their visibility.
- Keep the session counter beside the compass.

In-game confirmation is pending.

# Just do it 0.2.8 — AzeriteUI top widget compatibility

- Move AzeriteUI's TopCenterWidgets wrapper instead of fighting its native widget SetPoint hook.
- Use the wrapper bounds to detect overlap, and restore that wrapper's original position when disabling the compass.

In-game confirmation is pending.

# Just do it 0.2.7 — HUD spacing

- Move the session counter to the right of the compass.
- Move the native top-centre zone/PvP score container below the compass when it overlaps the HUD.
- Restore native anchors when the compass is disabled; defer changes during combat or for protected frames.

In-game confirmation is pending.

# Just do it 0.2.6 — Session quest counter

- Add a small muted session quest counter below the compass, without a background or popups.
- Increment on quest turn-in, in both Auto and Semi-auto modes.
- Preserve the count through UI reloads and zoning; reset on a new character login.
- Position below the instance hint when it is visible to avoid overlap.

In-game confirmation is pending.

# Just do it 0.2.5 — Campaign progression fix

- Refresh available quest lines after quest acceptance, removal and turn-in, with bounded retries for asynchronous game data.
- Exclude just turned-in quests immediately while the quest log catches up.
- Keep Auto navigation active when Blizzard clears its quest tracker after turn-in, or selects a newly accepted quest.
- Read campaign membership from the native campaign API and quest-line metadata for accepted steps.
- Manual pins and explicit selection of another known quest keep priority.

In-game confirmation of consecutive campaign transitions is pending.

# Just do it 0.2.4 — First Release

- Transparent compass with smooth heading and muted main/secondary markers.
- Live campaign and nearby quest suggestions, including available quests.
- Semi-auto mode and opt-in Auto mode with separate reward selection consent.
- Blizzard pins for available quests and route waypoints; native tracking for accepted outdoor quests.
- Route instructions from Blizzard shown in the compass and panel, including portal/transport guidance when exposed by the game.
- Clickable instance suggestion opens the matching quest group search when available, or Group Finder.
- Minimap panel, settings and a 45-minute skip for the current suggestion.
- Manual campaign/map diagnostics and Encounter Journal dungeon loot inspection.

## Scope

This release focuses on quest navigation. Full endgame equipment, crest, lockout and Great Vault recommendations remain in development. Route details depend on the data exposed by the game. No automatic queue entry. In-game validation is ongoing.

WoW Retail 12.1.0. MIT license.
