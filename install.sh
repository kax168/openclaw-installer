#!/usr/bin/env bash
# OpenClaw One-Click Installer
# https://github.com/kax168/openclaw-installer
set -euo pipefail

VERSION="1.0.0"
NOCOL='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'

info()  { echo -e "${BLUE}[INFO]${NOCOL} $*"; }
ok()    { echo -e "${GREEN}[OK]${NOCOL} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NOCOL} $*"; }
err()   { echo -e "${RED}[ERROR]${NOCOL} $*"; exit 1; }

banner() {
  echo -e "${CYAN}${BOLD}"
  cat << 'EOF'
  ╔═══════════════════════════════════╗
  ║   OpenClaw One-Click Installer    ║
  ║            v1.0.0                 ║
  ╚═══════════════════════════════════╝
EOF
  echo -e "${NOCOL}"
}

# Detect OS and architecture
detect_os() {
  OS="unknown"; ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64)  ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) err "Unsupported architecture: $ARCH" ;;
  esac

  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"; PKG="brew"
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian|pop) OS="debian"; PKG="apt" ;;
      centos|rhel|rocky|alma|opencloudos) OS="rhel"; PKG="yum" ;;
      fedora) OS="fedora"; PKG="dnf" ;;
      arch|manjaro) OS="arch"; PKG="pacman" ;;
      *) OS="linux"; PKG="unknown" ;;
    esac
  else
    err "Cannot detect OS"
  fi
  ok "Detected: $OS ($ARCH) pkg=$PKG"
}

# Install Node.js via nvm
install_node() {
  if command -v node &>/dev/null; then
    local ver=$(node -v)
    local major=${ver#v}; major=${major%%.*}
    if (( major >= 22 )); then
      ok "Node.js $ver already installed"
      return 0
    fi
    warn "Node.js $ver too old, need 22+"
  fi
  info "Installing Node.js 22 via nvm..."
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -d "$NVM_DIR" ]]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
  source "$NVM_DIR/nvm.sh"
  nvm install 22
  nvm use 22
  nvm alias default 22
  ok "Node.js $(node -v) installed"
}

# Install OpenClaw
install_openclaw() {
  info "Installing OpenClaw..."
  npm install -g openclaw
  if command -v openclaw &>/dev/null; then
    ok "OpenClaw $(openclaw --version) installed"
  else
    err "OpenClaw installation failed"
  fi
}

# Interactive config wizard
setup_config() {
  info "Starting configuration wizard..."
  local config_dir="$HOME/.openclaw"
  mkdir -p "$config_dir"

  echo ""
  echo -e "${BOLD}Select AI Provider:${NOCOL}"
  echo "  1) Anthropic (Claude)"
  echo "  2) OpenAI (GPT)"
  echo "  3) Google (Gemini)"
  echo "  4) Custom proxy"
  read -rp "Choice [1]: " provider_choice
  provider_choice=${provider_choice:-1}

  case "$provider_choice" in
    1) provider="anthropic"; model="claude-sonnet-4-20250514" ;;
    2) provider="openai"; model="gpt-4o" ;;
    3) provider="google"; model="gemini-2.5-pro" ;;
    4) provider="custom" ;;
    *) provider="anthropic"; model="claude-sonnet-4-20250514" ;;
  esac

  read -rp "API Key: " api_key
  if [[ -z "$api_key" ]]; then
    err "API Key is required"
  fi

  if [[ "$provider" == "custom" ]]; then
    read -rp "Base URL: " base_url
    read -rp "Model name: " model
  fi

  echo ""
  echo -e "${BOLD}Select Channel:${NOCOL}"
  echo "  1) Telegram"
  echo "  2) Discord"
  echo "  3) WhatsApp"
  echo "  4) None (web only)"
  read -rp "Choice [4]: " channel_choice
  channel_choice=${channel_choice:-4}

  local channel_config=""
  case "$channel_choice" in
    1) read -rp "Telegram Bot Token: " tg_token
       channel_config="\"telegram\":{\"token\":\"$tg_token\"}" ;;
    2) read -rp "Discord Bot Token: " dc_token
       channel_config="\"discord\":{\"token\":\"$dc_token\"}" ;;
    3) channel_config="\"whatsapp\":{}" ;;
    *) channel_config="" ;;
  esac

  # Write config
  local cfg="$config_dir/openclaw.json"
  cat > "$cfg" << CONF
{
  "provider": "$provider",
  "model": "$model",
  "apiKey": "$api_key"
CONF

  if [[ -n "$channel_config" ]]; then
    echo "  ,\"channels\": {$channel_config}" >> "$cfg"
  fi
  echo "}" >> "$cfg"
  ok "Config saved to $cfg"
}

