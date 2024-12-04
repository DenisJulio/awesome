local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")

-- Initialize GTK
Gtk.init()

local volume_widget = {}

-- Internal widget layout
local widget_content = wibox.widget {
    {
        {
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                image = "/home/denisjulio/.local/share/icons/McMojave-circle-blue-dark/status/16/audio-volume-high.svg",
                resize = true,                   -- Allow resizing
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
        widget = wibox.widget.textbox,
        font = beautiful.font,
        markup = "<b>100%</b>",
    },
    layout = wibox.layout.fixed.horizontal,
    spacing = 5,
}

local function get_icon_path(icon_name, size)
    local icon_theme = Gtk.IconTheme.get_default()
    local icon_info = icon_theme:lookup_icon(icon_name, size, 0)
    if icon_info then
        return icon_info:get_filename()
    else
        return nil
    end
end

-- Helper function to get the volume
local function get_volume(callback)
    awful.spawn.easy_async_with_shell("amixer sget Master", function(stdout)
        local volume = stdout:match("(%d?%d?%d)%%") -- Match the percentage
        local status = stdout:match("%[([%l]*)%]")  -- Match the mute status
        callback(tonumber(volume), status)
    end)
end

-- Function to update the widget
function volume_widget.update()
    get_volume(function(volume, status)
        local icon_name
        if status == "off" then
            icon_name = "audio-volume-muted"
            widget_content:get_children_by_id("text")[1].markup = "<b>Muted</b>"
        else
            if volume == 0 then
                icon_name = "audio-volume-muted"
            elseif volume <= 33 then
                icon_name = "audio-volume-low"
            elseif volume <= 66 then
                icon_name = "audio-volume-medium"
            else
                icon_name = "audio-volume-high"
            end
            widget_content:get_children_by_id("text")[1].markup = string.format("<b>%d%%</b>", volume)
        end

        -- Resolve the icon path dynamically
        local icon_path = get_icon_path(icon_name, 16) or "/path/to/fallback-icon.svg"
        widget_content:get_children_by_id("icon")[1].image = icon_path
    end)
end

-- Function to increase volume
function volume_widget.increase()
    awful.spawn("amixer sset Master 5%+")
    volume_widget.update()
end

-- Function to decrease volume
function volume_widget.decrease()
    awful.spawn("amixer sset Master 5%-")
    volume_widget.update()
end

-- Function to toggle mute
function volume_widget.toggle_mute()
    awful.spawn("amixer sset Master toggle")
    volume_widget.update()
end

-- Mouse controls
widget_content:connect_signal("button::press", function(_, _, _, button)
    if button == 4 then
        volume_widget.increase()
    elseif button == 5 then
        volume_widget.decrease()
    elseif button == 1 then
        volume_widget.toggle_mute()
    end
end)

-- Periodic update
gears.timer {
    timeout = 5,
    autostart = true,
    callback = volume_widget.update
}

-- Initial update
volume_widget.update()

-- Return the widget for use in wibar
volume_widget.widget = widget_content

return volume_widget
