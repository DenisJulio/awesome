local wibox = require("wibox")
local gears = require("gears")

local M = {}

--- Function to get days in a specific month
local function get_days_in_month(month, year)
    return os.date("*t", os.time { year = year, month = month + 1, day = 0 }).day
end

local function cal_cell_base(wid)
    return wibox.widget {
        {
            wid,
            forced_width = 40,                   -- Set desired width
            forced_height = 25,                  -- Set desired height
            widget = wibox.container.constraint, -- Constrain size
        },
        layout = wibox.container.place,
        halign = "center", -- Horizontal alignment
        valign = "center", -- Vertical alignment
    }
end

local function cal_cell_header(weekday)
    local day_w = wibox.widget {
        halign = "center",
        valign = "center",
        widget = wibox.widget.textbox,
        -- font = "Inter Display ExtraBold 10",
        markup = string.format("<b>%s</b>", weekday)
    }
    return cal_cell_base(day_w)
end

local function cal_cell(day)
    local day_w = wibox.widget {
        halign = "center",
        valign = "center",
        widget = wibox.widget.textbox,
        text = day
    }
    return cal_cell_base(day_w)
end

local function cal_cell_today(day)
    local day_w = wibox.widget {
        {
            halign = "center",
            valign = "center",
            widget = wibox.widget.textbox,
            markup = string.format("<b>%s</b>", day),
        },
        bg = "#cba6f7",
        fg = "#1e1e2e",
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 6) -- Configurable corner radius
        end,
        widget = wibox.container.background
    }
    return cal_cell_base(day_w)
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
    for _, day in ipairs({ "Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sab" }) do
        calendar_grid:add(cal_cell_header(day))
    end

    -- Fill the grid with day numbers
    for i = 1, first_day - 1 do
        calendar_grid:add(cal_cell(""))
    end

    local today = os.date("*t")
    local is_current_month = (today.year == year and today.month == month)

    for day = 1, days_in_month do
        local is_today = is_current_month and (day == today.day)
        if is_today then
            calendar_grid:add(cal_cell_today(tostring(day)))
        else
            calendar_grid:add(cal_cell(tostring(day)))
        end
    end

    return calendar_grid
end

--- @class CalendarGrid
--- @field widget table
local CalendarGrid = {}

--- @param o CalendarGrid
function CalendarGrid:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CalendarGrid:updateGrid(month, year)
    self.widget:reset()
    self.widget:add(create_calendar(year, month))
end

function M.newCalendarGrid(month, year)
    local grid = create_calendar(year, month)
    local grid_body = wibox.layout.fixed.vertical()
    grid_body:add(grid)
    return CalendarGrid:new {
        widget = grid_body
    }
end

return M
