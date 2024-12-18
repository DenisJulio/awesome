local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local lgi = require("lgi")

-----------------------------------------------------------
--- Utility functions
-----------------------------------------------------------

--- Function to parse .desktop files
local function parse_desktop_file(file_path)
    local entry = {}
    for line in io.lines(file_path) do
        local key, value = line:match("^(%w+)=(.+)$")
        if key and value then
            entry[key] = value
        end
    end
    return entry
end

--- Function to resolve the icon path using LGI
local function resolve_icon(icon_name)
    local theme = lgi.Gtk.IconTheme.get_default()
    local icon = theme:lookup_icon(icon_name, 48, 0) -- 48 is the size
    return icon and icon:get_filename() or nil
end

--- Function to create a launcher from a .desktop file with hover effects
local function create_launcher_from_desktop(file_path)
    local app = parse_desktop_file(file_path)
    if app and app.Name and app.Exec then
        local icon_path = resolve_icon(app.Icon or "") or app.Icon or nil

        -- Create an imagebox widget for the icon
        local icon_widget = wibox.widget {
            image = icon_path,
            resize = true,
            forced_width = 32,
            forced_height = 32,
            widget = wibox.widget.imagebox,
        }

        -- Create a background container
        local background_container = wibox.widget {
            {
                icon_widget,
                margins = 5,
                widget = wibox.container.margin,
            },
            bg = "#00000000", -- Default background color
            widget = wibox.container.background,
        }

        -- Add hover effect for scaling and background color
        background_container:connect_signal("mouse::enter", function()
            background_container.bg = "#44475a" -- Change background on hover
        end)

        background_container:connect_signal("mouse::leave", function()
            background_container.bg = "#00000000" -- Revert background color
        end)

        -- Add click functionality
        background_container:buttons(gears.table.join(
            awful.button({}, 1, function()
                awful.spawn("exo-open " .. file_path)
            end)
        ))
        return background_container
    end
end

--- Function to calculate the natural width of the dock
local function update_dock_size(dock)
    if not dock.widget then return end

    -- Measure the natural size of the content
    local layout = dock.widget.widget -- Access the inner layout via `wibox.container.place`
    if layout and layout.fit then
        local dock_width, _ = layout:fit(dock.screen, dock.width, dock.height)
        dock.width = dock_width
        dock.x = (awful.screen.focused().geometry.width - dock.width) / 2 -- Center horizontally
    end
end

--- Function to update the hover area based on the dock's geometry
local function update_hover_area(hover_area, dock)
    local dock_geometry = dock:geometry()
    hover_area.width = dock_geometry.width
    hover_area.x = dock_geometry.x
end

--- Update hover area whenever the dock size or position changes
local function update_dock_and_hover_area(hover_area, dock)
    update_dock_size(dock)              -- Update the dock size
    update_hover_area(hover_area, dock) -- Sync hover area with dock
end

--- Table to store dock state for each tag
local tag_dock_states = {}

--- Function to check if any client overlaps the dock area for the current tag
local function check_dock_visibility(dock)
    local dock_area = dock:geometry() -- Get dock geometry
    local overlapping = false
    local current_tag = awful.screen.focused().selected_tag

    -- Return early if there's no selected tag
    if not current_tag then return end

    -- Loop through all visible clients on the current screen
    for _, c in ipairs(client.get()) do
        if c.screen == dock.screen and c:isvisible() and c.first_tag == current_tag then
            local client_area = c:geometry()

            -- Check if client overlaps the dock area
            if client_area.x < dock_area.x + dock_area.width and
                client_area.x + client_area.width > dock_area.x and
                client_area.y < dock_area.y + dock_area.height and
                client_area.y + client_area.height > dock_area.y then
                overlapping = true
                break
            end
        end
    end

    -- Update dock visibility based on overlap and save state for the current tag
    if overlapping then
        dock.visible = false
    else
        dock.visible = true
    end

    -- Save the state for the current tag
    tag_dock_states[current_tag] = dock.visible
end

-------------------------------------------------------------------------------------
--- Type Definitions
-------------------------------------------------------------------------------------

--- @class DockModule
--- @field dock table
--- @field private hover_area table
local DockModule = {}

