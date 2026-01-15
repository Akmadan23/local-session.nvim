local win = require("local-session.win")
local fmt = string.format
local api = vim.api

---@class FileSpec
---@field [1] string|nil
---@field focus boolean|nil
---@field opts table|nil
---@field split FileSpec|nil
---@field vsplit FileSpec|nil
---@field callback string|function|nil

---@class RootSpec: FileSpec
---@field tabs (FileSpec|string)[]|nil
---@field config function|nil

local config = {
    filename = ".session.lua",
    notify_session_loaded = true,
}

local session_exists = function()
    return vim.fn.filereadable(config.filename) == 1
end

---@param msg string
---@param level string|nil
local notify = function(msg, level)
    vim.notify(msg, vim.log.levels[level or "WARN"], { title = "LocalSession" })
end

---@param user_config table
local update_config = function(user_config)
    local msg -- message to be displayed if errors are detected

    for user_k, user_v in pairs(user_config) do
        local invalid
        local default_v = config[user_k]
        local user_t = type(user_v)
        local default_t = type(default_v)

        if default_v == nil then
            invalid = fmt("Unknown option: %s", user_k)
        elseif user_t ~= default_t then
            invalid = fmt("Invalid option: %s. Expected %s, got %s", user_k, default_t, user_t)
        end

        if invalid then
            user_config[user_k] = nil

            if msg then
                msg = fmt("%s\n%s", msg, invalid)
            else
                msg = invalid
            end
        end
    end

    if msg then
        notify(msg)
    end

    -- Update the config with user preferences
    config = vim.tbl_extend("force", config, user_config)
end

local M = {}

---@param user_config table|nil
M.setup = function(user_config)
    if user_config then
        update_config(user_config)
    end

    api.nvim_create_autocmd("VimEnter", {
        group = api.nvim_create_augroup("LocalSession", {}),
        once = true,

        callback = function(args)
            -- try to load session only if nvim is launched with no file arguments
            if args.file == "" then
                vim.opt.shm:append("I") -- don't display nvim intro message
                vim.schedule(M.load)
            end
        end
    })

    api.nvim_create_user_command("LocalSessionLoad", function(x)
        M.load(x.fargs[1])
    end, {
        nargs = "?",
        complete = "dir"
    })

    api.nvim_create_user_command("LocalSessionEdit", function()
        M.edit()
    end, {
        nargs = 0,
    })
end

---@param path string|nil
M.load = function(path)
    if path then
        if path == vim.fn.getcwd() then
            path = nil
        elseif vim.fn.isdirectory(vim.fn.expand(path)) == 1 then
            vim.cmd.cd(path)
        else
            notify(fmt("Error: '%s' is not a directory.", path))
            return
        end
    end

    if not session_exists() then
        -- quit immediately if no session file is found
        return
    end

    -- try to run session file
    ---@type _, RootSpec
    local ok, res = pcall(dofile, config.filename)

    if not ok then
        notify("Syntax error: " .. res, "ERROR")
        return
    end

    if type(res) ~= "table" then
        notify(fmt("Error: '%s' does not return a table.", config.filename))
        return
    end

    if type(res.config) == "function" then
        res.config()
    elseif type(res.config) == "string" then
        vim.cmd(res.config)
    end

    if type(res[1]) == "string" then
        vim.cmd.edit(res[1])
        win.setup(res)
    elseif type(res.tabs) == "table" then
        local first = true

        local tabnew = function(file)
            if first then
                vim.cmd.edit(file)
                first = false
            else
                vim.cmd.tabnew(file)
            end
        end

        for _, tab in ipairs(res.tabs) do
            if type(tab) == "string" then
                local glob_tab = vim.fn.glob(tab)

                if glob_tab == tab then
                    tabnew(tab)
                else
                    for _, file in ipairs(vim.split(glob_tab, "\n")) do
                        tabnew(file)
                    end
                end
            elseif type(tab) == "table" then
                tabnew(tab[1])
                win.setup(tab)
            end
        end
    end

    if path then
        vim.cmd.cd("-")
    end

    api.nvim_set_current_win(win.focus_id)

    if config.notify_session_loaded then
        notify("Session loaded successfully.", "INFO")
    end
end

M.edit = function()
    if not session_exists() then
        notify(fmt("No '%s' found at %s.", config.filename, vim.fn.getcwd()))
        return
    end

    vim.cmd.edit(config.filename)
end

return M
