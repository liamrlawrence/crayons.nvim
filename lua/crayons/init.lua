local Config = require("cabinet").config_manager
local Styler = require("styler")

local M = {}



M.crayon_config = {
    themes = {
        {   -- 1
            name = "built-in",
            variants = {
                standard = "default",
                dark     = "default",
                darkest  = "default",
                light    = "default",
            }
        },
        -- Add more themes as needed
    },

    keybindings = {
        -- window
        standard        = "<leader>ts",
        dark            = "<leader>td",
        darkest         = "<leader>tdd",
        light           = "<leader>tl",
        -- global
        global_standard = "<leader>tgs",
        global_dark     = "<leader>tgd",
        global_darkest  = "<leader>tgdd",
        global_light    = "<leader>tgl",
    },

    special_themes = {
        -- Example: {
        --     colorscheme = "vscode",
        --     background = "dark",
        --     transparent = false,
        --     keybinding = "<leader>ttv",
        -- },
    },

    filetype_themes = {
        -- Filetype example (matched by filetype name):
        -- {
        --     filetype = "fugitive",
        --     colorscheme = "carbonfox",
        --     background = "dark"
        -- },
        --
        -- Pattern example (matched by filename glob):
        -- {
        --     pattern = "*.h",
        --     colorscheme = "carbonfox",
        --     background = "dark"
        -- },
        --
        -- List example (works for either filetype or pattern):
        -- {
        --     pattern = { "*.h", "*.hh", "*.hpp", "*.hxx" },
        --     colorscheme = "carbonfox",
        --     background = "dark"
        -- },
        --
        -- NOTE: Do not specify both on the same entry - if a window matches
        -- both, the pattern always wins and the filetype entry is ignored.
    },
}


-- Normalize a variant value into { colorscheme, transparent }.
-- Accepts either a plain string or a table of the form { "name", transparent = true }.
local function resolve_variant(v)
    if type(v) == "string" then
        return { colorscheme = v, transparent = false }
    elseif type(v) == "table" then
        return { colorscheme = v[1], transparent = v.transparent == true }
    end
    return { colorscheme = nil, transparent = false }
end


