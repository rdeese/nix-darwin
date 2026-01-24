# nix-darwin

Multi-machine nix-darwin configuration for macOS.

## Machines

| Config | Hostname | Username | Role |
|--------|----------|----------|------|
| `rupert-mbp` | rupert-mbp.local | rupertdeese | Primary workstation |
| `homebase` | homebase.local | rhd | Server (smart home services) |

## Bootstrap (New Machine)

### 1. Set Up macOS

Complete the macOS setup assistant to create your user account. Note your:
- **Username**: shown in Terminal with `whoami`
- **Home directory**: usually `/Users/<username>`

> **Note**: nix-darwin does not create users - your macOS user must exist first.

### 2. Install Determinate Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Close and reopen Terminal after installation.

### 3. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 4. Clone This Repo

Since this is a private repo, authenticate with GitHub first using browser OAuth:

```bash
# Run gh temporarily via nix, authenticate in browser
nix run nixpkgs#gh -- auth login

# Clone the repo
nix run nixpkgs#gh -- repo clone rdeese/nix-darwin ~/Documents/nix-darwin
cd ~/Documents/nix-darwin
```

### 5. Add Your Machine (if new)

If this machine isn't already in the flake, add it:

1. Edit `flake.nix` and add an entry to `machines`:
   ```nix
   machines = {
     workstation = { ... };
     homebase = { ... };
     # Add your machine:
     mymachine = {
       hostname = "mymachine";      # Network name (mymachine.local)
       username = "myuser";         # macOS username (from whoami)
       home = "/Users/myuser";      # Home directory
     };
   };
   ```

2. Add a darwinConfiguration at the bottom:
   ```nix
   # Base config only:
   darwinConfigurations."mymachine" = mkDarwinSystem {
     machine = machines.mymachine;
   };

   # Or with workstation apps (Linear, Slack, etc.):
   darwinConfigurations."mymachine" = mkDarwinSystem {
     machine = machines.mymachine;
     extraModules = [ workstationApps ];
   };
   ```

### 6. Apply Configuration

```bash
cd ~/Documents/nix-darwin

# First time (bootstraps nix-darwin):
nix run nix-darwin -- switch --flake .#<config-name>

# Future updates:
darwin-rebuild switch --flake .#<config-name>
```

## Homebase Server Setup

The homebase config includes launchd services for smart home automation. These require manual setup:

### 1. Unload Existing Services (if migrating)

```bash
sudo launchctl unload /Library/LaunchDaemons/com.lightctl.plist 2>/dev/null
launchctl unload ~/Library/LaunchAgents/com.tinyiot.server.plist 2>/dev/null
```

### 2. Set Up light-controls

light-controls runs on port 443 (HTTPS) for smart bulb control.

```bash
# Clone the repo (after gh auth above)
cd ~/Documents
gh repo clone rdeese/light-controls

# Set up Python environment
cd light-controls/standalone
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Copy to system location (service runs from /usr/local/lightctl)
sudo mkdir -p /usr/local/lightctl
sudo cp -r .venv src static pyproject.toml /usr/local/lightctl/
sudo chown -R rhd:staff /usr/local/lightctl

# Copy .env if you have one
cp .env /usr/local/lightctl/.env 2>/dev/null || echo "No .env to copy"
```

### 3. Set Up tiny-iot

tiny-iot runs on port 8000 for M5Stack ATOM Echo IoT devices.

```bash
cd ~/Documents
gh repo clone rdeese/tiny-iot

cd tiny-iot/server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env to add API keys (OPENAI_API_KEY, ANTHROPIC_API_KEY)
```

### 4. Apply Configuration

```bash
cd ~/Documents/nix-darwin
nix run nix-darwin -- switch --flake .#homebase
```

### 5. Verify Services

```bash
# Check services are loaded
sudo launchctl list | grep lightctl
sudo launchctl list | grep tinyiot

# Check logs
tail -f /usr/local/lightctl/lightctl.out
tail -f /tmp/tinyiot.log
```

### Service Management

```bash
# Stop/start services
sudo launchctl stop com.lightctl
sudo launchctl start com.lightctl
sudo launchctl stop com.tinyiot.server
sudo launchctl start com.tinyiot.server
```

## What's Included

### All Machines (Base)

**Nix packages:** git, vim, neovim, htop, tmux, ripgrep, fzf, gh, kanata, claude-code, devenv, coderabbit-cli

**Homebrew casks:** maccy, rectangle, 1password, arc, iterm2, karabiner-elements

**Home Manager:** zsh config, git aliases, neovim with plugins, tmux config, ssh config

**System defaults:** caps lock → control, 24h time, dock autohide, finder shows all files

### Workstation Apps (optional module)

**Homebrew casks:** linear, slack, zoom, selfcontrol, dbeaver-community, loom, nordvpn

**Homebrew brews:** railway, stripe-cli, cloudflare-wrangler, flyctl

**Dock:** 1Password, Arc, Linear, iTerm, Slack

### Homebase Additions

**Services:** lightctl (port 443), tinyiot (port 8000)

**Power management:** sleep disabled

## Troubleshooting

### "darwin-rebuild: command not found"

Run the bootstrap command:
```bash
nix run nix-darwin -- switch --flake .#<config-name>
```

### Service won't start

Check logs:
```bash
cat /usr/local/lightctl/lightctl.err   # lightctl
cat /tmp/tinyiot.err                    # tinyiot
```

Common issues:
- Missing `.env` file with API keys
- Python venv not set up
- Code not at expected path

### Homebrew casks fail

Some casks need Rosetta on Apple Silicon:
```bash
softwareupdate --install-rosetta
```

### Git clone fails

Re-authenticate with GitHub:
```bash
gh auth login
```
