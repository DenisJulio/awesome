local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")

local M = {}

--- Function to get days in a specific month
local function get_days_in_month(month, year)
    return os.date("*t", os.time { year = year, month = month + 1, day = 0 }).day
end

--- Function to create a calendar for a specific month
local function create_calendar(year, month)
    local days_in_month = get_days_in_month(month, year)
    local first_day = os.date("*t", os.time { year = year, month = month, day = 1 }).wday
    local calendar_grid = wibox.widget {
        layout = wibox.layout.grid,
        homogeneous = true,
        expand = true,
        spacing = 2,
        forced_num_rows = 6,
        forced_num_cols = 7,
    }

    -- Add days of the week header
    for _, day in ipairs({ "S", "M", "T", "W", "T", "F", "S" }) do
        calendar_grid:add(wibox.widget.textbox(day))
    end

    -- Fill the grid with day numbers
    for i = 1, first_day - 1 do
        calendar_grid:add(wibox.widget.textbox("")) -- Empty cells before the 1st
    end

    for day = 1, days_in_month do
        calendar_grid:add(wibox.widget.textbox(tostring(day)))
    end

    return calendar_grid
end

--- Main calendar widget with navigation
function new_calendar()
    local current_date = os.date("*t")
    local year, month = current_date.year, current_date.month

    local title = wibox.widget.textbox(os.date("%B %Y", os.time { year = year, month = month, day = 1 }))
    local calendar_body = create_calendar(year, month)

    local prev_button = wibox.widget.textbox("◀")
    prev_button:buttons(gears.table.join(awful.button({}, 1, function()
        month = month - 1
        if month < 1 then
            month = 12
            year = year - 1
        end
        title.text = os.date("%B %Y", os.time { year = year, month = month, day = 1 })
        calendar_body:reset()
        calendar_body:replace_widget(create_calendar(year, month))
    end)))

    local next_button = wibox.widget.textbox("▶")
    next_button:buttons(gears.table.join(awful.button({}, 1, function()
        month = month + 1
        if month > 12 then
            month = 1
            year = year + 1
        end
        title.text = os.date("%B %Y", os.time { year = year, month = month, day = 1 })
        calendar_body:reset()
        calendar_body:replace_widget(create_calendar(year, month))
    end)))

    local widget = wibox.widget {
        {
            {
                prev_button,
                title,
                next_button,
                layout = wibox.layout.align.horizontal,
            },
            calendar_body,
            layout = wibox.layout.fixed.vertical,
        },
        margins = 10,
        widget = wibox.container.margin,
    }

    return widget
end

--- @class CalendarPopup
--- @field popup table
local CalendarPopup = {}

function CalendarPopup:showCalendar()
    self.popup.visible = not self.popup.visible
end

--- @param args CalendarPopup
function CalendarPopup:new(args)
    self.__index = self
    return setmetatable(args, self)
end

--- @return CalendarPopup
function M.newCalendarPopup(parent)
    -- local calendar = wibox.widget.calendar.month(os.date("*t"))
    local calendar = new_calendar()
    local cp = {
        popup = awful.popup {
            widget = calendar,
            visible = false,
            ontop = true,
            shape = gears.shape.rounded_rect,
            preferred_positions = "bottom",
            placement = function(c)
                awful.placement.top(c,
                    {
                        margins = { top = 50 }
                    }
                )
            end
        }
    }
    local calendar_popup = CalendarPopup:new(cp)
    return calendar_popup
end

return M
