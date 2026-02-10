local gears = require("gears")
local beautiful = require("beautiful")

local M = {}

local function scandir(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('ls -a "' .. directory .. '"')
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

local function get_random_wallpaper(directory)
    local wallpapers = {}
    local files = scandir(directory)
    for _, file in ipairs(files) do
        if file ~= "." and file ~= ".." then
            table.insert(wallpapers, directory .. "/" .. file)
        end
    end
    if #wallpapers > 0 then
        return wallpapers[math.random(#wallpapers)]
    end
    return nil
end

function M.set_wallpaper(s)
    -- Define your wallpapers directory
    local wallpaper_dir = "/home/denisjulio/Pictures/wallpapers/catppuccin"
    local wallpaper = get_random_wallpaper(wallpaper_dir)

    if wallpaper then
        gears.wallpaper.maximized(wallpaper, s, true)
    else
        -- Fallback to the default wallpaper if no files are found
        if beautiful.wallpaper then
            wallpaper = beautiful.wallpaper
            if type(wallpaper) == "function" then
                wallpaper = wallpaper(s)
            end
            gears.wallpaper.maximized(wallpaper, s, true)
        else
            print("No wallpaper found in directory and no default wallpaper set.")
        end
    end
end

return M
