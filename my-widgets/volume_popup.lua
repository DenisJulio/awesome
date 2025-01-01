local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local color = require("gears.color")
local utils = require("my-widgets.utils")

--- @class VolumePopUpModule
--- @field VolumePopUp table
local VolumePopUpModule = {}

--- @class VolumePopUp
--- @field popup table the widget to be displayed
--- @field timer? table
--- @field textbox_widget table
local VolumePopUp = {}

--- Configuration options for creating the volume popup
--- @class VolumePopUpConfig
--- @field bg? string
--- @field border_color? string
--- @field icon_color? string
local VolumePopUpConfig = {}

--- The volume icon widget in its containers widgets
--- @param image string the path to an image to be displayed as the icon
local vol_icon = function(image)
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

--- The progress bar widget that displays the volume level
--- @param config VolumePopUpConfig
local function volume_bar(config)
    return {
        id               = "volume_bar",
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

local vol_textbox = wibox.widget {
    markup = "<b>0%</b>", -- Initial text: "0%",
    widget = wibox.widget.textbox,
    align = "center",
    valign = "center",
    font = "Inter Black 12"
}

--- The volume popup widget
--- @param config VolumePopUpConfig
local function create_volume_popup(config, vol_text_widget)
    local image = utils.get_icon("audio-volume-high", 16)
    local colored_img = color.recolor_image(image, config.icon_color)
    return awful.popup {
        widget       = {
            {
                vol_icon(colored_img),
                volume_bar(config),
                {
                    vol_text_widget,
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

--- Creates a volume popup widget with the specified configuration
--- @param config VolumePopUpConfig
--- @return VolumePopUp
function VolumePopUpModule:newVolumePopUp(config)
    local c = config or {}
    c.bg = c.bg or "#1E1E1E"
    c.border_color = c.border_color or "#4CAF50"
    --- @type VolumePopUp
    local volume_popup = {
        textbox_widget = vol_textbox,
        popup = create_volume_popup(c, vol_textbox),
    }
    return VolumePopUp:new(volume_popup)
end

--- Instantiates a new VolumePopUp
--- @param args VolumePopUp
function VolumePopUp:new(args)
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

-- Function to update and show the volume popup
function VolumePopUp:showPopUp(volume)
    -- Update the progress bar
    self.popup.widget:get_children_by_id("volume_bar")[1].value = volume

    -- Updata the text
    self.textbox_widget.markup = string.format("<b>%d%%</b>", volume)

    -- Show the popup
    self.popup.visible = true

    -- Hide it after 2 seconds
    if self.timer.started then
        self.timer:again()
    else
        self.timer:start()
    end
end

return VolumePopUpModule
