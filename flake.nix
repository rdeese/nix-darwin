{
  description = "RHD system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    claude-code.url = "github:sadjow/claude-code-nix";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # loads 1password-cli and shell plugins
    _1password-shell-plugins.url = "github:1Password/shell-plugins";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, nix-ai-tools, claude-code, determinate, ... }:
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
          pkgs.fzf # fuzzy finder
          pkgs.gh # github
          pkgs.kanata # keyboard remapper
          claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code # claude CLI AI
          pkgs.devenv # managing repo-specific nix configs
          pkgs.flyctl # for manipulating GF infrastructure
        ] ++ (with nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}; [
          coderabbit-cli
        ]);

      homebrew = {
        enable = true;

        onActivation.cleanup = "uninstall";
        onActivation.upgrade = true;

        taps = [];
        brews = [
            "railway" # app deploys cli
            "stripe-cli"
        ];
        casks = [
            "maccy" # clipboard history
            "rectangle" # window management
            "linear-linear" # project management
            "slack" # team communication
            "1password" # password manager
            "arc" # browser
            "iterm2" # terminal
            "karabiner-elements" # keyboard remapper, dependency of system package kanata
            "zoom" # video conferencing... sigh
            "selfcontrol" # site blocking
            "dbeaver-community" # database client
            "loom" # screen recording
            "nordvpn" # vpn
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
        app = "/Applications/iTerm.app";
      }
      {
        app = "/Applications/Slack.app";
      }
      {
        spacer = {
          small = true;
        };
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

      system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;

      system.defaults.dock.autohide = true;

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

      # Custom nix settings written to /etc/nix/nix.custom.conf
      determinate-nix.customSettings = {
        trusted-users = "root rupertdeese";
      };

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

      # autoruns .envrc on directory entry. primarily for use with devenv
      programs.direnv.enable = true;

      # Enables use of touchid for sudo
      security.pam.services.sudo_local.touchIdAuth = true;
    };
  homeconfig = {pkgs, lib, ...}: {
    home.username = "rupertdeese";
    home.homeDirectory = "/Users/rupertdeese";

    home.packages = [
      pkgs.bc
    ];

    home.sessionVariables = {
      # VISUAL is set by programs.neovim.defaultEditor = true
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

    programs.git = {
      enable = true;
      ignores = [ ".DS_Store" ];
      settings = {
        user = {
          name = "Rupert Deese";
          email = "github@rh.deese.org";
        };
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        format.pretty = "%Cred%h %Cblue%ad %<(20)%Cgreen%cn %Creset%s";
        log.abbrevCommit = true;
        log.date = "format:%F $R";
        status.short = true;
        pull.ff = "only";
        alias = {
          s = "status -s";
          l = "log --graph";
          co = "checkout";
          cm = "commit -m";
          d = "diff";
          ds = "diff --staged";
          tackon = "commit --amend --no-edit";
          p = "push";
          puo = "push -u origin";
        };
      };
    };

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins = with pkgs.vimPlugins; [
        vim-solarized8
        vim-fugitive
        vim-rhubarb
        vim-eunuch
        vim-repeat
        vim-surround
        vim-windowswap
        vim-grepper
        nvim-bqf
        ale
        fastfold
        fzf-lua
        rest-nvim
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
#            plenary-nvim
#            mini-nvim
      ];
      extraConfig = builtins.readFile ./nvim-vimrc.vim;
      extraLuaConfig = builtins.readFile ./nvim-config.lua;
    };

    programs.tmux = {
      enable = true;

      # Prefix: Ctrl-u (overrides the module's "shortcut" helper)
      prefix = "C-u";

      # vi bindings for copy/status prompts
      keyMode = "vi";

      # Window indexing starts at 1
      baseIndex = 1;

      # TERM seen inside tmux
      terminal = "tmux-256color";

      # Use zsh, and start it as a *login* shell in panes
      shell = lib.getExe pkgs.zsh;
      extraConfig = ''
        # Send prefix when pressing C-u again; drop default C-b
        unbind C-b
        bind C-u send-prefix

        # Tree without preview, sessions/windows collapsed, sort by name
        bind-key s choose-tree -Nsw -O name

        # Start login shell in every pane (keeps your ~/.zprofile logic)
        # REMOVED following the reasoning that nix should avoid any nastiness
        # that previously required starting a login shell always
        # set -g default-command "${lib.getExe pkgs.zsh} -l"

        # Move around panes with hjkl
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Monitor activity in all windows
        setw -g monitor-activity on

        # Enable mouse support (scrolling, selecting, copying)
        set -g mouse on

        # Status bar
        set -g status-left " #S "
        set -g status-right " %H:%M %a %d-%b-%y "
        set -g status-left-length 20
        setw -g window-status-format " #I: #W #F "
        setw -g window-status-current-format " #I: #W #F "

        #### Colors (Solarized light-ish)
        set -g status-bg white
        set -g status-fg yellow
        setw -g window-status-style bg=default,fg=brightyellow
        setw -g window-status-current-style bg=default,fg=brightred
        set -g pane-border-style fg=white
        set -g pane-active-border-style fg=brightcyan
        set -g message-style fg=brightred,bg=white
        set -g display-panes-active-colour blue
        set -g display-panes-colour brightred
        setw -g clock-mode-colour green
        setw -g window-status-bell-style fg=white,bg=red
      '';

      # 24h clock for tmux's built-in clock
      clock24 = true;

      # Plugins (no TPM needed — HM wires them up)
      plugins = with pkgs; [
        tmuxPlugins.resurrect
      ];
    };

    imports = [ inputs._1password-shell-plugins.hmModules.default ];
    programs._1password-shell-plugins = {
      # enable 1Password shell plugins for bash, zsh, and fish shell
      enable = true;
      # the specified packages as well as 1Password CLI will be
      # automatically installed and configured to use shell plugins
      plugins = with pkgs; [
        # gh
        awscli2
      ];
    };

    programs.starship = {
      enable = false;
      settings = {
        format = "$directory$git_branch$git_status$character";
        directory = { style = "bold magenta"; truncate_to_repo = true; };
        git_branch = { format = ":%F{green}[$branch]($style)"; };
        git_status = {
          format = "[$all_status$ahead_behind]($style)";
          style = "yellow";
        };
        character = {
          success_symbol = "[ λ.](green)";
          error_symbol = "[ λ.](red)";
        };
      };
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;

      # SPECULATIVE addition via CGPT to make sure non-login shells
      # get home manager driven env vars
      # initContentFirst = ''
      #   # Make sure tmux/non-login shells see HM session vars
      #   if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
      #     . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      #   fi
      # '';

      shellAliases = {
        tmns = "tmux new-s -d -s";
        router = ''arp -a | grep $(route -n get default | awk '/gateway/{print $2}') | awk '{print $1}' | head -n 1'';
        history = "history 1";
      };

      initContent = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
      '' + builtins.readFile ./zsh-extra.sh;
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        identityFile = "~/.ssh/id_ed25519";
        addKeysToAgent = "yes";
        extraOptions = {
          UseKeychain = "yes";
        };
      };
    };
  };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Ruperts-MacBook-Pro
    darwinConfigurations."Ruperts-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        determinate.darwinModules.default
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
