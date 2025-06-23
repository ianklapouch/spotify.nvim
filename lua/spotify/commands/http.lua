local TokenHandler = require("spotify.token.handler")

--- @param method string
--- @param endpoint string
--- @param callback function
local function request(method, endpoint, callback)
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
            "-H", "Content-Length: 0"
        }

        vim.system(cmd, { text = true }, function(result)
            local code = tonumber(result.stdout:match("%d%d%d$"))
            if code and code >= 200 and code < 300 then
                vim.notify("✅ Spotify API retornou código: " .. code, vim.log.levels.INFO)
                vim.notify("✅ Resposta: " .. (result.stdout or "desconhecido"), vim.log.levels.INFO)
                if callback then callback(true) end
            else
                vim.notify("❌ Spotify API retornou código: " .. (code or "desconhecido"), vim.log.levels.ERROR)
                vim.notify("❌ Resposta: " .. (result.stdout or "desconhecido"), vim.log.levels.ERROR)
                if callback then callback(false) end
            end

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
function Http.post(endpoint, callback)
    request("POST", endpoint, callback)
end

---@param endpoint string
---@param callback function
function Http.put(endpoint, callback)
    request("PUT", endpoint, callback)
end

return Http
