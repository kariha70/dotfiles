-- Configure Neovim to use LazyVim as the configuration baseline.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
if not uv or not uv.fs_stat then
  vim.api.nvim_echo(
    {
      {
        "Neovim does not expose a UV API (vim.uv or vim.loop). Please upgrade to a newer Neovim.",
        "Error",
      },
    },
    true,
    {}
  )
  return
end

local function resolve_git()
  if vim.fn.executable("git") == 1 then
    return "git"
  end

  local local_app_data = vim.env.LOCALAPPDATA or ""
  local candidates = {
    "C:/Program Files/Git/cmd/git.exe",
    "C:/Program Files/Git/bin/git.exe",
  }

  if local_app_data ~= "" then
    table.insert(candidates, local_app_data .. "/Programs/Git/cmd/git.exe")
    table.insert(candidates, local_app_data .. "/Programs/Git/bin/git.exe")
  end

  for _, candidate in ipairs(candidates) do
    if uv.fs_stat(candidate) then
      return candidate
    end
  end

  return nil
end

if not uv.fs_stat(lazypath) then
  local git = resolve_git()
  if not git then
    vim.api.nvim_echo(
      {
        {
          "Unable to bootstrap lazy.nvim: git is not available. Install Git or restart your shell to refresh PATH.",
          "Error",
        },
      },
      true,
      {}
    )
    return
  end

  vim.fn.system({
    git,
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo(
      {
        {
          "Unable to clone lazy.nvim. Check git/network access and restart Neovim.",
          "Error",
        },
      },
      true,
      {}
    )
    return
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  defaults = { lazy = true },
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    enabled = true,
    notify = false,
  },
})
