# nix-darwin

Multi-machine nix-darwin configuration for macOS.

## Machines

| Config | Hostname | Username | Description |
|--------|----------|----------|-------------|
| `rupert-mbp` | rupert-mbp | rupertdeese | Primary workstation |
| `homebase` | homebase | rhd | Home server (smart home services) |

## Bootstrap a New Mac

### 1. Complete macOS Setup

Create your user account through the macOS setup assistant. Note your username (`whoami` in Terminal).

### 2. Install Determinate Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Restart Terminal after installation.

### 3. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 4. Install 1Password and Get Credentials

```bash
brew install --cask 1password
```

Open 1Password, sign in, and retrieve your GitHub credentials.

### 5. Authenticate with GitHub

```bash
nix run nixpkgs#gh -- auth login
```

### 6. Clone This Repo

```bash
mkdir -p ~/Documents
nix run nixpkgs#gh -- repo clone rdeese/nix-darwin ~/Documents/nix-darwin
cd ~/Documents/nix-darwin
```

### 7. Apply Configuration

First time (bootstraps nix-darwin):

```bash
nix run nix-darwin -- switch --flake .#<config-name>
```

Future updates:

```bash
darwin-rebuild switch --flake .#<config-name>
```

Replace `<config-name>` with `rupert-mbp` or `homebase`.

## Homebase Server Setup

The homebase config includes launchd services that require manual setup.

### light-controls (port 443)

```bash
cd ~/Documents
gh repo clone rdeese/light-controls
cd light-controls/standalone
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

sudo mkdir -p /usr/local/lightctl
sudo cp -r .venv src static pyproject.toml /usr/local/lightctl/
sudo chown -R rhd:staff /usr/local/lightctl
```

### tiny-iot (port 8000)

```bash
cd ~/Documents
gh repo clone rdeese/tiny-iot
cd tiny-iot/server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env to add API keys
```

### Verify Services

```bash
sudo launchctl list | grep -E 'lightctl|tinyiot'
tail -f /usr/local/lightctl/lightctl.out
tail -f /tmp/tinyiot.log
```

## Updating

```bash
cd ~/Documents/nix-darwin
git pull
darwin-rebuild switch --flake .#<config-name>
```

## Troubleshooting

**"darwin-rebuild: command not found"** - Run the bootstrap command from step 7.

**Service won't start** - Check logs at `/usr/local/lightctl/lightctl.err` or `/tmp/tinyiot.err`.

**Homebrew casks fail on Apple Silicon** - Install Rosetta: `softwareupdate --install-rosetta`
