local CredentialsHandler = require("spotify.credentials.handler")
local CommandsHandler = require("spotify.commands.handler")

CommandsHandler.register_commands()

if not CredentialsHandler.credentials_file_exists() then
    vim.notify(
        "Incomplete configuration, enter your Client ID and Client secret using the command :SpotifyAuthorize",
        vim.log.levels.WARN,
        { title = "Spotify.nvim" }
    )
end
