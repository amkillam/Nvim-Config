return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack" },
  { import = "astrocommunity.pack.typescript-all-in-one", enabled = false },
  { import = "astrocommunity.pack.typescript-deno", enabled = false },
  { import = "astrocommunity.colorscheme" },
  { import = "astrocommunity.completion.copilot-lua-cmp" },
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim" },
  {
    "m4xshen/smartcolumn.nvim",
    opts = {
      colorcolumn = 120,
      disabled_filetypes = { "help" },
    },
  },
}
