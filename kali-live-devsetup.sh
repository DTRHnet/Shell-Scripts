#!/bin/bash
# =============================================================================
# Kali Linux Live USB - FULL Dev + Local LLM Installer (v4.3)
# FIXED: unbound variable $2 error
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✅ SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[❌ ERROR]${NC} $1"; }

# ====================== TUI SELECTOR ======================
select_install_location() {
    log "Installing whiptail for TUI..."
    sudo apt update -qq
    sudo apt install -y whiptail 

    log "Scanning disks and partitions..."
    TMP_FILE=$(mktemp)

    # List disks and partitions bigger than ~1GB
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE -r -n --bytes | \
        awk '$3 ~ /^(disk|part)$/ && $2+0 > 1000000000' > "$TMP_FILE"

    MAPFILE=()
    while IFS= read -r line; do
        NAME=$(echo "$line" | awk '{print $1}')
        SIZE_RAW=$(echo "$line" | awk '{print $2}')
        SIZE=$(numfmt --to=iec "$SIZE_RAW" 2>/dev/null || echo "$SIZE_RAW")
        TYPE=$(echo "$line" | awk '{print $3}')
        MOUNT=$(echo "$line" | awk '{print $4}')
        
        DISPLAY="${NAME}  |  ${SIZE}  |  ${TYPE}  |  ${MOUNT:-unmounted}"
        MAPFILE+=("$NAME" "$DISPLAY")
    done < "$TMP_FILE"
    rm -f "$TMP_FILE"

    if [ ${#MAPFILE[@]} -eq 0 ]; then
        error "No suitable partitions found!"
        echo "Current disks:"
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
        exit 1
    fi

    CHOICE=$(whiptail --title "Select Target for Ollama Models" \
        --menu "Choose partition with enough space (NOT the Live USB!)" \
        22 110 12 "${MAPFILE[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$CHOICE" ]; then
        error "No selection. Exiting."
        exit 1
    fi

    DEVICE="/dev/$CHOICE"
    MOUNT_POINT="/mnt/ollama_data"

    log "Selected: $DEVICE"

    sudo mkdir -p "$MOUNT_POINT"

    if mountpoint -q "$MOUNT_POINT"; then
        sudo umount "$MOUNT_POINT" || true
    fi

    log "Mounting $DEVICE..."
    sudo mount "$DEVICE" "$MOUNT_POINT" 2>/dev/null || \
    sudo mount -o rw,exec,users "$DEVICE" "$MOUNT_POINT" || {
        error "Mount failed!"
        echo "Tip: Use gparted to format the partition as ext4, then run script again."
        exit 1
    }

    success "Mounted $DEVICE → $MOUNT_POINT"
    export OLLAMA_MODELS="$MOUNT_POINT"
    echo "export OLLAMA_MODELS=$MOUNT_POINT" | sudo tee /etc/profile.d/ollama.sh > /dev/null
}

# ====================== MAIN INSTALLATION ======================
echo "================================================================"
echo "🚀 Kali Linux FULL Dev + Local LLM Installer v4.3"
echo "================================================================"

select_install_location

# System update
log "Updating package lists..."
sudo apt update -qq

# Node.js
log "Installing Node.js LTS..."
if ! command -v node >/dev/null 2>&1; then
    sudo apt install -y curl ca-certificates gnupg
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    success "Node.js: $(node --version)"
fi

# GitHub CLI
log "Installing GitHub CLI..."
if ! command -v gh >/dev/null 2>&1; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update -qq && sudo apt install gh -y
    success "GitHub CLI installed"
fi

# Vercel CLI
log "Installing Vercel CLI..."
if command -v npm >/dev/null 2>&1 && ! command -v vercel >/dev/null 2>&1; then
    sudo npm install -g vercel --loglevel=error
    success "Vercel CLI installed"
fi

# Antigravity
log "Installing Antigravity IDE..."
if ! command -v antigravity >/dev/null 2>&1; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null
    sudo apt update -qq
    sudo apt install -y antigravity
    success "Antigravity IDE installed"
fi

# Ollama
log "Installing Ollama..."
if ! command -v ollama >/dev/null 2>&1; then
    curl -fsSL https://ollama.com/install.sh | sh
    success "Ollama installed"
fi

# Start Ollama
log "Starting Ollama on external storage..."
pkill ollama || true
OLLAMA_MODELS="$MOUNT_POINT" ollama serve >/dev/null 2>&1 &
sleep 6

# Pull model
log "Downloading coding model (may take time)..."
MODEL="qwen2.5-coder:7b"
OLLAMA_MODELS="$MOUNT_POINT" ollama pull "$MODEL" || {
    MODEL="qwen2.5-coder:3b"
    OLLAMA_MODELS="$MOUNT_POINT" ollama pull "$MODEL"
}

# Create optimized model
mkdir -p ~/.ollama
cat > ~/.ollama/Modelfile.coding << EOF
FROM ${MODEL}
SYSTEM You are an expert senior full-stack software engineer. Write clean, secure, production-ready code.
PARAMETER temperature 0.65
PARAMETER num_ctx 16384
EOF

OLLAMA_MODELS="$MOUNT_POINT" ollama create coding-assistant -f ~/.ollama/Modelfile.coding
success "Local coding LLM 'coding-assistant' ready!"

# Guide
cat > ~/Desktop/Antigravity-Local-LLM-Setup.md << 'EOL'
# Antigravity + Local Ollama Setup

Models location: /mnt/ollama_data

Start Ollama with:
    OLLAMA_MODELS=/mnt/ollama_data ollama serve

In Antigravity:
- Base URL: http://localhost:11434/v1
- API Key: ollama
- Model: coding-assistant
EOL

success "Setup guide created on Desktop"

echo "================================================================"
echo -e "${GREEN}🎉 FULL INSTALLATION COMPLETED!${NC}"
echo "================================================================"
echo "Ollama models stored at: $MOUNT_POINT"
echo "Start command: OLLAMA_MODELS=$MOUNT_POINT ollama serve"
    



