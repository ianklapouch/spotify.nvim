local CredentialsHandler = require("spotify.credentials.handler")
local CommandsHandler = require("spotify.commands.handler")
local Notify = require("spotify.notify")

CommandsHandler.register_commands()

if not CredentialsHandler.credentials_file_exists() then
    Notify.warn("Incomplete configuration, enter your Client ID and Client secret using the command :SpotifyAuthorize")
end
