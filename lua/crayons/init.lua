local augroup = vim.api.nvim_create_augroup("crayons-group", {})
local Config = require("cabinet").config_manager

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
        darkest  = "<leader>tD",
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
        -- Example: {
        --     colorscheme = "gruvbox",
        --     background = "light",
        --     transparency = false,
        --     pattern = "*.md",
        -- },
    },
}


local function set_theme(theme_colorscheme, theme_background, theme_transparency, save_theme)
    vim.o.background = theme_background
    vim.cmd.colorscheme(theme_colorscheme)
    if theme_transparency then
        vim.api.nvim_set_hl(0, "LineNr",        { bg = "none" })
        vim.api.nvim_set_hl(0, "SignColumn",    { bg = "none" })
        vim.api.nvim_set_hl(0, "Normal",        { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat",   { bg = "none" })
        vim.api.nvim_set_hl(0, "Normal",        { bg = "none" })
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
            colorscheme = theme_colorscheme,
            background = theme_background,
            transparency = theme_transparency
        }
        Config.save("theme_config", M.current_theme)
    end
end


function M.load_config()
    local theme_colorscheme, theme_background, theme_transparency
    local loaded_config = Config.load("theme_config")
    if loaded_config then
        theme_colorscheme = loaded_config.colorscheme
        theme_background = loaded_config.background
        theme_transparency = loaded_config.transparency
    else
        -- Fallback if config file doesn't exist
        theme_colorscheme = M.crayon_config.themes[1]["variants"]["standard"]
        theme_background = "dark"
        theme_transparency = false
    end

    local config = {
        colorscheme = theme_colorscheme,
        background = theme_background,
        transparency = theme_transparency,
    }

    return config
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

    -- Load saved configuration
    local config = M.load_config()
    set_theme(config.colorscheme, config.background, config.transparency, true)

    -- Register keybinds for standard themes
    for index, theme_info in ipairs(M.crayon_config.themes) do
        --local name = theme_info.name
        local themes = theme_info.variants
        vim.keymap.set("n", M.crayon_config.keybindings.standard .. index, function() set_theme(themes.standard, "dark", false, true) end)
        vim.keymap.set("n", M.crayon_config.keybindings.light .. index, function() set_theme(themes.light, "light", false, true) end)
        vim.keymap.set("n", M.crayon_config.keybindings.dark .. index, function() set_theme(themes.dark, "dark", false, true) end)
        vim.keymap.set("n", M.crayon_config.keybindings.darkest .. index, function() set_theme(themes.darkest, "dark", true, true) end)
    end

    -- Register keybinds for special themes
    for _, special in ipairs(M.crayon_config.special_themes) do
        vim.keymap.set("n", special.keybinding, function() set_theme(special.colorscheme, special.background, special.transparency, true) end)
    end

    -- Setup autocommands for filetype themes
    for _, ft_theme in ipairs(M.crayon_config.filetype_themes) do
        vim.api.nvim_create_autocmd({"BufEnter", "BufLeave"}, {
            desc = "Set a specific theme for designated filetypes",
            group = augroup,
            pattern = ft_theme.pattern,
            callback = function(args)
                vim.schedule(function()
                    if args.event == "BufEnter" then
                        set_theme(ft_theme.colorscheme, ft_theme.background, ft_theme.transparency, false)
                    else
                        set_theme(M.current_theme.colorscheme, M.current_theme.background, M.current_theme.transparency, false)
                    end
                end)
            end
        })
    end
end



return M

