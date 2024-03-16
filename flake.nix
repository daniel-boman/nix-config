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
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  let
    configuration = { pkgs, ... }: {
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
            update = "darwin-rebuild switch --flake ~/.config/nix";
          };
          initExtra = ''
            set -e SSH_AGENT_PID
            set -x GPG_TTY $(tty)
            set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket) 
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
   
        }
      ];
      specialArgs = { inherit inputs; };
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Daniels-MacBook-Air".pkgs;

    
    
  };
}
