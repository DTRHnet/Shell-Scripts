#!/usr/bin/env bash

# ──────────────────────────────────────────────────────────────────────────────
#     ██████╗ ████████╗██████╗ ██╗  ██╗███╗   ██╗███████╗████████╗
#     ██╔══██╗╚══██╔══╝██╔══██╗██║  ██║████╗  ██║██╔════╝╚══██╔══╝
#     ██║  ██║   ██║   ██████╔╝███████║██╔██╗ ██║█████╗     ██║
#     ██║  ██║   ██║   ██╔══██╗██╔══██║██║╚██╗██║██╔══╝     ██║
#     ██████╔╝   ██║   ██║  ██║██║  ██║██║ ╚████║███████╗   ██║
#     ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝
#
#          DTRHnet INITIALIZER  [ v2026.02 – ELITE MATRIX MODE ]
#        Auto-deps • Interactive identity • Bottom progress • Verbose • Kali-safe
# ──────────────────────────────────────────────────────────────────────────────

set -uo pipefail
IFS=$'\n\t'

# ─── CLI Parsing (elite, silent) ───────────────────────────────────────────────
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo -e "${RED}✖${RESET} Unknown option: $1"
            echo -e "   Usage: $0 [-v|--verbose]"
            exit 1
            ;;
    esac
done

# ─── Colors (cyber-elite neon palette) ────────────────────────────────────────
GRN="\033[0;32m"   BGRN="\033[1;32m"   YEL="\033[1;33m"   RED="\033[0;31m"
CYN="\033[0;36m"   BCYN="\033[1;36m"   DIM="\033[2m"      BOLD="\033[1m"
RESET="\033[0m"    MAG="\033[0;35m"

# ─── Config ───────────────────────────────────────────────────────────────────
: "${GIT_USER:=$(whoami)}"
: "${GIT_EMAIL:=$(whoami)@localhost}"
: "${TIMEOUT_DEFAULT:=300}"   # generous for Kali network + sudo

DEV_ROOT="$HOME/dev"
WORK_DIR="$DEV_ROOT/work"
PERS_DIR="$DEV_ROOT/personal"
FORKS_DIR="$DEV_ROOT/forks"
EXPER_DIR="$DEV_ROOT/experiments"

# ─── Banner (elite presentation) ──────────────────────────────────────────────
banner() {
    clear
    cat << 'EOF'
#     ██████╗ ████████╗██████╗ ██╗  ██╗███╗   ██╗███████╗████████╗
#     ██╔══██╗╚══██╔══╝██╔══██╗██║  ██║████╗  ██║██╔════╝╚══██╔══╝
#     ██║  ██║   ██║   ██████╔╝███████║██╔██╗ ██║█████╗     ██║
#     ██║  ██║   ██║   ██╔══██╗██╔══██║██║╚██╗██║██╔══╝     ██║
#     ██████╔╝   ██║   ██║  ██║██║  ██║██║ ╚████║███████╗   ██║
#     ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝
#
#          DTRHnet INITIALIZER  [ v2026.02 – ELITE MATRIX MODE ]
EOF
    printf "${BGRN}%s${RESET}\n" "$(printf '═%.0s' {1..68})"
    echo -e "  ${DIM}Elite TUI • auto-deps • bottom progress • verbose${RESET}\n"
}

# ─── Logging (clean, professional) ────────────────────────────────────────────
log_ok()    { echo -e "  ${BGRN}✔${RESET}  $*"; }
log_info()  { echo -e "  ${BCYN}ℹ${RESET}  $*"; }
log_warn()  { echo -e "  ${YEL}⚠${RESET}  $*"; }
log_err()   { echo -e "  ${RED}✖${RESET}  $*"; }

