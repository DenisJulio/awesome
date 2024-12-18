local lgi = require("lgi")

local M = {}

--- Looks for an icon in the default icon theme
function M.get_icon(name, size)
    local icon_theme = lgi.Gtk.IconTheme.get_default()
    local icon_info = icon_theme:lookup_icon(name, size, 0)
    return icon_info and icon_info:get_filename() or nil
end

return M
