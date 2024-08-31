{
  description = "macOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
        url = "github:LnL7/nix-darwin";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, mac-app-util }:
  let
    configuration = { pkgs, lib, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget



      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;
      

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;
      # programs.fish.enable = true;

      environment.systemPackages = [ 
          pkgs.vim
          pkgs.nil
          pkgs.neofetch 
          pkgs.zsh 
          pkgs.oh-my-zsh
          pkgs.micro
          pkgs.rustup
          pkgs.gh
          pkgs.helix
          pkgs.yabai          
          #pkgs.zsh-autosuggestions
      ];

  

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      users.users."danielboman" = {
        name = "danielboman";
        home = "/Users/danielboman";
      };


      security.pam.enableSudoTouchIdAuth = true;

      system.defaults = {
        finder.AppleShowAllExtensions = true;
        NSGlobalDomain.InitialKeyRepeat = 10;
        NSGlobalDomain.KeyRepeat = 4;
      };

      services.yabai = {
      	enable = false;
      	enableScriptingAddition = true;
   		config = {
   		  focus_follows_mouse          = "autoraise";
   		  mouse_follows_focus          = "off";
   		  window_placement             = "second_child";
   		  window_opacity               = "off";
   		  window_opacity_duration      = "0.0";
   		  window_border                = "on";
   		  window_border_placement      = "inset";
   		  window_border_width          = 2;
   		  window_border_radius         = 3;
   		  active_window_border_topmost = "off";
   		  window_topmost               = "on";
   		  window_shadow                = "float";
   		  active_window_border_color   = "0xff5c7e81";
   		  normal_window_border_color   = "0xff505050";
   		  insert_window_border_color   = "0xffd75f5f";
   		  active_window_opacity        = "1.0";
   		  normal_window_opacity        = "1.0";
   		  split_ratio                  = "0.50";
   		  auto_balance                 = "on";
   		  mouse_modifier               = "fn";
   		  mouse_action1                = "move";
   		  mouse_action2                = "resize";
   		  layout                       = "bsp";
   		  top_padding                  = 36;
   		  bottom_padding               = 10;
   		  left_padding                 = 10;
   		  right_padding                = 10;
   		  window_gap                   = 10;
   		};
      };
    services.skhd = {
    	enable = true;
    	skhdConfig = ''
    		ctrl + alt - left : yabai -m window --focus west
    		ctrl + alt - right : yabai -m window --focus east
    		ctrl + alt - down : yabai -m window --focus south
    		ctrl + alt - up : yabai -m window --focus north
    		ctrl + alt - v : yabai -m window --toggle float --grid 4:4:1:1:2:2
    		ctrl + alt - t : alacritty
    		
    		
    	'';
    };

      
    };
    homeconfig = {pkgs, ...}: {
      home.stateVersion = "23.05";
      programs.home-manager.enable = true;

      home.packages = with pkgs; [];

      home.sessionVariables = {
        # TODO
      };
      
      home = {
        file = {
          #".zshrc" = {
          #  source = ./zsh_configuration;
          #};
          #".zshenv" = {
          #  source = ./zsh_env;
          #};
        };
      };

      programs.zsh = {
          enable = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          shellAliases = {
            rebuild = "darwin-rebuild switch --flake ~/.config/nix";
            update = "(cd ~/.config/nix && nix flake update)";
          };
          #initExtra = ''
          #  set -e SSH_AGENT_PID
          #  set -x GPG_TTY $(tty)
          #  set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
          #  set +x
          #'';

          profileExtra = ''
              export GPG_TTY=$(tty)
          '';
          initExtra = ''
              export CARGO_TARGET_DIR=$HOME/.cargo-target-cache
          '';
          oh-my-zsh = {
            enable = true;
            plugins = [
              "git"
              "history"
              "history-substring-search"
              "golang"
              "rust"
              "docker"
              #"zsh-autosuggestions"
              "ssh-agent"
            ];
            theme = "af-magic";


          };
      };

      programs.alacritty = {
        enable = true;
        settings = {
          window = {
            #decorations = "Transparent";
            blur = true;
          };
          font = {
            size = 14.0;
          };
        };
      };
      programs.gpg = {
        enable = true;

        publicKeys = [
          {
            source = ./yubikey-c.gpg;
            trust = 5;
          }
        ];
      };

      #services.gpg-agent = {
      #  enable = true;
      #  enableSshSupport = true;
      #  enableZshIntegration = true;
      #  enableScDaemon = true;
      #};

      programs.git = {
        enable = true;
        
        userEmail = "daniel.boman@pm.me";
        userName = "Daniel Boman";

        signing = {
          signByDefault = true;
          key = "C30B 055A 68C6 D657 1EF0  6133 5928 A043 6DB7 7DA6";
        };
      };

      
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."Daniels-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration 
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.verbose = true;
          home-manager.users."danielboman" = homeconfig;

          home-manager.sharedModules = [
            mac-app-util.homeManagerModules.default
          ];
        }
        mac-app-util.darwinModules.default
      ];
      specialArgs = { inherit inputs; };
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Daniels-MacBook-Air".pkgs;

    
    
  };
}
