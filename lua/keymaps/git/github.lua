local map = vim.keymap.set
local opts = { noremap = true, silent = true }

local function is_git_repo()
  return vim.fn.isdirectory(".git") == 1
end

local function run_cmd(cmd)
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    print("Error running: " .. cmd)
    print(result)
    return nil
  end
  return result
end

-- Helper to initialize local Git repo
local function init_local_git()
  if is_git_repo() then
    print("Already a Git repository.")
    return
  end
  if run_cmd("git init") then
    print("Local Git repo initialized.")
  end
end

-- Main <leader>gr logic
map("n", "<leader>gr", function()
  vim.ui.select({ "Create GitHub Repo", "Init Local Git Repo Only" }, {
    prompt = "Select Git action:",
  }, function(choice)
    if not choice then
      print("Canceled.")
      return
    end

    -- === Option 1: Create GitHub Repo ===
    if choice == "Create GitHub Repo" then
      if not is_git_repo() then
        print("Initializing Git repo...")
        if not run_cmd("git init") then
          return
        end
      end

      vim.ui.input({ prompt = "GitHub repo name: " }, function(repo)
        if not repo or repo == "" then
          print("Canceled: No repo name.")
          return
        end

        vim.ui.input({ prompt = "Visibility (1 = Public, 0 = Private): " }, function(visibility)
          local vis_flag = visibility == "0" and "--private" or "--public"
          if visibility ~= "0" and visibility ~= "1" then
            print("Invalid input. Use 1 or 0.")
            return
          end

          -- Remove origin if it already exists
          local remotes = vim.fn.systemlist("git remote")
          if vim.tbl_contains(remotes, "origin") then
            print("Removing existing origin...")
            if not run_cmd("git remote remove origin") then
              return
            end
          end

          -- Create README if missing
          local readme_path = "README.md"
          if vim.fn.filereadable(readme_path) == 0 then
            local content = "# " .. repo .. "\n\nCreated via Neovim automation."
            vim.fn.writefile(vim.split(content, "\n"), readme_path)
          end

          vim.ui.input({ prompt = "Commit message: " }, function(commit_msg)
            if not commit_msg or commit_msg == "" then
              print("Canceled: No commit message.")
              return
            end

            if not run_cmd("git add .") then
              return
            end
            if not run_cmd('git commit -m "' .. commit_msg .. '"') then
              return
            end
            run_cmd("git branch -M main") -- optional

            local create_cmd = string.format('gh repo create "%s" %s --source=. --remote=origin --push', repo, vis_flag)
            if not run_cmd(create_cmd) then
              return
            end

            run_cmd(string.format('gh repo view "%s" --web', repo))
            print("GitHub repo created and pushed.")
          end)
        end)
      end)

    -- === Option 2: Init Local Git Only ===
    elseif choice == "Init Local Git Repo Only" then
      init_local_git()
    end
  end)
end, { desc = "Git: Init Local or Create GitHub Repo", unpack(opts) })

-- <leader>gD: Delete GitHub repo + local .git, or just .git
map("n", "<leader>gD", function()
  if not is_git_repo() then
    local confirm = vim.fn.input("No .git folder. Nothing to delete. Press Enter to continue.")
    return
  end

  local remote_url = vim.fn.system("git config --get remote.origin.url"):gsub("\n", "")
  local repo = remote_url:match("github.com[:/](.-)%.git$")

  local confirm_msg
  if repo then
    confirm_msg = string.format("Delete GitHub repo '%s' AND local .git? (yes/NO): ", repo)
  else
    confirm_msg = "No remote GitHub repo. Delete local .git? (yes/NO): "
  end

  local confirm = vim.fn.input(confirm_msg)
  if confirm:lower() ~= "yes" then
    print("Canceled.")
    return
  end

  -- Delete GitHub repo if available
  if repo then
    local result = vim.fn.systemlist("gh repo delete " .. repo .. " --yes")
    if vim.v.shell_error ~= 0 then
      print("Failed to delete GitHub repo:")
      print(table.concat(result, "\n"))
    else
      print("GitHub repo deleted.")
    end
  end

  -- Always delete local .git
  if vim.fn.delete(".git", "rf") == 0 then
    print("Local .git folder removed.")
  else
    print("Failed to remove local .git folder.")
  end
end, { desc = "GitHub: Delete Remote Repo + .git", unpack(opts) })
