local M = {}
local uv = vim.loop or vim.uv
local spotify_auth = require("spotify.spotify-auth")
local cache_dir = vim.fn.stdpath('cache') .. '\\spotify.nvim'
local token_path = cache_dir .. '\\token_cache.json'
local secrets_path = cache_dir .. '\\secrets.json'

local function load_cached_token()
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

local function get_secrets()
    local file = io.open(secrets_path, 'r')
    if file then
        local content = file:read('*a')
        file:close()
        local success, data = pcall(vim.json.decode, content)
        if success then return data end
    end
    return nil
end

local function save_token_to_cache(token_data)
    local file = io.open(token_path, 'w')
    if file then
        file:write(token_data)
        file:close()
    end
end

local function on_success(token_data)
    vim.notify("🔑 Token válido até: " .. os.date("%Y-%m-%d %H:%M:%S", token_data.expires_in + os.time()),
        vim.log.levels.INFO)
    vim.notify("🔑 Token: " .. token_data.access_token, vim.log.levels.INFO)
    vim.notify("🔑 Tipo de token: " .. token_data.token_type, vim.log.levels.INFO)
    vim.notify("🔑 Expira em: " .. os.date("%Y-%m-%d %H:%M:%S", token_data.expires_in + os.time()),
        vim.log.levels.INFO)
    vim.notify("🔑 Data de criação: " .. os.date("%Y-%m-%d %H:%M:%S", token_data.created_at),
        vim.log.levels.INFO)
    vim.notify("🔑 Data de expiração: " .. os.date("%Y-%m-%d %H:%M:%S", token_data.expires_in + os.time()),
        vim.log.levels.INFO)
end

function M.get_access_token()
    local cached_token = load_cached_token()
    if cached_token then
        vim.notify("✅ Usando token do cache", vim.log.levels.INFO)
        return cached_token
    end

    local secrets = get_secrets()
    spotify_auth.authenticate(secrets.clientId, secrets.clientSecret, function(token_data, response)
        vim.notify("resposta", vim.log.levels.INFO)
        vim.notify(vim.inspect(response), vim.log.levels.INFO)
        if token_data then
            token_data.created_at = os.time()
            local json = vim.json.encode(token_data)
            save_token_to_cache(json)
            vim.notify("🔑 Autenticação com Spotify concluída", vim.log.levels.INFO)
            vim.notify("✅ Token válido até: " .. os.date("%Y-%m-%d %H:%M:%S", token_data.expires_in + os.time()),
                vim.log.levels.INFO)
            return token_data
        else
            vim.notify("❌ Falha ao autenticar", vim.log.levels.ERROR)
        end
    end)
end

local function user_has_secrets()
    return vim.fn.filereadable(secrets_path) == 1
end

function M.store_secrets(clientId, clientSecret)
    local secrets = {
        clientId = clientId,
        clientSecret = clientSecret
    }
    local file = io.open(secrets_path, 'w')
    if file then
        file:write(vim.json.encode(secrets))
        file:close()
    end
end

function M.setup()
    if not user_has_secrets() then
        vim.notify(
            "Spotify: Incomplete configuration, enter your Client ID and Client secret using the command :SpotifyAuthenticate",
            vim.log.levels.WARN)
    end
end

return M
