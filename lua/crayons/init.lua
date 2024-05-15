local Config = require("cabinet").config_manager

local M = {}



M.crayon_config = {
    themes = {
        {   -- 1
            name = "built-in",
            variants = {
                standard = "default",
                light    = "shine",
                dark     = "desert",
                darkest  = "default",
            }
        },
        -- Add more themes as needed
    },

    keybindings = {
        standard = "<leader>ts",
        light    = "<leader>tl",
        dark     = "<leader>td",
        darkest  = "<leader>tD"
    },

    special_themes = {
        -- Example: {
            -- name = "vscode",
            -- mode = "dark",
            -- transparency = false,
            -- keybinding = "<leader>ttv"
        -- },
    }
}


local function set_theme(theme_name, theme_mode, theme_transparency)
    vim.o.background = theme_mode
    vim.cmd.colorscheme(theme_name)
    if theme_transparency then
        vim.api.nvim_set_hl(0, "LineNr",            { bg = "none" })
        vim.api.nvim_set_hl(0, "SignColumn",        { bg = "none" })
        vim.api.nvim_set_hl(0, "Normal",            { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat",       { bg = "none" })
        vim.api.nvim_set_hl(0, "GitGutterAdd",      { bg = "none", fg = "#009900" })
        vim.api.nvim_set_hl(0, "GitGutterChange",   { bg = "none", fg = "#bbbb00" })
        vim.api.nvim_set_hl(0, "GitGutterDelete",   { bg = "none", fg = "#ff2222" })
        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
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

    -- Save settings
    local config_data = {
        theme_name = theme_name,
        theme_mode = theme_mode,
        theme_transparency = theme_transparency
    }
    Config.save("theme_config", config_data)
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

    -- Register keybindings for standard themes
    for index, theme_info in ipairs(M.crayon_config.themes) do
        local name = theme_info.name
        local themes = theme_info.variants
        vim.keymap.set("n", M.crayon_config.keybindings.standard .. index, function() set_theme(themes.standard, "dark", false) end)
        vim.keymap.set("n", M.crayon_config.keybindings.light .. index, function() set_theme(themes.light, "light", false) end)
        vim.keymap.set("n", M.crayon_config.keybindings.dark .. index, function() set_theme(themes.dark, "dark", false) end)
        vim.keymap.set("n", M.crayon_config.keybindings.darkest .. index, function() set_theme(themes.darkest, "dark", true) end)
    end

    -- Register keybindings for special themes
    for _, special in ipairs(M.crayon_config.special_themes) do
        vim.keymap.set("n", special.keybinding, function() set_theme(special.name, special.mode, special.transparency) end)
    end

    -- Load saved configuration
    local theme_name, theme_mode, theme_transparency
    local loaded_config = Config.load("theme_config")
    if loaded_config then
        theme_name = loaded_config.theme_name
        theme_mode = loaded_config.theme_mode
        theme_transparency = loaded_config.theme_transparency
    else
        -- Fallback if config file doesn't exist
        theme_name = M.crayon_config.themes[1]["variants"]["standard"]
        theme_mode = "dark"
        theme_transparency = false
    end
    set_theme(theme_name, theme_mode, theme_transparency)
end



return M

