local function get_username()
  try_get_username_cmd = {
    "git config user.name",
    "git config user.email",
    "whoami",
    "echo $USER",
  }
  for _, cmd in ipairs(try_get_username_cmd) do
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    if result ~= "" then
      return result
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
    vim.g.instant_username =  get_username()
    require("live-share").setup({
      port_internal = 8765,
      max_attempts = 40, -- 10 seconds
      service = "localhost.run"
    })
  end
}
