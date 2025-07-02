local TokenHandler = require("spotify.token.handler")

--- @param method string
--- @param endpoint string
--- @param body table | nil
--- @param callback function
local function request(method, endpoint, body, callback)
    local token = TokenHandler.get_token()

    if token == nil then
        token = TokenHandler.generate_token()
    end

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

            -- if isSuccess then
            --     vim.notify("✅ Spotify API retornou código: " .. code, vim.log.levels.INFO)
            --     vim.notify("✅ Resposta: " .. (result.stdout or "desconhecido"), vim.log.levels.INFO)
            -- else
            --     vim.notify("❌ Spotify API retornou código: " .. (code or "desconhecido"), vim.log.levels.ERROR)
            --     vim.notify("❌ Resposta: " .. (result.stdout or "desconhecido"), vim.log.levels.ERROR)
            -- end

            if callback then callback(isSuccess, code, body_response) end

            if result.stderr and result.stderr ~= "" then
                vim.notify("⚠️ Erro no curl: " .. result.stderr, vim.log.levels.WARN)
            end
        end)
    end
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
