local Uri = require("spotify.uri")

---@param str string
---@param separator string
---@return string[]
local function split_path(str, separator)
    local result = {}
    for match in (str .. separator):gmatch("(.-)" .. separator) do
        table.insert(result, match)
    end
    return result
end

---@class Utils
local Utils = {}

---@param ... string
---@return string
function Utils.join_path(...)
    local args = { ... }
    if #args == 0 then
        return ""
    end

    local path_separator = package.config:sub(1, 1)

    local all_parts = {}

    for _, arg in ipairs(args) do
        local parts = split_path(arg, path_separator)
        vim.list_extend(all_parts, parts)
    end

    return table.concat(all_parts, path_separator)
end

---@param str string
---@return string
function Utils.url_encode(str)
    return str and string.gsub(str, "([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

---@param uri string
---@return Uri
function Utils.parse_uri(uri)
    local protocol, host_port = uri:match("^(%w+)://([^/]+)")
    if not protocol or not host_port then
        error("URI inválida: " .. uri)
    end

    local host, port = host_port:match("^([^:]+):?(%d*)$")
    port = #port > 0 and tonumber(port) or (protocol == "https" and 443 or 80)

    local path = uri:match("^%w+://[^/]+(/.*)$") or "/"

    return Uri:new(protocol, host, port, path)
end

---@param str string
---@param width number
---@return string
function Utils.pad_right(str, width)
    local current = vim.fn.strdisplaywidth(str)
    local pad = math.max(0, width - current)
    return str .. string.rep(" ", pad)
end

return Utils
