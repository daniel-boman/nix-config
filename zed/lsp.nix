{
  nix = {
    settings = { diagnostics = { ignored = [ "unused_binding" ]; }; };
    binary = { path_lookup = true; };
  };
  rust-analyzer = {
    binary = { path_lookup = true; };

  };
}
