local Utils = require("spotify.utils")
local http = require("plenary.curl")

local redirect_uri = "http://127.0.0.1:8888/callback"
local spotify_auth_url = "https://accounts.spotify.com/api/token"
local auth_success_html = "<script>window.close();</script><p>Autenticação concluída! Esta janela pode ser fechada.</p>"

local function open_browser(client_id, redirect_uri)
    local auth_url = string.format(
        "https://accounts.spotify.com/authorize?response_type=code&client_id=%s&scope=%s&redirect_uri=%s",
        client_id,
        Utils.url_encode("user-modify-playback-state user-read-playback-state"),
        Utils.url_encode(redirect_uri)
    )

    local cmd

    if vim.fn.has("win32") == 1 then
        cmd = { "cmd", "/c", 'start "" "' .. auth_url .. '"' }
    elseif vim.fn.has("mac") == 1 then
        cmd = { "open", auth_url }
    else
        cmd = { "xdg-open", auth_url }
    end

    vim.fn.jobstart(cmd, { detach = true })
end

local function exchange_code(code, client_id, client_secret, redirect_uri, callback)
    local body = {
        grant_type = "authorization_code",
        code = code,
        redirect_uri = redirect_uri,
        client_id = client_id,
        client_secret = client_secret
    }

    local encoded_body = {}
    for k, v in pairs(body) do
        table.insert(encoded_body, string.format("%s=%s", Utils.url_encode(k), Utils.url_encode(v)))
    end

    http.request({
        url = spotify_auth_url,
        method = "POST",
        body = table.concat(encoded_body, "&"),
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["Accept"] = "application/json"
        },
        callback = function(response)
            if response.status ~= 200 then
                return callback(nil, response)
            end
            local _, data = pcall(vim.json.decode, response.body)
            callback(data)
        end
    })
end

local function start_auth_server(client_id, client_secret, redirect_uri, callback)
    local uri = Utils.parse_uri(redirect_uri)

    local server = vim.loop.new_tcp()
    server:bind(uri.host, uri.port)

    server:listen(128, function(err)
        if err then
            return
        end

        local client = vim.loop.new_tcp()
        server:accept(client)

        local request_data = ""
        client:read_start(function(err, chunk)
            if err then
                client:close()
                return
            end

            if not chunk then
                client:close()
                return
            end

            request_data = request_data .. chunk

            if request_data:find("\r\n\r\n") or request_data:find("\n\n") then
                local pattern = "GET " .. uri.path .. "%?code=([%w-_]+)"
                local code = request_data:match(pattern)

                if code then
                    server:close()

                    local response = string.format(
                        "HTTP/1.1 200 OK\r\n" ..
                        "Content-Type: text/html\r\n" ..
                        "Content-Length: %d\r\n" ..
                        "\r\n%s",
                        #auth_success_html,
                        auth_success_html
                    )

                    client:write(response)

                    vim.defer_fn(function()
                        client:shutdown()
                        client:close()
                        exchange_code(code, client_id, client_secret, redirect_uri, callback)
                    end, 100)
                end
            end
        end)
    end)

    return server
end

local M = {}

---@param credentials Credentials
---@return function
function M.authenticate(credentials, callback)
    local server = start_auth_server(credentials.client_id, credentials.client_secret, redirect_uri, callback)
    open_browser(credentials.client_id, redirect_uri)

    return function()
        if server and not server:is_closing() then
            server:close()
        end
    end
end

return M
