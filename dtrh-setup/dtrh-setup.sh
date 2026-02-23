#!/usr/bin/env bash

# ──────────────────────────────────────────────────────────────────────────────
# DTRHnet Setup & Tools TUI
# Requires: fzf, git, gh (GitHub CLI)
# ──────────────────────────────────────────────────────────────────────────────

set -uo pipefail
IFS=$'\n\t'

# Colors
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

banner() {
    cat << 'EOF'
   ____  _______  __  __ _          _   
  |  _ \|  ___\ \/ / / _| |_ _   _| |_ 
  | | | | |_   \  / | |_| __| | | | __|
  | |_| |  _|  /  \ |  _| |_| |_| | |_ 
  |____/|_|   /_/\_\_|  \__|\__,_|\__|

              DTRHnet
       Development & Security Hub
EOF
    echo -e "${CYAN}$(printf '─%.0s' {1..50})${NC}\n"
}

check_dependency() {
    local cmd="$1"
    local pkg="$2"
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}Error:${NC} $cmd is required but not found."
        echo -e "       Try: ${YELLOW}sudo apt update && sudo apt install $pkg${NC}"
        exit 1
    fi
}

github_setup() {
    echo -e "\n${GREEN}→ GitHub / Git global configuration${NC}\n"

    local name email

    # Name
    read -r -p "  Your full name (for git commits): " name
    name="${name:-$(git config --global user.name 2>/dev/null || echo 'Unknown User')}"

    # Email
    read -r -p "  Your email (used for git & GitHub): " email
    email="${email:-$(git config --global user.email 2>/dev/null || echo '')}"

    if [[ -z "$email" ]]; then
        echo -e "${YELLOW}Warning: No email provided. Git commits will lack author email.${NC}"
    fi

    # Apply
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global init.defaultBranch main
    git config --global core.editor "cursor --wait"   # or vim/nvim/nano
    git config --global pull.rebase true
    git config --global fetch.prune true
    git config --global --add safe.directory '*'

    # Global ignore
    cat > ~/.gitignore_global << 'END'
# macOS
.DS_Store
.AppleDouble
.LSOverride

# Editors
.vscode/
.cursor/
.idea/
*.swp
*~

# Misc
Thumbs.db
ehthumbs.db
END

    git config --global core.excludesfile ~/.gitignore_global

    echo -e "\n${GREEN}Git configured:${NC}"
    git config --global --list | grep -E 'user\.name|user\.email|init\.defaultBranch|core\.editor|pull\.rebase'

    # GitHub CLI login if not already
    if ! gh auth status &>/dev/null; then
        echo -e "\n${YELLOW}Logging into GitHub CLI...${NC}"
        gh auth login --with-token </dev/tty || true
    else
        echo -e "\n${GREEN}GitHub CLI already authenticated.${NC}"
    fi

    echo -e "\n${CYAN}Tip:${NC} You can now use aliases like gpr, gclone, gh repo view --web etc."
    echo -e "      (assuming you added them to ~/.zshrc as previously suggested)\n"
}

main_menu() {
    banner

    local options=(
        "Github              → Configure git + GitHub CLI + sensible defaults"
        "Reverse proxy/NAT   → (placeholder - upcoming)"
        "SSH keys & config   → (placeholder - upcoming)"
        "Cursor / Editor     → (placeholder - upcoming)"
        "Security hardening  → (placeholder - upcoming)"
        "Exit"
    )

    echo -e "${CYAN}Select an option:${NC}\n"

    local choice
    choice=$(printf "%s\n" "${options[@]}" \
        | fzf --height 15 --border --prompt="DTRHnet > " \
             --header-first --header="  Welcome to DTRHnet Setup" \
             --color=bg+:#1e1e2e,fg+:#c6d0f5,hl+:#f9e2af,pointer:#f38ba8)

    [[ -z "$choice" ]] && exit 0

    case "$choice" in
        Github*)
            github_setup
            ;;
        Reverse*)
            echo -e "\n${YELLOW}Reverse proxy / NAT bypass → coming soon${NC}\n"
            sleep 1.5
            ;;
        SSH*)
            echo -e "\n${YELLOW}SSH keys & config → coming soon${NC}\n"
            sleep 1.5
            ;;
        Cursor*)
            echo -e "\n${YELLOW}Cursor / Editor tweaks → coming soon${NC}\n"
            sleep 1.5
            ;;
        Security*)
            echo -e "\n${YELLOW}Kali hardening for dev usage → coming soon${NC}\n"
            sleep 1.5
            ;;
        Exit)
            echo -e "\n${GREEN}Goodbye from DTRHnet.${NC}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection${NC}"
            sleep 1
            ;;
    esac

    read -n1 -r -p "Press any key to return to menu..."
    clear
    main_menu
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

clear

check_dependency fzf fzf
check_dependency git git
check_dependency gh gh   # optional but recommended

main_menu
