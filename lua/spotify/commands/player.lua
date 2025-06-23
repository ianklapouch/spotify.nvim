local Http = require("spotify.commands.http")

---me/player commands
---@class PlayerCommands
local PlayerCommands = {}

---https://developer.spotify.com/documentation/web-api/reference/start-a-users-playback
function PlayerCommands.play()
    local endpoint = "me/player/play"
    Http.put(endpoint, function(success)
        vim.notify(success and "🎵 Spotify is playing" or "❌ Falha ao reproduzir",
            success and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/pause-a-users-playback
function PlayerCommands.pause()
    local endpoint = "me/player/pause"
    Http.put(endpoint, function(success)
        vim.notify(success and "🎵 Spotify is paused" or "❌ Falha ao pausar",
            success and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/skip-users-playback-to-next-track
function PlayerCommands.next()
    local endpoint = "me/player/next"
    Http.post(endpoint, function(success)
        vim.notify(success and "⏭️ Spotify: Next" or "❌ Falha ao pular para a próxima",
            success and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/skip-users-playback-to-previous-track
function PlayerCommands.prev()
    local endpoint = "me/player/previous"
    Http.post(endpoint, function(success)
        vim.notify(success and "⏮️ Spotify: Previous" or "❌ Falha ao pular para o anterior",
            success and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
end

return PlayerCommands
