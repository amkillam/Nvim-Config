local utils = require "utils"

local concurrency = utils.num_cpus()
if utils.OS() == "Darwin" then concurrency = math.ceil(concurrency / 2) end

require("lazy").setup({
  { "williamboman/mason.nvim" },
  { "kevinhwang91/promise-async" },
  { "kevinhwang91/nvim-ufo" },
  {
    "AstroNvim/AstroNvim",
    import = "astronvim.plugins",
    opts = { -- AstroNvim options must be set here with the `import` key
      mapleader = " ", -- This ensures the leader key must be configured before Lazy is set up
      maplocalleader = ",", -- This ensures the localleader key must be configured before Lazy is set up
      icons_enabled = true, -- Set to false to disable icons (if no Nerd Font is available)
      pin_plugins = false, -- Default will pin plugins when tracking `version` of AstroNvim, set to true/false to override
      update_notifications = true, -- Enable/disable notification about running `:Lazy update` twice to update pinned plugins
    },
  },
  { import = "community" },
  { import = "plugins" },
} --[[@as LazySpec]], {
  -- Configure any other `lazy.nvim` configuration options here
  install = { 
    colorscheme = {
        "folke/tokyonight.nvim",
        lazy = false,
        opts = { style = "storm" },
    }
  },
  ui = { backdrop = 100 },
  performance = {
    rtp = {
      -- disable some rtp plugins, add more to your liking
      disabled_plugins = {
        "netrwPlugin",
        "tohtml",
      },
    },
  },
  concurrency = concurrency,
} --[[@as LazyConfig]])
