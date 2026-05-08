-- crayons.lua
-- A plugin to manage a global colorscheme list with per-buffer overrides via Styler

local Config    = require("cabinet").config_manager
local Styler    = require("styler")
local M         = {}

-- Default configuration
M.default_config = {
    themes           = {},   -- array of { name, variants = { standard, light, dark, darkest } }
    buffer_themes    = {},   -- array of { filetype|buftype, colorscheme, background }
    keybind_prefix   = "<leader>t",   -- prefix for keymaps: <prefix><index><variant>
}

-- Variant suffix mapping
M.variant_suffix = {
    standard = "s",
    light    = "l",
    dark     = "d",
    darkest  = "t",
}

-- Debug helper
local function debug(msg)
    vim.schedule(function()
        vim.notify(msg, vim.log.levels.INFO, { title = "Crayons-Debug" })
    end)
end

-- Setup function
function M.setup(user_config)
    -- Merge defaults and user config
    M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})

    -- Initialize Cabinet for persistence
    Config.setup({ config_path = "crayons" })

    -- Load saved global state
    local saved = Config.load("theme_config") or {}
    M.current = {
        index   = saved.index   or 1,
        variant = saved.variant or "standard",
    }

    -- Build filetype→Theme map for Styler
    local styler_map = {}
    for _, bt in ipairs(M.config.buffer_themes) do
        if bt.filetype then
            styler_map[bt.filetype] = { colorscheme = bt.colorscheme, background = bt.background }
        end
    end
    Styler.setup({ themes = styler_map })

    -- Buftype overrides
    vim.api.nvim_create_augroup("CrayonsBuftype", { clear = true })
    for _, bt in ipairs(M.config.buffer_themes) do
        if bt.buftype then
            vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinNew" }, {
                group = "CrayonsBuftype",
                callback = function(event)
                    local buf = event.buf or vim.api.nvim_get_current_buf()
                    if vim.bo[buf].buftype == bt.buftype then
                        -- Manual override
                        Styler.bufs[buf] = { colorscheme = bt.colorscheme, background = bt.background }
                        debug(string.format("Buftype override: buf=%d, scheme=%s, bg=%s", buf, bt.colorscheme, bt.background))
                        Styler.update({ buf = buf })
                    end
                end,
            })
        end
    end

    -- Keymaps for global variants: <prefix><index><variant>
    for idx, entry in ipairs(M.config.themes) do
        for variant, suffix in pairs(M.variant_suffix) do
            if entry.variants and entry.variants[variant] then
                local key = string.format("%s%d%s", M.config.keybind_prefix, idx, suffix)
                vim.keymap.set("n", key, function()
                    M.set_global(idx, variant)
                end, { desc = string.format("Crayons: theme #%d (%s)", idx, variant) })
            end
        end
    end

    -- Apply global theme and trigger initial overrides
    M.apply_global()
end

-- Apply global theme
function M.apply_global()
    local idx, variant = M.current.index, M.current.variant
    local entry = M.config.themes[idx]
    if not entry or not entry.variants or not entry.variants[variant] then
        vim.notify(string.format("[Crayons] Invalid global theme: %s/%s", tostring(idx), variant), vim.log.levels.ERROR)
        return
    end

    local scheme = entry.variants[variant]
    debug(string.format("Global apply: idx=%d, variant=%s, scheme=%s", idx, variant, scheme))
    vim.cmd("colorscheme " .. scheme)

    -- Reapply per-buffer overrides
    Styler.update()
end

-- Set and persist global theme
function M.set_global(idx, variant)
    M.current.index   = idx
    M.current.variant = variant
    Config.save("theme_config", M.current)
    M.apply_global()
end

return M

