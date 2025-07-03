local Authorize = require("spotify.commands.authorize")
local PlayerCommands = require("spotify.commands.player")
local SearchCommands = require("spotify.commands.search")

---@class CommandsHandler
local CommandsHandler = {}

function CommandsHandler.register_commands()
    ---Authorize
    vim.api.nvim_create_user_command("SpotifyAuthorize", Authorize.run, { desc = "Authorize Spotify App" })
    ---Player
    vim.api.nvim_create_user_command("SpotifyGetPlaybackState", PlayerCommands.get_play_back_state,
        { desc = "Get Spotify playback state" })
    vim.api.nvim_create_user_command("SpotifyTransferPlayback", PlayerCommands.transfer_playback,
        { desc = "Transfer Spotify playback" })
    vim.api.nvim_create_user_command("SpotifyGetAvailableDevices", PlayerCommands.get_available_devices,
        { desc = "Get Spotify available devices" })

    vim.api.nvim_create_user_command("SpotifyTogglePlayback", PlayerCommands.toggle_playback,
        { desc = "Toggle Spotify playback" })
    vim.api.nvim_create_user_command("SpotifyNextTrack", PlayerCommands.next, { desc = "Skip to next track" })
    vim.api.nvim_create_user_command("SpotifyPreviousTrack", PlayerCommands.prev, { desc = "Skip to previous track" })
    vim.api.nvim_create_user_command("SpotifySetVolume", PlayerCommands.set_volume, { desc = "Set Spotify volume" })
    vim.api.nvim_create_user_command("SpotifyCurrentTrackInfo", PlayerCommands.get_currently_playing_track,
        { desc = "Get Spotify currently playing track" })
    vim.api.nvim_create_user_command("SpotifyShowCurrentQueue", PlayerCommands.get_queue,
        { desc = "Get Spotify currently playing track" })

    --- Search commands
    vim.api.nvim_create_user_command("SpotifySearch", SearchCommands.search_track,
        { desc = "Search Spotify track, artist or album" })



    -- vim.keymap.set("n", "<leader>spk", ":SpotifyPlay<CR>", { desc = "▶️ Play Spotify" })
    -- vim.keymap.set("n", "<leader>spj", ":SpotifyPause<CR>", { desc = "⏸️ Pause Spotify" })
    -- vim.keymap.set("n", "<leader>spl", ":SpotifyNext<CR>", { desc = "⏭️ Next track" })
    -- vim.keymap.set("n", "<leader>sph", ":SpotifyPrev<CR>", { desc = "⏮️ Previous track" })
    -- vim.keymap.set("n", "<leader>sp", ":SpotifyAuthorize<CR>", { desc = "🔑 Authorize Spotify" })
end

return CommandsHandler
