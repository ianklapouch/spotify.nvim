--- @class Notify
--- @field opts table
local Notify = {}

local opts = {
    title = "Spotify.nvim"
}

--- @param message string
function Notify.debug(message)
    vim.notify(message, vim.log.levels.DEBUG, opts)
end

--- @param message string
function Notify.error(message)
    vim.notify(message, vim.log.levels.ERROR, opts)
end

--- @param message string
function Notify.info(message)
    vim.notify(message, vim.log.levels.INFO, opts)
end

--- @param message string
function Notify.trace(message)
    vim.notify(message, vim.log.levels.TRACE, opts)
end

--- @param message string
function Notify.warn(message)
    vim.notify(message, vim.log.levels.WARN, opts)
end

return Notify
