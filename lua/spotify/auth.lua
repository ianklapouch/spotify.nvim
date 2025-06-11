local M = {}
local uv = vim.loop or vim.uv
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
    token_data.created_at = os.time() -- Adiciona timestamp atual
    local cache_path = get_token_path()
    local file = io.open(cache_path, 'w')
    if file then
        file:write(vim.json.encode(token_data))
        file:close()
    end
end

function M.get_access_token(callback)
    local cached_token = load_cached_token()
    if cached_token then
        vim.notify("✅ Usando token do cache", vim.log.levels.INFO)
        callback(cached_token)
        return
    end

    local script_path = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])")
    script_path = vim.fn.fnamemodify(script_path, ":p:h:h:h")
    script_path = script_path .. "/scripts/spotify-auth.js"

    script_path = script_path:gsub("/", "\\")

    local secrets = get_secrets()
    local cmd = {
        "node",
        script_path,
        secrets.clientId or "",
        secrets.clientSecret or "",
        "http://127.0.0.1:8888/callback"
    }

    vim.notify("cmd: " .. table.concat(cmd, " "), vim.log.levels.INFO)

    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)

    local handle
    local output = {}

    handle = uv.spawn("node", {
        args = {
            script_path,
            secrets.clientId or "",
            secrets.clientSecret or "",
            "http://127.0.0.1:8888/callback"
        },
        stdio = { nil, stdout, stderr }
    }, function(code, signal)
        stdout:read_stop()
        stderr:read_stop()
        stdout:close()
        stderr:close()
        if handle then handle:close() end

        if code ~= 0 then
            vim.notify("❌ Falha na autenticação (código: " .. code .. ")", vim.log.levels.ERROR)
            callback(nil)
            return
        end

        local full_output = table.concat(output)
        local success, json = pcall(vim.json.decode, full_output)

        if success and json and json.access_token then
            json.expires_in = json.expires_in or 3600
            save_token_to_cache(json)
            vim.notify("🔑 Autenticação com Spotify concluída", vim.log.levels.INFO)
            callback(json)
        else
            vim.notify("json: " .. vim.inspect(json), vim.log.levels.INFO)
            vim.notify("❌ Resposta inválida do Spotify: " .. (full_output:gsub("%s+", " "):sub(1, 100)),
                vim.log.levels.ERROR)
            callback(nil)
        end
    end)

    if not handle then
        vim.notify("❌ Falha ao iniciar processo de autenticação", vim.log.levels.ERROR)
        callback(nil)
        return
    end

    stdout:read_start(function(err, data)
        if err then return end
        if data then table.insert(output, data) end
    end)

    stderr:read_start(function(err, data)
        if err then return end
        if data then vim.notify("⚠️ Spotify Auth: " .. data, vim.log.levels.WARN) end
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
