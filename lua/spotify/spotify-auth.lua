local http = require("plenary.curl")
local uv = vim.loop
local a = require("plenary.async")

local REDIRECT_URI = "http://127.0.0.1:8888/callback"
local SPOTIFY_AUTH_URL = "https://accounts.spotify.com/api/token"
local AUTH_SUCCESS_HTML = "<script>window.close();</script><p>Autenticação concluída! Esta janela pode ser fechada.</p>"


local function urlencode(str)
    return str and string.gsub(str, "([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function parse_uri(uri)
    local protocol, host_port = uri:match("^(%w+)://([^/]+)")
    if not protocol or not host_port then
        error("URI inválida: " .. uri)
    end

    local host, port = host_port:match("^([^:]+):?(%d*)$")
    port = #port > 0 and tonumber(port) or (protocol == "https" and 443 or 80)

    local path = uri:match("^%w+://[^/]+(/.*)$") or "/"

    return {
        protocol = protocol,
        host = host,
        port = port,
        path = path
    }
end

local function open_browser(client_id, redirect_uri)
    local auth_url = string.format(
        "https://accounts.spotify.com/authorize?response_type=code&client_id=%s&scope=%s&redirect_uri=%s",
        client_id,
        "user-modify-playback-state",
        urlencode(redirect_uri)
    )

    local cmd
    vim.notify("client_id: " .. client_id, vim.log.levels.INFO)
    vim.notify("redirect_uri: " .. redirect_uri, vim.log.levels.INFO)
    vim.notify("urlencode(redirect_uri): " .. urlencode(redirect_uri), vim.log.levels.INFO)
    vim.notify("auth_url: " .. auth_url, vim.log.levels.INFO)
    if vim.fn.has("win32") == 1 then
        cmd = { "cmd", "/c", 'start "" "' .. auth_url .. '"' }
    elseif vim.fn.has("mac") == 1 then
        cmd = { "open", auth_url }
    else
        cmd = { "xdg-open", auth_url }
    end

    vim.notify("cmd: " .. table.concat(cmd, " "), vim.log.levels.INFO)
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
        table.insert(encoded_body, string.format("%s=%s", urlencode(k), urlencode(v)))
    end

    local res = http.request({
        url = SPOTIFY_AUTH_URL,
        method = "POST",
        body = table.concat(encoded_body, "&"),
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["Accept"] = "application/json"
        },
        callback = function(response)
            if response.status ~= 200 then
                vim.notify("Erro na API", vim.log.levels.ERROR)
                return callback(nil, response)
            end
            local success, data = pcall(vim.json.decode, response.body)
            callback(data, response)
        end
    })
end

local function start_auth_server(client_id, client_secret, redirect_uri, callback)
    vim.notify("start_auth_server", vim.log.levels.INFO)
    local uri = parse_uri(redirect_uri)

    local server = uv.new_tcp()
    server:bind(uri.host, uri.port)

    server:listen(128, function(err)
        vim.notify("listening", vim.log.levels.INFO)
        if err then
            vim.notify("Erro no servidor: " .. err, vim.log.levels.ERROR)
            return
        end

        local client = uv.new_tcp()
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
                        #AUTH_SUCCESS_HTML,
                        AUTH_SUCCESS_HTML
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

function M.authenticate(client_id, client_secret, callback)
    local server = start_auth_server(client_id, client_secret, REDIRECT_URI, callback)
    open_browser(client_id, REDIRECT_URI)

    vim.notify("Aguardando autenticação em: " .. REDIRECT_URI, vim.log.levels.INFO)

    return function()
        if server and not server:is_closing() then
            vim.notify("close server", vim.log.levels.INFO)
            server:close()
        end
    end
end

return M
