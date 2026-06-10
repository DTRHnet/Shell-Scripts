#!/bin/bash
# =============================================================================
# Kali Linux Live USB - Autonomous Dev Tools Installer (v2)
# Installs: Node.js LTS, GitHub CLI (gh), Vercel CLI, Google Antigravity IDE
# Features: Progress bar simulation, --debug mode, colored output
# =============================================================================

set -euo pipefail

# ====================== Configuration ======================
DEBUG_MODE=false
if [[ "${1:-}" == "--debug" ]]; then
    DEBUG_MODE=true
    echo -e "\e[33m🔧 DEBUG MODE ENABLED - Extreme verbosity activated\e[0m"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✅ SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        echo -e "${YELLOW}[DEBUG]${NC} $1"
    fi
}

# Simple progress bar function
progress_bar() {
    local width=50
    local percent=$1
    local completed=$((percent * width / 100))
    local remaining=$((width - completed))
    printf "\r${BLUE}[${GREEN}%-${completed}s${NC}${RED}%-${remaining}s${NC}] %3d%%${NC}" "" "" "$percent"
}

# ====================== Start ======================
echo "================================================================"
echo "🚀 Kali Linux Dev Tools Installer v2"
echo "Target: Node.js + gh CLI + Vercel CLI + Antigravity IDE (x64)"
echo "Mode: ${DEBUG_MODE:+DEBUG }Autonomous | Verbose"
echo "================================================================"

debug "Script started at $(date)"

# Update system
log "Updating package lists..."
sudo apt update -qq
progress_bar 10

sudo apt upgrade -y -qq
progress_bar 20
success "System packages updated"

# Check command helper
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Node.js via NodeSource
log "Installing Node.js (LTS via NodeSource)..."
if ! command_exists node; then
    debug "Adding NodeSource repository..."
    sudo apt install -y curl ca-certificates gnupg
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    success "Node.js installed: $(node --version)"
else
    success "Node.js already installed: $(node --version)"
fi
progress_bar 40

# 2. GitHub CLI
log "Installing GitHub CLI (gh)..."
if ! command_exists gh; then
    debug "Setting up official GitHub CLI repository..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update -qq
    sudo apt install gh -y
    success "GitHub CLI installed: $(gh --version)"
else
    success "GitHub CLI already installed: $(gh --version)"
fi
progress_bar 60

# 3. Vercel CLI
log "Installing Vercel CLI..."
if command_exists npm; then
    if ! command_exists vercel; then
        debug "Running: npm install -g vercel"
        sudo npm install -g vercel --loglevel=error
        success "Vercel CLI installed: $(vercel --version)"
    else
        success "Vercel CLI already installed: $(vercel --version)"
    fi
else
    error "npm not found. Skipping Vercel CLI."
fi
progress_bar 80

# 4. Antigravity IDE (Google)
log "Installing Google Antigravity IDE..."
if ! command_exists antigravity; then
    debug "Adding Antigravity APT repository..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
        sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
    
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
        sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null

    debug "Updating apt cache for Antigravity..."
    sudo apt update -qq
    
    debug "Installing antigravity package..."
    sudo apt install -y antigravity
    success "Antigravity IDE installed"
else
    success "Antigravity IDE already installed"
fi
progress_bar 100
echo ""

# ====================== Final Summary ======================
echo "================================================================"
echo -e "${GREEN}🎉 Installation Completed Successfully!${NC}"
echo "================================================================"

echo "Installed/Verified:"
echo "• Node.js     : $(node --version 2>/dev/null || echo 'Not found')"
echo "• npm         : $(npm --version 2>/dev/null || echo 'Not found')"
echo "• GitHub CLI  : $(gh --version 2>/dev/null || echo 'Not found')"
echo "• Vercel CLI  : $(vercel --version 2>/dev/null || echo 'Not found')"
echo "• Antigravity : $(command -v antigravity >/dev/null && echo 'Installed' || echo 'Not found')"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "   gh auth login"
echo "   vercel login"
echo "   antigravity --help"
echo ""
echo "Run this script again with './install-dev-tools.sh --debug' for maximum verbosity."
echo "Enjoy your enhanced Kali Live environment! 🚀"

debug "Script finished at $(date)"
