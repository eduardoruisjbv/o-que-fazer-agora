local _, J = ...

function J.BuildOptions()
    if J.optionsCategory or not (Settings and Settings.RegisterVerticalLayoutCategory
        and Settings.RegisterAddOnSetting) then return end

    local category, layout = Settings.RegisterVerticalLayoutCategory("Just do it")
    local function Header(text)
        if layout and CreateSettingsListSectionHeaderInitializer then
            layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
        end
    end
    local function Register(key, kind, label)
        local setting = Settings.RegisterAddOnSetting(category, "JustDoIt_" .. key,
            key, J.db.settings, kind, label, J.defaults[key])
        if setting.SetValueChangedCallback then
            setting:SetValueChangedCallback(function()
                local value = J.db.settings[key]
                if key == "mode" then J.RequestMode(value)
                elseif key == "compass" then
                    J.LayoutCompass()
                    if J.compass then J.compass:SetShown(value) end
                elseif key == "minimap" then
                    if J.minimap then J.minimap:SetShown(value) end
                elseif key == "showZoneIndicators" then J.UpdateBlizzardWidgetLayout()
                elseif J.readings and J.readings.state then J.Replan(true) end
            end)
        end
        return setting
    end
    local function Checkbox(key, label, tooltip)
        Settings.CreateCheckbox(category,
            Register(key, Settings.VarType.Boolean, label), tooltip)
    end
    local function Slider(key, label, minimum, maximum, step, tooltip, decimals)
        local options = Settings.CreateSliderOptions(minimum, maximum, step)
        if options.SetLabelFormatter and MinimalSliderWithSteppersMixin then
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
                if decimals then return string.format("%.2f", value) end
                return string.format("%d", value)
            end)
        end
        Settings.CreateSlider(category,
            Register(key, Settings.VarType.Number, label), options, tooltip)
    end

    Header("Guidance mode")
    local mode = Register("mode", Settings.VarType.String, "Guidance mode")
    Settings.CreateDropdown(category, mode, function()
        local values = Settings.CreateControlTextContainer()
        values:Add("semi", "Semi-auto", "Suggests objectives and provides compass guidance; you initiate quest actions.")
        values:Add("auto", "Auto", "Automatically manages the waypoint and compass guidance. Quest acceptance and turn-in stay manual.")
        return values:GetData()
    end, "Choose how Just do it guides your next activity.")

    Header("Interface")
    Checkbox("compass", "Show compass", "Displays the route compass in the world.")
    Checkbox("minimap", "Show minimap button", "Displays the Just do it button around the minimap.")
    Checkbox("showZoneIndicators", "Show Blizzard zone indicators", "Shows Blizzard's native zone indicators at the top of the screen.")

    Header("Route selection")
    Slider("corridor", "Route corridor width (m)", 25, 600, 25,
        "How far from the route an objective can be and remain eligible.")
    Slider("closeRadius", "Very close radius (m)", 25, 500, 25,
        "Treats objectives within this distance as immediately reachable.")
    Slider("closeRatio", "Distance relative to campaign", 0.1, 0.8, 0.05,
        "Balances local distance against campaign progression distance.", true)
    Slider("switchSeconds", "Stability before switching (s)", 1, 15, 1,
        "How long a better objective must remain preferable before the suggestion changes.")

    Settings.RegisterAddOnCategory(category)
    J.optionsCategory = category
end

function J.OpenSettings()
    if J.optionsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(J.optionsCategory:GetID())
    elseif J.ui then
        J.ShowPage("settings")
    end
end
