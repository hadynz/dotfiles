return {
  {
    "mrjones2014/smart-splits.nvim",
    -- Must lazy-load to prevent startup error when no multiplexer (tmux/wezterm) is installed.
    -- The plugin's own plugin/smart-splits.lua runs mux detection on source, before config() runs.
    -- With keys defined below, it loads on first <C-h/j/k/l> press instead.
    lazy = true,
    config = function()
      local opts = {
        at_edge = function(ctx)
          require("utils.hopscotch").spatial(ctx.direction)
        end,
      }
      if vim.fn.executable("tmux") == 0 and vim.fn.executable("wezterm") == 0 then
        opts.default_mux = "ignore"
      end

      require("smart-splits").setup(opts)
    end,
    keys = {
      { "<C-h>", "<cmd>lua require'smart-splits'.move_cursor_left()<cr>", mode = { "n", "v" }, desc = "Go to left window" },
      { "<C-j>", "<cmd>lua require'smart-splits'.move_cursor_down()<cr>", mode = { "n", "v" }, desc = "Go to lower window" },
      { "<C-k>", "<cmd>lua require'smart-splits'.move_cursor_up()<cr>", mode = { "n", "v" }, desc = "Go to upper window" },
      { "<C-l>", "<cmd>lua require'smart-splits'.move_cursor_right()<cr>", mode = { "n", "v" }, desc = "Go to right window" },
      { "<C-Up>", "<cmd>lua require'smart-splits'.resize_up()<cr>", desc = "Resize top" },
      { "<C-Down>", "<cmd>lua require'smart-splits'.resize_down()<cr>", desc = "Resize bottom" },
      { "<C-Left>", "<cmd>lua require'smart-splits'.resize_left()<cr>", desc = "Resize left" },
      { "<C-Right>", "<cmd>lua require'smart-splits'.resize_right()<cr>", desc = "Resize right" },
    },
    init = function()
      -- Terminal buffer navigation (e.g. LazyGit in floating window)
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local opts = { buffer = buf, silent = true }
          vim.keymap.set("t", "<C-h>", function()
            vim.cmd("stopinsert")
            require("smart-splits").move_cursor_left()
          end, vim.tbl_extend("force", opts, { desc = "Go to left window" }))
          vim.keymap.set("t", "<C-j>", function()
            vim.cmd("stopinsert")
            require("smart-splits").move_cursor_down()
          end, vim.tbl_extend("force", opts, { desc = "Go to lower window" }))
          vim.keymap.set("t", "<C-k>", function()
            vim.cmd("stopinsert")
            require("smart-splits").move_cursor_up()
          end, vim.tbl_extend("force", opts, { desc = "Go to upper window" }))
          vim.keymap.set("t", "<C-l>", function()
            vim.cmd("stopinsert")
            require("smart-splits").move_cursor_right()
          end, vim.tbl_extend("force", opts, { desc = "Go to right window" }))
        end,
        desc = "Terminal window navigation with smart-splits",
      })

      -- Refocus floating terminal window when navigating back (e.g. LazyGit)
      -- Handles both internal window navigation and external focus (e.g. wezterm/tmux pane)
      local _last_win = nil

      local function focus_floating_terminal()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(win) then
            local config = vim.api.nvim_win_get_config(win)
            if config.relative ~= "" then
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == "terminal" then
                vim.api.nvim_set_current_win(win)
                vim.cmd("startinsert")
                return
              end
            end
          end
        end
      end

      vim.api.nvim_create_autocmd("WinLeave", {
        callback = function() _last_win = vim.api.nvim_get_current_win() end,
        desc = "Track last window for floating terminal refocus",
      })
      vim.api.nvim_create_autocmd("WinEnter", {
        callback = function()
          if _last_win and vim.api.nvim_win_is_valid(_last_win) then
            local last_config = vim.api.nvim_win_get_config(_last_win)
            if last_config.relative ~= "" then return end
          end
          focus_floating_terminal()
        end,
        desc = "Refocus floating terminal on window enter",
      })
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function() focus_floating_terminal() end,
        desc = "Refocus floating terminal when Neovim regains focus",
      })
    end,
  },
}
