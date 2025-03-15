{ ... }:
let
  extensions = import ./extensions.nix;
  terminal = import ./terminal.nix;
  lsp = import ./lsp.nix;
  settings = import ./settings.nix;
  keymap = import ./keymap.nix;
in {
  enable = true;
  userKeymaps = keymap;
  userSettings = settings // {
    terminal = terminal;
    lsp = lsp;
  };

  extensions = extensions;

}
