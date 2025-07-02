local Notify = require("spotify.notify")
local snacks = require("snacks")
local Http = require("spotify.commands.http")

---@class PlayerCommands
local PlayerCommands = {}

---https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback
function PlayerCommands.get_play_back_state()
    local endpoint = "me/player"
    Http.get(endpoint, function(success, code, response)
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/transfer-a-users-playback
function PlayerCommands.transfer_playback()
    ---TODO
end

---https://developer.spotify.com/documentation/web-api/reference/get-a-users-available-devices
function PlayerCommands.get_available_devices()
    local endpoint = "me/player/devices"
    Http.get(endpoint, function(success, code, response)
        Notify.info("Devices: " .. vim.inspect(response))
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/get-the-users-currently-playing-track
function PlayerCommands.get_currently_playing_track(action)
    local endpoint = "me/player/currently-playing"
    Http.get(endpoint, function(isSuccess, _, body)
        if isSuccess then
            local data = vim.json.decode(body)
            local track_name = data.item.name or "Unknown Track"
            local album_name = data.item.album.name or "Unknown Album"
            local artist_name = data.item.artists[1].name or "Unknown Artist"

            if action ~= nil and type(action) == "string" then
                Notify.info(action .. track_name .. " - " .. artist_name)
            else
                local message = string.format(
                    "🎤 Artist: %s\n🎵 Track: %s\n💿 Album: %s",
                    artist_name,
                    track_name,
                    album_name
                )
                Notify.info(message)
            end
        end
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/start-a-users-playback
function PlayerCommands.play()
    local endpoint = "me/player/play"
    Http.put(endpoint, nil, function(isSuccess, code, _)
        if isSuccess then
            PlayerCommands.get_currently_playing_track("🎵 Now playing: ")
        elseif code == 404 then
            Notify.error("No Active Device!")
        end
    end)
end

function PlayerCommands.play_track(item)
    local endpoint = "me/player/play"
    local body = {
        "-d",
        '{"uris": ["' .. item.value .. '"]}'
    }
    Http.put(endpoint, body, function(isSuccess, code, _)
        if isSuccess then
            Notify.info("🎵 Now playing: " .. item.text)
        elseif code == 404 then
            Notify.error("No Active Device!")
        end
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/pause-a-users-playback
function PlayerCommands.pause()
    local endpoint = "me/player/pause"
    Http.put(endpoint, nil, function(isSuccess)
        if isSuccess then
            PlayerCommands.get_currently_playing_track("⏸️ Playback paused: ")
        end
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/skip-users-playback-to-next-track
function PlayerCommands.next()
    local endpoint = "me/player/next"
    Http.post(endpoint, function(isSuccess)
        if isSuccess then
            PlayerCommands.get_currently_playing_track("⏭️ Skipped to next track: ")
        end
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/skip-users-playback-to-previous-track
function PlayerCommands.prev()
    local endpoint = "me/player/previous"
    Http.post(endpoint, function(isSuccess)
        if isSuccess then
            PlayerCommands.get_currently_playing_track("⏮️ Returned to previous track: ")
        end
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/seek-to-position-in-currently-playing-track
function PlayerCommands.seek_to_position()
    ---TODO
end

---https://developer.spotify.com/documentation/web-api/reference/set-repeat-mode-on-users-playback
function PlayerCommands.set_repeat_mode()
    ---TODO
end

---https://developer.spotify.com/documentation/web-api/reference/set-volume-for-users-playback
function PlayerCommands.set_volume()
    local volume = vim.fn.input({
        prompt = "Volume percentage(0-100): ",
        default = nil,
        cancelreturn = nil,
        hidden = true
    })

    if volume == nil then
        return
    end

    volume = tonumber(volume)
    volume = math.floor(volume)

    if volume < 0 or volume > 100 then
        return
    end

    local endpoint = "me/player/volume?volume_percent=" .. volume
    Http.put(endpoint, nil, function(isSuccess)
        if isSuccess then
            Notify.info("Volume set to " .. volume .. "%")
        end
    end)
end

---https://developer.spotify.com/documentation/web-api/reference/toggle-shuffle-for-users-playback
function PlayerCommands.toggle_shuffle()
    ---TODO
end

--- https://developer.spotify.com/documentation/web-api/reference/get-recently-played
function PlayerCommands.get_recently_played()
    ---TODO
end

local function run_in_ui_thread(fn)
    vim.schedule(fn)
end
--- https://developer.spotify.com/documentation/web-api/reference/get-queue
function PlayerCommands.get_queue()
    local endpoint = "me/player/queue"
    Http.get(endpoint, function(isSuccess, code, body)
        if isSuccess and body then
            local response = vim.json.decode(body)

            local queue = {}

            if response.currently_playing ~= vim.NIL then
                local current_track = response.currently_playing.name
                local current_artist = response.currently_playing.artists[1].name
                local current_track_uri = response.currently_playing.uri
                table.insert(queue, {
                    name = current_track,
                    artist = current_artist,
                    uri = current_track_uri
                })
            end

            for _, track in pairs(response.queue) do
                local track_name = track.name or "Unknown Track"
                local artist_name = track.artists[1].name or "Unknown Artist"
                local track_uri = track.uri
                table.insert(queue, {
                    name = track_name,
                    artist = artist_name,
                    uri = track_uri
                })
            end

            run_in_ui_thread(function()
                snacks.picker.pick({
                    title = "🎶 Choose a track from queue",
                    items = vim.tbl_map(function(track)
                        return {
                            label = track.name .. " - " .. track.artist,
                            value = track.uri,
                        }
                    end, queue),
                    layout = {
                        preview = false
                    },
                    confirm = function(picker, item)
                        picker:close()
                        if item then
                            Notify.info("✅ Playing: " .. item.value)
                            PlayerCommands.play_track(item)
                            -- vim.api.nvim_command(":silent! Prosession " .. item.label)
                        end
                    end,
                })
            end)
        end
    end)
end

--- https://developer.spotify.com/documentation/web-api/reference/add-to-queue
function PlayerCommands.add_to_queue()

end

function PlayerCommands.toggle_playback()
    local endpoint = "me/player"
    Http.get(endpoint, function(isSuccess, code, body)
        if code == 204 or (body and vim.json.decode(body).is_playing == false) then
            PlayerCommands.play()
        elseif isSuccess and body and vim.json.decode(body).is_playing then
            PlayerCommands.pause()
        end
    end)
end

return PlayerCommands
