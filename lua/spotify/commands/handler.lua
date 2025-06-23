local Authorize = require("spotify.commands.authorize")
local PlayerCommands = require("spotify.commands.player")

---@class CommandsHandler
local CommandsHandler = {}

function CommandsHandler.register_commands()
    ---Authorize
    vim.api.nvim_create_user_command("SpotifyAuthorize", Authorize.run, { desc = "Authorize Spotify App" })
    ---Player
    vim.api.nvim_create_user_command("SpotifyPlay", PlayerCommands.play, { desc = "Resume Spotify playback" })
    vim.api.nvim_create_user_command("SpotifyPause", PlayerCommands.pause, { desc = "Pause Spotify playback" })
    vim.api.nvim_create_user_command("SpotifyNext", PlayerCommands.next, { desc = "Skip to next track" })
    vim.api.nvim_create_user_command("SpotifyPrev", PlayerCommands.prev, { desc = "Skip to previous track" })

    vim.keymap.set("n", "<leader>spk", ":SpotifyPlay<CR>", { desc = "▶️ Play Spotify" })
    vim.keymap.set("n", "<leader>spj", ":SpotifyPause<CR>", { desc = "⏸️ Pause Spotify" })
    vim.keymap.set("n", "<leader>spl", ":SpotifyNext<CR>", { desc = "⏭️ Next track" })
    vim.keymap.set("n", "<leader>sph", ":SpotifyPrev<CR>", { desc = "⏮️ Previous track" })
    -- vim.keymap.set("n", "<leader>sp", ":SpotifyAuthorize<CR>", { desc = "🔑 Authorize Spotify" })
end

return CommandsHandler
