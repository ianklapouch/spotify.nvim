local PlayerCommands = require("spotify.commands.player")
local Http = require("spotify.commands.http")
local UI = require("lua.spotify.ui")
local Notify = require("spotify.notify")

---@class SearchCommands
local SearchCommands = {}

function SearchCommands.search_track()
    local query_raw = vim.fn.input({
        prompt = "Search track: ",
        default = nil,
        cancelreturn = nil,
        hidden = true
    })

    if query_raw == nil then
        Notify.error("Invalid value for query")
        return
    end

    local query = query_raw:gsub(" ", "+")
    local endpoint = "search" .. "?q=" .. query .. "&type=track&limit=50"

    Http.get(endpoint, function(isSuccess, code, body)
        if isSuccess and body then
            local response = vim.json.decode(body)
            local tracks = response.tracks.items

            if tracks and #tracks > 0 then
                local title = "🎶 Choose a track from search (query: " .. query_raw .. ")"

                local items = vim.tbl_map(function(track)
                    return {
                        label = track.name .. " - " .. track.artists[1].name,
                        text = track.name .. " - " .. track.artists[1].name,
                        value = track.uri,
                        preview = "CUSTOM PREVIEW"
                    }
                end, tracks)

                UI.show_picker(title, items, function(item)
                    PlayerCommands.play_track(item)
                end)
            end
        end
    end)
end

return SearchCommands
