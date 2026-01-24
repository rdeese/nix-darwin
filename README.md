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

### 4. Download and Apply Configuration

Log into GitHub via Safari (use credentials from another device/password manager), then download this repo as a zip from GitHub and extract it:

```bash
mkdir -p ~/Documents
cd ~/Documents
unzip ~/Downloads/nix-darwin-master.zip
mv nix-darwin-master nix-darwin
cd nix-darwin
```

Apply the configuration (first time bootstraps nix-darwin):

```bash
nix run nix-darwin -- switch --flake .#<config-name>
```

Replace `<config-name>` with `rupert-mbp` or `homebase`.

### 5. Post-Install Setup

Once nix-darwin finishes, 1Password and other apps are installed.

**Sign into 1Password** to access your credentials.

**Set up GitHub CLI with SSH key:**

```bash
gh auth login
```

Select SSH and let it generate a key with a passphrase. Then add the passphrase to your keychain:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

**Enable login items** for Maccy (Preferences → Launch at login). Rectangle manages its own login item via the config.

**Convert the repo to a git clone:**

```bash
cd ~/Documents/nix-darwin
git init
git remote add origin git@github.com:rdeese/nix-darwin.git
git fetch
git reset origin/master
git branch -u origin/master
```

## Updating

```bash
cd ~/Documents/nix-darwin
git pull
darwin-rebuild switch --flake .#<config-name>
```

## Homebase Server Setup

The homebase config includes launchd services that require manual setup.

### light-controls (port 443)

```bash
cd ~/Documents
gh repo clone rdeese/light-controls
cd light-controls/standalone
sudo ./scripts/install-service.sh
```

Copy config files to `~/.lightctl/` (config.json, lights.json, curves.json, certs, etc.).

### tiny-iot (port 8000)

```bash
cd ~/Documents
gh repo clone rdeese/tiny-iot
cd tiny-iot/server
sudo ./scripts/install-service.sh
```

Copy `.env` file to `/usr/local/tinyiot/.env` with API keys.

### Verify Services

```bash
sudo launchctl list | grep -E 'lightctl|tinyiot'
tail -f /usr/local/lightctl/lightctl.out
tail -f /usr/local/tinyiot/tinyiot.log
```

## Troubleshooting

**"darwin-rebuild: command not found"** - Run `nix run nix-darwin -- switch --flake .#<config-name>`

**Service won't start** - Check logs at `/usr/local/lightctl/lightctl.err` or `/tmp/tinyiot.err`.

**Homebrew casks fail on Apple Silicon** - Install Rosetta: `softwareupdate --install-rosetta`

**Files conflict on first run** - Delete `/etc/nix/nix.custom.conf` and `/etc/zshenv` if they exist, then re-run.
