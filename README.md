# crayons.nvim
Crayons provides a straightforward way to quickly switch between your favorite themes.

## Features
- **Theme Management**: Easily switch between multiple themes with predefined variants.
- **Custom Keybindings**: Assign custom keybindings for different themes and variants.
- **Transparency Support**: Option to enable or disable transparency for themes.
- **Filetype Themes**: Set specific themes for designated filetypes or file patterns, rendered per-window simultaneously.
- **Extensible**: Add more themes and configurations as needed.
- **Persistent**: Settings are saved between sessions.

## Switching Themes
You can switch between themes and their variants through pre-configured keybindings:

### Per-window
-   **Standard Theme**: `<leader>ts#` - Switch to the standard variant of a theme, where `#` is the theme number.
-   **Dark Theme**: `<leader>td#` - Switch to the dark variant of a theme.
-   **Darkest Theme with Transparency**: `<leader>tdd#` - Switch to the darkest variant of a theme with transparency enabled.
-   **Light Theme**: `<leader>tl#` - Switch to the light variant of a theme.

### Global
-   **Standard Theme**: `<leader>tgs#` - Switch the global baseline to the standard variant, where `#` is the theme number.
-   **Dark Theme**: `<leader>tgd#` - Switch the global baseline to the dark variant.
-   **Darkest Theme with Transparency**: `<leader>tgdd#` - Switch the global baseline to the darkest variant with transparency enabled.
-   **Light Theme**: `<leader>tgl#` - Switch the global baseline to the light variant.

## Requirements
- Neovim 0.5+
- [cabinet.nvim](https://github.com/liamrlawrence/cabinet.nvim) for configuration management.
- [styler.nvim](https://github.com/folke/styler.nvim) for per-window themes.
- The themes that you will be using.

## Installation
Use your preferred package manager to install crayons:

[lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
return {
    "liamrlawrence/crayons.nvim",
    dependencies = {
        "liamrlawrence/cabinet.nvim",
        "folke/styler.nvim",
        -- Themes go here
    },

    config = function()
        require("crayons").setup()
    end
}
```


## Configuration
The `crayons.nvim` setup function allows you to customize and extend the plugin according to your needs. Below are the configuration options available:

### Adding New Themes
You can add new themes or modify existing ones by including them in the `themes` table during setup. Each theme has several variants (standard, light, dark, darkest).

Themes are set in order 1 through (1)0 across the keyboard (11+ will be ignored).

```lua
require("crayons").setup({
    themes = {
        {   -- 1
            name = "kanagawa",
            variants = {
                standard = "kanagawa-wave",
                dark     = "kanagawa-dragon",
                darkest  = "kanagawa-wave",
                light    = "kanagawa-lotus",
            }
        },
        {   -- 2
            name = "tokyonight",
            variants = {
                standard = "tokyonight-moon",
                dark     = "tokyonight-night",
                darkest  = "tokyonight-night",
                light    = "tokyonight-day",
            }
        },
        {}, -- 3         Use blanks to skip numbers
        {}, -- 4
        {}, -- 5
        {}, -- 6
        {}, -- 7
        {}, -- 8
        {}, -- 9
        {   -- 10
            name = "gruvbox",
                variants = {
                    standard = "gruvbox-soft",
                    dark     = "gruvbox-medium",
                    darkest  = "gruvbox-hard",
                    light    = "gruvbox-light",
                 }
        },
    }
})
```

### Adding Special Themes
Special themes are ones that have a single variant and you want to assign unique settings, such as transparency and a specific keybinding.
```lua
require("crayons").setup({
    special_themes = {
        {
            colorscheme = "vscode",      -- colorscheme name
            background = "dark",         -- "dark" or "light"
            transparency = true,         -- true or false
            keybinding = "<leader>ttv",  -- custom binding
        },
        -- ...
    }
})
```

### Adding Filetype Themes
Filetype themes assign a specific colorscheme based on either a filetype name or a filename glob pattern. Each window renders its theme independently, so splits with different filetypes will display different colorschemes simultaneously.

Use `filetype` to match by Neovim filetype name, or `pattern` to match by filename glob. Both fields accept either a single string or a list of strings. Do not specify both on the same entry — if a buffer matches both, the pattern takes priority and the filetype entry is ignored.

> **Note:** Transparency is not supported for filetype or pattern themes.

```lua
require("crayons").setup({
    filetype_themes = {
        -- Git
        {
            filetype = "fugitive",                -- single filetype
            colorscheme = "carbonfox",            -- colorscheme name
            background = "dark",                  -- "dark" or "light"
        },

        -- Markdown
        {
            pattern = "*.md",                     -- single glob pattern
            colorscheme = "tokyonight-moon",      -- colorscheme name
            background = "dark",                  -- "dark" or "light"
        },

        -- C/C++
        {
            filetype = { "c", "cpp" },            -- list of filetypes
            colorscheme = "kanagawa-wave",        -- colorscheme name
            background = "dark"                   -- "dark" or "light"
        },
        {
            pattern = { "*.h", "*.hh", "*.hpp" }, -- list of glob patterns
            colorscheme = "kanagawa-dragon",      -- colorscheme name
            background = "dark",                  -- "dark" or "light"
        },
        -- ...
    }
})
```

### Configuring / setting up themes
You can configure theme-specific settings above crayon's `setup()` function.

```lua
return {
    "liamrlawrence/crayons.nvim", dependencies = {
        "liamrlawrence/cabinet.nvim",
        "folke/styler.nvim",
        --
        "rebelot/kanagawa.nvim",
        "folke/tokyonight.nvim",
    },

    config = function()
        -- Theme setup
        require("kanagawa").setup({
            overrides = function(colors)
                local theme = colors.theme
                return {
                    EndOfBuffer = { fg = theme.ui.nontext },
                }
            end,
        })

        require("tokyonight").setup({
            on_highlights = function(highlights, colors)
                highlights.EndOfBuffer = { fg = colors.dark3 }
            end,
        })


        -- Plugin setup
        require("crayons").setup({
            themes = {
                -- ...
```

### Customizing Keybindings
You can change the default keybinds used for switching themes.
```lua
require("crayons").setup({
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
    }
})
```

## License
crayons.nvim is released under the MIT License.

