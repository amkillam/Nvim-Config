local utils = require "utils"
local ollama_provider = require "plugins.avante.ollama"

local os = utils.OS()
local ollama_model = "ishumilin/deepseek-r1-coder-tools:8b"
if os == "Darwin" then ollama_model = "ishumilin/deepseek-r1-coder-tools:70b" end

local build = "make BUILD_FROM_SOURCE=true"
if os == "Windows" then
  build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource true"
elseif os ~= "Darwin" then
  local gcc_version = vim.fn.system "gcc --version"
  if not string.find(gcc_version, "13.") then build = "CC=gcc-13 make BUILD_FROM_SOURCE=true" end
end

---@class AvanteProvider
local ollama_config = {
  model = ollama_model,
  endpoint = "http://127.0.0.1:11434",
  timeout = 60 * 60 * 1000, -- 1 hour timeout in milliseconds
  temperature = 0,
  max_tokens = 32768,
  api_key_name = "",
}
local ollama = vim.tbl_extend("force", ollama_provider, ollama_config)

---@param model string
local function ollama_with_model(model)
  -- copy ollama
  local ollama_provider_with_model = vim.deepcopy(ollama)
  ollama_provider_with_model.model = model
  return ollama_provider_with_model
end

---@param model string
local function model_params(model)
  local model_info = vim.fn.system("ollama show " .. model)
  local context_length = string.match(model_info, "context length%s+(%d+)")
  if not context_length then context_length = string.match(model_info, "num_ctx%s+(%d+)") end
  if not context_length then context_length = 32768 end

  local temperature = string.match(model_info, "temperature%s+(%d+.%d*)%s")
  if not temperature then temperature = 0 end
  return {
    ["context_length"] = context_length,
    ["temperature"] = temperature,
  }
end

local function installed_ollama_vendors()
  local ollama_models_list_raw = utils.remove_first_line(vim.fn.system "ollama list")
  local ollama_models_list = utils.split_lines(ollama_models_list_raw, " ")[1]
  local installed_model_vendors = {
    ["ollama"] = ollama,
  }
  for _, installed_model in pairs(ollama_models_list) do
    local prefixed_installed_model = "ollama/" .. installed_model
    local vendor = ollama_with_model(installed_model)
    vendor.model = installed_model

    local installed_model_params = model_params(installed_model)
    vendor.context_length = installed_model_params.context_length
    vendor.temperature = installed_model_params.temperature
    installed_model_vendors[prefixed_installed_model] = vendor
  end
  return installed_model_vendors
end

