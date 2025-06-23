---@class Credentials
---@field client_id string
---@field client_secret string
local Credentials = {}
Credentials.__index = Credentials

function Credentials:new(client_id, client_secret)
    local credentials = {
        client_id = client_id,
        client_secret = client_secret
    }
    return credentials
end

return Credentials
