{
  description = "Multi-machine nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Pin the devenv CLI to the last 1.x release. The gf repos commit a devenv.lock
    # whose module is pinned at a 1.x-era rev (ec805a5, 2025-12); a 2.x CLI (which
    # nixpkgs-unstable now ships) can't evaluate it — `git-hooks.configPath` is
    # missing — so every slot's `devenv up` dies before postgres starts. v1.11.2 is
    # the last 1.x release and matches the committed module. Do NOT follow nixpkgs
    # here: devenv's own pinned nixpkgs is what its cachix binary cache is built
    # against, so overriding it would force a from-source rebuild. (GEA-4077 tracks
    # the fleet-wide 1.x-vs-2.x decision.)
    devenv.url = "github:cachix/devenv/v1.11.2";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, determinate, devenv, ... }:
    let
      # Last 1.x devenv CLI, pinned in inputs above (matches the repos' committed
      # devenv.lock module; 2.x can't evaluate it). Both machines are aarch64.
      devenvCli = devenv.packages."aarch64-darwin".devenv;

      # Machine-specific parameters
      machines = {
        workstation = {
          hostname = "rupert-mbp";
          username = "rupertdeese";
          home = "/Users/rupertdeese";
        };
        homebase = {
          hostname = "homebase";
          username = "rhd";
          home = "/Users/rhd";
        };
      };

      # Shared system configuration (packages, system defaults, etc.)
      sharedConfiguration = { machine }: { pkgs, ... }: {
        environment.systemPackages =
          [
            pkgs.git
            pkgs.vim
            pkgs.neovim
            pkgs.htop
            pkgs.tmux
            pkgs.ripgrep
            pkgs.fzf
            pkgs.gh
            pkgs.kanata
            pkgs.flyctl
            devenvCli
            pkgs.uv
            pkgs.awscli2
            pkgs.ffmpeg
          ];

        # Some tools are intentionally NOT in nix or homebrew: they ship their own
        # self-updaters and lag in package managers, so we use their native installers.
        #   - Claude Code + CodeRabbit CLI  -> ~/.local/bin (self-updating)
        #   - Linear.app, Fathom.app        -> /Applications (self-updating Electron
        #       apps whose homebrew cask DMG URLs go stale and 404 on rebuild)
        # Their absence from the lists below is deliberate, not an oversight.

        homebrew = {
          enable = true;
          onActivation.cleanup = "uninstall";
          onActivation.upgrade = true;
          taps = [
            "steipete/tap"
            "hashicorp/tap"
            "mistertea/et"
          ];
          brews = [
            # network / dev CLIs
            "mosh"
            "railway"
            "stripe-cli"
            "cloudflare-wrangler"
            "steipete/tap/imsg"
            # data / docs / infra tools
            "duckdb"
            "pandoc"
            "git-crypt"
            "hashicorp/tap/terraform"
            "mise"
            "actionlint"
            "imessage-exporter"
            "mistertea/et/et"
            # build tooling (currently top-level installs; kept so a rebuild with
            # cleanup="uninstall" doesn't remove them — prune any you don't use)
            "cmake"
            "automake"
            "libtool"
            "pkgconf"
            "poppler"
            "curl"
            "libsodium"
          ];
          casks = [
            "docker-desktop"
            "google-chrome"
            "maccy"
            "rectangle"
            "1password"
            "1password-cli"
            "arc"
            "iterm2"
            "karabiner-elements"
            "slack"
            "zoom"
            "selfcontrol"
            "dbeaver-community"
            "loom"
            "nordvpn"
            "microsoft-excel"
            "raspberry-pi-imager"
            "tailscale-app"
            "transmission"
            "typora"
            "vlc"
            "gcloud-cli"
          ];
        };

        system.defaults.dock.persistent-apps = [
          { app = "/Applications/1Password.app"; }
          { app = "/Applications/Arc.app"; }
          { app = "/Applications/Linear.app"; }
          { app = "/Applications/iTerm.app"; }
          { app = "/Applications/Claude.app"; }
          { app = "/Applications/Slack.app"; }
          { app = "/System/Applications/Music.app"; }
          { spacer = { small = true; }; }
        ];

        system.keyboard = {
          enableKeyMapping = true;
          remapCapsLockToControl = true;
        };

        system.defaults.menuExtraClock.IsAnalog = true;
        system.defaults.dock.show-recents = false;
        system.defaults.dock.mru-spaces = false;
        system.defaults.dock.autohide = true;

        system.defaults.finder.AppleShowAllExtensions = true;
        system.defaults.finder.AppleShowAllFiles = true;
        system.defaults.finder.FXDefaultSearchScope = "SCcf";
        system.defaults.finder.NewWindowTarget = "Home";

        system.defaults.NSGlobalDomain.AppleEnableSwipeNavigateWithScrolls = false;
        system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
        system.defaults.NSGlobalDomain.NSAutomaticInlinePredictionEnabled = false;
        system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
        system.defaults.NSGlobalDomain.KeyRepeat = 2;
        system.defaults.NSGlobalDomain.AppleICUForce24HourTime = true;
        system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
        system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
        system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
        system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;

        system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;

        system.defaults.trackpad.Clicking = false;
        system.defaults.trackpad.TrackpadRightClick = true;
        system.defaults.trackpad.TrackpadThreeFingerDrag = true;
        system.defaults.NSGlobalDomain."com.apple.trackpad.scaling" = 3.0;

        system.defaults.screencapture.location = "~/Desktop";
        system.defaults.screencapture.type = "png";
        system.defaults.screencapture.disable-shadow = true;

        # Maccy clipboard manager settings
        system.defaults.CustomUserPreferences."org.p0deje.Maccy" = {
          showInStatusBar = false;
          showFooter = true;
          showSearch = true;
          showTitle = true;
          SUEnableAutomaticChecks = true;
          # Popup shortcut: Cmd+Shift+C
          "KeyboardShortcuts_popup" = ''{"carbonModifiers":4352,"carbonKeyCode":8}'';
        };

        # Rectangle window manager settings
        system.defaults.CustomUserPreferences."com.knollsoft.Rectangle" = {
          allowAnyShortcut = true;
          alternateDefaultShortcuts = true;
          hideMenubarIcon = true;
          launchOnLogin = true;
          subsequentExecutionMode = 3;
          unsnapRestore = 2;
          windowSnapping = 2;
          SUEnableAutomaticChecks = true;
          # Shortcuts (modifierFlags 786432 = Ctrl+Opt)
          bottomHalf = { keyCode = 38; modifierFlags = 786432; };
          topHalf = { keyCode = 40; modifierFlags = 786432; };
          leftHalf = { keyCode = 4; modifierFlags = 786432; };
          rightHalf = { keyCode = 37; modifierFlags = 786432; };
          maximize = { keyCode = 32; modifierFlags = 786432; };
          toggleTodo = { keyCode = 11; modifierFlags = 786432; };
          reflowTodo = { keyCode = 45; modifierFlags = 786432; };
        };

        nix.enable = false;

        determinateNix.customSettings = {
          trusted-users = ["root" machine.username];
        };

        system.configurationRevision = self.rev or self.dirtyRev or null;
        system.stateVersion = 6;

        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.config.allowUnfree = true;

        users.users.${machine.username} = {
          name = machine.username;
          home = machine.home;
        };

        system.primaryUser = machine.username;

        programs.zsh.enable = true;
        programs.direnv.enable = true;
        security.pam.services.sudo_local.touchIdAuth = true;

        networking.hostName = machine.hostname;
        networking.localHostName = machine.hostname;
        networking.computerName = machine.hostname;
      };

      # Homebase-specific configuration (services, sleep prevention)
      homebaseConfiguration = { machine }: { pkgs, config, ... }: {
        power.sleep.computer = "never";
        power.sleep.display = "never";
        power.sleep.harddisk = "never";

        # Disable all sleep for headless server with closed lid
        system.activationScripts.postActivation.text = ''
          pmset -a disablesleep 1
          pmset -a standby 0
          pmset -a powernap 0
          pmset -a autopoweroff 0
        '';

        # Light controls service (HTTPS on port 443)
        # TODO: Re-enable once lightctl is packaged with devenv/nix
        # launchd.daemons.lightctl = {
        #   serviceConfig = {
        #     Label = "com.lightctl";
        #     ProgramArguments = [
        #       "/usr/local/lightctl/.venv/bin/lightctl"
        #       "serve"
        #       "--host" "0.0.0.0"
        #       "--port" "443"
        #     ];
        #     WorkingDirectory = "/usr/local/lightctl";
        #     UserName = machine.username;
        #     GroupName = "staff";
        #     RunAtLoad = true;
        #     KeepAlive = true;
        #     StandardErrorPath = "/usr/local/lightctl/lightctl.err";
        #     StandardOutPath = "/usr/local/lightctl/lightctl.out";
        #     EnvironmentVariables = {
        #       HOME = machine.home;
        #     };
        #   };
        # };

        # Tiny IoT service (HTTP on port 8000)
        # TODO: Re-enable once tinyiot is working properly
        # launchd.daemons.tinyiot = {
        #   serviceConfig = {
        #     Label = "com.tinyiot.server";
        #     ProgramArguments = [
        #       "/usr/local/tinyiot/venv/bin/python"
        #       "/usr/local/tinyiot/main.py"
        #     ];
        #     WorkingDirectory = "/usr/local/tinyiot";
        #     UserName = machine.username;
        #     GroupName = "staff";
        #     RunAtLoad = true;
        #     KeepAlive = {
        #       SuccessfulExit = false;
        #     };
        #     ThrottleInterval = 5;
        #     StandardOutPath = "/usr/local/tinyiot/tinyiot.log";
        #     StandardErrorPath = "/usr/local/tinyiot/tinyiot.err";
        #     EnvironmentVariables = {
        #       PATH = "/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin";
        #       HOME = machine.home;
        #     };
        #   };
        # };
      };

      # Shared home-manager configuration
      sharedHomeConfig = { machine }: { pkgs, lib, ... }: {
        home.username = machine.username;
        home.homeDirectory = machine.home;

        home.packages = [
          pkgs.bc
        ];

        home.file.".config/kanata/kanata.kbd".source = ./kanata.kbd;

        home.stateVersion = "25.05";

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
            fidget-nvim
            nvim-nio
            nvim-lspconfig
            nvim-treesitter.withAllGrammars
          ];
          extraLuaPackages = ps: with ps; [
            mimetypes
            xml2lua
          ];
          extraConfig = builtins.readFile ./nvim-vimrc.vim;
          extraLuaConfig = builtins.readFile ./nvim-config.lua;
        };

        programs.tmux = {
          enable = true;
          prefix = "C-u";
          keyMode = "vi";
          baseIndex = 1;
          terminal = "tmux-256color";
          shell = lib.getExe pkgs.zsh;
          extraConfig = ''
            unbind C-b
            bind C-u send-prefix
            bind-key s choose-tree -Nsw -O name
            bind h select-pane -L
            bind j select-pane -D
            bind k select-pane -U
            bind l select-pane -R
            setw -g monitor-activity on
            set -g mouse on
            set -g status-left " #S "
            set -g status-right " %H:%M %a %d-%b-%y "
            set -g status-left-length 20
            setw -g window-status-format " #I: #W #F "
            setw -g window-status-current-format " #I: #W #F "
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
          clock24 = true;
          plugins = with pkgs; [
            tmuxPlugins.resurrect
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
          shellAliases = {
            tmns = "tmux new-s -d -s";
            router = ''arp -a | grep $(route -n get default | awk '/gateway/{print $2}') | awk '{print $1}' | head -n 1'';
            history = "history 1";
            rhd-keyboard = "sudo kanata -c ~/.config/kanata/kanata.kbd";
            unlock-keychain = "security unlock-keychain ~/Library/Keychains/login.keychain-db";
          };
          envExtra = ''
            eval "$(/opt/homebrew/bin/brew shellenv)"
            export PATH="$HOME/.local/bin:$PATH"
          '';
          initContent = builtins.readFile ./zsh-extra.sh;
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

      # Helper to build a darwin system
      mkDarwinSystem = { machine, extraModules ? [] }:
        nix-darwin.lib.darwinSystem {
          modules = [
            determinate.darwinModules.default
            (sharedConfiguration { inherit machine; })
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.verbose = true;
              home-manager.users.${machine.username} = sharedHomeConfig { inherit machine; };
            }
          ] ++ extraModules;
        };

    in
    {
      # Workstation: primary development machine
      darwinConfigurations."rupert-mbp" = mkDarwinSystem {
        machine = machines.workstation;
        extraModules = [
          {
            home-manager.users.${machines.workstation.username}.programs.zsh.envExtra = ''
              export GEARFLOW_WORKSPACE=~/Documents/Gearflow
            '';
          }
        ];
      };

      # Homebase: server machine running smart home services
      darwinConfigurations."homebase" = mkDarwinSystem {
        machine = machines.homebase;
        extraModules = [
          (homebaseConfiguration { machine = machines.homebase; })
        ];
      };

      # Backwards compatibility alias
      darwinConfigurations."Ruperts-MacBook-Pro" =
        self.darwinConfigurations."rupert-mbp";
    };
}
