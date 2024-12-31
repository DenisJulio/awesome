local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local buttons = require("awful.button")

local M = {}

local tasklist_buttons = gears.table.join(
    buttons {
        button = buttons.names.LEFT,
        on_press = function(c)
            if c == client.focus then
                c.minimized = true
            else
                c:emit_signal(
                    "request::activate",
                    "tasklist",
                    { raise = true }
                )
            end
        end
    },
    buttons {
        button = buttons.names.MIDDLE,
        on_press = function(c)
            c:kill()
        end
    })

M.create_tasklist = function(s)
    return awful.widget.tasklist {
        screen          = s,
        filter          = awful.widget.tasklist.filter.currenttags,
        layout          = {
            spacing = 5, -- Adjust spacing between icons
            layout = wibox.layout.fixed.horizontal,
        },
        widget_template = {
            {
                {
                    id = "icon_role", -- Tasklist icon role
                    widget = wibox.widget.imagebox,
                },
                margins = 5, -- Add margin around the icon
                widget = wibox.container.margin,
            },
            id = "background_role", -- Use the background role for active/urgent tasks
            widget = wibox.container.background,
        },
        buttons         = tasklist_buttons
    }
end

return M
