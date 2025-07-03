local PlayerCommands = require("spotify.commands.player")
local Http = require("spotify.commands.http")
local UI = require("spotify.ui")
local Notify = require("spotify.notify")

---@class SearchCommands
local SearchCommands = {}

function SearchCommands.search_track()
    local query_raw = vim.fn.input({
        prompt = "Search track, artist or album: ",
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
                local counter = 0

                local items = vim.tbl_map(function(track)
                    counter = counter + 1
                    local counter_str = tostring(counter)
                    if #counter_str == 1 then
                        counter_str = "0" .. counter_str
                    end

                    local duration_str = ""
                    if track.duration_ms then
                        local total_seconds = math.floor(track.duration_ms / 1000)
                        local minutes = math.floor(total_seconds / 60)
                        local seconds = total_seconds % 60
                        duration_str = string.format("%02d:%02d", minutes, seconds)
                    end

                    return {
                        index = counter_str,
                        track_name = track.name,
                        artist_name = track.artists[1].name,
                        label = track.name .. " - " .. track.artists[1].name,
                        text = track.name .. " - " .. track.artists[1].name,
                        album_name = track.album.name,
                        value = track.uri,
                        duration = duration_str,
                    }
                end, tracks)

                table.insert(items, 1, { divider = true, text = "" })
                table.insert(items, 1, { header = true, text = "" })

                UI.show_picker(title, items, function(item)
                    PlayerCommands.play_track(item)
                end)
            end
        end
    end)
end

return SearchCommands
