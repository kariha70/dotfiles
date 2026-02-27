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

if not uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
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
