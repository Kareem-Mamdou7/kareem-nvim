-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function inject_ipynb_template()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local is_empty = #lines == 1 and lines[1] == ""

  if not is_empty then
    return
  end

  local template = [[
{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "print('Kareem Gamed')"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": "3.10"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
]]
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(template, "\n"))
  vim.notify("📓 Jupyter Notebook template inserted", vim.log.levels.INFO)
end

-- Trigger on actual new file (like :e new.ipynb or nvim new.ipynb)
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.ipynb",
  callback = inject_ipynb_template,
})

-- Trigger on reading an *empty file* (like neo-tree or nvim-tree creating it then opening it)
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*.ipynb",
  callback = function()
    -- delay a bit to let file load before checking
    vim.defer_fn(inject_ipynb_template, 10)
  end,
})

-- flutter project

vim.api.nvim_create_user_command("FlutterNew", function(opts)
  local project_name = opts.args
  if project_name == "" then
    print("❌ You must specify a project name!")
    return
  end

  -- Get the current working directory in Neovim
  local current_dir = vim.fn.getcwd()
  local project_path = current_dir .. "/" .. project_name

  -- Create the project using flutter
  vim.fn.system({
    "flutter",
    "create",
    project_path,
  })

  -- Change directory to the new project
  vim.cmd("cd " .. project_path)

  -- Open the main.dart file
  vim.cmd("e lib/main.dart")

  print("✅ Flutter project '" .. project_name .. "' created inside " .. current_dir .. " and ready to go!")
end, { nargs = 1 })
