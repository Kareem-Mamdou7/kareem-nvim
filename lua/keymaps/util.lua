local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- 🔁 Mapping: Fun effect
map("n", "<leader>cx", "<cmd>CellularAutomaton make_it_rain<CR>", {
  desc = "Make it rain",
})

-- 🔁 Mapping: Prompted substitution with confirmation
map("n", "<leader>cw", function()
  vim.ui.input({ prompt = "Word to replace:" }, function(old_word)
    if not old_word or old_word == "" then
      return
    end
    vim.ui.input({ prompt = "Replace with:" }, function(new_word)
      if new_word == nil then
        return
      end
      local cmd = string.format("%%s/%s/%s/gc", vim.fn.escape(old_word, "/\\"), vim.fn.escape(new_word, "/\\"))
      vim.cmd(cmd)
    end)
  end)
end, { desc = "Global substitute with confirmation", unpack(opts) })

-- 🔁 Mapping: Manual substitution with confirmation (global)
map("n", "<leader>r", ":%s///gc<Left><Left><Left>", {
  desc = "Manual global replace with confirm",
  noremap = true,
  silent = false,
})

-- 🧠 Hint: Vim replace confirmation menu (for reference)
--[[
  Replace with new value?
    [y] - yes (this one)
    [n] - no (skip)
    [a] - all (remaining)
    [q] - quit (stop)
    [l] - last (replace & quit)
    [^E] - scroll up
    [^Y] - scroll down
--]]

-- 🎨 Mapping: Export to Carbon (visual or full buffer)
map({ "n", "v" }, "<leader>C", function()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd("CarbonNow")
  else
    vim.cmd("normal! ggVG")
    vim.cmd("CarbonNow")
  end
end, {
  desc = "Export selection or whole buffer to Carbon image",
  silent = true,
})
