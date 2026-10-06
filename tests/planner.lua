-- Pure regression checks, not a WoW client/API simulator.
-- Run from the project root: luajit tests/planner.lua
local J = {}
local now, epoch = 0, 100000
GetTime = function() return now end
GetServerTime = function() return epoch end
issecretvalue = function(value) return value == 999999 end
local function Load(file) assert(loadfile("JustDoIt/" .. file))("JustDoIt", J) end
Load("Core.lua")
Load("Readings.lua")
Load("Planner.lua")
Load("Compass.lua")
J.InitDB()
J.UpdateMapPins = function() end

local passed = 0
local function Check(condition, message)
    assert(condition, message)
    passed = passed + 1
end
local function World(x, y, continent) return {x = x, y = y, continent = continent or 1} end
local function Quest(id, x, y, campaign, turnIn, accepted)
    return {key = "quest:" .. id, questID = id, title = "Quest " .. id, mapID = 10,
        x = 0.5, y = 0.5, world = World(x, y), campaign = campaign or false,
        turnIn = turnIn or false, accepted = accepted or false}
end
local state = {position = {mapID = 10, world = World(0, 0)}, atMax = false}
local settings = J.db.settings

Check(J.InCorridor(World(0, 0), World(1000, 0), World(500, 100), 180), "inside corridor")
Check(not J.InCorridor(World(0, 0), World(1000, 0), World(500, 181), 180), "outside corridor")
Check(not J.InCorridor(World(0, 0), World(1000, 0), World(-10, 0), 180), "behind player")
Check(not J.InCorridor(World(0, 0), World(1000, 0), World(1010, 0), 180), "past destination")
Check(not J.InCorridor(World(0, 0), World(1000, 0), World(100, 0, 2), 180), "different continent")
Check(J.InCorridor(World(0, 0), World(0, 0), World(50, 0), 180), "zero-length corridor")

local campaign = Quest(1, 1000, 0, true)
local close = Quest(2, 100, 0)
local plan = J.ChoosePlan({campaign, close}, state, settings)
Check(plan.primary == close and plan.secondary == campaign, "near secondary temporarily leads")
local outside = Quest(3, -50, 0)
plan = J.ChoosePlan({campaign, outside}, state, settings)
Check(plan.primary == campaign and not plan.secondary, "unfinished quest behind player does not lead")
outside.turnIn = true
plan = J.ChoosePlan({campaign, outside}, state, settings)
Check(plan.primary == outside and plan.secondary == campaign, "near delivery may lead outside corridor")
local distantSecondary = Quest(4, 500, 20)
plan = J.ChoosePlan({campaign, distantSecondary}, state, settings)
Check(plan.primary == campaign and plan.secondary == distantSecondary, "corridor side quest remains secondary")

local sameDistance = Quest(5, 1000, 0, true, false, true)
plan = J.ChoosePlan({campaign, sameDistance}, state, settings)
Check(plan.primary == sameDistance, "accepted campaign breaks a distance tie")
local instanceQuest = Quest(6, 10, 0, true)
instanceQuest.instanced = true
plan = J.ChoosePlan({campaign, instanceQuest}, state, settings)
Check(plan.primary == campaign, "instance objective is not mistaken for open-world guidance")
plan = J.ChoosePlan({close, distantSecondary}, state, settings)
Check(plan.heuristic and plan.primary == close, "map heuristic when no confirmed campaign")

J.db.ignored[close.key] = epoch + 2700
plan = J.ChoosePlan({campaign, close}, state, settings)
Check(plan.primary == campaign, "exact quest exclusion respected")
epoch = epoch + 2701
Check(not J.IsIgnored(close.key), "exclusion expires after 45 minutes")

J.readings = {state = state, quests = {campaign, distantSecondary}}
J.Replan(true)
J.readings.quests = {campaign, close}
J.Replan(false)
Check(J.plan.primary == campaign, "do not switch immediately")
now = now + settings.switchSeconds - 0.1
J.Replan(false)
Check(J.plan.primary == campaign, "advantage must persist")
now = now + 0.2
J.Replan(false)
Check(J.plan.primary == close, "switch after sustained advantage")
J.readings.quests = {campaign}
J.Replan(false)
Check(J.plan.primary == campaign, "removed objective replaced without stale guidance")

local a, b, c = J.Call("tuple", function() return 12, nil, 34 end)
Check(a == 12 and b == nil and c == 34, "preserve nil holes in API tuples")
a, b = J.Call("secret", function() return 999999, 7 end)
Check(a == nil and b == 7 and J.errors.secret ~= nil, "secret result withheld")
Check(J.Call("missing", nil) == nil and J.errors.missing ~= nil, "missing API distinguished from empty result")
J.Call("empty", function() return nil end)
Check(J.errors.empty == nil, "legitimate empty result not reported as API failure")

Check(math.abs(J.RelativeHeading(World(0, 0), World(100, 0), 0)) < 0.001, "north when facing north")
Check(math.abs(J.RelativeHeading(World(0, 0), World(0, 100), 0) - math.pi / 2) < 0.001, "west lies to left")
Check(J.RelativeHeading(World(0, 0), World(0, 0, 2), 0) == nil, "no cross-continent bearing")

print(string.format("%d pure regression checks passed. Client/API validation still required.", passed))
