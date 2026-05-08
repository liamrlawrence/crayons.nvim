local Config = require("cabinet").config_manager
local Styler = require("styler")

local M = {}



M.crayon_config = {
    themes = {
        {   -- 1
            name = "built-in",
            variants = {
                standard = "default",
                light    = "default",
                dark     = "default",
                darkest  = "default",
            }
        },
        -- Add more themes as needed
    },

    keybindings = {
        standard = "<leader>ts",
        light    = "<leader>tl",
        dark     = "<leader>td",
        darkest  = "<leader>tdd",
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
        -- { filetype = "fugitive", colorscheme = "carbonfox", background = "dark" },
        --
        -- Pattern example (matched by filename glob):
        -- { pattern = "*.h", colorscheme = "dawnfox", background = "light" },
        --
        -- NOTE: Do not specify both on the same entry - if a buffer matches
        -- both, the pattern always wins and the filetype entry is ignored.
    },
}


local function set_theme(theme_colorscheme, theme_background, theme_transparency, save_theme)
    vim.o.background = theme_background
    vim.cmd.colorscheme(theme_colorscheme)
    if theme_transparency then
        vim.api.nvim_set_hl(0, "LineNr",      { bg = "none" })
        vim.api.nvim_set_hl(0, "SignColumn",  { bg = "none" })
        vim.api.nvim_set_hl(0, "Normal",      { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    end

    -- Highlight current parameter when looking at a Signature
    local marked = vim.api.nvim_get_hl(0, { name = "PMenu" })
    vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
        fg = marked.fg,
        bg = marked.bg,
        ctermfg = marked.ctermfg,
        ctermbg = marked.ctermbg,
        bold = true
    })

    if save_theme then
        M.current_theme = {
            colorscheme  = theme_colorscheme,
            background   = theme_background,
            transparency = theme_transparency
        }
        Config.save("theme_config", M.current_theme)
    end
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
    set_theme(config.colorscheme, config.background, config.transparency, true)

    -- Register keybinds for standard themes
    for index, theme_info in ipairs(M.crayon_config.themes) do
        local key_index = (index == 10) and 0 or index
        if key_index < 11 then                          -- NOTE: Themes 11+ will not be set!
            local themes = theme_info.variants
            vim.keymap.set("n", M.crayon_config.keybindings.standard .. key_index, function() set_theme(themes.standard, "dark",  false, true) end)
            vim.keymap.set("n", M.crayon_config.keybindings.light    .. key_index, function() set_theme(themes.light,    "light", false, true) end)
            vim.keymap.set("n", M.crayon_config.keybindings.dark     .. key_index, function() set_theme(themes.dark,     "dark",  false, true) end)
            vim.keymap.set("n", M.crayon_config.keybindings.darkest  .. key_index, function() set_theme(themes.darkest,  "dark",  true,  true) end)
        end
    end

    -- Register keybinds for special themes
    for _, special in ipairs(M.crayon_config.special_themes) do
        vim.keymap.set("n", special.keybinding, function() set_theme(special.colorscheme, special.background, special.transparency, true) end)
    end

    -- Build styler themes table from filetype entries
    local styler_themes = {}
    for _, ft_theme in ipairs(M.crayon_config.filetype_themes) do
        if ft_theme.filetype then
            styler_themes[ft_theme.filetype] = {
                colorscheme = ft_theme.colorscheme,
                background  = ft_theme.background,
            }
        end
    end
    Styler.setup({ themes = styler_themes })

    -- Register pattern-based themes via buf-level overrides.
    -- Styler.bufs takes priority over Styler.themes, so pattern always
    -- wins when a buffer matches both a pattern and a filetype entry.
    local pattern_group = vim.api.nvim_create_augroup("crayons-patterns", { clear = true })
    for _, ft_theme in ipairs(M.crayon_config.filetype_themes) do
        if ft_theme.pattern then
            vim.api.nvim_create_autocmd({ "BufWinEnter", "BufNew" }, {
                desc    = "Set theme based on filetype",
                group   = pattern_group,
                pattern = ft_theme.pattern,
                callback = function(args)
                    Styler.bufs[args.buf] = {
                        colorscheme = ft_theme.colorscheme,
                        background  = ft_theme.background,
                    }
                    Styler.update({ buf = args.buf })
                end
            })
        end
    end
end



return M

