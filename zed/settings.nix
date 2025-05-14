{
  base_keymap = "VSCode";
  hour_format = "hour24";
  languages = { "Nix" = { language_servers = [ "nixd" "nil" ]; formatter = "nil"; }; };
  vim_mode = false;
  show_whitespaces = "trailing";
  auto_update = false;
  inlay_hints = {
      enabled = true;
      show_type_hints = true;
      show_parameter_hints = true;
      show_other_hinds = true;
      show_background = false;
      edit_debounce_ms = 500;
      scroll_debounce_ms = 50;
  };
}
