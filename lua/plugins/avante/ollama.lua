-- local Config = require "avante.config"
-- local Clipboard = require "avante.clipboard"
-- local P = require "avante.providers"

---@class AvanteDefaultBaseProvider
---@field endpoint? string
---@field model? string
---@field deployment? string
---@field api_version? string
---@field proxy? string
---@field allow_insecure? boolean
---@field api_key_name? string
---@field timeout? integer
---@field local? boolean
---@field _shellenv? string
---@field tokenizer_id? string
---@field use_xml_format? boolean
---@field role_map? table<string, string>
---@field __inherited_from? string

local Config = {}
Config.BASE_PROVIDER_KEYS = {
  "endpoint",
  "model",
  "deployment",
  "api_version",
  "proxy",
  "allow_insecure",
  "api_key_name",
  "timeout",
  -- internal
  "local",
  "_shellenv",
  "tokenizer_id",
  "use_xml_format",
  "role_map",
  "__inherited_from",
}
Config.behaviour = {
  support_paste_from_clipboard = true,
}

local P = {}
P.parse_config = function(opts)
  ---@type AvanteDefaultBaseProvider
  local s1 = {}
  ---@type table<string, any>
  local s2 = {}

  for key, value in pairs(opts) do
    if vim.tbl_contains(Config.BASE_PROVIDER_KEYS, key) then
      s1[key] = value
    else
      s2[key] = value
    end
  end

  return s1,
    vim.iter(s2):filter(function(_, v) return type(v) ~= "function" end):fold({}, function(acc, k, v)
      acc[k] = v
      return acc
    end)
end

local Utils = {}

Utils.get_os_name = function()
  local os_name = vim.uv.os_uname().sysname
  if os_name == "Linux" then
    return "linux"
  elseif os_name == "Darwin" then
    return "darwin"
  elseif os_name == "Windows_NT" then
    return "windows"
  else
    error("Unsupported operating system: " .. os_name)
  end
end

--- This function will run given shell command synchronously.
---@param input_cmd string
---@return vim.SystemCompleted
Utils.shell_run = function(input_cmd)
  local shell = vim.o.shell:lower()
  ---@type string
  local cmd

  -- powershell then we can just run the cmd
  if shell:match "powershell" or shell:match "pwsh" then
    cmd = input_cmd
  elseif vim.fn.has "wsl" > 0 then
    -- wsl: powershell.exe -Command 'command "/path"'
    cmd = "powershell.exe -NoProfile -Command '" .. input_cmd:gsub("'", '"') .. "'"
  elseif vim.fn.has "win32" > 0 then
    cmd = 'powershell.exe -NoProfile -Command "' .. input_cmd:gsub('"', "'") .. '"'
  else
    -- linux and macos we wil just do sh -c
    cmd = "sh -c " .. vim.fn.shellescape(input_cmd)
  end

  local output = vim.fn.system(cmd)
  local code = vim.v.shell_error

  return { stdout = output, code = code }
end

Utils.debug = function(...)
  -- if
  --   true --not require("avante.config").options.debug
  -- then
  --   return
  -- end
  --
  local args = { ... }
  if #args == 0 then return end
  local timestamp = os.date "%Y-%m-%d %H:%M:%S"
  local formated_args = { "[" .. timestamp .. "] [AVANTE] [DEBUG]" }
  for _, arg in ipairs(args) do
    if type(arg) == "string" then
      table.insert(formated_args, arg)
    else
      table.insert(formated_args, vim.inspect(arg))
    end
  end
  print(unpack(formated_args))
end

function Utils.url_join(...)
  local parts = { ... }
  local result = parts[1] or ""

  for i = 2, #parts do
    local part = parts[i]
    if part and part ~= "" then
      -- Remove trailing slash from result if present
      if result:sub(-1) == "/" then result = result:sub(1, -2) end

      -- Remove leading slash from part if present
      if part:sub(1, 1) == "/" then part = part:sub(2) end

      -- Join with slash
      result = result .. "/" .. part
    end
  end

  return result
end