# ─── Elite Bottom-Anchored Progress Bar (Kali-safe, bug-free) ─────────────────
draw_bottom_progress() {
    local msg="$1"
    local percent=${2:-0}
    local width=68
    local bar_width=$((width - 14))
    local filled=$((percent * bar_width / 100))

    # Safe character repetition (fixes the printf "% ':" bug)
    local bar="" empty=""
    if (( filled > 0 )); then
        printf -v bar '%*s' "$filled" ''
        bar=${bar// /█}
    fi
    if (( bar_width - filled > 0 )); then
        printf -v empty '%*s' "$((bar_width - filled))" ''
        empty=${empty// /░}
    fi

    local perc_str
    printf -v perc_str '%3d%%' "$percent"

    tput sc
    tput cup $(( $(tput lines) - 1 )) 0
    printf "\033[2K"  # clear line
    printf "  ${CYN}⟐${RESET}  ${msg} ${DIM}[${RESET}${bar}${empty}${DIM}]${RESET} ${perc_str} "
    tput rc
}

clear_bottom_progress() {
    tput sc
    tput cup $(( $(tput lines) - 1 )) 0
    printf "\033[2K"
    tput rc
}

run_with_progress() {
    local msg="$1"
    local max_time="${2:-$TIMEOUT_DEFAULT}"
    shift 2

    local start_time=$(date +%s)
    local output_file=$(mktemp)

    if $VERBOSE; then
        timeout --foreground "${max_time}s" "$@" 2>&1 &
    else
        timeout --foreground "${max_time}s" "$@" >"$output_file" 2>&1 &
    fi
    local cmd_pid=$!

    # Background progress renderer
    (
        while kill -0 "$cmd_pid" 2>/dev/null; do
            local elapsed=$(( $(date +%s) - start_time ))
            local percent=$(( elapsed * 100 / max_time ))
            (( percent > 100 )) && percent=100
            draw_bottom_progress "$msg" "$percent"
            sleep 0.12
        done
        draw_bottom_progress "$msg" 100
        sleep 0.6
        clear_bottom_progress
    ) & local progress_pid=$!

    wait "$cmd_pid"
    local status=$?
    kill "$progress_pid" 2>/dev/null 2>&1 || true
    clear_bottom_progress

    if [[ $status -eq 0 ]]; then
        log_ok "$msg"
    elif [[ $status -eq 124 ]]; then
        log_err "$msg timed out after ${max_time}s"
        if ! $VERBOSE; then
            echo -e "  ${DIM}Last output:${RESET}"
            tail -n 8 "$output_file" 2>/dev/null || true
        fi
    else
        log_err "$msg failed (code $status)"
        if ! $VERBOSE; then
            echo -e "  ${DIM}Last output:${RESET}"
            tail -n 8 "$output_file" 2>/dev/null || true
        fi
    fi

    rm -f "$output_file"
    return $status
}

# ─── Dependency installer (Kali/Debian-first, elite timeouts) ─────────────────
install_dep() {
    local cmd="$1" pkg="$2"

    if command -v "$cmd" &>/dev/null; then return 0; fi

    log_warn "$cmd not found — installing $pkg"

    if [[ -f /etc/debian_version ]] || grep -qiE 'ubuntu|debian|kali' /etc/os-release 2>/dev/null; then
        run_with_progress "Updating package lists" 240 sudo apt update -qq
        run_with_progress "Installing $pkg" 360 sudo apt install -yqq "$pkg"
    elif grep -qi fedora /etc/os-release 2>/dev/null; then
        run_with_progress "Installing $pkg" 360 sudo dnf install -y "$pkg"
    elif grep -qi arch /etc/os-release 2>/dev/null; then
        run_with_progress "Installing $pkg" 360 sudo pacman -S --noconfirm "$pkg"
    else
        log_err "Unsupported distro — install $pkg manually"
        return 1
    fi

    if command -v "$cmd" &>/dev/null; then
        log_ok "$cmd installed successfully"
        return 0
    else
        log_err "$cmd still missing after installation"
        return 1
    fi
}

# ─── Directory setup ──────────────────────────────────────────────────────────
ensure_dirs() {
    mkdir -p "$WORK_DIR" "$PERS_DIR" "$FORKS_DIR" "$EXPER_DIR" 2>/dev/null
    log_ok "Development directory structure ready"
}

# ─── First-time identity setup ────────────────────────────────────────────────
setup_identity() {
    log_info "Configuring git identity (first run)"

    read -r -p "  Git username [$GIT_USER]: " input
    [[ -n "$input" ]] && GIT_USER="$input"

    read -r -p "  Git email   [$GIT_EMAIL]: " input
    [[ -n "$input" ]] && GIT_EMAIL="$input"

    git config --global user.name "$GIT_USER"
    git config --global user.email "$GIT_EMAIL"
    git config --global init.defaultBranch main
    git config --global pull.rebase true
    git config --global fetch.prune true
    git config --global --add safe.directory '*'

    log_ok "Git identity locked → $GIT_USER <$GIT_EMAIL>"

    cat > ~/.gitignore_global << 'END'
.DS_Store
Thumbs.db
.cursor/
.vscode/
*~
END
    git config --global core.excludesfile ~/.gitignore_global
    log_ok "Global .gitignore created"
}

# ─── Clone wizard ─────────────────────────────────────────────────────────────
clone_and_organize() {
    log_info "GitHub repository clone & organization wizard"

    if ! gh auth status &>/dev/null; then
        log_warn "GitHub CLI not authenticated"
        gh auth login </dev/tty || { log_err "GitHub authentication failed"; return 1; }
    fi

    local vis
    vis=$(printf "Public repos\nPrivate repos\nCancel" | \
          fzf --height=10 --border --prompt="Visibility > " --header="Select repository visibility")

    [[ "$vis" == "Cancel" || -z "$vis" ]] && { log_info "Aborted."; return 0; }

    local gh_args=("--limit" "100")
    [[ "$vis" == "Private"* ]] && gh_args+=("--visibility" "private")

    local repos
    if ! run_with_progress "Fetching repository list" 240 \
         gh repo list "${gh_args[@]}" --json nameWithOwner,description \
         --jq '.[] | "\(.nameWithOwner)\t\(.description // \"no description\")"' > /tmp/dtrh-repos.txt; then
        log_err "Failed to fetch repository list"
        return 1
    fi
    repos=$(cat /tmp/dtrh-repos.txt)
    rm -f /tmp/dtrh-repos.txt

    [[ -z "$repos" ]] && { log_err "No repositories found"; return 1; }

    local selection
    selection=$(echo "$repos" | \
        fzf --height=22 --border --prompt="Select repository > " \
            --preview="echo -e \"${CYN}{1}${RESET}\n\n{2}\"" \
            --preview-window=right:50% \
            --delimiter=$'\t' --with-nth=1.. --header="ENTER = clone")

    [[ -z "$selection" ]] && return 0

    local repo_fullname="${selection%%$'\t'*}"
    local reponame="${repo_fullname##*/}"
    local target

    target=$(printf "%s\tPersonal / open-source\n%s\tClient / private work\n%s\tForks & contributions\n%s\tExperiments\nCancel" \
             "$PERS_DIR" "$WORK_DIR" "$FORKS_DIR" "$EXPER_DIR" | \
             fzf --height=14 --border --prompt="Destination folder > " --delimiter=$'\t' --with-nth=2..)

    [[ "$target" == *"Cancel"* || -z "$target" ]] && return 0
    target=$(echo "$target" | cut -f1)

    local fullpath="$target/$reponame"

    if [[ -d "$fullpath" ]]; then
        log_warn "Repository already exists at $fullpath"
        read -p "    Pull latest changes? (y/N) " -n1 ans </dev/tty; echo
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            run_with_progress "Pulling latest changes" 300 \
                bash -c "cd '$fullpath' && git pull --rebase --autostash"
        fi
    else
        run_with_progress "Cloning $repo_fullname" 600 \
            git clone --progress "https://github.com/$repo_fullname.git" "$fullpath"
    fi

    if [[ -d "$fullpath" ]]; then
        log_ok "Repository ready → ${fullpath}"
        if command -v cursor &>/dev/null; then
            read -p "    Open in Cursor? (y/N) " -n1 ans </dev/tty; echo
            [[ "$ans" =~ ^[Yy]$ ]] && cursor "$fullpath"
        fi
    fi
}

# ─── TUI Help Preview ─────────────────────────────────────────────────────────
preview_content() {
    case "$1" in
        Clone*) cat << 'HELP'
Clone & Organize Repo
─────────────────────
Browse public/private GitHub repos
Choose structured destination
Smart clone or pull
Optional Cursor integration
HELP
            ;;
        Open*)  echo -e "${DIM}Recent project selector – coming soon${RESET}" ;;
        SSH*)   echo -e "${DIM}SSH key & config manager – coming soon${RESET}" ;;
        Reverse*) echo -e "${DIM}Reverse proxy / NAT exposure tools – coming soon${RESET}" ;;
        Kali*)  echo -e "${DIM}Kali → dev hardening presets – coming soon${RESET}" ;;
        Exit*)  echo -e "${BGRN}Exit cleanly${RESET}" ;;
        *)      echo -e "${DIM}Select an operation...${RESET}" ;;
    esac
}

