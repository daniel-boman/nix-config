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

        environment.systemPackages = with pkgs; [
          vim
          nixd
          nil
          nixfmt
          neofetch
          zsh
          oh-my-zsh
          micro
          rustup
          gh
          helix
          talosctl
          kubectl
          jetbrains.goland
          raycast
        ];

        nixpkgs.config.allowUnfree = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        users.users."daniel" = {
          name = "daniel";
          home = "/Users/daniel";
        };

        security.pam.enableSudoTouchIdAuth = true;

        system.defaults = {
          finder.AppleShowAllExtensions = true;
          finder.AppleShowAllFiles = true;

          NSGlobalDomain.InitialKeyRepeat = 15;
          NSGlobalDomain.KeyRepeat = 2;

          CustomUserPreferences = {

            "com.apple.TextEdit" = {
              "com.apple.TextEdit.NSShowAppCentricOpenPanelInsteadOfUntitledFile" =
                true;
            };
          };
        };

      };
      homeconfig = { pkgs, ... }: {
        home.stateVersion = "23.05";
        programs.home-manager.enable = true;

        home.packages = with pkgs; [ ];

        home.sessionVariables = {
          # TODO
          NIXD_FLAGS = "-log=error";
        };

        home = { file = { }; };
        programs.zed-editor = import ./zed { inherit pkgs; };
        programs.zsh = {
          enable = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          shellAliases = {
            rebuild = "darwin-rebuild switch --flake /etc/nix-darwin";
            update = "(cd /etc/nix-darwin && nix flake update)";
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
            export PATH=$PATH:$HOME/bin
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
              "ssh-agent"
            ];
            theme = "af-magic";

          };
        };

        programs.alacritty = {
          enable = false;
          settings = {
            window = { blur = true; };
            font = { size = 18.0; };
          };
        };
        programs.gpg = {
          enable = true;

          publicKeys = [{
            source = ./yubikey-c.gpg;
            trust = 5;
          }];
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
            signByDefault = false;
            key = "C30B 055A 68C6 D657 1EF0  6133 5928 A043 6DB7 7DA6";
          };
        };

      };
    in {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."Daniels-MacBook-Air" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users."danielboman" = homeconfig;

            home-manager.sharedModules =
              [ mac-app-util.homeManagerModules.default ];
          }
          mac-app-util.darwinModules.default
        ];
        specialArgs = { inherit inputs; };
      };
      darwinConfigurations."Daniels-Mac-mini" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users."daniel" = homeconfig;
            home-manager.backupFileExtension = ".backup";

            home-manager.sharedModules =
              [ mac-app-util.homeManagerModules.default ];
          }
          mac-app-util.darwinModules.default
        ];
        specialArgs = { inherit inputs; };
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."Daniels-MacBook-Air".pkgs;

    };
}
