local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit...", "MoreMsg" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Home Manager makes the tracked config read-only. Seed a writable runtime lock
-- from Git when updated so the repository remains the source of truth while
-- lazy.nvim can record first-run installation state.
local uv = vim.uv or vim.loop
local config_lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
local state_lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json"
local c_stat = uv.fs_stat(config_lockfile)
if c_stat then
  local s_stat = uv.fs_stat(state_lockfile)
  if not s_stat or s_stat.mtime.sec < c_stat.mtime.sec or s_stat.size ~= c_stat.size then
    vim.fn.mkdir(vim.fn.stdpath("state"), "p")
    uv.fs_unlink(state_lockfile)
    assert(uv.fs_copyfile(config_lockfile, state_lockfile))
    uv.fs_chmod(state_lockfile, 420) -- 0644 in octal (rw-r--r--)
  end
end

require("lazy").setup({
  lockfile = state_lockfile,
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = false,
    notify = false,
  },
  rocks = {
    enabled = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
