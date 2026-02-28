#!/usr/bin/env bash
# detect.sh - OS/Architecture Detection
# Part of OpenClaw Installer

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

detect_os() {
    local os=""
    case "$(uname -s)" in
        Linux*)  os="linux" ;;
        Darwin*) os="macos" ;;
        MINGW*|MSYS*|CYGWIN*) os="windows" ;;
        *) os="unknown" ;;
    esac
    echo "$os"
}

detect_arch() {
    local arch=""
    case "$(uname -m)" in
        x86_64|amd64)  arch="x64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l)        arch="armv7" ;;
        *) arch="unknown" ;;
    esac
    echo "$arch"
}

detect_distro() {
    if [[ "$(detect_os)" != "linux" ]]; then
        echo "none"
        return
    fi
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian) echo "debian" ;;
            centos|rhel|fedora|rocky|alma) echo "rhel" ;;
            arch|manjaro) echo "arch" ;;
            alpine) echo "alpine" ;;
            *) echo "$ID" ;;
        esac
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v brew &>/dev/null; then
        echo "brew"
    elif command -v apk &>/dev/null; then
        echo "apk"
    else
        echo "unknown"
    fi
}

print_system_info() {
    local os=$(detect_os)
    local arch=$(detect_arch)
    local distro=$(detect_distro)
    local pkg=$(detect_pkg_manager)
    echo -e "${BLUE}System Detection:${NC}"
    echo -e "  OS:       ${GREEN}${os}${NC}"
    echo -e "  Arch:     ${GREEN}${arch}${NC}"
    echo -e "  Distro:   ${GREEN}${distro}${NC}"
    echo -e "  Package:  ${GREEN}${pkg}${NC}"
}
