local Utils = require("spotify.utils")
local cache_dir = Utils.join_path(vim.fn.stdpath('cache'), 'spotify.nvim')
local credentials_path = Utils.join_path(cache_dir, 'credentials.json')

---@class CredentialsHandler
local CredentialsHandler = {}

---@return boolean
function CredentialsHandler.credentials_file_exists()
    return vim.fn.filereadable(credentials_path) == 1
end

---@return Credentials | nil
function CredentialsHandler.get_credentials()
    local file = io.open(credentials_path, 'r')
    if file then
        local content = file:read('*a')
        file:close()
        local success, data = pcall(vim.json.decode, content)
        if success then return data end
    end
    return nil
end

---@param credentials Credentials
function CredentialsHandler.store_credentials(credentials)
    local file = io.open(credentials_path, 'w')
    if file then
        file:write(vim.json.encode(credentials))
        file:close()
    end
end

return CredentialsHandler
