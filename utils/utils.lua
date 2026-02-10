local Utils = {}

function Utils.get_hostname()
    local f = io.open("/etc/hostname", "r")
    local hostname = f:read("*line")
    f:close()
    return hostname
end

function Utils.is_on_desktop()
    if Utils.get_hostname() == "archlinux" then
        return true
    else
        return false
    end
end

return Utils
