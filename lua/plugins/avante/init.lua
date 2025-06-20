local utils = require "utils"
local ollama_provider = require "plugins.avante.ollama"

local OS = utils.OS()
local ollama_model = "ishumilin/deepseek-r1-coder-tools:8b"
if OS == "Darwin" then ollama_model = "ishumilin/deepseek-r1-coder-tools:70b" end

-- Vertex AI endpoint configuration
local function get_vertex_endpoint()
  local project_id = os.getenv "VERTEXAI_PROJECT" or "PROJECT_ID"
  local location = os.getenv "VERTEXAI_LOCATION" or "LOCATION"

  if location == "global" then
    return string.format(
      "https://aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models",
      project_id,
      location
    )
  else
    return string.format(
      "https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models",
      location,
      project_id,
      location
    )
  end
end

local vertex_endpoint = get_vertex_endpoint()

local build = "make BUILD_FROM_SOURCE=true"
if OS == "Windows" then
  build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource true"
elseif OS ~= "Darwin" then
  local gcc_version = vim.fn.system "gcc --version"
  if not string.find(gcc_version, "13.") then build = "CC=gcc-13 make BUILD_FROM_SOURCE=true" end
end
---@class AvanteProvider
local ollama_config = {
  model = ollama_model,
  endpoint = "http://127.0.0.1:11434",
  timeout = 60 * 60 * 1000, -- 1 hour timeout in milliseconds
  api_key_name = "",
  extra_request_body = {
    temperature = 0,
    max_tokens = 32768,
  },
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
  if ollama_models_list ~= nil then
    for _, installed_model in pairs(ollama_models_list) do
      local prefixed_installed_model = "ollama/" .. installed_model
      local vendor = ollama_with_model(installed_model)
      vendor.model = installed_model

      local installed_model_params = model_params(installed_model)
      vendor.context_length = installed_model_params.context_length
      if not vendor.extra_request_body then vendor.extra_request_body = {} end
      vendor.extra_request_body.temperature = installed_model_params.temperature
      installed_model_vendors[prefixed_installed_model] = vendor
    end
  end
  return installed_model_vendors
end

---To add support for custom provider, follow the format below
---See https://github.com/yetone/avante.nvim/wiki#custom-providers for more details
---@type {[string]: AvanteProvider}
local vendors = {
  ---@type AvanteSupportedProvider
  ["claude-haiku"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-3-5-haiku-20241022",
    timeout = 30000, -- Timeout in milliseconds
    extra_request_body = {
      temperature = 0,
      max_tokens = 8192,
    },
  },
  ---@type AvanteSupportedProvider
  ["claude-opus"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-opus-4-latest",
    timeout = 30000, -- Timeout in milliseconds
    extra_request_body = {
      temperature = 0,
      max_tokens = 64000,
    },
  },
  ["claude-sonnet"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-sonnet-4-20250514",
    timeout = 30000, -- Timeout in milliseconds
    extra_request_body = {
      temperature = 0,
      max_tokens = 64000,
    },
  },
  ["claude-3-5-sonnet"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-3-5-sonnet-20241022",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 8192,
    },
  },
  ["claude-3-opus"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-3-opus-20240229",
    timeout = 60000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["claude-3-sonnet"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-3-sonnet-20240229",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["claude-3-haiku"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-3-haiku-20240307",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["claude-3-5-haiku-20241022"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-3-5-haiku-20241022",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 8192,
    },
  },
  ["claude-3-5-sonnet-20241022"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-3-5-sonnet-20241022",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 8192,
    },
  },
  ["claude-3-opus-20240229"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-3-opus-20240229",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["claude-3-sonnet-20240229"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-3-sonnet-20240229",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["claude-3-haiku-20240307"] = {
    __inherited_from = "claude",
    endpoint = "https://api.anthropic.com",
    api_key_name = "ANTHROPIC_API_KEY",
    model = "claude-3-haiku-20240307",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["openai-gpt-4o-mini"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "gpt-4o-mini",
    timeout = 120000,
    extra_request_body = {
      temperature = 0,
      max_completion_tokens = 16384,
    },
  },
  ["openai-gpt-4o"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "gpt-4o",
    timeout = 120000,
    extra_request_body = {
      temperature = 0,
      max_completion_tokens = 16384,
    },
  },
  ["openai-gpt-4o-2024-11-20"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "gpt-4o-2024-11-20",
    timeout = 120000,
    extra_request_body = {
      temperature = 0,
      max_completion_tokens = 16384,
    },
  },
  ["openai-gpt-4o-2024-08-06"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "gpt-4o-2024-08-06",
    timeout = 120000,
    extra_request_body = {
      temperature = 0,
      max_completion_tokens = 16384,
    },
  },
  ["openai-gpt-4o-2024-05-13"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "gpt-4o-2024-05-13",
    timeout = 120000,
    extra_request_body = {
      temperature = 0,
      max_completion_tokens = 4096,
    },
  },
  ["openai-o1"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "o1",
    timeout = 300000,
    extra_request_body = {
      max_completion_tokens = 100000,
      reasoning_effort = "high",
    },
  },
  ["openai-o1-preview"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "o1-preview",
    timeout = 300000,
    extra_request_body = {
      max_completion_tokens = 32768,
      reasoning_effort = "high",
    },
  },
  ["openai-o1-mini"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "o1-mini",
    timeout = 180000,
    extra_request_body = {
      max_completion_tokens = 65536,
      reasoning_effort = "medium",
    },
  },
  ["openai-o3"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "o3",
    timeout = 300000,
    extra_request_body = {
      max_completion_tokens = 100000,
      reasoning_effort = "high",
    },
  },
  ["openai-o3-mini"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "o3-mini",
    timeout = 180000,
    extra_request_body = {
      max_completion_tokens = 65536,
      reasoning_effort = "medium",
    },
  },
  ["openai-gpt-4-turbo"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "gpt-4-turbo",
    timeout = 120000,
    extra_request_body = {
      temperature = 0,
      max_completion_tokens = 4096,
    },
  },
  ["openai-gpt-4-turbo-2024-04-09"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "gpt-4-turbo-2024-04-09",
    timeout = 120000,
    extra_request_body = {
      temperature = 0,
      max_completion_tokens = 4096,
    },
  },
  ["openai-gpt-4"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "gpt-4",
    timeout = 120000,
    extra_request_body = {
      temperature = 0,
      max_completion_tokens = 4096,
    },
  },
  ["openai-gpt-3.5-turbo"] = {
    __inherited_from = "openai",
    endpoint = "https://api.openai.com/v1",
    api_key_name = "OPENAI_API_KEY",
    model = "gpt-3.5-turbo",
    timeout = 60000,
    extra_request_body = {
      temperature = 0,
      max_completion_tokens = 4096,
    },
  },
  ["cohere-command-r-plus"] = {
    __inherited_from = "cohere",
    endpoint = "https://api.cohere.ai/v1",
    api_key_name = "COHERE_API_KEY",
    model = "command-r-plus",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["cohere-command-r-plus-08-2024"] = {
    __inherited_from = "cohere",
    endpoint = "https://api.cohere.ai/v1",
    api_key_name = "COHERE_API_KEY",
    model = "command-r-plus-08-2024",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["cohere-command-r"] = {
    __inherited_from = "cohere",
    endpoint = "https://api.cohere.ai/v1",
    api_key_name = "COHERE_API_KEY",
    model = "command-r",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["cohere-command-r-08-2024"] = {
    __inherited_from = "cohere",
    endpoint = "https://api.cohere.ai/v1",
    api_key_name = "COHERE_API_KEY",
    model = "command-r-08-2024",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["cohere-command"] = {
    __inherited_from = "cohere",
    endpoint = "https://api.cohere.ai/v1",
    api_key_name = "COHERE_API_KEY",
    model = "command",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["cohere-command-light"] = {

    __inherited_from = "cohere",
    endpoint = "https://api.cohere.ai/v1",
    api_key_name = "COHERE_API_KEY",
    model = "command-light",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  aihubmix = {
    __inherited_from = "openai",
    endpoint = "https://aihubmix.com/v1",
    model = "gpt-4o-2024-11-20",
    api_key_name = "AIHUBMIX_API_KEY",
    timeout = 120000,
    extra_request_body = {
      temperature = 0,
      max_completion_tokens = 16384,
    },
  },
  ["aihubmix-claude"] = {
    __inherited_from = "claude",
    endpoint = "https://aihubmix.com",
    model = "claude-opus-4-latest",
    api_key_name = "AIHUBMIX_API_KEY",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 64000,
    },
  },
  ["bedrock-claude-sonnet-4"] = {
    __inherited_from = "bedrock",
    endpoint = "https://bedrock-runtime.us-east-1.amazonaws.com",
    api_key_name = "AWS_ACCESS_KEY_ID",
    model = "us.anthropic.claude-sonnet-4-20250514-v1:0",
    timeout = 30000,
    extra_request_body = {
      temperature = 0,
      max_tokens = 4096,
    },
  },
  ["vertex-gemini-2.5-flash-preview-05-20"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,
    model = "gemini-2.5-flash-preview-05-20",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },

  ["vertex-gemini-2.5-pro-preview-06-05"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.5-pro-preview-06-05",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 32768 },
      },
    },
  },
  ["vertex-gemini-2.5-flash-lite-preview-06-17"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.5-flash-lite-preview-06-17",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },
  ["vertex-gemini-2.5-flash"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.5-flash",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },
  ["vertex-gemini-2.5-pro"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.5-pro",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 32768 },
      },
    },
  },

  ["vertex-gemini-1.5-pro"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-1.5-pro",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-1.5-pro-001"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-1.5-pro-001",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-1.5-pro-002"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-1.5-pro-002",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-1.5-latest"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-1.5-latest",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-1.5-flash-001"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-1.5-flash-001",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-1.5-flash-002"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-1.5-flash-002",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-1.5-flash-latest"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-1.5-flash-latest",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-1.5-flash-8b"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-1.5-flash-8b",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-1.5-flash-8b-latest"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-1.5-flash-8b-latest",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-exp-1206"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-exp-1206",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-2.0-flash-exp"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.0-flash-exp",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-2.0-flash-thinking-exp"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.0-flash-thinking-exp",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },
  ["vertex-gemini-2.0-flash-thinking-exp-1219"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.0-flash-thinking-exp-1219",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },
  ["vertex-gemini-2.0-flash-thinking-exp-1226"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.0-flash-thinking-exp-1226",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },
  ["vertex-gemini-2.0-flash-thinking-exp-1231"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.0-flash-thinking-exp-1231",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },
  ["vertex-gemini-2.0-flash-thinking-exp-0107"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.0-flash-thinking-exp-0107",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },
  ["vertex-gemini-2.0-flash-thinking-exp-0114"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.0-flash-thinking-exp-0114",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },
  ["vertex-gemini-2.0-flash-thinking-exp-0121"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.0-flash-thinking-exp-0121",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },

  -- New models added as requested
  ["vertex-gemini-2.5-pro-exp-03-25"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.5-pro-exp-03-25",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 32768 },
      },
    },
  },
  ["vertex-gemini-2.5-pro-preview-03-25"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-2.5-pro-preview-03-25",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 32768 },
      },
    },
  },
  ["vertex-gemini-2.0-flash-exp-1206"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,
    model = "gemini-2.0-flash-exp-1206",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      temperature = 0,
    },
  },
  ["vertex-gemini-exp-1114"] = {
    __inherited_from = "vertex",
    endpoint = vertex_endpoint,

    model = "gemini-exp-1114",
    timeout = 300000, -- Timeout in milliseconds
    api_key_name = "GOOGLE_APPLICATION_CREDENTIALS",
    extra_request_body = {
      safetySettings = {
        ["0"] = { threshold = "OFF" },
        ["1"] = { threshold = "OFF" },
        ["2"] = { threshold = "OFF" },
        ["3"] = { threshold = "OFF" },
      },
      generationConfig = {
        maxOutputTokens = 64000,
        temperature = 0,
        thinkingConfig = { includeThoughts = true, thinkingBudget = 24576 },
      },
    },
  },
}
-- //Extend vendors with installed_ollama_vendors()
vendors = vim.tbl_extend("force", vendors, installed_ollama_vendors())

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
    "AvanteToggle",
    "AvanteToggleDebug",
    "AvanteToggleHint",
    "AvanteToggleSuggestion",
    "AvanteClear",
    "AvanteFocus",
    "AvanteSelectModel",
    "AvanteConflictOurs",
    "AvanteConflictTheirs",
    "AvanteConflictAllTheirs",
    "AvanteConflictBoth",
    "AvanteConflictCursor",
    "AvanteConflictPrevConflict",
    "AvanteConflictNextConflict",
    "AvanteShowRepoMap",
    "AvanteSwitchProvider",
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

        maps.n[prefix .. "t"] = {
          function() require("avante.api").toggle() end,
          desc = "Avante toggle",
        }

        maps.v[prefix .. "t"] = {
          function() require("avante.api").toggle() end,
          desc = "Avante toggle",
        }

        maps.n[prefix .. "d"] = {
          function() require("avante.api").toggle.debug() end,
          desc = "Avante toggle debug",
        }

        maps.v[prefix .. "d"] = {
          function() require("avante.api").toggle.debug() end,
          desc = "Avante toggle debug",
        }

        maps.n[prefix .. "s"] = {
          function() require("avante.api").toggle.hint() end,
          desc = "Avante toggle suggestion",
        }

        maps.v[prefix .. "s"] = {
          function() require("avante.api").toggle.hint() end,
          desc = "Avante toggle suggestion",
        }

        maps.n[prefix .. "S"] = {
          function() require("avante.api").stop() end,
          desc = "Avante stop",
        }

        maps.v[prefix .. "S"] = {
          function() require("avante.api").stop() end,
          desc = "Avante stop",
        }

        maps.n[prefix .. "R"] = {
          function() require("avante.repo_map").show() end,
          desc = "Avante show repo map",
        }

        maps.v[prefix .. "R"] = {
          function() require("avante.repo_map").show() end,
          desc = "Avante show repo map",
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
    provider = "vertex-gemini-2.5-flash-preview-05-20",
    -- WARNING: Since auto-suggestions are a high-frequency operation and therefore expensive,
    -- currently designating it as `copilot` provider is dangerous because: https://github.com/yetone/avante.nvim/issues/1048
    -- Of course, you can reduce the request frequency by increasing `suggestion.debounce`.
    auto_suggestions_provider = "vertex-gemini-2.5-flash-preview-05-20",
    cursor_applying_provider = "vertex-gemini-2.5-flash-preview-05-20",
    memory_summary_provider = "vertex-gemini-2.5-flash-preview-05-20",
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

Where possible, iteratively create unit tests for code generated. Modularise where possible.

Ensur that the code is clean, readable, and maintainable.

Do not stop until you have completed your task. Pursue all possible avenues to achieve the desired outcome.

Consult all available resources, including specification, documentation, code, and other developers, to ensure that the code is correct and efficient. \
When unavailable, acquire information using all tools available to you. If possible, acquire information through extensive code review, and as a last resort, you may \
use bash commands (`curl`, `wget`, etc) or search the web.

Ensure that the code is well-documented and that all changes are clearly explained in the commit message. 

Document and generate unit tests for code written as you go. Run unit tests to ensure that the code is correct. Upon failure, debug and fix the code.

Above all else, you may not introduce any new bugs or regressions, nor may you introduce any new security vulnerabilities. You must ensure that the code is correct and secure.

Remember, you may NOT stop until you have completed your task. 

You can do this. Take a deep breath, gather your thoughts, and begin. The world is counting on you.
]],
    rag_service = {
      enabled = false, -- Enables the rag service, requires OPENAI_API_KEY to be set
      -- host_mount = os.getenv "HOME" .. "/.avante/rag", -- The host mount for the rag service
      runner = "docker", -- The runner for the rag service, (can use docker, or nix)
      provider = "openai", -- The provider to use for RAG service. eg: openai or ollama
      llm_model = "", -- The LLM model to use for RAG service
      embed_model = "", -- The embedding model to use for RAG service
      endpoint = "https://api.openai.com/v1", -- The API endpoint for RAG service
      docker_extra_args = "", -- Extra arguments to pass to the docker command
    },
    confirm_prompt = {
      enabled = false,
    },
    web_search_engine = {
      provider = "searxng",
      proxy = nil,
      providers = {
        tavily = {
          api_key_name = "TAVILY_API_KEY",
          extra_request_body = {
            include_answer = "basic",
          },
          ---@type WebSearchEngineProviderResponseBodyFormatter
          format_response_body = function(body) return body.answer, nil end,
        },
        serpapi = {
          api_key_name = "SERPAPI_API_KEY",
          extra_request_body = {
            engine = "google",
            google_domain = "google.com",
          },
          ---@type WebSearchEngineProviderResponseBodyFormatter
          format_response_body = function(body)
            if body.answer_box ~= nil and body.answer_box.result ~= nil then return body.answer_box.result, nil end
            if body.organic_results ~= nil then
              local jsn = vim
                .iter(body.organic_results)
                :map(
                  function(result)
                    return {
                      title = result.title,
                      link = result.link,
                      snippet = result.snippet,
                      date = result.date,
                    }
                  end
                )
                :take(10)
                :totable()
              return vim.json.encode(jsn), nil
            end
            return "", nil
          end,
        },
        searchapi = {
          api_key_name = "SEARCHAPI_API_KEY",
          extra_request_body = {
            engine = "google",
          },
          ---@type WebSearchEngineProviderResponseBodyFormatter
          format_response_body = function(body)
            if body.answer_box ~= nil then return body.answer_box.result, nil end
            if body.organic_results ~= nil then
              local jsn = vim
                .iter(body.organic_results)
                :map(
                  function(result)
                    return {
                      title = result.title,
                      link = result.link,
                      snippet = result.snippet,
                      date = result.date,
                    }
                  end
                )
                :take(10)
                :totable()
              return vim.json.encode(jsn), nil
            end
            return "", nil
          end,
        },
        google = {
          api_key_name = "GOOGLE_SEARCH_API_KEY",
          engine_id_name = "GOOGLE_SEARCH_ENGINE_ID",
          extra_request_body = {},
          ---@type WebSearchEngineProviderResponseBodyFormatter
          format_response_body = function(body)
            if body.items ~= nil then
              local jsn = vim
                .iter(body.items)
                :map(
                  function(result)
                    return {
                      title = result.title,
                      link = result.link,
                      snippet = result.snippet,
                    }
                  end
                )
                :take(10)
                :totable()
              return vim.json.encode(jsn), nil
            end
            return "", nil
          end,
        },
        kagi = {
          api_key_name = "KAGI_API_KEY",
          extra_request_body = {
            limit = "10",
          },
          ---@type WebSearchEngineProviderResponseBodyFormatter
          format_response_body = function(body)
            if body.data ~= nil then
              local jsn = vim
                .iter(body.data)
                -- search results only
                :filter(function(result) return result.t == 0 end)
                :map(
                  function(result)
                    return {
                      title = result.title,
                      url = result.url,
                      snippet = result.snippet,
                    }
                  end
                )
                :take(10)
                :totable()
              return vim.json.encode(jsn), nil
            end
            return "", nil
          end,
        },
        brave = {
          api_key_name = "BRAVE_API_KEY",
          extra_request_body = {
            count = "10",
            result_filter = "web",
          },
          format_response_body = function(body)
            if body.web == nil then return "", nil end

            local jsn = vim.iter(body.web.results):map(
              function(result)
                return {
                  title = result.title,
                  url = result.url,
                  snippet = result.description,
                }
              end
            )

            return vim.json.encode(jsn), nil
          end,
        },
        searxng = {
          api_url_name = "SEARXNG_API_URL",
          extra_request_body = {
            format = "json",
          },
          ---@type WebSearchEngineProviderResponseBodyFormatter
          format_response_body = function(body)
            if body.results == nil then return "", nil end

            local jsn = vim.iter(body.results):map(
              function(result)
                return {
                  title = result.title,
                  url = result.url,
                  snippet = result.content,
                }
              end
            )

            return vim.json.encode(jsn), nil
          end,
        },
      },
    },
    providers = vim.tbl_extend("force", vendors, {
      ---@type AvanteSupportedProvider
      openai = {
        endpoint = "https://api.openai.com/v1",
        model = "o3",
        timeout = 120000, -- Timeout in milliseconds
        extra_request_body = {
          temperature = 0,
          max_completion_tokens = 100000,
          reasoning_effort = "high",
        },
      },
      ---@type AvanteSupportedProvider
      copilot = {
        endpoint = "https://api.githubcopilot.com",
        model = "claude-sonnet-4-thought",
        proxy = nil, -- [protocol://]host[:port] Use this proxy
        allow_insecure = false, -- Allow insecure server connections
        timeout = 30000, -- Timeout in milliseconds
        extra_request_body = {
          temperature = 0,
        },
      },
      ---@type AvanteAzureProvider
      azure = {
        endpoint = "", -- example: "https://<your-resource-name>.openai.azure.com"
        deployment = "", -- Azure deployment name (e.g., "gpt-4o", "my-gpt-4o-deployment")
        api_version = "2024-06-01",
        timeout = 30000, -- Timeout in milliseconds
        extra_request_body = {
          temperature = 0,
          max_completion_tokens = 4096,
        },
      },

      bedrock = {
        endpoint = "https://bedrock.us-east-1.amazonaws.com", -- Bedrock endpoint
        model = "anthropic.claude-2.1",
        timeout = 30000, -- Timeout in milliseconds
        api_key_name = "BEDROCK_API_KEY", -- Environment variable for Bedrock API key
        extra_request_body = {
          temperature = 0,
          max_tokens = 4096,
        },
      },
      ---@type AvanteSupportedProvider
      claude = {
        api_key_name = "ANTHROPIC_API_KEY",
        endpoint = "https://api.anthropic.com",
        model = "claude-sonnet-4-20250514",
        timeout = 30000, -- Timeout in milliseconds
        extra_request_body = {
          temperature = 0,
          max_tokens = 64000,
        },
      },
      ---@type AvanteSupportedProvider
      gemini = {
        endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
        model = "gemini-1.5-flash-latest",
        timeout = 30000, -- Timeout in milliseconds
        extra_request_body = {
          temperature = 0,
          max_tokens = 4096,
        },
      },
      ---@type AvanteSupportedProvider
      cohere = {
        endpoint = "https://api.cohere.com/v1",
        model = "command-r-plus-08-2024",
        timeout = 30000, -- Timeout in milliseconds
        extra_request_body = {
          temperature = 0,
          max_tokens = 4096,
        },
      },
      vertex = {
        endpoint = vertex_endpoint, -- Vertex AI endpoint
        model = "gemini-2.5-flash-preview-05-20", -- Default model
        timeout = 300000, -- Timeout in milliseconds
        api_key_name = "GOOGLE_APPLICATION_CREDENTIALS", -- Environment variable for Google credentials
        extra_request_body = {
          temperature = 0,
          max_tokens = 64000,
          thinkingConfig = {
            generationConfig = { includeThoughts = true, thinkingBudget = 24576 },
          },
        },
      },
    }),

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
      first_provider = "claude",
      second_provider = "openai",
      prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
      timeout = 60000, -- Timeout in milliseconds
    },
    ---Specify the behaviour of avante.nvim
    ---1. auto_apply_diff_after_generation: Whether to automatically apply diff after LLM response.
    ---                                     This would simulate similar behaviour to cursor. Default to false.
    ---2. auto_set_keymaps                : Whether to automatically set the keymap for the current line. Default to true.
    ---                                     Note that avante will safely set these keymap. See https://github.com/yetone/avante.nvim/wiki#keymaps-and-api-i-guess for more details.
    ---3. auto_set_highlight_group        : Whether to automatically set the highlight group for the current line. Default to true.
    ---4. support_paste_from_clipboard    : Whether to support pasting image from clipboard. This will be determined automatically based whether img-clip is available or not.
    behaviour = {
      auto_focus_sidebar = true,
      auto_suggestions = false, -- Experimental stage
      auto_suggestions_respect_ignore = false,
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = true,
      jump_result_buffer_on_finish = false,
      support_paste_from_clipboard = true,
      minimize_diff = true,
      enable_token_counting = true,
      enable_cursor_planning_mode = true,
      auto_approve_tool_permissions = true,
      auto_check_diagnostics = true,
      enable_claude_text_editor_tool_mode = true,
      use_cwd_as_project_root = true,
    },
    history = {
      max_tokens = 4096,
      carried_entry_count = nil,
      storage_path = vim.fn.stdpath "state" .. "/avante",
      paste = {
        extension = "png",
        filename = "pasted-%Y-%m-%d-%H-%M-%S",
      },
    },
    highlights = {
      diff = {
        current = nil,
        incoming = nil,
      },
    },
    img_paste = {
      url_encode_path = true,
      template = "\nimage: $FILE_PATH\n",
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
        accept = "<C-asa>",
        next = "<C-as]>",
        prev = "<C-as[>",
        dismiss = "<C-asd>",
      },
      jump = {
        next = "<C-a]]>",
        prev = "<C-a[[>",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      -- NOTE: The following will be safely set by avante.nvim
      ask = "<leader>aa",
      edit = "<leader>ae",
      refresh = "<leader>ar",
      focus = "<leader>af",
      stop = "<leader>aS",
      toggle = {
        default = "<leader>at",
        debug = "<leader>ad",
        hint = "<leader>ah",
        suggestion = "<leader>as",
        repomap = "<leader>aR",
      },
      sidebar = {
        apply_all = "<C-ap>",
        apply_cursor = "<C-a>",
        retry_user_request = "<C-r>",
        edit_user_request = "<C-e>",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
        remove_file = "d",
        add_file = "@",
        close = { "<C-Esc>", "<C-q>" },
        ---@diagnostic disable-next-line: duplicate-doc-alias
        ---@alias AvanteCloseFromInput { normal: string | nil, insert: string | nil }
        ---@type AvanteCloseFromInput | nil
        close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
      },
      files = {
        add_current = "<leader>ac", -- Add current buffer to selected files
      },
      select_model = "<leader>am",
      select_history = "<leader>ah", -- Select history command
    },

    windows = {
      position = "right",
      wrap = true, -- similar to vim.o.wrap
      width = 30, -- default % based on available width in vertical layout
      height = 30, -- default % based on available height in horizontal layout
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
        border = "rounded",
        start_insert = true, -- Start insert mode when opening the ask window
        focus_on_apply = "ours", -- which diff to focus after applying
      },
    },

    --- @class AvanteConflictConfig
    diff = {
      autojump = true,
      --- Override the 'timeoutlen' setting while hovering over a diff (see :help timeoutlen).
      --- Helps to avoid entering operator-pending mode with diff mappings starting with `c`.
      --- Disable by setting to -1.
      override_timeoutlen = 500,
    },
    --- @class AvanteHintsConfig
    hints = {
      enabled = false,
    },
    --- @class AvanteRepoMapConfig
    repo_map = {
      ignore_patterns = { "__pycache__", "node_modules" }, -- ignore files matching these
      negate_patterns = {}, -- negate ignore files matching these.
    },
    --- @class AvanteFileSelectorConfig
    selector = {
      ---@diagnostic disable-next-line: duplicate-doc-alias
      --- @alias FileSelectorProvider "native" | "fzf" | "mini.pick" | "snacks" | "telescope" | string : nil
      provider = "native",
      -- Options override for custom providers
      provider_opts = {},
    },
    suggestion = {
      debounce = 600,
      throttle = 600,
    },
    disabled_tools = {}, ---@type string[]

    ---@type AvanteLLMToolPublic[] | fun(): AvanteLLMToolPublic[]
    custom_tools = {},
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
