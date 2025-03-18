local filetypes = {
  { text = "markdown" },
  { text = "javascript" },
  { text = "javascriptreact" },
  { text = "lua" },
  { text = "python" },
  { text = "typescript" },
  { text = "typescriptreact" },
}

local function get_git_root_directory(path)
  local function is_git_repo(dir)
    local git_dir = dir .. "/.git"
    local stat = vim.loop.fs_stat(git_dir)
    return stat and stat.type == "directory"
  end

  local function get_parent_directory(dir)
    return vim.fn.fnamemodify(dir, ":h")
  end

  local directories = {}
  local current_dir = path
  while current_dir do
    table.insert(directories, current_dir)
    if is_git_repo(current_dir) then
      break
    end
    local parent_dir = get_parent_directory(current_dir)
    if parent_dir == current_dir then
      break
    end
    current_dir = parent_dir
  end

  return directories
end

local function list_directories_from_buffer()
  local current_buffer_path = vim.fn.expand("%:p:h")
  local directories = get_git_root_directory(current_buffer_path)
  return directories
end

local grep_current_buffer_dirs = function()
  -- Get a list of all parent directories of the current buffer (up to the git root)
  local directories = list_directories_from_buffer()

  -- Present the directories to the user for selection
  vim.ui.select(directories, {
    prompt = "Select directory to Grep:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      Snacks.picker.grep({ dirs = { choice } })
    else
      print("No directory selected")
    end
  end)
end

return {
  "folke/snacks.nvim",
  enabled = true,
  opts = {
    picker = {
      layout = {
        preset = "telescope",
      },
      win = {
        list = {
          keys = {
            ["<A-->"] = "edit_split",
          },
        },
      },
    },
    input = {
      win = {
        border = vim.g.borderStyle,
        keys = { q = "close", ["<Esc>"] = "close" },
      },
    },
  },
  keys = {
    -- Disable defaults
    { "<leader><space>", false },
    { "<leader>.", false },
    { "<leader>S", false },

    -- Picker
    { "<F5>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    { "<C-p>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    { "<leader>.", function() Snacks.picker.grep_word() end, desc = "Grep word under cursor" },
    { "<leader>E", function() Snacks.explorer() end, desc = "Show explorer" },
    { "<leader>gt", function() Snacks.picker.git_status() end, desc = "List modified git files" },
    { "<leader><leader>g", function() Snacks.picker.git_status() end, desc = "List modified git files" },
    { "<leader><leader>b", function() Snacks.picker.buffers() end, desc = "Open buffers" },
    { "<leader><leader>r", function() Snacks.picker.recent() end, desc = "Recent files" },
    { "<leader>sx", grep_current_buffer_dirs, desc = "Grep (current Buffer Dirs)" },

    -- Scratch
    { "<F9>", function() require("utils.snacks.scratch").new_scratch(filetypes) end, desc = "Toggle Scratch Buffer" },
    { "<F10>", function() require("utils.snacks.scratch").select_scratch() end, desc = "Select Scratch Buffer" },
  },
}
