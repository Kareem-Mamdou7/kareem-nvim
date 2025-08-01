local M = {}
local job_id = nil

local function ensure_tsconfig()
  if vim.fn.filereadable("tsconfig.json") == 0 then
    vim.notify("No tsconfig.json found. Running: tsc --init", vim.log.levels.WARN)
    local result = vim.fn.system("tsc --init")
    if vim.v.shell_error ~= 0 then
      vim.notify("Failed to create tsconfig.json:\n" .. result, vim.log.levels.ERROR)
      return false
    end
    vim.notify("tsconfig.json created", vim.log.levels.INFO)
  end
  return true
end

function M.toggle()
  if job_id then
    vim.fn.jobstop(job_id)
    vim.notify("TSC watch stopped", vim.log.levels.INFO)
    job_id = nil
    return
  end

  if not ensure_tsconfig() then
    return
  end

  job_id = vim.fn.jobstart({ "tsc", "-w" }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      -- Do nothing unless there's an actual error in stdout (not common)
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            vim.notify("[tsc error] " .. line, vim.log.levels.ERROR)
          end
        end
      end
    end,
    on_exit = function()
      vim.notify("TSC watch exited", vim.log.levels.WARN)
      job_id = nil
    end,
  })

  vim.notify("TSC watch started", vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>tw", M.toggle, { desc = "Toggle TSC Watch" })

return M
