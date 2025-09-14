{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
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
	      "1password-cli" # need to experiment with this!
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
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Ruperts-MacBook-Pro
    darwinConfigurations."Ruperts-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
