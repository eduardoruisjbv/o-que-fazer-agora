local _, J = ...

function J.InCorridor(player, destination, point, width)
    if not player or not destination or not point or player.continent ~= destination.continent
        or player.continent ~= point.continent then return false end
    local dx, dy = destination.x - player.x, destination.y - player.y
    local length2 = dx * dx + dy * dy
    if length2 == 0 then return (J.Distance(player, point) or math.huge) <= width end
    local t = ((point.x - player.x) * dx + (point.y - player.y) * dy) / length2
    if t < 0 or t > 1 then return false end
    local x, y = player.x + t * dx, player.y + t * dy
    local px, py = point.x - x, point.y - y
    return px * px + py * py <= width * width
end

local function Nearest(a, b)
    local ad, bd = a.distance or math.huge, b.distance or math.huge
    if ad ~= bd then return ad < bd end
    if a.accepted ~= b.accepted then return a.accepted end
    return a.questID < b.questID
end

function J.ChoosePlan(quests, state, settings)
    local campaigns, secondary, instanced = {}, {}, {}
    for _, q in ipairs(quests) do
        q.distance = J.Distance(state.position and state.position.world, q.world)
        if not J.IsIgnored(q.key) then
            if q.instanced and not q.turnIn then instanced[#instanced + 1] = q
            elseif q.campaign then campaigns[#campaigns + 1] = q
            elseif q.world and q.mapID == (state.position and state.position.mapID) then secondary[#secondary + 1] = q end
        end
    end
    table.sort(campaigns, Nearest)
    table.sort(secondary, Nearest)
    table.sort(instanced, function(a, b)
        if a.campaign ~= b.campaign then return a.campaign end
        return Nearest(a, b)
    end)
    local campaign, main, side = campaigns[1]
    if campaign then
        main = campaign
        local player = state.position and state.position.world
        for _, q in ipairs(secondary) do
            local inCorridor = J.InCorridor(player, campaign.world, q.world, settings.corridor)
            local exceptional = q.distance and campaign.distance and q.distance <= settings.closeRadius
                and q.distance < campaign.distance * settings.closeRatio
            if exceptional and (inCorridor or q.turnIn) then
                main, side = q, campaign
                break
            elseif inCorridor and not side then side = q end
        end
    else main, side = secondary[1], secondary[2] end
    return {primary = main, secondary = side, campaign = campaign, instanced = instanced[1], heuristic = not campaign,
        preview = state.atMax, reason = campaign and "Campaign and objectives along the route"
            or "Nearby quests · campaign not confirmed"}
end

local function Same(a, b)
    return (a and a.key or "") == (b and b.key or "")
end

function J.Replan(force)
    if not J.db or not J.readings.state then return end
    local wanted = J.ChoosePlan(J.readings.quests or {}, J.readings.state, J.db.settings)
    local current = J.plan
    if force or not current or not current.primary then
        J.plan, J.pendingPlan = wanted, nil
    elseif Same(current.primary, wanted.primary) then
        -- Coordinates may change after a quest objective is completed. Refresh
        -- the same quest immediately; stabilize changes to the secondary, too.
        current.primary, current.campaign = wanted.primary, wanted.campaign
        current.reason, current.preview, current.heuristic = wanted.reason, wanted.preview, wanted.heuristic
        if Same(current.secondary, wanted.secondary) then
            current.secondary, J.pendingPlan = wanted.secondary, nil
        else
            local key = "secondary:" .. (wanted.secondary and wanted.secondary.key or "none")
            if not J.pendingPlan or J.pendingPlan.key ~= key then
                J.pendingPlan = {key = key, since = J.Now()}
            elseif J.Now() - J.pendingPlan.since >= J.db.settings.switchSeconds then
                current.secondary, J.pendingPlan = wanted.secondary, nil
            end
        end
    else
        local stillAvailable = false
        for _, q in ipairs(J.readings.quests or {}) do
            if q.key == current.primary.key and not J.IsIgnored(q.key) then
                stillAvailable = true
                current.primary = q
                break
            end
        end
        if not stillAvailable then J.plan, J.pendingPlan = wanted, nil
        else
            local a, b = current.primary, wanted.primary
            local priorityChanged = b and (a.campaign ~= b.campaign or a.turnIn ~= b.turnIn)
            local clearlyCloser = b and b.distance and a.distance
                and b.distance < a.distance * (1 - J.db.settings.switchMargin)
            if priorityChanged or clearlyCloser then
                if not J.pendingPlan or J.pendingPlan.key ~= b.key then
                    J.pendingPlan = {key = b.key, since = J.Now()}
                elseif J.Now() - J.pendingPlan.since >= J.db.settings.switchSeconds then
                    J.plan, J.pendingPlan = wanted, nil
                end
            else J.pendingPlan = nil end
        end
    end
    J.plan.instanced = wanted.instanced
    J.UpdateMapPins()
    J.Emit("plan")
end

function J.FollowSuggestion()
    local q = J.plan and J.plan.primary
    if not q then return end
    J.following = q.key
    J.BeginActivity(q)
    if J.AutoEnabled() then
        J.directionGranted = true
        J.nativeKey = nil
        J.SyncAutomation()
    end
    J.Print("Seguindo: " .. q.title)
    J.Emit("plan")
end
