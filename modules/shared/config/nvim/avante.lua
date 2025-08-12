-- Avante configuration module
local M = {}

function M.setup()
  -- Read OpenRouter API key from file and set environment variable
  local api_key_file = os.getenv("HOME") .. "/.openrouter_api_key"
  local file = io.open(api_key_file, "r")
  if file then
    local api_key = file:read("*all"):gsub("%s+", "")
    file:close()
    vim.env.OPENROUTER_API_KEY = api_key
    print("Avante: Loaded OpenRouter API key from " .. api_key_file)
  else
    print("Avante: Warning - Could not read API key from " .. api_key_file)
  end

  -- model profiles
  local profiles = {
    free = {
      provider = "openai_compatible",
      openai_compatible = {
        endpoint = "https://openrouter.ai/api/v1",
        model = "qwen/qwen3-coder:free",
        api_key = vim.env.OPENROUTER_API_KEY,
        extra_headers = { ["HTTP-Referer"] = "avante.nvim" }, -- optional but recommended by OpenRouter
      },
      -- Disable other providers explicitly
      anthropic = { enabled = false },
      openai = { enabled = false },
    },
    budget = {
      provider = "openai_compatible",
      openai_compatible = {
        endpoint = "https://openrouter.ai/api/v1",
        model = "deepseek/deepseek-v3",
        api_key = vim.env.OPENROUTER_API_KEY,
        extra_headers = { ["HTTP-Referer"] = "avante.nvim" },
      },
      -- Disable other providers explicitly
      anthropic = { enabled = false },
      openai = { enabled = false },
    },
    premium = {
      provider = "openai_compatible",
      openai_compatible = {
        endpoint = "https://openrouter.ai/api/v1",
        model = "openai/gpt-5",
        api_key = vim.env.OPENROUTER_API_KEY,
        extra_headers = { ["HTTP-Referer"] = "avante.nvim" },
      },
      -- Disable other providers explicitly
      anthropic = { enabled = false },
      openai = { enabled = false },
    },
  }

  -- base settings shared by all profiles
  local base = {
    provider = "openai_compatible", -- Force OpenRouter provider
    -- Disable all other providers explicitly
    anthropic = { enabled = false },
    openai = { enabled = false },
    prompts = {
      system = table.concat({
        "You are a precise coding assistant.",
        "Prefer minimal, idempotent diffs.",
        "Do not invent APIs; if unsure, say so.",
      }, "\n"),
      temperature = 0.2,
    },
    edit = { patch_mode = true }, -- ask for unified diffs by default
    ui = { border = "rounded" },
  }

  -- current profile name
  local current = "free"

  -- initial setup with the 'free' profile
  local config = vim.tbl_deep_extend("force", base, profiles[current])
  
  -- Ensure we're using OpenRouter and disable any native providers
  config.provider = "openai_compatible"
  config.anthropic = { enabled = false }
  config.openai = { enabled = false }
  
  require("avante").setup(config)
  
  -- Store the current configuration for reference
  _G.avante_config = config
  
  -- Notify that configuration is loaded
  vim.notify("Avante configured with " .. current .. " profile using OpenRouter", vim.log.levels.INFO)

  -- helper to switch models on the fly
  local function use_profile(name)
    local p = profiles[name]
    if not p then
      vim.notify("Avante: unknown profile '" .. tostring(name) .. "' (free|budget|premium)", vim.log.levels.WARN)
      return
    end
    local new_config = vim.tbl_deep_extend("force", base, p)
    
    -- Ensure we're using OpenRouter and disable any native providers
    new_config.provider = "openai_compatible"
    new_config.anthropic = { enabled = false }
    new_config.openai = { enabled = false }
    
    require("avante").setup(new_config)
    current = name
    _G.avante_config = new_config
    vim.notify("Avante → " .. name .. " (OpenRouter)", vim.log.levels.INFO)
  end

  -- user commands
  vim.api.nvim_create_user_command("AvanteModel", function(opts)
    use_profile(opts.args)
  end, { nargs = 1, complete = function() return { "free", "budget", "premium" } end })

  vim.api.nvim_create_user_command("AvanteFree", function() use_profile("free") end, {})
  vim.api.nvim_create_user_command("AvanteBudget", function() use_profile("budget") end, {})
  vim.api.nvim_create_user_command("AvantePremium", function() use_profile("premium") end, {})
  
  -- Debug command to check current configuration
  vim.api.nvim_create_user_command("AvanteDebug", function()
    print("Current API Key: " .. (vim.env.OPENROUTER_API_KEY and "Set" or "Not set"))
    print("Current Profile: " .. current)
    print("Current Config: " .. vim.inspect(_G.avante_config))
  end, {})

  -- optional keymaps
  vim.keymap.set("n", "<leader>af", function() use_profile("free") end, { desc = "Avante: model = free" })
  vim.keymap.set("n", "<leader>ab", function() use_profile("budget") end, { desc = "Avante: model = budget" })
  vim.keymap.set("n", "<leader>ap", function() use_profile("premium") end, { desc = "Avante: model = premium" })
end

return M
  