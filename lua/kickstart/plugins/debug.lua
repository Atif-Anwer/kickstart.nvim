-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',  -- Python debugger
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
    -- Add keybinding to select Python interpreter
    {
      '<leader>dp',
      function()
        -- Function to find conda environments
        local function find_conda_envs()
          local handle = io.popen('conda env list --json')
          if not handle then return {} end
          local result = handle:read("*a")
          handle:close()

          local ok, json_data = pcall(vim.json.decode, result)
          if not ok then return {} end

          local envs = {}
          for _, path in ipairs(json_data.envs) do
            local name = path:match(".+[/\\](.+)$") or path
            table.insert(envs, { name = name, path = path })
          end
          return envs
        end

        -- Get conda environments
        local conda_envs = find_conda_envs()
        local env_names = {}
        local env_paths = {}

        for _, env in ipairs(conda_envs) do
          table.insert(env_names, env.name)
          env_paths[env.name] = env.path
        end

        -- Prompt user to select environment
        vim.ui.select(env_names, {
          prompt = 'Select Python Environment',
          format_item = function(item)
            return "Conda: " .. item
          end,
        }, function(choice)
          if choice then
            local python_path = env_paths[choice] .. '/bin/python'
            if vim.fn.has('win32') == 1 then
              python_path = env_paths[choice] .. '\\python.exe'
            end
            -- Setup dap-python with the selected interpreter
            require('dap-python').setup(python_path)
            vim.notify('Python debugger using: ' .. python_path)
          end
        end)
      end,
      desc = 'Debug: Select Python Interpreter',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'debugpy',  -- Python debugger
      },
    }

    -- Python setup with Conda support
    local function get_python_path()
      -- Hardcoded Conda environment path
      local conda_env_path = 'C:\\Users\\Atif\\miniconda3\\envs\\TEM_311'
      if vim.fn.isdirectory(conda_env_path) == 1 then
        return conda_env_path .. '\\python.exe'
      end

      -- Fallback to other methods if hardcoded path doesn't exist
      -- First check if there's a poetry environment
      local poetry_path = vim.fn.system('poetry env info -p')
      if vim.v.shell_error == 0 then
        poetry_path = vim.fn.trim(poetry_path)
        if vim.fn.has('win32') == 1 then
          return poetry_path .. '\\Scripts\\python.exe'
        end
        return poetry_path .. '/bin/python'
      end

      -- Then check for a virtualenv
      if vim.env.VIRTUAL_ENV then
        if vim.fn.has('win32') == 1 then
          return vim.env.VIRTUAL_ENV .. '\\Scripts\\python.exe'
        end
        return vim.env.VIRTUAL_ENV .. '/bin/python'
      end

      -- Check for active Conda environment
      if vim.env.CONDA_PREFIX then
        if vim.fn.has('win32') == 1 then
          return vim.env.CONDA_PREFIX .. '\\python.exe'
        end
        return vim.env.CONDA_PREFIX .. '/bin/python'
      end

      -- Fallback to system Python
      return vim.fn.exepath('python3') or vim.fn.exepath('python') or 'python'
    end

    -- Configure the debugger
    local dap = require('dap')

    -- Clear existing Python configurations
    dap.configurations.python = {}

    -- Setup dap-python with explicit paths
    local dap_python = require('dap-python')

    -- Use the Conda environment's Python and debugpy
    local python_path = 'C:\\Users\\Atif\\miniconda3\\envs\\TEM_311\\python.exe'

    -- Basic dap-python setup with Conda environment
    dap_python.setup(python_path, {
        include_configs = true,
        console = 'integratedTerminal',
        pythonPath = python_path,
    })

    -- Configure Python adapter explicitly
    dap.adapters.python = {
        type = 'executable',
        command = python_path,
        args = { '-m', 'debugpy.adapter' }
    }

    -- Add custom Python launch configurations
    table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Launch file with arguments',
        program = '${file}',
        python = python_path,
        args = function()
            local args_string = vim.fn.input('Arguments: ')
            return vim.split(args_string, ' +')
        end,
        pythonPath = python_path,
        justMyCode = false,
        console = 'integratedTerminal',
    })

    -- Add configuration for Django
    table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Django',
        program = vim.fn.getcwd() .. '\\manage.py',
        args = {'runserver', '--noreload'},
        python = python_path,
        pythonPath = python_path,
        django = true,
        console = 'integratedTerminal',
    })

    -- Add configuration for FastAPI
    table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'FastAPI',
        module = 'uvicorn',
        python = python_path,
        pythonPath = python_path,
        args = function()
            local args_string = vim.fn.input('Args (default: main:app --reload): ')
            if args_string == '' then
                return {'main:app', '--reload'}
            end
            return vim.split(args_string, ' ')
        end,
        console = 'integratedTerminal',
    })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
      layouts = {
        {
          elements = {
            -- Elements can be strings or table with id and size keys.
            { id = "scopes", size = 0.25 },
            "breakpoints",
            "stacks",
            "watches",
          },
          size = 40, -- 40 columns
          position = "left",
        },
        {
          elements = {
            "repl",
            "console",
          },
          size = 0.25, -- 25% of total lines
          position = "bottom",
        },
      },
    }

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
  end,
}
