{
  description = "RHD system flake";

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
            "iterm2" # terminal
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
  homeconfig = {pkgs, lib, ...}: {
    home.username = "rupertdeese";
    home.homeDirectory = "/Users/rupertdeese";

    home.packages = [
      pkgs.bc
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

    programs.git = {
      enable = true;
      userName = "Rupert Deese";
      userEmail = "github@rh.deese.org";
      ignores = [ ".DS_Store" ];
      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        format.pretty = "%Cred%h %Cblue%ad %<(20)%Cgreen%cn %Creset%s";
        log.abbrevCommit = true;
        log.date = "format:%F $R";
        status.short = true;
        pull.ff = "only";
      };
      aliases = {
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
        QFEnter
        ale
        fastfold
        fzf-lua
        rest-nvim
        aider-nvim
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
#            plenary-nvim
#            mini-nvim
      ];
      extraConfig = ''
        " Turn off mouse
        set mouse=

        " use two spaces for indents, and make them actual spaces
        set shiftwidth=2
        set tabstop=2
        set autoindent
        set expandtab

        set number
        syntax enable
        set background=light
        colorscheme solarized8
        set nobackup
        filetype indent on
        filetype plugin on
        set noincsearch

        " try out syntax folding by default
        let php_folding=2
        set foldminlines=5
        autocmd Syntax * setlocal foldmethod=syntax
        autocmd Syntax * normal zR

        " Set <Leader> key
        let mapleader=','
        
        " reduce length of timeout waiting for rest of command
        set timeoutlen=300 " ms
        
        " Keep space around the cursor when scrolling
        set scrolloff=8
        
        " To encourage macro usage
        nnoremap <Space> @q
        
        " Shortcut for deleting into the null register ("_), to preserve clipboard
        " contents
        nnoremap -d "_d
        
        " change split opening to bottom and right instead of top and left
        set splitbelow
        set splitright

        " remap windowswap to a ctrl-w command
        let g:windowswap_map_keys = 0 "prevent default bindings
        nnoremap <silent> <C-W>y :call WindowSwap#EasyWindowSwap()<CR>

        " TODO: add back fzf stuff (using fzf-lua)

        " Grepper

        " Use rg over grep
        if executable('rg')
          set grepprg=rg\ --nogroup\ --nocolor
        endif

        " Use Grepper to search for the word under the cursor using rg
        " (replaces backwards identifier search)
        nnoremap # :Grepper -cword -noprompt<CR>

        " Use \ as a shortcut for :Grepper
        nnoremap \ :Grepper<CR>

        nmap gw <plug>(GrepperOperator)
        xmap gw <plug>(GrepperOperator)

        " let g:grepper.tools =
        "   \ ['rg', 'git', 'ack']
      '';
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
      plugins = with pkgs; [ gh awscli2 ];
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

      initContent = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
        '';
      shellAliases = {
        tmns = "tmux new-s -d -s";
        router = ''arp -a | grep $(route -n get default | awk '/gateway/{print $2}') | awk '{print $1}' | head -n 1'';
        history = "history 1";
      };

      initExtra = ''
        # Keymap
        bindkey -e

        # History
        HISTFILE="$HOME/.zsh_history"
        HISTSIZE=100000
        SAVEHIST=$HISTSIZE
        setopt INC_APPEND_HISTORY
        setopt HIST_IGNORE_DUPS
        setopt HIST_REDUCE_BLANKS
        setopt HIST_VERIFY

        # Kill autocorrect
        unsetopt CORRECT CORRECT_ALL

        __pretty_line() {
          # Needs 'bc' and 'tput' (ensure pkgs.bc is installed below)
          local OFFSET END LINE STUFF C
          OFFSET=$(bc <<< "16 + ($RANDOM % 36 + 1)*6")
          END=$(bc <<< "$OFFSET + 5")
          LINE=""
          for C in $(seq $OFFSET $END); do
            STUFF=$(printf ' %.0s' $(seq 1 $(bc <<< "$(tput cols)/12")))
            LINE+="\033[48;5;''${C}m''${STUFF}"
          done
          for C in $(seq $END $OFFSET); do
            STUFF=$(printf ' %.0s' $(seq 1 $(bc <<< "$(tput cols)/12")))
            LINE+="\033[48;5;''${C}m''${STUFF}"
          done
          LINE+=$(printf ' %.0s' $(seq 1 $(bc <<< "$(tput cols) - 12*($(tput cols)/12)")))
          echo -e "$LINE"
          tput sgr0
        }

        __clear_with_line () { clear; __pretty_line; zle redisplay }

        zle -N __clear_with_line
        bindkey '^L' __clear_with_line
      '';
    };

    programs.ssh = {
      enable = true;
      extraConfig = ''
        Host *
        AddKeysToAgent yes
        UseKeychain yes
        IdentityFile ~/.ssh/id_ed25519
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
