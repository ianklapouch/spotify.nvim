local Snacks = require("snacks")

local function run_on_ui_thread(fn)
    vim.schedule(fn)
end

local M = {}

function M.show_picker(title, items, on_confirm)
    run_on_ui_thread(function()
        Snacks.picker.pick({
            title = title,
            items = items,
            layout = {
                preview = false
            },
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
