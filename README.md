# nix-darwin

Multi-machine nix-darwin configuration for macOS.

## Machines

| Config | Hostname | Username | Role |
|--------|----------|----------|------|
| `rupert-mbp` | rupert-mbp.local | rupertdeese | Primary workstation |
| `homebase` | homebase.local | rhd | Server (smart home services) |
| `minimal` | (customize) | (customize) | Base config for other machines |

## Prerequisites

### Install Determinate Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Bootstrap (New Machine)

1. Clone this repo:
   ```bash
   cd ~/Documents
   git clone https://github.com/rdeese/nix-darwin.git
   cd nix-darwin
   ```

2. Bootstrap nix-darwin (first time only):
   ```bash
   # For workstation:
   nix run nix-darwin -- switch --flake .#rupert-mbp

   # For homebase server:
   nix run nix-darwin -- switch --flake .#homebase

   # For a minimal setup (edit flake.nix first to add your machine):
   nix run nix-darwin -- switch --flake .#minimal
   ```

3. Future updates:
   ```bash
   darwin-rebuild switch --flake .#<config-name>
   ```

## Adding a New Machine

1. Add an entry to the `machines` map in `flake.nix`:
   ```nix
   machines = {
     # ... existing machines ...
     mymachine = {
       hostname = "mymachine";
       username = "myuser";
       home = "/Users/myuser";
     };
   };
   ```

2. Add a darwinConfiguration:
   ```nix
   # Minimal (base packages + dotfiles only):
   darwinConfigurations."mymachine" = mkDarwinSystem {
     machine = machines.mymachine;
   };

   # With workstation apps (Linear, Slack, etc.):
   darwinConfigurations."mymachine" = mkDarwinSystem {
     machine = machines.mymachine;
     extraModules = [ workstationApps ];
   };
   ```

3. Bootstrap: `nix run nix-darwin -- switch --flake .#mymachine`

## Homebase Server Setup

The homebase config includes launchd services for smart home automation. These services require manual setup of their codebases:

### 1. Unload Existing Services (if migrating)

```bash
sudo launchctl unload /Library/LaunchDaemons/com.lightctl.plist 2>/dev/null
launchctl unload ~/Library/LaunchAgents/com.tinyiot.server.plist 2>/dev/null
```

### 2. Set Up light-controls

light-controls runs on port 443 (HTTPS) for smart bulb control.

```bash
# Clone the repo
cd ~/Documents
git clone https://github.com/rdeese/light-controls.git

# Set up the service directory
cd light-controls/standalone
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Copy to system location (service runs from /usr/local/lightctl)
sudo mkdir -p /usr/local/lightctl
sudo cp -r .venv src static pyproject.toml /usr/local/lightctl/
sudo chown -R rhd:staff /usr/local/lightctl

# Copy .env if needed
cp .env /usr/local/lightctl/.env
```

### 3. Set Up tiny-iot

tiny-iot runs on port 8000 for M5Stack ATOM Echo IoT devices.

```bash
# Clone the repo
cd ~/Documents
git clone https://github.com/rdeese/tiny-iot.git

# Set up Python environment
cd tiny-iot/server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env to add API keys (OPENAI_API_KEY, ANTHROPIC_API_KEY)
```

### 4. Apply the nix-darwin config

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
# Stop a service
sudo launchctl stop com.lightctl
sudo launchctl stop com.tinyiot.server

# Start a service
sudo launchctl start com.lightctl
sudo launchctl start com.tinyiot.server

# View service status
sudo launchctl print system/com.lightctl
sudo launchctl print system/com.tinyiot.server
```

## What's Included

### All Machines (Base)

**Nix packages:** git, vim, neovim, htop, tmux, ripgrep, fzf, gh, kanata, claude-code, devenv

**Homebrew:** maccy, rectangle, 1password, arc, iterm2, karabiner-elements

**Home Manager:** zsh config, git aliases, neovim with plugins, tmux config, ssh config

**System defaults:** caps lock → control, 24h time, dock autohide, finder shows all files

### Workstation Additions

**Homebrew casks:** linear, slack, zoom, selfcontrol, dbeaver-community, loom, nordvpn

**Homebrew brews:** railway, stripe-cli, cloudflare-wrangler

### Homebase Additions

**Services:** lightctl (port 443), tinyiot (port 8000)

**Power management:** sleep disabled (computer, display, harddisk)

## Troubleshooting

### "darwin-rebuild: command not found"

Run the bootstrap command again:
```bash
nix run nix-darwin -- switch --flake .#<config-name>
```

### Service won't start

Check the logs:
```bash
# lightctl
cat /usr/local/lightctl/lightctl.err

# tinyiot
cat /tmp/tinyiot.err
```

Common issues:
- Missing `.env` file with API keys
- Python venv not set up
- Code not cloned to expected path

### Homebrew casks fail to install

Some casks require Rosetta on Apple Silicon:
```bash
softwareupdate --install-rosetta
```

### SSH key passphrase prompts

If git operations hang waiting for passphrase:
```bash
ssh-add ~/.ssh/id_ed25519
```
