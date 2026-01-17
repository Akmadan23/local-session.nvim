local M = {}

-- ID of focused window (first by default)
M.focus_id = 1000

---@param win FileSpec
M.setup = function(win)
    if type(win.opts) == "table" then
        for key, value in pairs(win.opts) do
            vim.o[key] = value
        end
    end

    if type(win.callback) == "string" then
        vim.cmd(win.callback)
    elseif type(win.callback) == "function" then
        win.callback()
    end

    if win.focus == true then
        M.focus_id = vim.api.nvim_get_current_win()
    end

    -- process 'split' and 'vsplit' fields
    for _, s in ipairs { "split", "vsplit" } do
        local split_val = win[s]
        if type(split_val) == "string" then
            vim.cmd[s](split_val)
            break
        elseif type(split_val) == "table" and type(split_val.path) == "string" then
            vim.cmd[s](split_val.path)
            M.setup(split_val)
            break
        end
    end
end

return M
