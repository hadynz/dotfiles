return {
  "nickjvandyke/opencode.nvim",
  dependencies = {
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    require("which-key").add({ "<leader>a", group = "+ai" })

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Recommended/example keymaps.
    vim.keymap.set({ "n", "x" }, "<leader>ai", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode inline" })
    vim.keymap.set({ "n", "x" }, "<leader>aa", function() require("opencode").select() end, { desc = "Execute opencode action" })
    vim.keymap.set({ "n", "t" }, "<leader>at", function() require("opencode").toggle() end, { desc = "Toggle opencode" })

    vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end, { desc = "Add range to opencode", expr = true })
    vim.keymap.set("n", "goo", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })

    vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end, { desc = "Scroll opencode up" })
    vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "Scroll opencode down" })

    -- You may want these if you use the opinionated `<C-a>` and `<C-x>` keymaps above — otherwise consider `<leader>o…` (and remove terminal mode from the `toggle` keymap).
    vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
    vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })

    local function get_opencode_pids()
      local result = vim.fn.system("pgrep -f 'opencode.*--port'")
      local pids = {}
      for pid in result:gmatch("%d+") do
        table.insert(pids, tonumber(pid))
      end
      return pids
    end

    vim.keymap.set("n", "<leader>ak", function()
      local pids = get_opencode_pids()
      if #pids == 0 then
        vim.notify("No opencode servers running", vim.log.levels.INFO)
        return
      end
      for _, pid in ipairs(pids) do
        vim.fn.system("kill " .. pid)
      end
      vim.notify("Killed all opencode servers (" .. #pids .. ")", vim.log.levels.INFO)
    end, { desc = "Kill all opencode servers" })
  end,
}
