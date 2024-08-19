return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "nvim-telescope/telescope-live-grep-args.nvim" },
      { "nvim-telescope/telescope-symbols.nvim" },
    },
    keys = {
      { "<leader>o",  "<cmd>Telescope find_files<cr>",      desc = "open" },
      { "<leader>tF", "<cmd>Telescope filetypes<cr>",       desc = "filetypes" },
      { "<leader>tg", "<cmd>Telescope git_branches<cr>",    desc = "git branches" },
      { "<leader>tb", "<cmd>Telescope buffers<cr>",         desc = "buffers" },
      { "<leader>tH", "<cmd>Telescope command_history<cr>", desc = "cmd history" },
      { "<leader>th", "<cmd>Telescope help_tags<cr>",       desc = "help" },
      { "<leader>ti", "<cmd>Telescope media_files<cr>",     desc = "media" },
      { "<leader>tm", "<cmd>Telescope marks<cr>",           desc = "marks" },
      { "<leader>tM", "<cmd>Telescope man_pages<cr>",       desc = "man pages" },
      { "<leader>to", "<cmd>Telescope vim_options<cr>",     desc = "options" },
      { "<leader>tT", "<cmd>Telescope live_grep<cr>",       desc = "text" },
      { "<leader>tf", "<cmd>TelescopeSearchDir<cr>",        desc = "search from" },
      { "<leader>tr", "<cmd>Telescope oldfiles<cr>",        desc = "recents" },
      { "<leader>tp", "<cmd>Telescope registers<cr>",       desc = "registers" },
      { "<leader>te", "<cmd>Telescope file_browser<cr>",    desc = "fuzzy explorer" },
      { "<leader>tc", "<cmd>Telescope colorscheme<cr>",     desc = "colorschemes" },
      { "<leader>tq", "<cmd>Telescope quickfix<cr>",        desc = "quickfix" },
      { "<leader>ts", "<cmd>Telescope treesitter<cr>",      desc = "symbols" },
      { "<leader>tS", "<cmd>Telescope aerial<cr>",          desc = "aerial" },
      { "<leader>t.", "<cmd>Telescope resume<cr>",          desc = "resume" },
      { "<leader>t*", "<cmd>Telescope grep_string<cr>",     desc = "word under cursor" },
      {
        "<leader>tt",
        function()
          require("telescope.builtin").grep_string({
            search = vim.fn.input("Grep > "),
          })
        end,
        desc = "grep text",
      },
      { "<leader>s", "<cmd>Telescope grep_string<cr>", mode = "v", desc = "search selection" },
      {
        "<leader>/",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args()
        end,
        desc = "Searches string",
      },
    },
    opts = function(_, opts)
      local actions = require("telescope.actions")
      local layout = require("telescope.actions.layout")
      local trouble = require("trouble.sources.telescope")
      local lga_actions = require("telescope-live-grep-args.actions")

      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        prompt_prefix = "   ",
        selection_caret = " ",
        mappings = {
          i = {
            ["<C-u>"] = false,        -- Mapping <C-u> to clear prompt
            ["<C-t>"] = trouble.open, -- Open with Trouble
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-p>"] = layout.toggle_preview,
            ["<C-Down>"] = actions.cycle_history_next,
            ["<C-Up>"] = actions.cycle_history_prev,
            ["<C-Space>"] = actions.to_fuzzy_refine, -- Start a fuzzy search in the frozen list
            ["<Esc>"] = actions.close,
            ["<C-h>"] = actions.which_key,
          },
          n = {
            ["<c-t>"] = trouble,
          },
        },
      })
      opts.pickers = vim.tbl_deep_extend("force", opts.pickers or {}, {
        oldfiles = {
          theme = "dropdown",
          previewer = false,
        },
      })
      opts.extensions = vim.tbl_deep_extend("force", opts.extensions or {}, {
        live_grep_args = {
          auto_quoting = true,
          additional_args = function()
            return { "--smart-case" }
          end,
          mappings = {
            i = {
              ["<C-w>"] = lga_actions.quote_prompt(),
              ["<C-q>"] = lga_actions.quote_prompt({ postfix = " -t " }),
              ["<C-y>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
            },
          },
        },
      })
    end,
  },
}