# ─── Main Entry Point (banner shown first) ────────────────────────────────────
banner
sleep 2.8   # Elite pause – let the matrix sink in

install_dep fzf fzf

# gh is optional but highly recommended
if ! command -v gh &>/dev/null; then
    log_warn "GitHub CLI (gh) is missing – strongly recommended"
    read -p "    Install gh now? (Y/n) " -n1 ans </dev/tty; echo
    [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]] && install_dep gh gh
fi

ensure_dirs

if [[ ! -f ~/.dtrhnet-initialized ]]; then
    setup_identity
    touch ~/.dtrhnet-initialized
    log_ok "First-run initialization complete"
fi

# ─── SSH Key Management (new function) ────────────────────────────────────────
manage_ssh_keys() {
    clear
    banner
    echo -e "${BOLD}${CYN}SSH KEY MATRIX CONTROL${RESET}\n"

    # 1. Check if ~/.ssh already exists and has keys
    local ssh_dir="$HOME/.ssh"
    local key_file="$ssh_dir/id_ed25519"
    local pub_file="${key_file}.pub"

    if [[ -d "$ssh_dir" && -f "$key_file" && -f "$pub_file" ]]; then
        log_ok "Existing ed25519 key pair detected → ${key_file}"
        
        # Optional: show fingerprint
        if command -v ssh-keygen >/dev/null; then
            echo -e " ${DIM}Fingerprint:${RESET}"
            ssh-keygen -l -f "$key_file" 2>/dev/null || true
        fi
        
        read -n1 -r -p " ${YEL}Generate new key anyway? (y/N)${RESET} " ans </dev/tty; echo
        if [[ ! "$ans" =~ ^[Yy]$ ]]; then
            echo -e " ${DIM}Keeping existing key.${RESET}\n"
        else
            echo -e " ${YEL}Proceeding to generate new key (old one will be renamed).${RESET}\n"
            # Backup old keys (non-destructive)
            local ts=$(date +%Y%m%d-%H%M%S)
            mv "$key_file"    "$key_file.bak-$ts"    2>/dev/null
            mv "$pub_file"    "$pub_file.bak-$ts"    2>/dev/null
        fi
    fi

    # 2. Generate key if needed
    if [[ ! -f "$key_file" || ! -f "$pub_file" ]]; then
        log_info "Generating new ed25519 SSH key pair..."

        mkdir -p "$ssh_dir" 2>/dev/null
        chmod 700 "$ssh_dir"

        run_with_progress "Generating SSH key (ed25519)" 120 \
            ssh-keygen -t ed25519 -C "${GIT_USER:-$(whoami)}@$(hostname -s)" -f "$key_file" -N ""

        if [[ $? -ne 0 || ! -f "$pub_file" ]]; then
            log_err "SSH key generation failed"
            return 1
        fi

        chmod 600 "$key_file"
        chmod 644 "$pub_file"

        log_ok "Key pair created:"
        ls -l "$key_file" "$pub_file" | sed 's/^/  /'
        echo
    fi

    # 3. Show public key
    echo -e "${CYN}Public key (ready to copy / upload):${RESET}"
    cat "$pub_file"
    echo

    # 4. Check GitHub authentication
    if ! gh auth status &>/dev/null; then
        log_warn "GitHub CLI not authenticated"
        run_with_progress "Launching GitHub auth" 180 gh auth login </dev/tty || {
            log_err "GitHub authentication failed — cannot continue"
            return 1
        }
    fi

    # 5. Check if this key is already on GitHub
    local pubkey_content
    pubkey_content=$(cat "$pub_file" | tr -d '\n\r')

    local existing_keys
    if ! existing_keys=$(run_with_progress "Checking existing GitHub SSH keys" 90 \
         gh api users/$(gh api user --jq .login)/keys --jq '.[].key'); then
        log_warn "Could not fetch current GitHub SSH keys — assuming not added"
    else
        if echo "$existing_keys" | grep -qF "$pubkey_content"; then
            log_ok "This exact public key is already registered on GitHub"
            echo -e " ${DIM}No upload needed.${RESET}\n"
            read -n1 -r -p " ${BGRN}Press any key to return...${RESET}" </dev/tty
            return 0
        fi
    fi

    # 6. Upload to GitHub (with confirmation)
    echo -e "${YEL}Ready to upload this key to your GitHub account.${RESET}"
    echo -e " Title suggestion: ${CYN}$(hostname -s) – $(date +%Y-%m)${RESET}\n"

    read -r -p " ${CYN}Enter key title:${RESET} " key_title </dev/tty
    [[ -z "$key_title" ]] && key_title="$(hostname -s) – $(date +%Y-%m)"

    read -n1 -r -p " ${YEL}Upload now? (Y/n)${RESET} " confirm </dev/tty; echo
    if [[ -z "$confirm" || "$confirm" =~ ^[Yy]$ ]]; then
        if run_with_progress "Adding SSH key to GitHub" 90 \
             gh ssh-key add "$pub_file" --title "$key_title"; then
            log_ok "SSH key successfully added to GitHub → $key_title"
        else
            log_err "Failed to upload SSH key to GitHub"
            echo -e " ${DIM}Tip: You can manually add it via${RESET}"
            echo -e "   https://github.com/settings/keys"
            echo -e " ${DIM}(copy content shown above)${RESET}\n"
        fi
    else
        log_info "Upload skipped. Key remains local."
        echo -e " ${DIM}You can add it later via GitHub settings.${RESET}\n"
    fi

    # 7. Optional: test connection
    echo -e "${CYN}Quick test:${RESET} ssh -T git@github.com"
    timeout 8 ssh -T git@github.com 2>&1 | sed 's/^/  /' || true
    echo

    log_ok "SSH key management sequence complete"
    read -n1 -r -p " ${BGRN}Press any key to return to console...${RESET}" </dev/tty
}

