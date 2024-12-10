local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local lgi = require("lgi")

-- Function to parse .desktop files
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

-- Function to resolve the icon path using LGI
local function resolve_icon(icon_name)
    local theme = lgi.Gtk.IconTheme.get_default()
    local icon = theme:lookup_icon(icon_name, 48, 0) -- 48 is the size
    return icon and icon:get_filename() or nil
end



-- Function to create a launcher from a .desktop file with hover effects
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

local dock_bottom_space = 3
local dock_height = 45
local dock_border_width = 3

-- Create the dock
local dock = wibox {
    width = awful.screen.focused().geometry.width * 0.3,                                                      -- Full screen width
    height = dock_height,                                                                                     -- Dock height
    x = (awful.screen.focused().geometry.width - awful.screen.focused().geometry.width * 0.3) / 2,            -- Center horizontally
    y = awful.screen.focused().geometry.height - (dock_height + dock_bottom_space + (dock_border_width * 2)), -- Position at the bottom
    bg = "#11111b",                                                                                           -- Background color
    border_width = dock_border_width,                                                                         -- No border
    border_color = "#89dceb",                                                                                 -- Background color
    visible = false,                                                                                          -- Initially hidden
    ontop = true,                                                                                             -- Always on top
    type = "dock",                                                                                            -- Dock type
}

local rootAppsDir = "/usr/share/applications/"
local appsDir = "/home/denisjulio/.local/share/applications/"

-- Add some example widgets to the dock
dock:setup {
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = 3,
        create_launcher_from_desktop(appsDir .. "google-drive-pwa.desktop"),
        create_launcher_from_desktop(rootAppsDir .. "firefox.desktop"),
        create_launcher_from_desktop(appsDir .. "excalidraw-pwa.desktop"),
        create_launcher_from_desktop(rootAppsDir .. "obsidian.desktop"),
        create_launcher_from_desktop(rootAppsDir .. "thunar.desktop"),
        create_launcher_from_desktop(rootAppsDir .. "google-chrome.desktop"),
        create_launcher_from_desktop(rootAppsDir .. "org.mozilla.Thunderbird.desktop"),
        create_launcher_from_desktop(rootAppsDir .. "tor-browser.desktop"),
    },
    widget = wibox.container.place,
    halign = "center",
}

-- Function to calculate the natural width of the dock
local function update_dock_size()
    if not dock.widget then return end

    -- Measure the natural size of the content
    local layout = dock.widget.widget -- Access the inner layout via `wibox.container.place`
    if layout and layout.fit then
        local dock_width, _ = layout:fit(dock.screen, dock.width, dock.height)
        dock.width = dock_width
        dock.x = (awful.screen.focused().geometry.width - dock.width) / 2 -- Center horizontally
    end
end

-- Create a hover area to trigger dock visibility
local hover_area = wibox {
    width = awful.screen.focused().geometry.width,  -- Full screen width
    height = 5,                                     -- Small hover area
    x = 0,                                          -- Position at the screen's left edge
    y = awful.screen.focused().geometry.height - 5, -- Positioned just above the dock
    bg = "#00000000",                               -- Fully transparent
    visible = true,                                 -- Always visible
    ontop = true,                                   -- Always on top
    type = "utility",                               -- Non-interactive utility type
}

-- Function to update the hover area based on the dock's geometry
local function update_hover_area()
    local dock_geometry = dock:geometry()
    hover_area.width = dock_geometry.width
    hover_area.x = dock_geometry.x
    -- hover_area.y = dock_geometry.y - hover_area.height -- Position just above the dock
end

-- Update hover area whenever the dock size or position changes
local function update_dock_and_hover_area()
    update_dock_size()  -- Update the dock size
    update_hover_area() -- Sync hover area with dock
end

-- Table to store dock state for each tag
local tag_dock_states = {}

-- Function to check if any client overlaps the dock area for the current tag
local function check_dock_visibility()
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

-- Restore dock visibility when switching tags
awful.tag.attached_connect_signal(nil, "property::selected", function()
    check_dock_visibility()
end)

-- Show dock on mouse hover regardless of tag
hover_area:connect_signal("mouse::enter", function()
    dock.visible = true
end)

-- Hide dock when the mouse leaves if a client overlaps
dock:connect_signal("mouse::leave", function()
    check_dock_visibility()
end)

-- Signal handlers to update dock visibility
client.connect_signal("manage", check_dock_visibility)
client.connect_signal("unmanage", check_dock_visibility)
client.connect_signal("property::geometry", check_dock_visibility)
client.connect_signal("property::hidden", check_dock_visibility)
client.connect_signal("property::minimized", check_dock_visibility)

-- Ensure dock visibility is updated for each tag on startup
awful.screen.connect_for_each_screen(function(s)
    for _, tag in ipairs(s.tags) do
        tag:connect_signal("property::selected", function()
            check_dock_visibility()
        end)
    end
end)

-- Initial check when AwesomeWM starts
check_dock_visibility()

-- Call it initially to align hover area on startup
update_hover_area()

-- Update the dock size and position after setting up widgets
gears.timer.delayed_call(update_dock_and_hover_area)

-- Recalculate dock size and position when screen geometry changes
awful.screen.connect_for_each_screen(function(s)
    s:connect_signal("property::geometry", update_dock_and_hover_area)
end)

return hover_area
