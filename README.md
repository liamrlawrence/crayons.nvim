# crayons.nvim
Crayons provides a straightforward way to quickly switch between your favorite themes.

## Features
- **Theme Management**: Easily switch between multiple themes with predefined variants.
- **Custom Keybindings**: Assign custom keybindings for different themes and variants.
- **Transparency Support**: Option to enable or disable transparency for themes.
- **Filetype Themes**: Set specific themes for designated filetypes.
- **Extensible**: Add more themes and configurations as needed.
- **Persistent**: Settings are saved between sessions.

## Switching Themes
You can switch between themes and their variants through pre-configured keybindings:

-   **Standard Theme**: `<leader>ts#` - Switch to the standard variant of a theme, where `#` is the theme number.
-   **Light Theme**: `<leader>tl#` - Switch to the light variant of a theme.
-   **Dark Theme**: `<leader>td#` - Switch to the dark variant of a theme.
-   **Darkest Theme with Transparency**: `<leader>tdd#` - Switch to the darkest variant of a theme with transparency enabled.

## Requirements
- Neovim 0.5+
- [cabinet.nvim](https://github.com/liamrlawrence/cabinet.nvim) for configuration management.
- The themes that you will be using.

## Installation
Use your preferred package manager to install crayons:

[lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
return {
    "liamrlawrence/crayons.nvim",
    dependencies = {
        "liamrlawrence/cabinet.nvim",
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

Themes are set in order 1 through (1)0 across the keyboard, 11+ will be ignored.

```lua
require("crayons").setup({
    themes = {
        {   -- Theme #1
            name = "gruvbox",
            variants = {
                standard = "gruvbox-medium",
                light    = "gruvbox-light",
                dark     = "gruvbox-dark",
                darkest  = "gruvbox-dark",
            }
        },
        {}, -- Theme #2
        {}, -- Theme #3         Use blanks to skip numbers
        {   -- Theme #4
            name = "tokyonight",
            variants = {
                standard = "tokyonight-storm",
                light    = "tokyonight-day",
                dark     = "tokyonight-night",
                darkest  = "tokyonight-night",
            }
        },
        -- ...
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
Filetype themes allow you to assign a specific colorscheme based on file extension. This is particularly useful if you want to have a consistent theme for something like Markdown files.
```lua
event = "VeryLazy",     -- ft is required when lazy loading with filetype_themes,
ft = { "md" },          -- otherwise the theme might not get set

config = function()
    require("crayons").setup({
        filetype_themes = {
            {
                colorscheme = "gruvbox-light",  -- colorscheme name
                background = "light",           -- "dark" or "light"
                transparency = false,           -- true or false
                pattern = "*.md",               -- autocmd pattern
            },
            -- ...
        }
    })
end
```

### Customizing Keybindings
You can change the default keybinds used for switching themes.
```lua
require("crayons").setup({
    keybindings = {
        standard = "<leader>ts",
        light    = "<leader>tl",
        dark     = "<leader>td",
        darkest  = "<leader>tdd"
    }
})
```

## License
crayons.nvim is released under the MIT License.