local Clipboard = {}
Clipboard.get_base64_content = function(filepath)
  local os_mapping = Utils.get_os_name()
  ---@type vim.SystemCompleted
  local output
  if os_mapping == "darwin" or os_mapping == "linux" then
    output = Utils.shell_run(("cat %s | base64 | tr -d '\n'"):format(filepath))
  else
    output =
      Utils.shell_run(("([Convert]::ToBase64String([IO.File]::ReadAllBytes('%s')) -replace '`r`n')"):format(filepath))
  end
  if output.code == 0 then
    return output.stdout
  else
    error "Failed to convert image to base64"
  end
end

---@class OllamaChatResponse
---@field id string
---@field created_at integer
---@field model string
---@field message? OllamaMessage
---@field response? string
---@field done boolean
---@field done_reason? "stop" | "timeout" | "max_turns" | "max_time" | "max_tokens" | "max_characters" | "max_messages" | "max_evaluations" | "load" | "unload"
---@field load_duration? integer
---@field prompt_eval_count? integer
---@field prompt_eval_duration? integer
---@field eval_count? integer
---@field eval_duration? integer
---
---@class OllamaMessage
---@field role? "user" | "system" | "assistant"
---@field content string
---@field images?  string[]

---@class AvantePromptOptions
---@field messages OllamaMessage[]
---@field system_prompt string

---@class AvanteProviderFunctor
local ollama = {}

ollama.api_key_name = ""

ollama.role_map = {
  user = "user",
  assistant = "assistant",
  system = "system",
}

---@param opts AvantePromptOptions
ollama.get_user_message = function(opts)
  vim.deprecate("get_user_message", "parse_messages", "0.1.0", "avante.nvim")
  return table.concat(
    vim
      .iter(opts.messages)
      :filter(function(_, value) return value == nil or value.role ~= "user" end)
      :fold({}, function(acc, value)
        acc = vim.list_extend({}, acc)
        acc = vim.list_extend(acc, { value.content })
        return acc
      end),
    "\n"
  )
end

ollama.parse_messages = function(opts)
  local messages = {}

  table.insert(messages, { role = "system", content = opts.system_prompt })

  vim
    .iter(opts.messages)
    :each(function(msg) table.insert(messages, { role = ollama.role_map[msg.role], content = msg.content }) end)

  if Config.behaviour.support_paste_from_clipboard and opts.image_paths and #opts.image_paths > 0 then
    local message_content = messages[#messages].content
    if type(message_content) ~= "table" then message_content = { type = "text", text = message_content } end
    for _, image_path in ipairs(opts.image_paths) do
      table.insert(message_content, {
        type = "image_url",
        image_url = {
          url = "data:image/png;base64," .. Clipboard.get_base64_content(image_path),
        },
      })
    end
    messages[#messages].content = message_content
  end

  local final_messages = {}
  local prev_role = nil

  vim.iter(messages):each(function(message)
    local role = message.role
    if role == prev_role then
      if role == ollama.role_map["user"] then
        table.insert(final_messages, { role = ollama.role_map["assistant"], content = "Ok, I understand." })
      else
        table.insert(final_messages, { role = ollama.role_map["user"], content = "Ok" })
      end
    end
    prev_role = role
    table.insert(final_messages, { role = ollama.role_map[role] or role, content = message.content })
  end)

  return final_messages
end

ollama.parse_stream_data = function(data_stream, opts)
  if data_stream == nil or data_stream == "" then return end
  ---@type boolean, OllamaChatResponse
  local ok, json = pcall(vim.json.decode, data_stream)
  if ok then
    if json.done then
      return
    elseif json.message and json.message.content then
      opts.on_chunk(json.message.content)
    elseif json.response then
      opts.on_chunk(json.response)
    end
  end
end

ollama.parse_response_without_stream = ollama.parse_stream_data

ollama.parse_curl_args = function(provider, code_opts)
  local base, body_opts = P.parse_config(provider)

  Utils.debug("endpoint", base.endpoint)
  Utils.debug("model", base.model)

  local body = vim.deepcopy(body_opts)
  body.model = provider.model or code_opts.model

  body.messages = ollama.parse_messages(code_opts)

  return {
    url = Utils.url_join(base.endpoint, "/api/chat"),
    proxy = base.proxy,
    insecure = base.allow_insecure,
    headers = { ["Content-Type"] = "application/json" },
    body = body,
  }
end

return ollama
