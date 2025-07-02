local CredentialsHandler = require("spotify.credentials.handler")
local Utils = require("spotify.utils")
local Notify = require("spotify.notify")
local spotify_auth = require("spotify.spotify-auth")
local cache_dir = Utils.join_path(vim.fn.stdpath('cache'), 'spotify.nvim')
local token_path = Utils.join_path(cache_dir, 'token.json')

---@class TokenHandler
local TokenHandler = {}

---@return Token | nil
function TokenHandler.get_token()
    if vim.fn.filereadable(token_path) == 1 then
        local file = io.open(token_path, 'r')
        if file then
            local content = file:read('*a')
            file:close()
            local success, data = pcall(vim.json.decode, content)
            if success and data and data.access_token then
                if os.time() < (data.created_at + data.expires_in - 60) then
                    return data
                end
            end
        end
    end
    return nil
end

---@param token Token
function TokenHandler.store_token(token)
    local json_token = vim.json.encode(token)
    local file = io.open(token_path, 'w')
    if file then
        file:write(json_token)
        file:close()
    end
end

---@return Token | nil
function TokenHandler.generate_token(callback)
    local credentials = CredentialsHandler.get_credentials()
    if credentials ~= nil then
        spotify_auth.authenticate(credentials, function(token)
            if token ~= nil then
                token.created_at = os.time()
                TokenHandler.store_token(token)
                if callback then callback(token) end
            end
        end)
    else
        Notify.warn(
        "Incomplete configuration, enter your Client ID and Client secret using the command :SpotifyAuthenticate")
    end
    return nil
end

return TokenHandler
