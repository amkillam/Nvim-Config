local utils = require "../utils"
local OS = utils.OS()
local ollama_model = os.getenv "AVANTE_OLLAMA_MODEL"
if ollama_model == "" then
  if OS == "Darwin" then
    ollama_model = "ollama_qwen2_5_coder_32b_instruct_fp16"
  else
    ollama_model = "ollama_qwen2_5_coder_7b"
  end
end

local build = "make BUILD_FROM_SOURCE=true"
if OS == "Windows" then build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource true" end

return { -- further customize the options set by the community
  "yetone/avante.nvim",
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

        maps.n[prefix .. "a"] = { function() require("avante.api").ask() end, desc = "Avante ask" }
        maps.v[prefix .. "a"] = { function() require("avante.api").ask() end, desc = "Avante ask" }

        maps.v[prefix .. "r"] = { function() require("avante.api").refresh() end, desc = "Avante refresh" }

        maps.n[prefix .. "e"] = { function() require("avante.api").edit() end, desc = "Avante edit" }
        maps.v[prefix .. "e"] = { function() require("avante.api").edit() end, desc = "Avante edit" }

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
    provider = "ollama", -- Only recommend using Claude
    auto_suggestions_provider = "copilot",
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
      model = "gpt-4o",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 4096,
      ["local"] = false,
    },
    ---@type AvanteSupportedProvider
    copilot = {
      endpoint = "https://api.githubcopilot.com",
      model = "gpt-4o",
      proxy = nil, -- [protocol://]host[:port] Use this proxy
      allow_insecure = false, -- Allow insecure server connections
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 4096,
    },
    ---@type AvanteAzureProvider
    azure = {
      endpoint = "", -- example: "https://<your-resource-name>.openai.azure.com"
      deployment = "", -- Azure deployment name (e.g., "gpt-4o", "my-gpt-4o-deployment")
      api_version = "2024-06-01",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 4096,
      ["local"] = false,
    },
    ---@type AvanteSupportedProvider
    claude = {
      endpoint = "https://api.anthropic.com",
      model = "claude-3-5-sonnet-20240620",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 8000,
      ["local"] = false,
    },
    ---@type AvanteSupportedProvider
    gemini = {
      endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
      model = "gemini-1.5-flash-latest",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 4096,
      ["local"] = false,
    },
    ---@type AvanteSupportedProvider
    cohere = {
      endpoint = "https://api.cohere.com/v1",
      model = "command-r-plus-08-2024",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 4096,
      ["local"] = false,
    },
    ---@type AvanteSupportedProvider
    ollama = {
      endpoint = "https://localhost:11434/api/generate",
      model = ollama_model,
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 8000,
      ["local"] = true,
    },
    ---@type AvanteSupportedProvider
    ollama_qwen2_5_coder_7b = {
      endpoint = "https://localhost:11434/api/generate",
      model = "qwen2.5-coder:7b",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 8000,
      ["local"] = true,
    },
    ---@type AvanteSupportedProvider
    ollama_qwen2_5_coder_32b_instruct_q8_0 = {
      endpoint = "https://localhost:11434/api/generate",
      model = "qwen2.5-coder:32b-instruct-q8_0",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 8000,
      ["local"] = true,
    },
    ---@type AvanteSupportedProvider
    ollama_qwen2_5_coder_32b_instruct_fp16 = {
      endpoint = "https://localhost:11434/api/generate",
      model = "qwen2.5-coder:32b-instruct-fp16",
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 8000,
      ["local"] = true,
    },
    ---To add support for custom provider, follow the format below
    ---See https://github.com/yetone/avante.nvim/README.md#custom-providers for more details
    ---@type {[string]: AvanteProvider}
    vendors = {},
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
    },
    history = {
      storage_path = vim.fn.stdpath "state" .. "/avante",
      paste = {
        extension = "png",
        filename = "pasted-%Y-%m-%d-%H-%M-%S",
      },
    },
    highlights = {
      ---@type AvanteConflictHighlights
      diff = {
        current = "DiffText",
        incoming = "DiffAdd",
      },
    },
    mappings = {
      ---@class AvanteConflictMappings
      diff = {
        ours = "<leader>aco",
        theirs = "<leader>act",
        all_theirs = "<leader>aca",
        both = "<leader>acb",
        cursor = "<leader>acc",
        next = "<leader>a]x",
        prev = "<leader>a[x",
      },
      suggestion = {
        accept = "<leader>a<M-l>",
        next = "<leader>a<M-]>",
        prev = "<leader>a<M-[>",
        dismiss = "<leader>a<C-]>",
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
      refresh = "<leader>ar",
      toggle = {
        default = "<leader>at",
        debug = "<leader>ad",
        hint = "<leader>ah",
        suggestion = "<leader>as",
      },
      sidebar = {
        apply_all = "A",
        apply_cursor = "a",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
      },
    },
    windows = {
      position = "right",
      wrap = true, -- similar to vim.o.wrap
      width = 30, -- default % based on available width in vertical layout
      height = 30, -- default % based on available height in horizontal layout
      sidebar_header = {
        align = "center", -- left, center, right for title
        rounded = true,
      },
      input = {
        prefix = "> ",
      },
      edit = {
        border = "rounded",
      },
    },
    --- @class AvanteConflictConfig
    diff = {
      autojump = true,
    },
    --- @class AvanteHintsConfig
    hints = {
      enabled = false,
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
