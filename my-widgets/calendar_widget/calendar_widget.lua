local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")

local M = {}

--- @class CalendarState
--- @field curr_month integer
--- @field curr_year integer
local CalendarState = {}

--- @param o CalendarState
function CalendarState:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CalendarState:incMonth()
    local m, y = self.curr_month, self.curr_year
    m = m + 1
    if m > 12 then
        m = 1
        y = y + 1
    end
    self.curr_month, self.curr_year = m, y
end

function CalendarState:decMonth()
    local m, y = self.curr_month, self.curr_year
    m = m - 1
    if m < 1 then
        m = 12
        y = y - 1
    end
    self.curr_month, self.curr_year = m, y
end

--- @class CalendarWidget
--- @field widget table
--- @field private state CalendarState
--- @field private grid CalendarGrid
--- @field private title CalendarTitle
local CalendarWidget = {}

--- @param o CalendarWidget
function CalendarWidget:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @param state CalendarState
--- @param grid CalendarGrid
--- @param title CalendarTitle
local function updateCalendarView(state, grid, title)
    title:setText(state.curr_year, state.curr_month)
    grid:updateGrid(state.curr_month, state.curr_year)
end

function CalendarWidget:reset()
    local current_date = os.date("*t")
    local year, month = current_date.year, current_date.month
    self.state.curr_month, self.state.curr_year = month, year
    updateCalendarView(self.state, self.grid, self.title)
end

--- Main calendar widget with navigation
--- @return CalendarWidget
local function new_calendar_widget()
    local current_date = os.date("*t")
    local year, month = current_date.year, current_date.month
    local cal_state = CalendarState:new {
        curr_month = month,
        curr_year = year
    }

    local calendar_grid = require("my-widgets.calendar_widget.calendar_grid").newCalendarGrid(cal_state.curr_month,
        cal_state.curr_year)
    local title = require("my-widgets.calendar_widget.calendar_widget_title").newCalendarTitle(cal_state.curr_year,
        cal_state.curr_month)
    local calendar_buttons = require("my-widgets.calendar_widget.calendar_buttons").calendarButtons(
        function()
            cal_state:incMonth()
            updateCalendarView(cal_state, calendar_grid, title)
        end,
        function()
            cal_state:decMonth()
            updateCalendarView(cal_state, calendar_grid, title)
        end
    )

    local widget = wibox.widget {
        {
            {
                calendar_buttons.prevMonthButton,
                title.textbox,
                calendar_buttons.nextMonthButton,
                layout = wibox.layout.align.horizontal,
            },
            calendar_grid.widget,
            layout = wibox.layout.fixed.vertical
        },
        margins = 10,
        widget = wibox.container.margin,
    }
    return CalendarWidget:new {
        widget = widget,
        state = cal_state,
        title = title,
        grid = calendar_grid
    }
end

--- @class CalendarPopup
--- @field popup table
--- @field calendar CalendarWidget
local CalendarPopup = {}

function CalendarPopup:showCalendar()
    self.popup.visible = not self.popup.visible
    if (not self.popup.visible) then
        self.calendar:reset()
    end
end

--- @param args CalendarPopup
function CalendarPopup:new(args)
    self.__index = self
    return setmetatable(args, self)
end

--- @return CalendarPopup
function M.newCalendarPopup(parent)
    local calendar = new_calendar_widget()
    return CalendarPopup:new {
        calendar = calendar,
        popup = awful.popup {
            widget = calendar.widget,
            visible = false,
            ontop = true,
            shape = gears.shape.rounded_rect,
            border_color = "#cba6f7",
            border_width = 2,
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
end

return M
