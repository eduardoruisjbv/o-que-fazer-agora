local _, J = ...
local pi = math.pi

function J.RelativeHeading(player, target, facing)
    if not player or not target or player.continent ~= target.continent or not J.Number(facing) then return nil end
    -- WoW world coordinates: x increases north, y increases west. Facing zero
    -- is north and positive angles rotate west. Positive delta is left on HUD.
    local angle = math.atan2(target.y - player.y, target.x - player.x)
    return (angle - facing + pi) % (2 * pi) - pi
end

local function Marker(parent, color, symbol)
    local marker = CreateFrame("Button", nil, parent)
    marker:SetSize(26, 28)
    marker.glyph = marker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    marker.glyph:SetPoint("CENTER")
    marker.glyph:SetText(symbol)
    marker.glyph:SetTextColor(unpack(color))
    marker.glyph:SetShadowOffset(1, -1)
    marker.distance = marker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    marker.distance:SetPoint("TOP", marker, "BOTTOM", 0, 0)
    marker.distance:SetTextColor(unpack(color))
    marker.distance:SetShadowOffset(1, -1)
    marker:SetScript("OnEnter", function(self)
        if not self.candidate then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Just do it · " .. (self.primary and "Principal" or "Secundária"), unpack(color))
        GameTooltip:AddLine(self.candidate.title, 1, 1, 1, true)
        GameTooltip:AddLine(self.candidate.action .. " · " .. J.DistanceText(self.candidate.distance), 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    marker:SetScript("OnLeave", function() GameTooltip:Hide() end)
    marker:Hide()
    return marker
end

function J.CreateCompass()
    local frame = CreateFrame("Frame", "JustDoItCompass", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local centerY = select(2, self:GetCenter())
        J.db.settings.compassY = math.max(-500, math.min(-12, centerY - UIParent:GetHeight() + self:GetHeight() / 2))
        J.LayoutCompass()
    end)
    frame.heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.heading:SetPoint("TOP", 0, -2)
    frame.heading:SetTextColor(0.75, 0.8, 0.82)
    frame.heading:SetShadowOffset(1, -1)
    frame.instanceHint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.instanceHint:SetPoint("TOP", frame, "BOTTOM", 0, -3)
    frame.instanceHint:SetWidth(480)
    frame.instanceHint:SetTextColor(0.67, 0.68, 0.66, 0.75)
    frame.instanceHint:SetShadowOffset(1, -1)
    local center = frame:CreateTexture(nil, "ARTWORK")
    center:SetColorTexture(0.88, 0.91, 0.93, 0.45)
    center:SetSize(1, 10)
    center:SetPoint("CENTER", 0, 4)
    frame.labels = {}
    for i = 1, 8 do
        local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("CENTER", 0, 4)
        label:SetTextColor(0.82, 0.85, 0.86, 0.6)
        label:SetShadowOffset(1, -1)
        frame.labels[i] = label
    end
    frame.primary = Marker(frame, J.primaryColor, "P")
    frame.primary.primary = true
    frame.secondary = Marker(frame, J.secondaryColor, "S")
    frame.elapsed, frame.renderElapsed, frame.positionElapsed, frame.rateElapsed = 0, 0, 0.1, 1
    frame.animationFPS = 60
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        self.renderElapsed = self.renderElapsed + elapsed
        self.positionElapsed = self.positionElapsed + elapsed
        self.rateElapsed = self.rateElapsed + elapsed
        if self.rateElapsed >= 1 then
            local fps = J.Number(J.Call("GetFramerate", GetFramerate)) or 60
            self.animationFPS = math.max(30, fps / 2)
            self.rateElapsed = 0
        end
        local interval = 1 / self.animationFPS
        if self.elapsed + 0.00001 < interval then return end
        local dt = self.renderElapsed
        self.elapsed = math.max(0, self.elapsed - interval) % interval
        self.renderElapsed = 0
        J.TickCompass(dt)
    end)
    J.compass = frame
    J.LayoutCompass()
end

function J.LayoutCompass()
    if not J.compass then return end
    J.compass:ClearAllPoints()
    J.compass:SetPoint("TOP", UIParent, "TOP", 0, J.db.settings.compassY)
    J.compass:SetSize(J.db.settings.compassWidth, 44)
    J.TickCompass()
end

function J.TickCompass(elapsed)
    local frame = J.compass
    if not frame then return end
    frame:EnableMouse(IsShiftKeyDown())
    -- World/map conversion remains 10 Hz, independently of the smooth heading.
    if not frame.position or frame.positionElapsed >= 0.1 then
        frame.position = J.Position()
        frame.inInstance = J.Bool(J.Call("IsInInstance", IsInInstance))
        frame.positionElapsed = 0
    end
    local inInstance = frame.inInstance
    frame:SetShown(J.db.settings.compass)
    if not frame:IsShown() then return end
    local position = frame.position
    local player = position and position.world
    local facing = J.Number(J.Call("GetPlayerFacing", GetPlayerFacing))
    local plan = J.plan or {}
    local main, side = plan.primary, plan.secondary
    local instanceQuest = plan.instanced
    frame.instanceHint:SetText(instanceQuest
        and ((instanceQuest.campaign and "Campanha · " or "") .. "Instância · " .. instanceQuest.title) or "")
    frame.instanceHint:SetShown(instanceQuest ~= nil)
    frame.heading:SetText(not main and ""
        or not player and "Posição indisponível"
        or not facing and "Orientação indisponível"
        or "")
    local directions = {"N", "NO", "O", "SO", "S", "SE", "L", "NE"}
    if facing then
        for i, label in ipairs(frame.labels) do
            local delta = ((i - 1) * pi / 4 - facing + pi) % (2 * pi) - pi
            label:SetShown(math.abs(delta) <= pi / 2)
            label:SetText(directions[i])
            label:ClearAllPoints()
            label:SetPoint("CENTER", -delta / (pi / 2) * (frame:GetWidth() - 50) / 2, 4)
        end
    else for _, label in ipairs(frame.labels) do label:Hide() end end
    local function Draw(marker, q, deferred)
        local delta = q and not deferred and J.RelativeHeading(player, q.world, facing)
        if not delta then marker:Hide(); return end
        local halfWidth = (frame:GetWidth() - 50) / 2
        -- Interpolate the shortest angular path, including crossing north.
        -- Never interpolate two wrapped screen positions through the centre.
        if marker.key ~= q.key or not marker.angle then marker.angle = delta end
        marker.key = q.key
        local difference = (delta - marker.angle + pi) % (2 * pi) - pi
        local blend = elapsed and (1 - math.exp(-math.min(elapsed, 0.1) / 0.045)) or 1
        marker.angle = (marker.angle + difference * blend + pi) % (2 * pi) - pi
        local ratio = -marker.angle / (pi / 2)
        marker:ClearAllPoints()
        marker:SetPoint("CENTER", frame, "CENTER", math.max(-1, math.min(1, ratio)) * halfWidth, 1)
        marker.candidate = q
        local distance = J.Distance(player, q.world)
        q.distance = distance
        marker.distance:SetText(J.DistanceText(distance))
        marker.glyph:SetText(math.abs(ratio) > 1 and (ratio < 0 and "<" or ">") or (marker.primary and "P" or "S"))
        marker:Show()
    end
    -- Guidance includes available campaign starts before accepting or following.
    -- Auto also points the native Blizzard waypoint at the selected main target.
    Draw(frame.primary, main, inInstance)
    Draw(frame.secondary, side, inInstance)
end

function J.UpdateMapPins()
    if not J.mapPins or not WorldMapFrame then return end
    local mapID = WorldMapFrame:GetMapID()
    local canvas = WorldMapFrame:GetCanvas()
    local plan = J.plan or {}
    local candidates = {plan.primary, plan.secondary}
    for i, pin in ipairs(J.mapPins) do
        local q = candidates[i]
        if q and q.mapID == mapID and q.x and q.y then
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", canvas, "TOPLEFT", q.x * canvas:GetWidth(), -q.y * canvas:GetHeight())
            pin.candidate = q
            pin:Show()
        else pin:Hide() end
    end
end

function J.SetupMapPins()
    if J.mapPins or not WorldMapFrame or not WorldMapFrame.GetCanvas then return end
    local canvas = WorldMapFrame:GetCanvas()
    if not canvas then return end
    J.mapPins = {Marker(canvas, J.primaryColor, "P"), Marker(canvas, J.secondaryColor, "S")}
    for i, pin in ipairs(J.mapPins) do
        pin.primary = i == 1
        pin:SetFrameLevel(canvas:GetFrameLevel() + 20)
        local background = pin:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(0.02, 0.03, 0.04, 0.85)
        pin.distance:Hide()
    end
    -- The canvas changes map/size when panned or zoomed. Update only while visible.
    local elapsed = 0
    WorldMapFrame:HookScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed >= 0.2 then elapsed = 0; J.UpdateMapPins() end
    end)
    WorldMapFrame:HookScript("OnHide", function() for _, pin in ipairs(J.mapPins) do pin:Hide() end end)
    J.UpdateMapPins()
end
