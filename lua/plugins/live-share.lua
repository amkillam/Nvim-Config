local function get_username()
  local try_get_username_cmds = {
    "echo $LIVESHARE_USERNAME",
    "git config user.name",
    "git config user.email",
    "whoami",
    "echo $USER",
  }
  for _, cmd in ipairs(try_get_username_cmds) do
    local handle = io.popen(cmd)
    if handle ~= nil then
      local result = handle:read "*a"
      handle:close()

      if result ~= "" and result ~= nil then return result end
    end
  end

  return "unknown"
end

return {
  "azratul/live-share.nvim",
  dependencies = {
    "jbyuki/instant.nvim",
  },
  config = function()
    vim.g.instant_username = get_username()
    require("live-share").setup {
      port_internal = 8765,
      max_attempts = 40, -- 10 seconds
      service = "localhost.run",
    }
  end,
}
