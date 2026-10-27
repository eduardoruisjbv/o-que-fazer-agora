# Graph Report - o-que-fazer-agora  (2026-10-26)

## Corpus Check
- 18 files · ~15,291 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 3 file(s) not represented in the graph (top: (none) 3)

## Summary
- 185 nodes · 415 edges · 12 communities (10 shown, 2 thin omitted)
- Extraction: 65% EXTRACTED · 35% INFERRED · 0% AMBIGUOUS · INFERRED: 145 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3f38ffe9`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- References and validation limits
- J.Call
- steps
- Automation.lua
- J.CreateUI
- J.Number
- Core.lua
- CHANGELOG.md
- ItemCache.lua
- automation.lua
- planner.lua

## God Nodes (most connected - your core abstractions)
1. `J.Number()` - 29 edges
2. `J.Call()` - 23 edges
3. `J.Initialize()` - 18 edges
4. `J.CreateUI()` - 17 edges
5. `J.ReadLoot()` - 16 edges
6. `J.API()` - 15 edges
7. `J.SyncAutomation()` - 14 edges
8. `J.Bool()` - 13 edges
9. `J.RefreshReadings()` - 12 edges
10. `J.Replan()` - 11 edges

## Surprising Connections (you probably didn't know these)
- `J.Report()` --calls--> `Add()`  [INFERRED]
  Journal.lua → tests/automation.lua
- `J.ReadQuests()` --calls--> `Add()`  [INFERRED]
  Readings.lua → tests/automation.lua
- `J.CreateUI()` --calls--> `J.AutoEnabled()`  [INFERRED]
  UI.lua → Automation.lua
- `J.UpdateModeUI()` --calls--> `J.AutoEnabled()`  [INFERRED]
  UI.lua → Automation.lua
- `Mutate()` --calls--> `J.Error()`  [INFERRED]
  Automation.lua → Core.lua

## Import Cycles
- None detected.

## Communities (12 total, 2 thin omitted)

### Community 0 - "References and validation limits"
Cohesion: 0.07
Nodes (27): Accepted quests and instanced steps (0.2.3), Automatic navigation (0.2.2), Available quests (0.2.1), Campaign and map, Loot, Minimap icon and mask, Quest actions, References and validation limits (+19 more)

### Community 1 - "J.Call"
Cohesion: 0.21
Nodes (24): J.RewardChoice(), NPC(), J.Call(), J.Error(), J.Field(), J.Plain(), J.String(), J.Table() (+16 more)

### Community 2 - "steps"
Cohesion: 0.08
Nodes (24): CF_API_TOKEN, tag, jobs, upload, name, permissions, contents, types (+16 more)

### Community 3 - "Automation.lua"
Cohesion: 0.21
Nodes (18): ClearOwnedDirection(), InCombat(), IsWatched(), J.AutoEnabled(), J.HandleAutomationEvent(), J.InitAutomation(), J.RequestAutoRewards(), J.RequestMode() (+10 more)

### Community 4 - "J.CreateUI"
Cohesion: 0.25
Nodes (16): J.BuildOptions(), J.OpenSettings(), Box(), Button(), CandidateCard(), Checkbox(), J.CreateMinimapButton(), J.CreateUI() (+8 more)

### Community 5 - "J.Number"
Cohesion: 0.26
Nodes (15): J.Initialize(), J.RefreshProgression(), J.ScheduleReadings(), J.CreateCompass(), J.LayoutCompass(), J.RelativeHeading(), J.SetupMapPins(), J.TickCompass() (+7 more)

### Community 6 - "Core.lua"
Cohesion: 0.25
Nodes (13): J.BeginActivity(), J.FinishActivity(), J.Ignore(), J.IsIgnored(), J.Now(), J.On(), J.Timestamp(), J.ChoosePlan() (+5 more)

### Community 7 - "CHANGELOG.md"
Cohesion: 0.20
Nodes (9): Just do it 0.2.10 — PvP status and item metadata cache, Just do it 0.2.11 — PvP and navigation fixes, Just do it 0.2.4 — First Release, Just do it 0.2.5 — Campaign progression fix, Just do it 0.2.6 — Session quest counter, Just do it 0.2.7 — HUD spacing, Just do it 0.2.8 — AzeriteUI top widget compatibility, Just do it 0.2.9 — Optional zone indicators (+1 more)

### Community 8 - "ItemCache.lua"
Cohesion: 0.39
Nodes (8): J.CachedItemAPI(), cache.Copy(), cache.Invalidate(), cache.Read(), cache.Scope(), pack(), plain(), wipeAll()

### Community 9 - "automation.lua"
Cohesion: 0.47
Nodes (3): Add(), Hook(), Remove()

## Knowledge Gaps
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `J.Number()` connect `J.Number` to `J.Call`, `Automation.lua`, `J.CreateUI`, `Core.lua`?**
  _High betweenness centrality (0.065) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `J.Number()` (e.g. with `ClearOwnedDirection()` and `IsWatched()`) actually correct?**
  _`J.Number()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **Should `References and validation limits` be split into smaller, more focused modules?**
  _Cohesion score 0.06666666666666667 - nodes in this community are weakly interconnected._
- **Why does `J.CreateUI()` connect `J.CreateUI` to `J.Call`, `Automation.lua`, `J.Number`, `Core.lua`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **Are the 17 inferred relationships involving `J.Call()` (e.g. with `J.InitAutomation()` and `J.RewardChoice()`) actually correct?**
  _`J.Call()` has 17 INFERRED edges - model-reasoned connections that need verification._
- **Should `steps` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Why does `J.Initialize()` connect `J.Number` to `J.Call`, `Automation.lua`, `J.CreateUI`, `Core.lua`?**
  _High betweenness centrality (0.050) - this node is a cross-community bridge._