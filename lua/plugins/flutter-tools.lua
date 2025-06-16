return {
  "akinsho/flutter-tools.nvim",
  config = function()
    require("flutter-tools").setup({}) -- your config here

    vim.api.nvim_create_autocmd("BufWinEnter", {
      pattern = "*__FLUTTER_DEV_LOG__*",
      callback = function(args)
        local buf = args.buf
        local already_closed = false

        local function safe_close()
          if already_closed or not vim.api.nvim_buf_is_valid(buf) then
            return true
          end

          -- Check last lines
          local ok, lines =
            pcall(vim.api.nvim_buf_get_lines, buf, math.max(0, vim.api.nvim_buf_line_count(buf) - 20), -1, false)

          if not ok then
            return true
          end

          for _, line in ipairs(lines) do
            if line:match("Lost connection to device") then
              pcall(function()
                if vim.api.nvim_buf_is_valid(buf) then
                  vim.api.nvim_buf_delete(buf, { force = true })
                  if not already_closed then
                    vim.notify("🧹 Flutter Dev Log closed after lost connection!")
                    already_closed = true
                  end
                end
              end)
              return true
            end
          end
          return false
        end

        -- Timer for background checking
        local timer = vim.loop.new_timer()
        local timer_active = true

        local function stop_timer()
          if timer_active then
            pcall(function()
              timer:stop()
              timer:close()
            end)
            timer_active = false
          end
        end

        timer:start(
          0,
          500,
          vim.schedule_wrap(function()
            if not timer_active then
              return
            end
            if safe_close() then
              stop_timer()
              if text_changed_autocmd then
                pcall(vim.api.nvim_del_autocmd, text_changed_autocmd)
              end
            end
          end)
        )

        -- TextChanged for instant detection
        local text_changed_autocmd
        text_changed_autocmd = vim.api.nvim_create_autocmd("TextChanged", {
          buffer = buf,
          callback = function()
            if safe_close() then
              stop_timer()
              pcall(vim.api.nvim_del_autocmd, text_changed_autocmd)
            end
          end,
        })

        -- Cleanup on buffer close
        vim.api.nvim_create_autocmd("BufWipeout", {
          buffer = buf,
          once = true,
          callback = function()
            stop_timer()
            if text_changed_autocmd then
              pcall(vim.api.nvim_del_autocmd, text_changed_autocmd)
            end
          end,
        })
      end,
    })
  end,
}
