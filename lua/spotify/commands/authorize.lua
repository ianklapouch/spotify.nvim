local Credentials = require("spotify.credentials.credentials")
local CredentialsHandler = require("spotify.credentials.handler")
local TokenHandler = require("spotify.token.handler")
local Notify = require("spotify.notify")

---@class Authorize
local Authorize = {}

function Authorize.run()
    local client_id = vim.fn.input({
        prompt = "Client ID: ",
        default = "",
        cancelreturn = nil,
        hidden = true
    })

    local client_secret = vim.fn.input({
        prompt = "Client secret: ",
        default = "",
        cancelreturn = nil,
        hidden = true
    })

    if client_id == nil or client_secret == nil then
        Notify.error("Falha ao autenticar")
        return
    end

    CredentialsHandler.store_credentials(Credentials:new(client_id, client_secret))
    TokenHandler.generate_token()
end

return Authorize
