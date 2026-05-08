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
        --     transparency = false,
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


-- Global theme application, used on startup and when switching themes.
local function set_global_theme(colorscheme, background, transparency)
    vim.o.background = background
    vim.cmd.colorscheme(colorscheme)
    if transparency then
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
local function switch_global_theme(colorscheme, background, transparency)
    set_global_theme(colorscheme, background, transparency)

    Styler.clear(vim.api.nvim_get_current_win())

    M.current_theme = {
        colorscheme  = colorscheme,
        background   = background,
        transparency = transparency,
    }
    Config.save("theme_config", M.current_theme)
end


-- Theme switch that applies only to the current window via a styler namespace.
-- Does not touch the global baseline or other windows.
local function switch_win_theme(colorscheme, background)
    local win = vim.api.nvim_get_current_win()
    Styler.set_theme(win, { colorscheme = colorscheme, background = background })
end


function M.load_config()
    local loaded_config = Config.load("theme_config")
    if loaded_config then
        return {
            colorscheme  = loaded_config.colorscheme,
            background   = loaded_config.background,
            transparency = loaded_config.transparency,
        }
    else
        return {
            colorscheme  = M.crayon_config.themes[1].variants.standard,
            background   = "dark",
            transparency = false,
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
    set_global_theme(config.colorscheme, config.background, config.transparency)
    M.current_theme = config

    -- Register keybinds for standard themes
    for index, theme_info in ipairs(M.crayon_config.themes) do
        local key_index = (index == 10) and 0 or index
        if key_index < 11 then                          -- NOTE: Themes 11+ will not be set!
            local themes = theme_info.variants
            local kb = M.crayon_config.keybindings
            -- Per-window switch
            vim.keymap.set("n", kb.standard .. key_index, function() switch_win_theme(themes.standard, "dark")  end)
            vim.keymap.set("n", kb.dark     .. key_index, function() switch_win_theme(themes.dark,     "dark")  end)
            vim.keymap.set("n", kb.darkest  .. key_index, function() switch_win_theme(themes.darkest,  "dark")  end)
            vim.keymap.set("n", kb.light    .. key_index, function() switch_win_theme(themes.light,    "light") end)
            -- Global switch
            vim.keymap.set("n", kb.global_standard .. key_index, function() switch_global_theme(themes.standard, "dark",  false) end)
            vim.keymap.set("n", kb.global_dark     .. key_index, function() switch_global_theme(themes.dark,     "dark",  false) end)
            vim.keymap.set("n", kb.global_darkest  .. key_index, function() switch_global_theme(themes.darkest,  "dark",  true)  end)
            vim.keymap.set("n", kb.global_light    .. key_index, function() switch_global_theme(themes.light,    "light", false) end)
        end
    end

    -- Register keybinds for special themes
    for _, special in ipairs(M.crayon_config.special_themes) do
        vim.keymap.set("n", special.keybinding, function() switch_global_theme(special.colorscheme, special.background, special.transparency) end)
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
    local ft_group = vim.api.nvim_create_augroup("crayons-filetypes", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = ft_group,
        desc  = "Apply filetype theme to all windows showing this buffer",
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

    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = ft_group,
        desc  = "Apply filetype theme when a buffer enters a window",   -- NOTE: Catches cases where FileType won't re-fire, e.g. when an already-open buffer enters a window
        callback = function(args)
            local win = vim.api.nvim_get_current_win()
            local theme = ft_themes_map[vim.bo[args.buf].filetype]
            if theme then
                Styler.set_theme(win, theme)
            else
                Styler.clear(win)
            end
        end
    })

    local pattern_group = vim.api.nvim_create_augroup("crayons-patterns", { clear = true })
    for _, ft_theme in ipairs(M.crayon_config.filetype_themes) do
        if ft_theme.pattern then
            vim.api.nvim_create_autocmd("BufWinEnter", {
                desc = "Apply pattern theme to the current window when a matching buffer enters",
                group   = pattern_group,
                pattern = ft_theme.pattern,
                callback = function()
                    Styler.set_theme(vim.api.nvim_get_current_win(), {
                        colorscheme = ft_theme.colorscheme,
                        background  = ft_theme.background,
                    })
                end
            })
        end
    end
end


return M