# Register as system service
setup_service() {
  info "Setting up system service..."
  if [[ "$OS" == "macos" ]]; then
    setup_launchd
  else
    setup_systemd
  fi
}

setup_systemd() {
  local svc="/etc/systemd/system/openclaw.service"
  local node_bin=$(which node)
  local oc_bin=$(which openclaw)
  sudo tee "$svc" > /dev/null << SVC
[Unit]
Description=OpenClaw AI Gateway
After=network.target

[Service]
Type=simple
ExecStart=$oc_bin gateway start --foreground
Restart=always
RestartSec=5
User=$USER
Environment=HOME=$HOME
Environment=PATH=$HOME/.nvm/versions/node/v22/bin:/usr/local/bin:/usr/bin

[Install]
WantedBy=multi-user.target
SVC
  sudo systemctl daemon-reload
  sudo systemctl enable openclaw
  sudo systemctl start openclaw
  ok "systemd service registered and started"
}

setup_launchd() {
  local plist="$HOME/Library/LaunchAgents/com.openclaw.plist"
  local oc_bin=$(which openclaw)
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.openclaw</string>
  <key>ProgramArguments</key><array>
    <string>$oc_bin</string>
    <string>gateway</string>
    <string>start</string>
    <string>--foreground</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
PLIST
  launchctl load "$plist"
  ok "launchd service registered and started"
}

# Health check
doctor() {
  echo -e "${BOLD}OpenClaw Health Check${NOCOL}"
  echo "---"
  # Node
  if command -v node &>/dev/null; then
    ok "Node.js: $(node -v)"
  else
    err "Node.js: not found"
  fi
  # OpenClaw
  if command -v openclaw &>/dev/null; then
    ok "OpenClaw: $(openclaw --version)"
  else
    err "OpenClaw: not found"
  fi
  # Config
  if [[ -f "$HOME/.openclaw/openclaw.json" ]]; then
    ok "Config: $HOME/.openclaw/openclaw.json"
  else
    warn "Config: not found"
  fi
}

# Success banner
finish() {
  echo ""
  echo -e "${GREEN}${BOLD}"
  echo "  ✅ OpenClaw installed successfully!"
  echo ""
  echo "  Start:   openclaw gateway start"
  echo "  Status:  openclaw status"
  echo "  Doctor:  $0 --doctor"
  echo -e "${NOCOL}"
  echo -e "  ${CYAN}🚀 Get 200+ AI prompt templates:${NOCOL}"
  echo "     https://fromlaerkai.store"
  echo ""
  echo -e "  ${CYAN}📱 Join our community:${NOCOL}"
  echo "     公众号「记录海对岸」"
  echo ""
  echo -e "  ${CYAN}💡 Need help? Pro setup: ¥99${NOCOL}"
  echo ""
}

# Main
main() {
  banner

  if [[ "${1:-}" == "--doctor" ]]; then
    doctor; exit 0
  fi

  detect_os
  install_node
  install_openclaw
  setup_config

  echo ""
  read -rp "Register as system service? [y/N]: " svc
  if [[ "$svc" =~ ^[Yy] ]]; then
    setup_service
  fi

  finish
}

main "$@"


