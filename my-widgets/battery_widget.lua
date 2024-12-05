local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

-- Battery Widget: Text and Icon
local battery_icon = wibox.widget {
    widget = wibox.widget.imagebox,
    resize = true
}

local battery_text = wibox.widget {
    widget = wibox.widget.textbox,
    align = "center",
    valign = "center"
}

local battery_widget = wibox.widget {
    layout = wibox.layout.fixed.horizontal,
    spacing = 1,
    {
        {
            battery_icon,
            forced_width = 16,                   -- Set desired width
            forced_height = 16,                  -- Set desired height
            widget = wibox.container.constraint, -- Constrain size
        },
        widget = wibox.container.place,          -- Center the icon
        halign = "center",                       -- Horizontal alignment
        valign = "center",                       -- Vertical alignment
    },
    battery_text
}

-- Function to Get Icon Path Using LGI
local function get_icon_path(icon_name)
    local theme = Gtk.IconTheme.get_default()
    local icon_info = theme:lookup_icon(icon_name, 24, Gtk.IconLookupFlags.USE_BUILTIN)
    if icon_info then
        return icon_info:get_filename()
    end
    return nil
end

-- Function to Get Icon Based on Status and Charge
local function get_battery_icon(status, charge)
    if status == "Charging" then
        if charge >= 90 then
            return "battery-full-charging-symbolic"
        elseif charge >= 70 then
            return "battery-good-charging-symbolic"
        elseif charge >= 40 then
            return "battery-medium-charging-symbolic"
        elseif charge >= 10 then
            return "battery-low-charging-symbolic"
        else
            return "battery-caution-charging-symbolic"
        end
    else -- Discharging or Fully Charged
        if charge >= 90 then
            return "battery-full-symbolic"
        elseif charge >= 70 then
            return "battery-good-symbolic"
        elseif charge >= 40 then
            return "battery-medium-symbolic"
        elseif charge >= 10 then
            return "battery-low-symbolic"
        else
            return "battery-empty-symbolic"
        end
    end
end

-- Function to Update Battery Widget
local function update_battery()
    awful.spawn.easy_async_with_shell("acpi -b", function(stdout)
        -- Parse the acpi output
        local status, charge = stdout:match("Battery %d+: (%a+), (%d+)%%")
        if status and charge then
            charge = tonumber(charge) -- Convert to number for comparisons

            -- Get the icon path and update the widget
            local icon_name = get_battery_icon(status, charge)
            local icon_path = get_icon_path(icon_name)
            if icon_path then
                battery_icon.image = gears.surface.load_uncached(icon_path)
            else
                battery_icon.image = nil -- Fallback if no icon is found
            end
            battery_text.text = charge .. "%"
        else
            -- Fallback for parsing errors
            local fallback_icon = get_icon_path("battery-missing-symbolic")
            battery_icon.image = fallback_icon and gears.surface.load_uncached(fallback_icon) or nil
            battery_text.text = "N/A"
        end
    end)
end

-- Periodic Update
gears.timer {
    timeout   = 10, -- Update every 30 seconds
    autostart = true,
    callback  = update_battery
}

-- Initial Update
update_battery()

-- Add to Wibar
return battery_widget
