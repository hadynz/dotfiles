return {
  "justinmk/vim-gtfo",
  keys = {
    { "<leader>fo", ':<c-u>call gtfo#open#file("%:p")<cr>',    desc = "Open file in Finder" },
    { "<leader>fO", ":<c-u>call gtfo#open#file(getcwd())<cr>", desc = "Open dir in Finder" },
  },
  config = function()
    vim.cmd [[ let g:gtfo#terminals = { 'mac' : 'iterm' } ]]
  end
}
