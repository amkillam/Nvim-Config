return {
  "jay-babu/mason-nvim-dap.nvim",
  -- overrides `require("mason-nvim-dap").setup(...)`
  opts = function(_, opts)
    -- add more things to the ensure_installed table protecting against community packs modifying it
    opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
      "codelldb",
      "cpptools",
    })
  end,
}