-- Global theme application, used on startup and when switching themes.
local function set_global_theme(colorscheme, background, transparent)
    vim.o.background = background
    local ok = pcall(vim.cmd.colorscheme, colorscheme)
    if not ok then
        vim.notify(
            string.format("Colorscheme '%s' not found, falling back to default", colorscheme),
            vim.log.levels.WARN,
            { title = "crayons.nvim" }
        )
        vim.cmd.colorscheme("default")
    end
    if transparent then
        vim.api.nvim_set_hl(0, "LineNr",      { bg = "none" })
        vim.api.nvim_set_hl(0, "SignColumn",  { bg = "none" })
        vim.api.nvim_set_hl(0, "Normal",      { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    end
end


-- Theme switch that updates the global baseline AND clears the current
-- window's styler namespace so it shows the new theme. Other windows are
-- unaffected: filetype windows keep their namespaces, unthemed windows
-- pick up the new global via namespace 0.
local function switch_global_theme(colorscheme, background, transparent)
    if not colorscheme then
        vim.notify("No colorscheme assigned to this key", vim.log.levels.WARN, { title = "crayons.nvim" })
        return
    end
    set_global_theme(colorscheme, background, transparent)

    Styler.clear(vim.api.nvim_get_current_win())

    M.current_theme = {
        colorscheme = colorscheme,
        background  = background,
        transparent = transparent,
    }
    Config.save("theme_config", M.current_theme)
end


-- Theme switch that applies only to the current window via a styler namespace.
-- Does not touch the global baseline or other windows.
-- NOTE: transparency is not supported for per-window themes
local function switch_win_theme(colorscheme, background, transparent)
    if not colorscheme then
        vim.notify("No colorscheme assigned to this key", vim.log.levels.WARN, { title = "crayons.nvim" })
        return
    end
    if transparent then
        vim.notify("Per-window transparency is not supported; use the global keybind instead", vim.log.levels.WARN, { title = "crayons.nvim" })
    end
    local win = vim.api.nvim_get_current_win()
    Styler.set_theme(win, { colorscheme = colorscheme, background = background })
end


function M.load_config()
    local loaded_config = Config.load("theme_config")
    if loaded_config then
        return {
            colorscheme = loaded_config.colorscheme,
            background  = loaded_config.background,
            transparent = loaded_config.transparent,
        }
    else
        return {
            colorscheme = M.crayon_config.themes[1].variants.standard,
            background  = "dark",
            transparent = false,
        }
    end
end


function M.setup(user_config)
    -- Setup Cabinet to store theme settings
    Config.setup({
        config_path = "crayons"
    })

    -- User config replaces default
    if user_config then
        M.crayon_config = vim.tbl_deep_extend("force", M.crayon_config, user_config)
    end

    -- Load and apply saved global theme
    local config = M.load_config()
    set_global_theme(config.colorscheme, config.background, config.transparent)
    M.current_theme = config

    -- Register keybinds for standard themes
    for index, theme_info in ipairs(M.crayon_config.themes) do
        local key_index = (index == 10) and 0 or index
        if key_index < 11 then                          -- NOTE: Themes 11+ will not be set!
            local variants = theme_info.variants or {}
            local kb = M.crayon_config.keybindings

            local standard = resolve_variant(variants.standard)
            local dark     = resolve_variant(variants.dark)
            local darkest  = resolve_variant(variants.darkest)
            local light    = resolve_variant(variants.light)

            -- Window
            vim.keymap.set("n", kb.standard .. key_index, function() switch_win_theme(standard.colorscheme, "dark",  standard.transparent) end, { desc = "Win set theme standard " .. index })
            vim.keymap.set("n", kb.dark     .. key_index, function() switch_win_theme(dark.colorscheme,     "dark",  dark.transparent)     end, { desc = "Win set theme dark " .. index })
            vim.keymap.set("n", kb.darkest  .. key_index, function() switch_win_theme(darkest.colorscheme,  "dark",  darkest.transparent)  end, { desc = "Win set theme darkest " .. index })
            vim.keymap.set("n", kb.light    .. key_index, function() switch_win_theme(light.colorscheme,    "light", light.transparent)    end, { desc = "Win set theme light " .. index })
            -- Global
            vim.keymap.set("n", kb.global_standard .. key_index, function() switch_global_theme(standard.colorscheme, "dark",  standard.transparent) end, { desc = "Global set theme standard " .. index })
            vim.keymap.set("n", kb.global_dark     .. key_index, function() switch_global_theme(dark.colorscheme,     "dark",  dark.transparent)     end, { desc = "Global set theme dark " .. index })
            vim.keymap.set("n", kb.global_darkest  .. key_index, function() switch_global_theme(darkest.colorscheme,  "dark",  darkest.transparent)  end, { desc = "Global set theme darkest " .. index })
            vim.keymap.set("n", kb.global_light    .. key_index, function() switch_global_theme(light.colorscheme,    "light", light.transparent)    end, { desc = "Global set theme light " .. index })
        end
    end

    -- Register keybinds for special themes
    for _, special in ipairs(M.crayon_config.special_themes) do
        vim.keymap.set("n", special.keybinding, function() switch_global_theme(special.colorscheme, special.background, special.transparent == true) end)
    end

    -- Build a filetype -> theme lookup from all filetype entries
    local ft_themes_map = {}
    for _, ft_theme in ipairs(M.crayon_config.filetype_themes) do
        if ft_theme.filetype then
            local filetypes = type(ft_theme.filetype) == "table"
                and ft_theme.filetype
                or  { ft_theme.filetype }
            for _, ft in ipairs(filetypes) do
                ft_themes_map[ft] = {
                    colorscheme = ft_theme.colorscheme,
                    background  = ft_theme.background,
                }
            end
        end
    end


    -- Apply themes
    local theme_group = vim.api.nvim_create_augroup("crayons-theme", { clear = true })

    -- NOTE: Catches case where ':set filetype=T' is manually run
    vim.api.nvim_create_autocmd("FileType", {
        group = theme_group,
        desc = "Apply filetype theme to all windows showing this buffer",
        callback = function(args)
            local theme = ft_themes_map[vim.bo[args.buf].filetype]
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_get_buf(win) == args.buf then
                    if theme then
                        Styler.set_theme(win, theme)
                    else
                        Styler.clear(win)
                    end
                end
            end
        end
    })

    -- NOTE: Catches cases where FileType won't re-fire, e.g. when an already-open buffer enters a window
    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = theme_group,
        desc = "Apply filetype theme to all windows showing this buffer",
        callback = function(args)
            local buf = args.buf
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(buf) then return end
                local theme = ft_themes_map[vim.bo[buf].filetype]
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    if vim.api.nvim_win_get_buf(win) == buf then
                        if theme then
                            vim.w[win].theme = nil
                            Styler.set_theme(win, theme)
                        else
                            Styler.clear(win)
                        end
                    end
                end
            end)
        end
    })

    -- NOTE: Catches case where a FileType / Pattern themed buffer is split
    vim.api.nvim_create_autocmd("WinNew", {
        group = theme_group,
        desc = "Apply filetype or pattern theme to a newly created window",
        callback = function()
            local win = vim.api.nvim_get_current_win()
            local buf = vim.api.nvim_win_get_buf(win)
            vim.schedule(function()
                if not vim.api.nvim_win_is_valid(win) then return end
                if not vim.api.nvim_buf_is_valid(buf) then return end

                -- Check filetype themes first
                local theme = ft_themes_map[vim.bo[buf].filetype]

                -- Check pattern themes (pattern wins over filetype if both match)
                local bufname = vim.api.nvim_buf_get_name(buf)
                for _, ft_theme in ipairs(M.crayon_config.filetype_themes) do
                    if ft_theme.pattern then
                        local patterns = type(ft_theme.pattern) == "table"
                            and ft_theme.pattern
                            or  { ft_theme.pattern }
                        for _, pat in ipairs(patterns) do
                            if vim.fn.match(bufname, vim.fn.glob2regpat(pat)) >= 0 then
                                theme = {
                                    colorscheme = ft_theme.colorscheme,
                                    background  = ft_theme.background,
                                }
                                break
                            end
                        end
                    end
                end

                if theme then
                    vim.w[win].theme = nil
                    Styler.set_theme(win, theme)
                else
                    Styler.clear(win)
                end
            end)
        end
    })

    -- NOTE: Primary handler for applying pattern themes when a matching buffer enters a window
    for _, ft_theme in ipairs(M.crayon_config.filetype_themes) do
        if ft_theme.pattern then
            vim.api.nvim_create_autocmd("BufWinEnter", {
                desc = "Apply pattern theme to all windows showing a matching buffer",
                group = theme_group,
                pattern = ft_theme.pattern,
                callback = function(args)
                    local buf = args.buf
                    vim.schedule(function()
                        if not vim.api.nvim_buf_is_valid(buf) then return end
                        for _, win in ipairs(vim.api.nvim_list_wins()) do
                            if vim.api.nvim_win_get_buf(win) == buf then
                                vim.w[win].theme = nil
                                Styler.set_theme(win, {
                                    colorscheme = ft_theme.colorscheme,
                                    background  = ft_theme.background,
                                })
                            end
                        end
                    end)
                end
            })
        end
    end

end


return M

