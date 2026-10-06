local addonName, J = ...
J.name, J.version = addonName, "0.2.3"
J.icon = 4635196 -- Native WoW Explorer Compass trinket icon (FileDataID).
J.readings, J.errors, J.listeners = {}, {}, {}
J.primaryColor = {0.64, 0.71, 0.74} -- Muted blue grey.
J.secondaryColor = {0.73, 0.66, 0.55} -- Soft bronze.
J.defaults = {
    compass = true, minimap = true, minimapAngle = 220,
    corridor = 180, closeRadius = 150, closeRatio = 0.35,
    switchMargin = 0.15, switchSeconds = 4,
    compassWidth = 480, compassY = -40,
    mode = "semi", autoConsent = 0, autoRewards = false,
}

function J.Plain(value)
    return not (issecretvalue and issecretvalue(value))
end

function J.Number(value)
    if not J.Plain(value) or type(value) ~= "number" then return nil end
    if value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end

function J.String(value)
    if J.Plain(value) and type(value) == "string" then return value end
end

function J.Bool(value)
    return J.Plain(value) and value == true
end

function J.Table(value)
    return J.Plain(value) and type(value) == "table" and value or nil
end

function J.Field(value, key)
    if not J.Table(value) then return nil end
    local result = value[key]
    if J.Plain(result) then return result end
end

function J.Error(key, message)
    J.errors[key] = J.String(message) or "Dado protegido ou leitura indisponível."
end

-- Do not compare, format, serialize, or calculate with secret values in 12.x.
-- Nil is a legitimate empty answer; an unavailable/failed API is recorded separately.
function J.Call(key, fn, ...)
    if type(fn) ~= "function" then
        J.Error(key, "API indisponível neste cliente.")
        return nil
    end
    local function Pack(...) return {n = select("#", ...), ...} end
    local result = Pack(pcall(fn, ...))
    if not result[1] then J.Error(key, result[2]); return nil end
    J.errors[key] = nil
    for i = 2, result.n do
        if not J.Plain(result[i]) then
            result[i] = nil
            J.Error(key, "A API retornou um valor protegido; leitura suspensa.")
        end
    end
    return unpack(result, 2, result.n)
end

function J.API(namespace, method, ...)
    local api = _G[namespace]
    return J.Call(namespace .. "." .. method, api and api[method], ...)
end

function J.InitDB()
    JustDoItDB = type(JustDoItDB) == "table" and JustDoItDB or {}
    J.db = JustDoItDB
    J.db.settings = type(J.db.settings) == "table" and J.db.settings or {}
    -- Move the old untouched default, but preserve positions the player moved.
    if (J.db.schema or 0) < 2 and J.db.settings.compassY == -125 then
        J.db.settings.compassY = J.defaults.compassY
    end
    for key, value in pairs(J.defaults) do
        if type(J.db.settings[key]) ~= type(value) then J.db.settings[key] = value end
    end
    if J.db.settings.mode ~= "auto" or J.db.settings.autoConsent ~= 1 then
        J.db.settings.mode = "semi"
    end
    -- Clamp persisted values before they reach frame sizes or geometry.
    local ranges = {corridor = {25, 600}, closeRadius = {25, 500},
        closeRatio = {0.1, 0.8}, switchMargin = {0.05, 0.5}, switchSeconds = {1, 15},
        compassWidth = {320, 700}, compassY = {-500, -12}, minimapAngle = {0, 360}}
    for key, range in pairs(ranges) do
        local v = J.Number(J.db.settings[key]) or J.defaults[key]
        J.db.settings[key] = math.max(range[1], math.min(range[2], v))
    end
    J.db.ignored = type(J.db.ignored) == "table" and J.db.ignored or {}
    J.db.history = type(J.db.history) == "table" and J.db.history or {}
    J.db.ownedWatches = type(J.db.ownedWatches) == "table" and J.db.ownedWatches or {}
    J.db.schema = 2
end

function J.On(event, fn)
    J.listeners[event] = J.listeners[event] or {}
    table.insert(J.listeners[event], fn)
end

function J.Emit(event, ...)
    for _, fn in ipairs(J.listeners[event] or {}) do fn(...) end
end

function J.Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffa3b5bdJust do it|r: " .. message)
    end
end

function J.Now()
    return J.Number(J.Call("GetTime", GetTime)) or 0
end

function J.Timestamp()
    return J.Number(J.Call("GetServerTime", GetServerTime)) or time()
end

function J.IsIgnored(key)
    local expires = J.Number(J.db.ignored[key])
    if not expires then return false end
    if expires <= J.Timestamp() then J.db.ignored[key] = nil; return false end
    return true
end

function J.Ignore(candidate)
    if not candidate then return end
    J.db.ignored[candidate.key] = J.Timestamp() + 45 * 60
    if J.plan and J.plan.primary and J.plan.primary.key == candidate.key then
        J.plan, J.pendingPlan = nil, nil
        J.UpdateMapPins()
    end
    J.Replan(true)
end

function J.DistanceText(distance)
    if not J.Number(distance) then return "distância indisponível" end
    if distance >= 1000 then return string.format("%.1f km", distance / 1000) end
    return string.format("%d m", distance)
end

function J.BeginActivity(candidate)
    if not candidate then return end
    J.active = J.active or {}
    if not J.active[candidate.key] then
        J.active[candidate.key] = {started = J.Timestamp(), title = candidate.title}
    end
end

function J.FinishActivity(questID)
    local key = "quest:" .. questID
    local active = J.active and J.active[key]
    if not active then return end
    local seconds = math.max(0, J.Timestamp() - active.started)
    if seconds > 0 then
        local history = J.db.history[key] or {count = 0, total = 0}
        history.count, history.total = history.count + 1, history.total + seconds
        history.last = seconds
        J.db.history[key] = history
    end
    J.active[key] = nil
end
