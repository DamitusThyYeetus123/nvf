{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.nvim.dag) entryAnywhere;
  inherit (lib.nvim.lua) toLuaObject;

  cfg = config.vim.ui.illuminate;
in {
  config = mkIf cfg.enable {
    vim.startPlugins = ["vim-illuminate"];

    vim.luaConfigRC.vim-illuminate = entryAnywhere ''
      require('illuminate').configure({${toLuaObject cfg.setupOpts}})
    '';
  };
}