return { -- further customize the options set by the community
  "amkillam/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  build = build,
  version = false,
  cmd = {
    "AvanteAsk",
    "AvanteBuild",
    "AvanteEdit",
    "AvanteRefresh",
    "AvanteSwitchProvider",
    "AvanteChat",
    "AvanteToggle",
    "AvanteClear",
  },
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = assert(opts.mappings)
        local prefix = "<Leader>a"

        maps.n[prefix] = { desc = "Avante functionalities" }

        maps.n[prefix .. "a"] = {
          function() require("avante.api").ask() end,
          desc = "Avante ask",
        }
        maps.v[prefix .. "a"] = {
          function() require("avante.api").ask() end,
          desc = "Avante ask",
        }

        maps.n[prefix .. "c"] = {
          function() require("avante.api").ask() end,
          desc = "Avante chat",
        }

        maps.v[prefix .. "c"] = {
          function() require("avante.api").ask() end,
          desc = "Avante chat",
        }

        maps.v[prefix .. "r"] = {
          function() require("avante.api").refresh() end,
          desc = "Avante refresh",
        }

        maps.n[prefix .. "e"] = {
          function() require("avante.api").edit() end,
          desc = "Avante edit",
        }
        maps.v[prefix .. "e"] = {
          function() require("avante.api").edit() end,
          desc = "Avante edit",
        }

        maps.n[prefix .. "m"] = {
          function() require("avante.api").select_model() end,
          desc = "Avante select model",
        }

        maps.v[prefix .. "m"] = {
          function() require("avante.api").select_model() end,
          desc = "Avante select model",
        }

        -- the following key bindings do not have an official api implementation
        maps.n.co = { "<Plug>(AvanteConflictOurs)", desc = "Choose ours", expr = true }
        maps.v.co = { "<Plug>(AvanteConflictOurs)", desc = "Choose ours", expr = true }

        maps.n.ct = { "<Plug>(AvanteConflictTheirs)", desc = "Choose theirs", expr = true }
        maps.v.ct = { "<Plug>(AvanteConflictTheirs)", desc = "Choose theirs", expr = true }

        maps.n.ca = { "<Plug>(AvanteConflictAllTheirs)", desc = "Choose all theirs", expr = true }
        maps.v.ca = { "<Plug>(AvanteConflictAllTheirs)", desc = "Choose all theirs", expr = true }

        maps.n.cb = { "<Plug>(AvanteConflictBoth)", desc = "Choose both", expr = true }
        maps.v.cb = { "<Plug>(AvanteConflictBoth)", desc = "Choose both", expr = true }

        maps.n.cc = { "<Plug>(AvanteConflictCursor)", desc = "Choose cursor", expr = true }
        maps.v.cc = { "<Plug>(AvanteConflictCursor)", desc = "Choose cursor", expr = true }

        maps.n["]x"] = { "<Plug>(AvanteConflictPrevConflict)", desc = "Move to previous conflict", expr = true }

        maps.n["[x"] = { "<Plug>(AvanteConflictNextConflict)", desc = "Move to next conflict", expr = true }
      end,
    },
  },
  opts = {
    debug = false,
    provider = "ollama",
    -- WARNING: Since auto-suggestions are a high-frequency operation and therefore expensive,
    -- currently designating it as `copilot` provider is dangerous because: https://github.com/yetone/avante.nvim/issues/1048
    -- Of course, you can reduce the request frequency by increasing `suggestion.debounce`.
    auto_suggestions_provider = "claude",
    -- Used for counting tokens and encoding text.
    -- By default, we will use tiktoken.
    -- For most providers that we support we will determine this automatically.
    -- If you wish to use a given implementation, then you can override it here.
    tokenizer = "tiktoken",
    -- Default system prompt. Users can override this with their own prompt
    -- You can use `require('avante.config').override({system_prompt = "MY_SYSTEM_PROMPT"}) conditionally
    -- in your own autocmds to do it per directory, or that fit your needs.
    system_prompt = [[
Act as an expert software developer.
Always use best practices when coding.
Respect and use existing conventions, libraries, etc that are already present in the code base.
]],
    ---@type AvanteSupportedProvider
    openai = {
      endpoint = "https://api.openai.com/v1",
      model = "o3-mini",
      timeout = 120000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 200000,
    },
    ---@type AvanteSupportedProvider
    copilot = {
      endpoint = "https://api.githubcopilot.com",
      model = "gpt-4o",
      proxy = nil, -- [protocol://]host[:port] Use this proxy
      allow_insecure = false, -- Allow insecure server connections
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
    },
    ---@type AvanteAzureProvider
    azure = {
      endpoint = "", -- example: "https://<your-resource-name>.openai.azure.com"
      deployment = "", -- Azure deployment name (e.g., "gpt-4o", "my-gpt-4o-deployment")
      api_version = "2024-06-01",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 4096,
    },
    ---@type AvanteSupportedProvider
    claude = {
      endpoint = "https://api.anthropic.com",
      model = "claude-3-5-sonnet-20241022",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 8000,
    },
    ---@type AvanteSupportedProvider
    gemini = {
      endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
      model = "gemini-1.5-flash-latest",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 4096,
    },
    ---@type AvanteSupportedProvider
    cohere = {
      endpoint = "https://api.cohere.com/v1",
      model = "command-r-plus-08-2024",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 4096,
    },

    ---Specify the special dual_boost mode
    ---1. enabled: Whether to enable dual_boost mode. Default to false.
    ---2. first_provider: The first provider to generate response. Default to "openai".
    ---3. second_provider: The second provider to generate response. Default to "claude".
    ---4. prompt: The prompt to generate response based on the two reference outputs.
    ---5. timeout: Timeout in milliseconds. Default to 60000.
    ---How it works:
    --- When dual_boost is enabled, avante will generate two responses from the first_provider and second_provider respectively. Then use the response from the first_provider as provider1_output and the response from the second_provider as provider2_output. Finally, avante will generate a response based on the prompt and the two reference outputs, with the default Provider as normal.
    ---Note: This is an experimental feature and may not work as expected.
    dual_boost = {
      enabled = false,
      first_provider = "openai",
      second_provider = "claude",
      prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
      timeout = 60000, -- Timeout in milliseconds
    },
    ---To add support for custom provider, follow the format below
    ---See https://github.com/yetone/avante.nvim/README.md#custom-providers for more details
    ---@type {[string]: AvanteProvider}
    vendors = installed_ollama_vendors(),
    ---Specify the behaviour of avante.nvim
    ---1. auto_apply_diff_after_generation: Whether to automatically apply diff after LLM response.
    ---                                     This would simulate similar behaviour to cursor. Default to false.
    ---2. auto_set_keymaps                : Whether to automatically set the keymap for the current line. Default to true.
    ---                                     Note that avante will safely set these keymap. See https://github.com/yetone/avante.nvim/wiki#keymaps-and-api-i-guess for more details.
    ---3. auto_set_highlight_group        : Whether to automatically set the highlight group for the current line. Default to true.
    ---4. support_paste_from_clipboard    : Whether to support pasting image from clipboard. This will be determined automatically based whether img-clip is available or not.
    behaviour = {
      auto_suggestions = false, -- Experimental stage
      auto_set_highlight_group = true,
      auto_set_keymaps = false,
      auto_apply_diff_after_generation = true,
      support_paste_from_clipboard = true,
      minimize_diff = true, -- Whether to remove unchanged lines when applying a code block
      enable_token_counting = true, -- Whether to enable token counting. Default to true.
    },
    history = {
      storage_path = vim.fn.stdpath "state" .. "/avante",
      paste = {
        extension = "png",
        filename = "pasted-%Y-%m-%d-%H-%M-%S",
      },
    },
    mappings = {
      ---@class AvanteConflictMappings
      diff = {
        ours = "<leader>ado",
        theirs = "<leader>adt",
        all_theirs = "<leader>ada",
        both = "<leader>adb",
        cursor = "<leader>adc",
        next = "<leader>ad]",
        prev = "<leader>ad[",
      },
      suggestion = {
        accept = "<leader>asa",
        next = "<leader>as]",
        prev = "<leader>as[",
        dismiss = "<leader>asd",
      },
      jump = {
        next = "<leader>a]]",
        prev = "<leader>a[[",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      -- NOTE: The following will be safely set by avante.nvim
      ask = "<leader>aa",
      edit = "<leader>ae",
      chat = "<leader>ac",
      refresh = "<leader>ar",
      toggle = {
        default = "<leader>at",
        debug = "<leader>ad",
        hint = "<leader>ah",
        suggestion = "<leader>as",
      },
      sidebar = {
        apply_all = "<C-ap>",
        apply_cursor = "<C-a>",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
      },
      select_model = "<leader>am",
    },
    windows = {
      ---@type "right" | "left" | "top" | "bottom"
      position = "right", -- the position of the sidebar
      wrap = true, -- similar to vim.o.wrap
      width = 30, -- default % based on available width
      sidebar_header = {
        enabled = true, -- true, false to enable/disable the header
        align = "center", -- left, center, right for title
        rounded = true,
      },
      input = {
        prefix = "> ",
        height = 8, -- Height of the input window in vertical layout
      },
      edit = {
        border = "rounded",
        start_insert = true, -- Start insert mode when opening the edit window
      },
      ask = {
        floating = false, -- Open the 'AvanteAsk' prompt in a floating window
        start_insert = true, -- Start insert mode when opening the ask window
        border = "rounded",
        ---@type "ours" | "theirs"
        focus_on_apply = "ours", -- which diff to focus after applying
      },
    }, --- @class AvanteConflictConfig
    highlights = {
      ---@type AvanteConflictHighlights
      diff = {
        current = "DiffText",
        incoming = "DiffAdd",
      },
    },
    --- @class AvanteConflictUserConfig
    diff = {
      autojump = true,
      ---@type string | fun(): any
      list_opener = "copen",
      --- Override the 'timeoutlen' setting while hovering over a diff (see :help timeoutlen).
      --- Helps to avoid entering operator-pending mode with diff mappings starting with `c`.
      --- Disable by setting to -1.
      override_timeoutlen = 500,
    },
    suggestion = {
      debounce = 600,
      throttle = 600,
    },
  },
  specs = {
    {
      -- make sure `Avante` is added as a filetype
      "MeanderingProgrammer/render-markdown.nvim",
      optional = true,
      opts = function(_, opts)
        if not opts.file_types then opts.filetypes = { "markdown" } end
        opts.file_types = require("astrocore").list_insert_unique(opts.file_types, { "Avante" })
      end,
    },
    {
      -- make sure `Avante` is added as a filetype
      "OXY2DEV/markview.nvim",
      optional = true,
      opts = function(_, opts)
        if not opts.filetypes then opts.filetypes = { "markdown", "quarto", "rmd" } end
        opts.filetypes = require("astrocore").list_insert_unique(opts.filetypes, { "Avante" })
      end,
    },
  },
}
