-- Required libraries
local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local lgi = require("lgi")

-- Get system icon
local theme = lgi.Gio.ThemedIcon.new
local icon_theme = lgi.Gtk.IconTheme.get_default()

local function get_icon(name, size)
    local icon_info = icon_theme:lookup_icon(name, size, 0)
    return icon_info and icon_info:get_filename() or nil
end

-- Brightness Widget
local brightness_widget = wibox.widget {
    {
        {
            {
                id = "icon",
                image = get_icon("display-brightness-symbolic", 24) or "/usr/share/icons/default/brightness-icon.png",
                resize = true,
                widget = wibox.widget.imagebox
            },
            forced_width = 14,                   -- Set desired width
            forced_height = 14,                  -- Set desired height
            widget = wibox.container.constraint, -- Constrain size
        },
        widget = wibox.container.place,          -- Center the icon
        halign = "center",                       -- Horizontal alignment
        valign = "center",                       -- Vertical alignment
    },
    {
        id = "text",
        text = "100%",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    },
    layout = wibox.layout.fixed.horizontal,
    spacing = 3,
}

-- Update function
local function update_brightness(callback)
    awful.spawn.easy_async_with_shell("brightnessctl get", function(stdout)
        local current = tonumber(stdout:match("%d+"))
        awful.spawn.easy_async_with_shell("brightnessctl max", function(max_stdout)
            local max = tonumber(max_stdout:match("%d+"))
            if current and max then
                local percent = math.floor((current / max) * 100)
                brightness_widget:get_children_by_id("text")[1].text = percent .. "%"
                callback(percent)
            end
        end)
    end)
end

-- Functions to increase and decrease brightness
local function increase_brightness(callback)
    awful.spawn("brightnessctl set +5%", false)
    update_brightness(callback)
end

local function decrease_brightness(callback)
    awful.spawn("brightnessctl set 5%-", false)
    update_brightness(callback)
end

-- Expose the widget and functions
brightness_widget.increase_brightness = increase_brightness
brightness_widget.decrease_brightness = decrease_brightness

-- Initial update
update_brightness()

-- Return the widget
return brightness_widget
