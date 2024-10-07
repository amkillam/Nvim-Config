if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- You can also add or configure plugins by creating files in this `plugins/` folder
-- Here are some examples:

---@type LazySpec
return {

  -- == Examples of Adding Plugins ==

  "andweeb/presence.nvim",
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function() require("lsp_signature").setup() end,
  },

  -- == Examples of Overriding Plugins ==

  -- customize alpha options
  {
    "goolord/alpha-nvim",
    opts = function(_, opts)
      -- customize the dashboard header
      opts.section.header.val = {
        " █████  ███████ ████████ ██████   ██████",
        "██   ██ ██         ██    ██   ██ ██    ██",
        "███████ ███████    ██    ██████  ██    ██",
        "██   ██      ██    ██    ██   ██ ██    ██",
        "██   ██ ███████    ██    ██   ██  ██████",
        " ",
        "    ███    ██ ██    ██ ██ ███    ███",
        "    ████   ██ ██    ██ ██ ████  ████",
        "    ██ ██  ██ ██    ██ ██ ██ ████ ██",
        "    ██  ██ ██  ██  ██  ██ ██  ██  ██",
        "    ██   ████   ████   ██ ██      ██",
      }
      return opts
    end,
  },

  -- You can disable default plugins as follows:
  { "max397574/better-escape.nvim", enabled = false },

  -- You can also easily customize additional setup of plugins that is outside of the plugin's setup call
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.luasnip"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom luasnip configuration such as filetype extend or custom snippets
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "javascriptreact" })
    end,
  },

  {
    "windwp/nvim-autopairs",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom autopairs configuration such as custom rules
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"
      npairs.add_rules(
        {
          Rule("$", "$", { "tex", "latex" })
            -- don't add a pair if the next character is %
            :with_pair(cond.not_after_regex "%%")
            -- don't add a pair if  the previous character is xxx
            :with_pair(
              cond.not_before_regex("xxx", 3)
            )
            -- don't move right when repeat character
            :with_move(cond.none())
            -- don't delete if the next character is xx
            :with_del(cond.not_after_regex "xx")
            -- disable adding a newline when you press <cr>
            :with_cr(cond.none()),
        },
        -- disable for .vim files, but it work for another filetypes
        Rule("a", "a", "-vim")
      )
    end,
  },

  -- Custom Parameters (with defaults)
  {
    "David-Kunz/gen.nvim",
    opts = {
      model = "codeqwen:7b-chat", -- The default model to use.
      host = "localhost", -- The host running the Ollama service.
      port = "11434", -- The port on which the Ollama service is listening.
      quit_map = "q", -- set keymap for close the response window
      retry_map = "<c-r>", -- set keymap to re-send the current prompt
      init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
      -- Function to initialize Ollama
      command = function(options)
        local body = { model = options.model, stream = true }
        return "curl --silent --no-buffer -X POST http://"
          .. options.host
          .. ":"
          .. options.port
          .. "/api/chat -d $body"
      end,
      -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
      -- This can also be a command string.
      -- The executed command must return a JSON object with { response, context }
      -- (context property is optional).
      -- list_models = '<omitted lua function>', -- Retrieves a list of model names
      display_mode = "float", -- The display mode. Can be "float" or "split".
      show_prompt = false, -- Shows the prompt submitted to Ollama.
      show_model = false, -- Displays which model you are using at the beginning of your chat session.
      no_auto_close = false, -- Never closes the window automatically.
      debug = false, -- Prints errors and the command which is run.
    },
  },

  {
    "yetone/avonte.nvim",
    opts = {
      debug = false,
      ---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | [string]
      provider = "claude", -- Only recommend using Claude
      auto_suggestions_provider = "copilot",
      ---@alias Tokenizer "tiktoken" | "hf"
      -- Used for counting tokens and encoding text.
      -- By default, we will use tiktoken.
      -- For most providers that we support we will determine this automatically.
      -- If you wish to use a given implementation, then you can override it here.
      tokenizer = "tiktoken",
      ---@alias AvanteSystemPrompt string
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
        model = "gpt-4o-2024-05-13",
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
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = true,
        support_paste_from_clipboard = false,
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
          switch_windows = "<Tab>",
          reverse_switch_windows = "<S-Tab>",
        },
      },
      windows = {
        ---@alias AvantePosition "right" | "left" | "top" | "bottom"
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
  },
}
