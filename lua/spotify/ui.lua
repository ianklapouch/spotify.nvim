local Snacks = require("snacks")
local Utils = require("spotify.utils")

local function run_on_ui_thread(fn)
    vim.schedule(fn)
end

local M = {}

function M.show_picker(title, items, on_confirm)
    run_on_ui_thread(function()
        local longest_title = 0
        local longest_album = 0

        for _, item in ipairs(items) do
            if not item.header and not item.divider then
                local display_title = item.track_name .. " - " .. item.artist_name
                longest_title = math.max(longest_title, vim.fn.strdisplaywidth(display_title))
                longest_album = math.max(longest_album, vim.fn.strdisplaywidth(item.album_name))
            end
        end

        longest_title = longest_title + 1
        longest_album = longest_album + 1

        Snacks.picker.pick({
            title = title,
            items = items,
            layout = {
                preview = false
            },
            on_change = function(picker, item)
                if item and (item.divider or item.header) then
                    picker:action("list_down")
                end
            end,
            format = function(item)
                local ret = {}

                if item.header then
                    local header_index = " #   "
                    local header_title = Utils.pad_right("Title", longest_title) .. "   "
                    local header_album = Utils.pad_right("Album", longest_album) .. "   "
                    local header_duration = ""

                    ret[#ret + 1] = { header_index, "SnacksPickerLabel" }
                    ret[#ret + 1] = { header_title, "SnacksPickerLabel" }
                    ret[#ret + 1] = { header_album, "SnacksPickerLabel" }
                    ret[#ret + 1] = { header_duration, "SnacksPickerLabel" }
                    return ret
                end

                if item.divider then
                    ret[#ret + 1] = { string.rep("-", 200), "SnacksPickerLabel" }
                    return ret
                end

                local item_title = item.track_name .. " - " .. item.artist_name
                ret[#ret + 1] = { item.index .. "   ", "SnacksPickerLabel" }
                ret[#ret + 1] = { Utils.pad_right(item_title, longest_title) .. "   ", "SnacksPickerLabel" }
                ret[#ret + 1] = { Utils.pad_right(item.album_name, longest_album) .. "   ", "SnacksPickerLabel" }
                ret[#ret + 1] = { item.duration, "SnacksPickerLabel" }
                return ret
            end,
            confirm = function(picker, item)
                picker:close()
                if item then
                    on_confirm(item)
                end
            end,
        })
    end)
end

return M
