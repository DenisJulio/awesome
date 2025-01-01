local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local color = require("gears.color")
local utils = require("my-widgets.utils")

local M = {}

local constants = {
    brightness_bar_id = "brightness_bar",
}

--- @class BrightnessPopUp
--- @field popup table the widget to be displayed
--- @field timer? table
--- @field text_widget table
local BrightnessPopUp = {}

--- Configuration options for creating the brightness popup
--- @class BrightnessPopUpConfig
--- @field bg? string
--- @field border_color? string
--- @field icon_color? string
local BrightnessPopUpConfig = {}

--- The brightness icon widget in its containers widgets
--- @param image string the path to an image to be displayed as the icon
local brightness_icon = function(image)
    return wibox.widget {
        {
            {
                id = "icon",
                widget = wibox.widget.imagebox,
                image = image,
                resize = true,                   -- Allow resizing
            },
            forced_width = 18,                   -- Set desired width
            forced_height = 18,                  -- Set desired height
            widget = wibox.container.constraint, -- Constrain size
        },
        widget = wibox.container.place,          -- Center the icon
        halign = "center",                       -- Horizontal alignment
        valign = "center",                       -- Vertical alignment
    }
end

local brightness_icon_widget = wibox.widget {
    widget = wibox.widget.textbox,
    text = "󰃟 ",
    align = "center",
    valign = "center",
    font = "Inter 12"
}

--- The progress bar widget that displays the brightness level
--- @param config BrightnessPopUpConfig
local function brightness_bar(config)
    return {
        id               = constants.brightness_bar_id,
        max_value        = 100,
        value            = 50, -- Initial value
        forced_height    = 20,
        forced_width     = 200,
        shape            = gears.shape.rounded_bar,
        bar_shape        = gears.shape.rounded_bar,
        color            = config.border_color,
        background_color = config.bg,
        widget           = wibox.widget.progressbar,
    }
end

local brightness_textbox = wibox.widget {
    markup = "<b>0%</b>", -- Initial text: "0%",
    widget = wibox.widget.textbox,
    align = "center",
    valign = "center",
    font = "Inter Black 12"
}

--- The brightness popup widget
--- @param config BrightnessPopUpConfig
local function create_brightness_popup(config, brightness_text_widget)
    local image = utils.get_icon("display-brightness-symbolic", 16)
    local colored_img = color.recolor_image(image, config.icon_color)
    return awful.popup {
        widget       = {
            {
                {
                    brightness_icon_widget,
                    layout = wibox.container.background,
                    fg = config.border_color,
                },
                -- brightness_icon(colored_img),
                brightness_bar(config),
                {
                    brightness_text_widget,
                    layout = wibox.container.background,
                    fg = config.border_color,
                },
                id      = "container",
                spacing = 10,
                layout  = wibox.layout.fixed.horizontal,
            },
            margins = 10,
            widget = wibox.container.margin,
        },
        ontop        = true,
        visible      = false, -- Start hidden
        shape        = gears.shape.rounded_rect,
        bg           = config.bg,
        border_color = config.border_color,
        border_width = 3,
        placement    = function(c)
            awful.placement.top(c, { margins = { top = 50 } }) -- Adjust position
        end,
    }
end

--- Creates a bightness popup widget with the specified configuration
--- @param config BrightnessPopUpConfig
--- @return BrightnessPopUp
function M:newBrightnessPopUp(config)
    local c = config or {}
    c.bg = c.bg or "#1E1E1E"
    c.border_color = c.border_color or "#4CAF50"
    --- @type BrightnessPopUp
    local brightness_popup = {
        text_widget = brightness_textbox,
        popup = create_brightness_popup(c, brightness_textbox)
    }
    return BrightnessPopUp:new(brightness_popup)
end

--- Instantiates a new BrightnessPopUp
--- @param args BrightnessPopUp
function BrightnessPopUp:new(args)
    self.__index = self
    args.timer = gears.timer {
        timeout = 1,
        autostart = false,
        single_shot = false,
        callback = function()
            args.popup.visible = false
        end
    }
    return setmetatable(args, self)
end

-- Function to update and show the brightness popup
function BrightnessPopUp:showPopUp(brightness_lvl)
    -- Update the progress bar
    self.popup.widget:get_children_by_id(constants.brightness_bar_id)[1].value = brightness_lvl

    self.text_widget.markup = "<b>" .. brightness_lvl .. "%</b>"

    -- Show the popup
    self.popup.visible = true

    if self.timer.started then
        self.timer:again()
    else
        self.timer:start()
    end
end

return M
