local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "<leader>cx", "<cmd>CellularAutomaton make_it_rain<CR>", { desc = "Make it rain" })

map("n", "<leader>cw", function()
  vim.ui.input({ prompt = "Word to replace:" }, function(old_word)
    if not old_word or old_word == "" then
      return
    end
    vim.ui.input({ prompt = "Replace with:" }, function(new_word)
      if new_word == nil then
        return
      end
      local cmd = string.format("%%s/%s/%s/g", vim.fn.escape(old_word, "/\\"), vim.fn.escape(new_word, "/\\"))
      vim.cmd(cmd)
    end)
  end)
end, { desc = "Global substitute with input", unpack(opts) })

vim.keymap.set({ "n", "v" }, "<leader>C", function()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "" then
    -- Already in visual mode, just export
    vim.cmd("CarbonNow")
  else
    -- Not in visual mode: select all, then export
    vim.cmd("normal! ggVG") -- Select the whole buffer
    vim.cmd("CarbonNow")
  end
end, {
  desc = "Export selection or whole buffer to Carbon image",
  silent = true,
})
