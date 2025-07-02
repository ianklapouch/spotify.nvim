local Notify = require("spotify.notify")
local TokenHandler = require("spotify.token.handler")

---@param callback function
local function ensure_token(callback)
    local token = TokenHandler.get_token()
    if token then
        callback(token)
    else
        TokenHandler.generate_token(function(new_token)
            if new_token then
                callback(new_token)
            end
        end)
    end
end

--- @param method string
--- @param endpoint string
--- @param body table | nil
--- @param token Token
--- @param callback function
local function make_request(method, endpoint, body, token, callback)
    if token then
        local cmd = {
            "curl",
            "-s",
            "-w", "%{http_code}",
            "-X", method,
            "https://api.spotify.com/v1/" .. endpoint,
            "-H", "Authorization: Bearer " .. token.access_token,
            "-H", "Content-Type: application/json",
        }

        if body ~= nil then
            vim.list_extend(cmd, body)
        else
            vim.list_extend(cmd,
                {
                    "-H",
                    "Content-Length: 0"
                })
        end

        vim.system(cmd, { text = true }, function(result)
            local body_response, code_str = result.stdout:match("^(.*)(%d%d%d)$")
            local code = tonumber(code_str)
            local isSuccess = code and code >= 200 and code < 300

            if callback then callback(isSuccess, code, body_response) end

            if result.stderr and result.stderr ~= "" then
                Notify.error("Erro no curl: " .. result.stderr)
            end
        end)
    end
end

--- @param method string
--- @param endpoint string
--- @param body table | nil
--- @param callback function
local function request(method, endpoint, body, callback)
    ensure_token(function(token)
        make_request(method, endpoint, body, token, callback)
    end)
end

---@class Http
local Http = {}

---@param endpoint string
---@param callback function
function Http.get(endpoint, callback)
    request("GET", endpoint, nil, callback)
end

---@param endpoint string
---@param callback function
function Http.post(endpoint, callback)
    request("POST", endpoint, nil, callback)
end

---@param endpoint string
---@param callback function
function Http.put(endpoint, body, callback)
    request("PUT", endpoint, body, callback)
end

return Http
