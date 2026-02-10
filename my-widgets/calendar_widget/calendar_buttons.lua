local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")

local M = {}

--- @class CalendarButtons
--- @field nextMonthButton table
--- @field prevMonthButton table
local CalendarButtons = {}

--- @param o CalendarButtons
function CalendarButtons:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

local function button_bg(icon)
    local w = wibox.widget {
        {
            {
                text = icon,
                halign = "center",
                valign = "center",
                widget = wibox.widget.textbox,
            },
            border_width = 1,
            shape = function(cr, width, height)
                gears.shape.rounded_rect(cr, width, height, 6)
            end,
            widget = wibox.container.background
        },
        forced_width = 40,  -- Set desired width
        forced_height = 25, -- Set desired height
        widget = wibox.container.constraint
    }
    return w
end

--- @param onClick fun() Callback
--- @return table The widget button
local function newNextMonthButton(onClick)
    local next_button = button_bg("")

    next_button:buttons(gears.table.join(awful.button({}, 1, function()
        onClick()
    end)))

    return next_button
end


--- @param onClick fun() Callback
--- @return table The widget button
local function newPrevMonthButton(onClick)
    local prev_button = button_bg("")

    prev_button:buttons(gears.table.join(awful.button({}, 1, function()
        onClick()
    end)))

    return prev_button
end

--- @return CalendarButtons
function M.calendarButtons(onNextMonthButtonClick, onPrevMonthButtonClick)
    return CalendarButtons:new {
        nextMonthButton = newNextMonthButton(onNextMonthButtonClick),
        prevMonthButton = newPrevMonthButton(onPrevMonthButtonClick)
    }
end

return M
