local wibox = require("wibox")

local function cal_title_str(y, m)
    local month_str = os.date("%B", os.time { year = y, month = m, day = 1 })
    month_str = month_str:sub(1, 1):upper() .. month_str:sub(2)
    local year_str = os.date("%Y", os.time { year = y, month = m, day = 1 })
    return month_str .. " " .. year_str
end

--- Creates a textbox widget for the calendar title
local function cal_title_textbox(y, m)
    local title_str = cal_title_str(y, m)
    return wibox.widget {
        halign = "center",
        valign = "center",
        widget = wibox.widget.textbox,
        font = "Inter Display ExtraBold 11",
        markup = string.format("<b>%s</b>", title_str)
    }
end

--- @class CalendarTitle
--- @field textbox table The textbox widget that the instance encapsulates
local CalendarTitle = {}

function CalendarTitle:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Changes the text displayed in the calendar title based in the provided year and month
--- @param y integer The string representation of the year
--- @param m integer The string representation of the month
function CalendarTitle:setText(y, m)
    self.textbox.markup = cal_title_str(y, m)
end

local M = {}

--- Creates a new CalendarTitle instance based on the provided year and month
--- @param y integer The string representation of the year
--- @param m integer The string representation of the month
--- @return CalendarTitle
function M.newCalendarTitle(y, m)
    local calendar_title = CalendarTitle:new {
        textbox = cal_title_textbox(y, m)
    }
    return calendar_title
end

return M
