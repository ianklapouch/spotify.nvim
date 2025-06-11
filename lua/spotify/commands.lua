local M = {}
local auth = require("spotify.auth")

local function api_request(method, endpoint, callback)
  auth.get_access_token(function(token_data)
    if not token_data or not token_data.access_token then
      vim.notify("❌ Falha na autenticação com o Spotify", vim.log.levels.ERROR)
      if callback then callback(false) end
      return
    end

    local cmd = {
      "curl",
      "-s",
      "-w", "%{http_code}",
      "-X", method,
      "https://api.spotify.com/v1/me/player" .. endpoint,
      "-H", "Authorization: Bearer " .. token_data.access_token,
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
  end)
end

function M.play(callback) api_request("PUT", "/play", callback) end

function M.pause(callback) api_request("PUT", "/pause", callback) end

function M.next(callback) api_request("POST", "/next", callback) end

function M.prev(callback) api_request("POST", "/previous", callback) end

local function authenticate()
  local clientId = vim.fn.input({
    prompt = "Client ID: ",
    default = "",
    cancelreturn = nil,
    hidden = true
  })

  local clientSecret = vim.fn.input({
    prompt = "Client secret: ",
    default = "",
    cancelreturn = nil,
    hidden = true
  })

  if clientId == nil or clientSecret == nil then 
    vim.notify("❌ Falha ao autenticar", vim.log.levels.ERROR)
    return
  end

  auth.store_secrets(clientId, clientSecret)
end

function M.register_commands()
  vim.api.nvim_create_user_command("SpotifyPlay", function()
    M.play(function(success)
      vim.notify(success and "🎵 Spotify is playing" or "❌ Falha ao reproduzir",
        success and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end, { desc = "Resume Spotify playback" })
  vim.api.nvim_create_user_command("SpotifyPause", function()
    M.pause(function(success)
      vim.notify(success and "🎵 Spotify is paused" or "❌ Falha ao pausar",
        success and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end, { desc = "Pause Spotify playback" })

  vim.api.nvim_create_user_command("SpotifyNext", function()
    M.next(function(success)
      vim.notify(success and "⏭️ Spotify: Next" or "❌ Falha ao pular para a próxima",
        success and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end, { desc = "Skip to next track" })
  vim.api.nvim_create_user_command("SpotifyPrev", function()
    M.prev(function(success)
      vim.notify(success and "⏮️ Spotify: Previous" or "❌ Falha ao pular para o anterior",
        success and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end, { desc = "Skip to previous track" })

  vim.api.nvim_create_user_command("SpotifyAuthenticate", authenticate, { desc = "Teste" })
end

return M
