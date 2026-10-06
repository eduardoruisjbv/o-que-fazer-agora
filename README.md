# Just do it

A character-focused World of Warcraft Retail 12.x addon that suggests the next activity for your character.

## Delivery status

**0.2.4 — first release, with Auto and Semi-auto modes.** Combines three game-data reads with quest guidance. Auto starts enabled by default; quest interactions remain manual in both modes. Full PvE equipment recommendations are still pending.

- Open the panel from the minimap or with `/jdi`; there is no login popup. The **Mode: Semi-auto / Auto** selector is at the top, with controls on the Settings tab. The compact circular button uses the native compass icon (FileDataID 4635196).
- Reads available campaigns, campaigns in the quest log, the current chapter, and blockers.
- Reads quest-log quests, map POIs, available quest lines, and world quests, including coordinates exposed by the game.
- Discovers dungeons through the Encounter Journal, reads Normal/Heroic/Mythic loot, and filters for the active specialization.
- Uses links and item levels returned by the game; it does not invent levels when data is unavailable.
- Semi-auto mode has a transparent horizontal compass at the top, with no background or border. The primary marker is muted blue-gray and the secondary marker soft bronze; P/S letters also distinguish them. Animation follows half the game's FPS (target minimum 30 Hz), with angular smoothing; position is polled separately at 10 Hz.
- Adds P/S pins to the map with tooltip labels. Semi-auto preserves the tracker and arrow; Auto adds suggestions to the tracker while preserving manual pins. In Auto, available quests receive a pin and accepted quests use their native quest tracking; manual pins take priority. **Follow Suggestion** lets you resume control.
- Includes proximity/corridor rules, stable suggestion switching, and a 45-minute exclusion for the exact activity.
- Provides a copyable report, also saved to `JustDoItDB.lastReport` when you leave the game.

The addon works for one player and does not communicate with other players. Encounter Journal queries are manual, out of combat, and require its native window to be closed. Each read restores the Journal's filters and previous visual selection. Secret 12.x data is neither compared nor serialized.

## Installation

Copy the **JustDoIt** folder (the one containing `JustDoIt.toc`) to `_retail_/Interface/AddOns/`. The in-game title is **Just do it**; the technical folder name has no spaces.

Declared interface: **120100**, matching the Retail addons on this machine. If installing on another patch, check the client's actual version.

## First-stage validation

1. Restart WoW if you added the folder while it was open. Enable **Just do it** in the addon list.
2. Enter a character with an active campaign in a zone with quests. Open `/jdi` and check the next-action details.
3. Run `/jdi probe` out of combat with the Encounter Journal closed.
4. On the **Readings** tab, check the campaign/chapter, quests/POIs, and coordinates. Compare them with the native map and quest log; zero quests/campaigns in an empty zone does not mean the API failed.
5. Check the discovered dungeon and its loot table. Use `<` and `>` to switch dungeons and the buttons to change difficulty. Compare item and item-level data with the native Encounter Journal using the same specialization.
6. Move and turn your character. Check P/S direction, distances, and hiding of external markers inside an instance. The next available campaign quest appears on the compass and map before you accept it; in Auto, the native indicator follows the main suggestion automatically when no manual pin exists.
7. Run `/jdi report`, copy the text with Ctrl+A/Ctrl+C, and save the result. It includes errors, pending data, and the actual client build.

The report exposes queried game data; it does not certify that a suggestion is the correct next step. Validation requires comparison in the client.

## Commands

| Command | Action |
| --- | --- |
| `/jdi` or `/justdoit` | Open/close the panel |
| `/jdi probe` | Open Readings and run all three queries |
| `/jdi report` | Open the copyable report |
| `/jdi config` | Open preview settings |
| `/jdi bussola` | Show/hide the compass |
| `/jdi seguir` | Start compass guidance |
| `/jdi outra` | Ignore the exact suggestion for 45 minutes |

Shift-drag moves the compass; dragging the minimap button moves its position on the minimap.

## Agreed next stage

After validating all three reads in the client, investigate real upgrade/crest costs, item level by difficulty, Delve loot, boss lockouts, weekly activities, Great Vault, difficulty history, queues, and XP bonuses. The automation available in 0.2.0 needs in-client exercise: switch modes, preserve manual pins/points, and talk to NPCs with multiple quests. Auto consent and additional reward permission are separate.

The full rules summary is in [docs/DESIGN.md](docs/DESIGN.md). API references are in [docs/API.md](docs/API.md).

Both modes leave quest selection, acceptance, completion, and rewards to the player. Auto tracks suggestions and updates native navigation; Semi-auto keeps the same suggestions and compass guidance while preserving the tracker and arrow. It does not enter queues or invent equipment upgrades from inspected loot. At max level, the interface identifies its suggestion as an **open-world preview** while the equipment engine awaits stage 2.

## Using the mode selector

1. Auto starts enabled. Run `/jdi` to check the mode at the top, or right-click the minimap button to open Settings.
2. Select **Semi-auto** to keep suggestions and compass guidance without changing native tracking, arrows, or pins.
3. In either mode, choose, accept, complete, and collect quest rewards manually.
4. Switch back to **Auto** to resume suggestion tracking and native navigation, respecting manual marks and pins.

Local checks of consent, pin ownership, and reward selection do not replace testing in the 12.x client.

In 0.2.3, available instanced steps from Readings appear as a subtle line below the compass, with campaign steps taking priority. They do not receive external direction; open-world deliveries return to normal selection. Full dungeon suggestions based on equipment are still pending.

In 0.2.4, Blizzard-provided travel instructions appear on the compass and panel. For those segments, Auto uses a waypoint, preferring the local route step when the game exposes one; accepted quests without a travel instruction continue using native quest tracking. The panel's instanced suggestion is clickable and opens the matching quest search when available, or Group Finder as a fallback.

## License

MIT. See [LICENSE](LICENSE).