# ─── Elite Main TUI Loop ──────────────────────────────────────────────────────
while true; do
    banner

    choice=$(printf "%s\n" \
        "Clone & Organize Repo     → Public / Private GitHub → structured clone" \
        "Open recent project       → (placeholder)" \
        "SSH / keys management     → (placeholder)" \
        "Reverse proxy / NAT tools → (placeholder)" \
        "Kali → dev hardening      → (placeholder)" \
        "Exit / Quit" \
        | fzf --height=19 --border --prompt="DTRHnet > " \
              --header="  ELITE OPERATIONS CONSOLE" \
              --color=bg+:#1e1e2e,fg+:#c6d0f5,hl+:#f9e2af,pointer:#f38ba8,border:#cba6f7 \
              --preview="preview_content {1}" \
              --preview-window=down:7:wrap \
              --ansi)

    [[ -z "$choice" ]] && exit 0

    case "$choice" in
        Clone*)           clone_and_organize ;;
        Open*|SSH*|Reverse*|Kali*)
                          echo -e "\n${YEL}→ Feature coming in next elite update${RESET}\n"; sleep 1.4 ;;
        Exit*|Quit*)      echo -e "\n${BGRN}Session terminated. Stay frosty.${RESET}\n"; exit 0 ;;
        *)                log_warn "No action defined for selection"; sleep 1 ;;
    esac

    read -n1 -r -p "    Press any key to return to console..." </dev/tty
done
      
