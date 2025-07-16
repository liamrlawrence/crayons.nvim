local augroup = vim.api.nvim_create_augroup("crayons-group", {})
local Config = require("cabinet").config_manager

local M = {}

-- Global configuration.
M.crayon_config = {
    themes = {
        {   -- Global themes (for keybindings and special themes)
            name = "built-in",
            variants = {
                standard = "default",
                light    = "default",
                dark     = "default",
                darkest  = "default",
            }
        },
        -- Add more global themes as needed.
    },

    keybindings = {
        standard = "<leader>ts",
        light    = "<leader>tl",
        dark     = "<leader>td",
        darkest  = "<leader>tD",
    },

    special_themes = {
        -- Example:
        -- {
        --   colorscheme = "vscode",
        --   background = "dark",
        --   transparency = false,
        --   keybinding = "<leader>ttv",
        -- },
    },

    -- Legacy filetype_themes (applied per-buffer, not globally)
    filetype_themes = {
            -- Example:
            -- {
            --   colorscheme = "gruvbox",
            --   background = "light",
            --   transparency = false,
            --   pattern = "*.md",
            -- },
    },

    -- New: buffer_themes allow per-buffer theming based on filetype and/or buftype.
    buffer_themes = {
        -- Example:
        -- {
            --   filetype = "fugitive*",
            --   buftype = "terminal",  -- one or both may be specified
            --   colorscheme = "carbonfox",
            --   background = "dark",
            --   transparency = false,
            -- },
        },
    }

    -- Table to store the matched theme per buffer.
    M.buf_theme_store = {}

    -- Global theme setter (for keybindings and special themes)
    local function set_theme(theme_colorscheme, theme_background, theme_transparency, save_theme)
        vim.o.background = theme_background
        vim.cmd.colorscheme(theme_colorscheme)
        if theme_transparency then
            vim.api.nvim_set_hl(0, "LineNr",      { bg = "none" })
            vim.api.nvim_set_hl(0, "SignColumn",  { bg = "none" })
            vim.api.nvim_set_hl(0, "Normal",      { bg = "none" })
            vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
        end

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
                transparency = theme_transparency,
            }
            Config.save("theme_config", M.current_theme)
        end
    end


    function M.load_config()
        local loaded_config = Config.load("theme_config")
        if loaded_config then
            return {
                colorscheme = loaded_config.colorscheme,
                background = loaded_config.background,
                transparency = loaded_config.transparency,
            }
        else
            return {
                colorscheme = M.crayon_config.themes[1].variants.standard,
                background = "dark",
                transparency = false,
            }
        end
    end


    -- Integrated per-buffer theming logic.
    -- 'local_mode' tells the loader not to schedule a restoration of the global theme,
    -- keeping the local theme isolated.
    local function load_theme(theme, local_mode)
        local ns_name = table.concat({ "crayons", theme.colorscheme, theme.background or "" }, "_")
        local namespaces = vim.api.nvim_get_namespaces()
        if namespaces[ns_name] then
            return namespaces[ns_name]
        end

        local ns = vim.api.nvim_create_namespace(ns_name)
        local orig_colorscheme = vim.g.colors_name or ""
        local orig_background = vim.go.background
        local orig_set_hl = vim.api.nvim_set_hl
        local has_hl = false

        vim.api.nvim_set_hl = function(_, group, hl)
            has_hl = true
            orig_set_hl(ns, group, hl)
        end

        local orig_eventignore = vim.go.eventignore
        vim.go.eventignore = "all"
        local saved_colors_name = vim.g.colors_name
        vim.g.colors_name = nil

        if theme.background and vim.go.background ~= theme.background then
            vim.go.background = theme.background
        end

        vim.cmd("colorscheme " .. theme.colorscheme)

        vim.g.colors_name = saved_colors_name
        vim.api.nvim_set_hl = orig_set_hl
        vim.go.background = orig_background
        vim.go.eventignore = orig_eventignore

        if not has_hl then
            vim.notify(
                "Colorscheme " .. theme.colorscheme .. " is not supported. It must use vim.api.nvim_set_hl.",
                vim.log.levels.ERROR,
                { title = "crayons.nvim" }
            )
        end

        if not local_mode then
            vim.schedule(function()
                if orig_colorscheme ~= "" then
                    vim.cmd("colorscheme " .. orig_colorscheme)
                end
            end)
        end

        return ns
    end


    -- Set a per-buffer theme using the integrated technique.
    -- This applies the theme to the current window.
    function M.set_buffer_theme(theme)
        local win = vim.api.nvim_get_current_win()
        if vim.w[win].theme and vim.w[win].theme.colorscheme == theme.colorscheme then
            return
        end
        vim.w[win].theme = theme
        -- Call load_theme in local_mode to prevent global restoration.
        local ns = load_theme(theme, true)
        vim.api.nvim_win_set_hl_ns(win, ns)
    end


    -- Clear the per-buffer theme by resetting the window's namespace.
    function M.clear_buffer_theme()
        local win = vim.api.nvim_get_current_win()
        if vim.w[win].theme then
            vim.api.nvim_win_set_hl_ns(win, 0)
            vim.w[win].theme = nil
        end
    end

    -- Apply the appropriate local theme to a given buffer.
    -- Checks buffer_themes first, then filetype_themes.
    local function apply_local_theme(buf)
        local ft = vim.bo[buf].filetype or ""
        local bt = vim.bo[buf].buftype or ""
        local applied = false

        if M.crayon_config.buffer_themes then
            for _, theme in ipairs(M.crayon_config.buffer_themes) do
                local match = false
                if theme.filetype then
                    local lua_pattern = theme.filetype:gsub("%*", ".*")
                    if ft:match(lua_pattern) then match = true end
                end
                if theme.buftype then
                    local lua_pattern = theme.buftype:gsub("%*", ".*")
                    if bt:match(lua_pattern) then match = true end
                end
                if match then
                    M.buf_theme_store[buf] = {
                        colorscheme = theme.colorscheme,
                        background = theme.background,
                        transparency = theme.transparency,
                    }
                    M.set_buffer_theme(M.buf_theme_store[buf])
                    applied = true
                    break
                end
            end
        end

        if not applied and M.crayon_config.filetype_themes then
            for _, ft_theme in ipairs(M.crayon_config.filetype_themes) do
                local lua_pattern = ft_theme.pattern:gsub("%*", ".*")
                if ft:match(lua_pattern) then
                    M.buf_theme_store[buf] = {
                        colorscheme = ft_theme.colorscheme,
                        background = ft_theme.background,
                        transparency = ft_theme.transparency,
                    }
                    M.set_buffer_theme(M.buf_theme_store[buf])
                    applied = true
                    break
                end
            end
        end

        if not applied then
            M.buf_theme_store[buf] = nil
            M.clear_buffer_theme()
        end
    end


    function M.setup(user_config)
        -- Setup Cabinet for storing theme settings.
        Config.setup({ config_path = "crayons" })

        if user_config then
            M.crayon_config = vim.tbl_deep_extend("force", M.crayon_config, user_config)
        end

        -- Load and set the global (fallback) theme.
        local config = M.load_config()
        set_theme(config.colorscheme, config.background, config.transparency, true)

        -- Register keybindings for global themes.
        for index, theme_info in ipairs(M.crayon_config.themes) do
            local key_index = (index == 10) and 0 or index
            if key_index < 11 then -- supports themes 1-10
                local themes = theme_info.variants
                vim.keymap.set("n", M.crayon_config.keybindings.standard .. key_index, function()
                    set_theme(themes.standard, "dark", false, true)
                end)
                vim.keymap.set("n", M.crayon_config.keybindings.light .. key_index, function()
                    set_theme(themes.light, "light", false, true)
                end)
                vim.keymap.set("n", M.crayon_config.keybindings.dark .. key_index, function()
                    set_theme(themes.dark, "dark", false, true)
                end)
                vim.keymap.set("n", M.crayon_config.keybindings.darkest .. key_index, function()
                    set_theme(themes.darkest, "dark", true, true)
                end)
            end
        end

        -- Register keybindings for special themes.
        for _, special in ipairs(M.crayon_config.special_themes) do
            vim.keymap.set("n", special.keybinding, function()
                set_theme(special.colorscheme, special.background, special.transparency, true)
            end)
        end

        -- New autocommand: apply local themes when a buffer is displayed in any window.
        -- Added "TermOpen" so that terminal buffers get themed immediately.
        vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinNew", "TermOpen" }, {
            desc = "Apply local theme based on buffer settings",
            group = augroup,
            pattern = "*",
            callback = function(args)
                apply_local_theme(args.buf)
            end,
        })
    end


return M

