return {
  "akinsho/toggleterm.nvim",
  version = "*",
  opts = {
    size = 20,
    open_mapping = [[<c-\>]],
    hide_numbers = true,
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    insert_mappings = true,
    terminal_mappings = true,
    persist_size = true,
    persist_mode = true,
    direction = "horizontal", -- "vertical" | "horizontal" | "tab" | "float"
    close_on_exit = true,
    shell = vim.o.shell,
    auto_scroll = true,
    float_opts = {
      border = "curved",
      winblend = 0,
    },
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)
    
    -- Keymaps custom
    local Terminal = require("toggleterm.terminal").Terminal
    
    -- Terminal horizontal
    vim.keymap.set("n", "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<cr>", { desc = "Toggle Horizontal Terminal" })
    
    -- Terminal vertical
    vim.keymap.set("n", "<leader>tv", "<cmd>ToggleTerm size=80 direction=vertical<cr>", { desc = "Toggle Vertical Terminal" })
    
    -- Terminal flottant
    vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Toggle Floating Terminal" })
    
    -- Terminal en plein écran
    vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm direction=tab<cr>", { desc = "Toggle Terminal Tab" })
    
    -- Keymaps dans le terminal
    function _G.set_terminal_keymaps()
      local opts = {buffer = 0}
      -- Esc pour passer en mode normal
      vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
      -- Navigation entre fenêtres
      vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
      vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
      vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
      vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
    end
    
    vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
  end,
}
