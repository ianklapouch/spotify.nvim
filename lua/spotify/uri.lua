---@class Uri
---@field protocol string
---@field host string
---@field port number
---@field path string
local Uri = {}
Uri.__index = Uri

function Uri:new(protocol, host, port, path)
    local uri = {
        protocol = protocol,
        host = host,
        port = port,
        path = path
    }
    return uri
end

return Uri
