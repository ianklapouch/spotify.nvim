---@class Token
---@field token_type string
---@field access_token string
---@field refresh_token string
---@field scope string
---@field created_at number
---@field expires_in number
local Token = {}
Token.__index = Token

function Token:new(access_token, refresh_token, created_at, expires_in)
    local token = {
        token_type = "Bearer",
        access_token = access_token,
        refresh_token = refresh_token,
        scope = "user-modify-playback-state",
        created_at = created_at,
        expires_in = expires_in
    }
    return token
end

return Token
