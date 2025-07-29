return {
  "nvimdev/lspsaga.nvim",
  config = function()
    require("lspsaga").setup({
      lightbulb = {
        enable = false,
      },
      symbol_in_winbar = {
        enable = false,
      },
    })

    -- Global keymaps (simple and works everywhere)
    vim.keymap.set("n", "J", "<cmd>Lspsaga hover_doc<CR>", { desc = "Lspsaga Hover" })
    vim.keymap.set("n", "<leader>cw", "<cmd>Lspsaga rename<CR>", { desc = "Lspsaga Rename" })
    vim.keymap.set("n", "<leader>tt", "<cmd>Lspsaga term_toggle<CR>", { desc = "Lspsaga Terminal" })
    vim.keymap.set("n", "<leader>o", "<cmd>Lspsaga outline<CR>", { desc = "Lspsaga Outline" })
  end,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
}