--- @class DockConfig
--- @field height? number
--- @field bottom_space? number
--- @field border_width? number
--- @field desktopFilePaths table<number, string>
local DockConfig = {}

--- @param d DockConfig
local function create_dock(d)
    return wibox {
        width = awful.screen.focused().geometry.width,                                             -- Full screen width
        height = d.height,                                                                               -- Dock height
        x = (awful.screen.focused().geometry.width - awful.screen.focused().geometry.width * 0.3) / 2,   -- Center horizontally
        y = awful.screen.focused().geometry.height - (d.height + d.bottom_space + (d.border_width * 2)), -- Position at the bottom
        bg = "#11111b",                                                                                  -- Background color
        border_width = d.border_width,                                                                   -- No border
        border_color = "#89dceb",                                                                        -- Background color
        visible = false,                                                                                 -- Initially hidden
        ontop = true,                                                                                    -- Always on top
        type = "dock",                                                                                   -- Dock type
    }
end

--- Create a hover area to trigger dock visibility
local function create_hover_area()
    return wibox {
        width = awful.screen.focused().geometry.width,  -- Full screen width
        height = 5,                                     -- Small hover area
        x = 0,                                          -- Position at the screen's left edge
        y = awful.screen.focused().geometry.height - 5, -- Positioned just above the dock
        bg = "#00000000",                               -- Fully transparent
        visible = true,                                 -- Always visible
        ontop = true,                                   -- Always on top
        type = "utility",                               -- Non-interactive utility type
    }
end

--- Setup the dock adding the icon launchers to it
local function setup_dock(dock, desktopFiles)
    dock:setup {
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = 3,
        },
        widget = wibox.container.place,
        halign = "center",
    }

    for _, desktopFile in pairs(desktopFiles) do
        dock.widget.widget:add(create_launcher_from_desktop(desktopFile))
    end
end

--- Register signals to update dock visibility
local function register_signals(hover_area, dock)
    -- Restore dock visibility when switching tags
    awful.tag.attached_connect_signal(nil, "property::selected", function()
        check_dock_visibility(dock)
    end)

    -- Show dock on mouse hover regardless of tag
    hover_area:connect_signal("mouse::enter", function()
        dock.visible = true
    end)

    -- Hide dock when the mouse leaves if a client overlaps
    dock:connect_signal("mouse::leave", function()
        check_dock_visibility(dock)
    end)
    -- Signal handlers to update dock visibility
    client.connect_signal("manage", function()
        check_dock_visibility(dock)
    end)
    client.connect_signal("unmanage", function()
        check_dock_visibility(dock)
    end)
    client.connect_signal("property::geometry", function()
        check_dock_visibility(dock)
    end)
    client.connect_signal("property::hidden", function()
        check_dock_visibility(dock)
    end)
    client.connect_signal("property::minimized", function()
        check_dock_visibility(dock)
    end)

    awful.screen.connect_for_each_screen(function(s)
        -- Ensure dock visibility is updated for each tag on startup
        for _, tag in ipairs(s.tags) do
            tag:connect_signal("property::selected", function()
                check_dock_visibility(dock)
            end)
        end
        s:connect_signal("property::geometry", function()
            update_dock_and_hover_area(hover_area, dock)
        end)
    end)
    -- Initial check when AwesomeWM starts
    check_dock_visibility(dock)

    -- Call it initially to align hover area on startup
    update_hover_area(hover_area, dock)

    -- Update the dock size and position after setting up widgets
    gears.timer.delayed_call(function()
        update_dock_and_hover_area(hover_area, dock)
    end)
end

--- Create a new dock with the specified configuration
--- @param dockConfig DockConfig
--- @return DockModule dockModule
function DockModule:new(dockConfig)
    local dockModule = {}
    self.__index = self
    local d = dockConfig or {}
    d.height = d.height or 45
    d.bottom_space = d.bottom_space or 3
    d.border_width = d.border_width or 3

    self.dock = create_dock(d)
    self.hover_area = create_hover_area()
    setup_dock(self.dock, dockConfig.desktopFilePaths)
    register_signals(self.hover_area, self.dock)
    return dockModule
end

return DockModule
