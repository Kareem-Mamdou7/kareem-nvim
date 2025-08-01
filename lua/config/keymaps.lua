-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

require("keymaps.util")
require("keymaps.flutter")
require("keymaps.git.local")
require("keymaps.git.github")
require("keymaps.git.reset")
require("keymaps.runner.keybinding") -- if you want access to utility functions
require("keymaps.tsc_watch")
