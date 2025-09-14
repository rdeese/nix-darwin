{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    # loads 1password-cli and shell plugins
    _1password-shell-plugins.url = "github:1Password/shell-plugins";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, ... }:
  let
    configuration = { pkgs, ... }: {
      environment.systemPackages =
        [
	    pkgs.git
	    pkgs.vim
	    pkgs.neovim
	    pkgs.htop
	    pkgs.tmux
	    pkgs.ripgrep
	    pkgs.gh
        ];

      homebrew = {
          enable = true;

          onActivation.cleanup = "uninstall";
      
          taps = [];
          brews = [];
          casks = [
	      "maccy" # clipboard history
	      "rectangle" # window management
	      "linear-linear" # project management
	      "slack" # team communication
	      "1password" # password manager
	      "arc" # browser
	  ];
      };

      system.keyboard = {
      	enableKeyMapping = true;
        remapCapsLockToControl = true;
      };

      system.defaults.menuExtraClock.IsAnalog = true;
      system.defaults.dock.show-recents = false;
      system.defaults.dock.mru-spaces = false;

      system.defaults.dock.persistent-apps = [
        {
          app = "/Applications/1Password.app";
        }
        {
          app = "/Applications/Arc.app";
        }
        {
          app = "/Applications/Linear.app";
        }
        {
          app = "/Applications/Slack.app";
        }
        {
          spacer = {
            small = true;
          };
        }
        {
          folder = "/System/Applications/Utilities";
        }
      ];

      system.defaults.finder.AppleShowAllExtensions = true;
      system.defaults.finder.AppleShowAllFiles = true;
      system.defaults.finder.FXDefaultSearchScope = "SCcf";
      system.defaults.finder.NewWindowTarget = "Home";

      system.defaults.NSGlobalDomain.AppleEnableSwipeNavigateWithScrolls = false;

      system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
      system.defaults.NSGlobalDomain.NSAutomaticInlinePredictionEnabled = false;

      # TODO identify appropriate values
      # system.defaults.NSGlobalDomain.InitialKeyRepeat = 
      # system.defaults.NSGlobalDomain.KeyRepeat = 

      system.defaults.NSGlobalDomain.AppleICUForce24HourTime = true;

      # Turns the function keys back into normal function keys when true
      # Interesting idea.
      # system.defaults.NSGlobalDomain."com.apple.keyboard.fnState"

      # Consider this article as a source for how to set additional
      # configs that nix-darwin hasn't explicitly added yet:
      # https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236

      # Hack for setting the default browser:
      # https://tommorris.org/posts/2024/til-setting-default-browser-on-macos-using-nix/

      # Let determinate manage nix, not nix-darwin
      nix.enable = false;

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Allow unfree software
      nixpkgs.config.allowUnfree = true;

      # Declare the user that will be running `nix-darwin`.
      users.users.rupertdeese = {
          name = "rupertdeese";
          home = "/Users/rupertdeese";
      };

      system.primaryUser = "rupertdeese";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;

      # Enables use of touchid for sudo
      security.pam.services.sudo_local.touchIdAuth = true;
    };
    homeconfig = {pkgs, ...}: {
        home.username = "rupertdeese";
        home.homeDirectory = "/Users/rupertdeese";

        home.packages = [
	    pkgs.fortune
	];

        home.sessionVariables = {
	    # convince tmux to use vim bindings
            VISUAL = "vim";
        };

	# This value determines the Home Manager release that your
        # configuration is compatible with. This helps avoid breakage
        # when a new Home Manager release introduces backwards
        # incompatible changes.
        #
        # You can update Home Manager without changing this value. See
        # the Home Manager release notes for a list of state version
        # changes in each release.
        home.stateVersion = "25.05";
        
        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;

        programs.git.enable = true;
        programs.neovim = {
          enable = true;
          defaultEditor = true;
          viAlias = true;
          vimAlias = true;
          vimdiffAlias = true;
#          plugins = with pkgs.vimPlugins; [
#            nvim-lspconfig
#            nvim-treesitter.withAllGrammars
#            plenary-nvim
#            gruvbox-material
#            mini-nvim
#          ];
        };

	imports = [ inputs._1password-shell-plugins.hmModules.default ];
        programs._1password-shell-plugins = {
          # enable 1Password shell plugins for bash, zsh, and fish shell
          enable = true;
          # the specified packages as well as 1Password CLI will be
          # automatically installed and configured to use shell plugins
          plugins = with pkgs; [ gh awscli2 ];
        };

	programs.zsh = {
	  enable = true;
          initContent = ''
            eval "$(/opt/homebrew/bin/brew shellenv)"
          '';
        };
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Ruperts-MacBook-Pro
    darwinConfigurations."Ruperts-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
          configuration
	  home-manager.darwinModules.home-manager  {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.verbose = true;
              home-manager.users.rupertdeese = homeconfig;
          }
      ];
    };
  };
}
