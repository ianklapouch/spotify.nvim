local M = {}

function M.setup()
    require("spotify.auth").setup()
    require("spotify.commands").register_commands()
end

return M
