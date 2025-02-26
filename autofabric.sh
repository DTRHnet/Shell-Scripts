#!/usr/bin/env bash
################################################################################
# Unified Fabric Installer (Linux/macOS/Termux)
#
# This script will:
#   1) Detect the OS/distro (Linux, macOS, or Termux on Android).
#   2) Install required dependencies: git, curl, go, ollama.
#   3) Clone and install Fabric from GitHub with "go install .".
#   4) Add $HOME/go/bin to your PATH persistently (on Linux/macOS).
#   5) Pull and test a default Ollama model (deepseek-r1).
#   6) Invoke "fabric --setup" so the user can configure patterns/models.
#   7) Test piping by sending a query to "fabric ask".
#
# Usage:
#   ./install_fabric.sh [OPTIONS]
#
# Options:
#   -a, --auto         Non-interactive installation (no user prompts).
#   -I, --interactive  Interactive installation (prompts at each major step).
#   -h, --help         Show this help message and exit.
#
# NOTE: Windows is not supported by this script. Use the dedicated Windows script.
################################################################################

set -euo pipefail

###############################################################################
# 0. Parse script options (auto vs. interactive mode)
###############################################################################
auto=false
interactive=false

usage() {
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -a, --auto         Run automatic installation without prompts."
  echo "  -I, --interactive  Run interactive installation with step-by-step prompts."
  echo "  -h, --help         Show this help message and exit."
  echo ""
  echo "Installs Fabric, Go, Ollama, and dependencies on Linux/macOS/Android (Termux)."
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--auto)
      auto=true
      ;;
    -I|--interactive)
      interactive=true
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo "Error: Unknown option '$1'"
      usage
      ;;
    *)
      # Stop parsing if a non-option argument is encountered
      break
      ;;
  esac
  shift
done

# If both interactive and auto are set, that's an error.
if [ "$auto" = true ] && [ "$interactive" = true ]; then
  echo "Error: Cannot use --auto and --interactive at the same time."
  exit 1
fi

# Default to interactive if neither was specified
if [ "$auto" = false ] && [ "$interactive" = false ]; then
  interactive=true
fi

###############################################################################
# 1. Detect OS / Distribution and set package manager variables
###############################################################################
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
  msys*|mingw*|cygwin*|windows*)
    echo "Error: This script does not support Windows. Use the separate Windows script."
    exit 1
    ;;
esac

OS_NAME=""
PM=""
PM_NAME=""
PM_CMD=""

# For special handling of Termux
is_termux=false

if [ "$OS" = "linux" ]; then
  # Check for Termux on Android
  if command -v termux-setup-storage >/dev/null 2>&1; then
    OS_NAME="Android (Termux)"
    is_termux=true
    PM="apt"
    PM_NAME="APT"
    PM_CMD="apt-get"
  else
    OS_NAME="Linux"
    # Try to identify distro via /etc/os-release
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "$ID" in
        debian|ubuntu|linuxmint|elementary|pop*)
          PM="apt"
          PM_NAME="APT"
          PM_CMD="apt-get"
          ;;
        fedora|rhel|centos|rocky|alma*)
          if command -v dnf >/dev/null 2>&1; then
            PM="dnf"
            PM_NAME="DNF"
            PM_CMD="dnf"
          else
            PM="yum"
            PM_NAME="YUM"
            PM_CMD="yum"
          fi
          ;;
        arch|manjaro|endeavouros|garuda)
          PM="pacman"
          PM_NAME="Pacman"
          PM_CMD="pacman"
          ;;
        gentoo)
          PM="emerge"
          PM_NAME="Portage"
          PM_CMD="emerge"
          ;;
        void)
          PM="xbps"
          PM_NAME="XBPS"
          PM_CMD="xbps-install"
          ;;
        *)
          # Fallback if unknown distro but we have a package manager
          :
          ;;
      esac
    fi

    # If still not set, fallback by detecting available package managers
    if [ -z "$PM" ]; then
      if command -v apt-get >/dev/null 2>&1; then
        PM="apt"; PM_NAME="APT"; PM_CMD="apt-get"
      elif command -v dnf >/dev/null 2>&1; then
        PM="dnf"; PM_NAME="DNF"; PM_CMD="dnf"
      elif command -v yum >/dev/null 2>&1; then
        PM="yum"; PM_NAME="YUM"; PM_CMD="yum"
      elif command -v pacman >/dev/null 2>&1; then
        PM="pacman"; PM_NAME="Pacman"; PM_CMD="pacman"
      elif command -v emerge >/dev/null 2>&1; then
        PM="emerge"; PM_NAME="Portage"; PM_CMD="emerge"
      elif command -v xbps-install >/dev/null 2>&1; then
        PM="xbps"; PM_NAME="XBPS"; PM_CMD="xbps-install"
      else
        echo "Error: No supported package manager found on this Linux system."
        exit 1
      fi
    fi
  fi
elif [ "$OS" = "darwin" ]; then
  OS_NAME="macOS"
  PM="brew"
  PM_NAME="Homebrew"
  PM_CMD="brew"
  # Ensure Homebrew is installed on macOS
  if ! command -v brew >/dev/null 2>&1; then
    echo "Error: Homebrew is not installed. Please install Homebrew (https://brew.sh) first."
    exit 1
  fi
else
  echo "Error: Unsupported OS type '$OS'."
  exit 1
fi

echo "Detected OS: $OS_NAME"

# Determine if we need sudo
SUDO=""
if [ "$is_termux" = true ]; then
  # Termux doesn't use sudo
  SUDO=""
elif [ "$(id -u)" -ne 0 ]; then
  # For macOS (brew) we typically don't use sudo for brew commands
  # For Linux, we do unless it's brew
  if [ "$PM" != "brew" ]; then
    SUDO="sudo"
  fi
fi

###############################################################################
# 2. Possibly prompt in interactive mode
###############################################################################
if [ "$interactive" = true ]; then
  echo "Running in **interactive** mode. You will be prompted for major steps."
else
  echo "Running in **automatic** mode (no prompts)."
fi

confirm_step() {
  # If auto mode, skip prompt; if interactive, ask user
  local prompt="$1"
  if [ "$interactive" = true ]; then
    read -rp "$prompt [Y/n] " resp
    case "$resp" in
      [Nn]*)
        return 1
        ;;
    esac
  fi
  return 0
}

###############################################################################
# 3. Update package repositories
###############################################################################
update_package_lists() {
  case "$PM" in
    apt)
      echo "Updating package lists via apt..."
      $SUDO apt-get update
      ;;
    dnf)
      echo "Refreshing package metadata via dnf..."
      $SUDO dnf -y makecache
      ;;
    yum)
      echo "Refreshing package metadata via yum..."
      $SUDO yum makecache -y
      ;;
    pacman)
      echo "Updating package database via pacman..."
      $SUDO pacman -Sy --noconfirm
      ;;
    brew)
      echo "Updating Homebrew formulas..."
      brew update
      ;;
    emerge)
      echo "Syncing Portage tree..."
      $SUDO emerge --sync
      ;;
    xbps)
      echo "Updating XBPS repository index..."
      $SUDO xbps-install -S
      ;;
    *)
      echo "No recognized package manager available to update (?)."
      ;;
  esac
}

###############################################################################
# 4. Install packages from distro PM
#    We'll install 'git' and 'curl' from the PM, plus Go if available.
###############################################################################
install_from_pm() {
  local pkg="$1"
  case "$PM" in
    # For any of these, just call their usual install commands.
    apt)
      $SUDO apt-get install -y "$pkg"
      ;;
    dnf)
      $SUDO dnf install -y "$pkg"
      ;;
    yum)
      $SUDO yum install -y "$pkg"
      ;;
    pacman)
      $SUDO pacman -S --noconfirm "$pkg"
      ;;
    brew)
      brew install "$pkg"
      ;;
    emerge)
      $SUDO emerge "$pkg"
      ;;
    xbps)
      $SUDO xbps-install -y "$pkg"
      ;;
    *)
      echo "Error: No recognized PM for installing $pkg"
      return 1
      ;;
  esac
}

###############################################################################
# 5. Check if a command exists
###############################################################################
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

###############################################################################
# 6. Install dependencies: git, curl, go, ollama
###############################################################################
install_dependencies() {
  # We'll always want to install or ensure installed:
  #   - git
  #   - curl
  #   - go
  #   - ollama
  local pkgs_to_install=()

  # Step A: Ensure git
  if ! command_exists git; then
    pkgs_to_install+=(git)
  fi

  # Step B: Ensure curl
  if ! command_exists curl; then
    pkgs_to_install+=(curl)
  fi

  # Step C: Install GO
  # For macOS => brew install go
  # For Linux => attempt with PM, or you can adapt if needing newer version
  if ! command_exists go; then
    if [ "$PM" = "brew" ]; then
      pkgs_to_install+=(go)
    else
      # Attempt from distro's repo
      pkgs_to_install+=(golang)
    fi
  fi

  # Let's do the normal PM-based approach for everything except Ollama:
  if [ "${#pkgs_to_install[@]}" -gt 0 ]; then
    echo "Installing missing packages: ${pkgs_to_install[*]}"
    for pkg in "${pkgs_to_install[@]}"; do
      install_from_pm "$pkg"
    done
  else
    echo "git, curl, and go appear to be installed."
  fi

  # Step D: Install Ollama
  # On macOS => `brew install ollama`
  # On Linux => Official script from https://ollama.com/install.sh
  # On Termux => uncertain if supported, but let's try the Linux approach.
  if ! command_exists ollama; then
    echo "Ollama not found. Installing..."
    if [ "$PM" = "brew" ]; then
      brew install ollama
    else
      # For Linux (including Termux, though it may not work on all archs)
      curl -fsSL https://ollama.com/install.sh | $SUDO bash
    fi
  else
    echo "Ollama is already installed."
  fi

  echo "All dependencies installed."
}

###############################################################################
# 7. Clone and install Fabric
###############################################################################
FABRIC_REPO="https://github.com/danielmiessler/fabric.git"
FABRIC_CLONE_DIR="fabric-main"

install_fabric() {
  # Clone the repo if not already
  if [ ! -d "$FABRIC_CLONE_DIR" ]; then
    git clone "$FABRIC_REPO" "$FABRIC_CLONE_DIR"
  else
    echo "Directory $FABRIC_CLONE_DIR already exists; skipping clone."
  fi

  # Build fabric
  echo "Building Fabric..."
  cd "$FABRIC_CLONE_DIR" || exit 1
  go install .
  cd - >/dev/null 2>&1
  echo "Fabric installed to $(go env GOPATH)/bin/fabric"
}

###############################################################################
# 8. Export PATH for Linux/macOS so that "fabric" is in PATH
###############################################################################
export_paths() {
  # For Termux, there's no typical "sudo" or system paths, but $HOME/go/bin is fine
  if [ "$OS_NAME" = "macOS" ] || [ "$OS_NAME" = "Linux" ] || [ "$is_termux" = true ]; then
    local gobin
    gobin="$(go env GOPATH)/bin"
    # Add it to the current session:
    case ":$PATH:" in
      *":$gobin:"*) : ;;  # Already in PATH
      *) export PATH="$PATH:$gobin" ;;
    esac
    # Also persist it in shell RC file (bashrc or zshrc)
    local shellrc="$HOME/.bashrc"
    if [ -n "${SHELL:-}" ] && [[ "$SHELL" == *"zsh" ]]; then
      shellrc="$HOME/.zshrc"
    fi

    if ! grep -q "export PATH=.*$gobin" "$shellrc" 2>/dev/null; then
      echo "export PATH=\"\$PATH:$gobin\"" >> "$shellrc"
      echo "Appended 'export PATH=\"\$PATH:$gobin\"' to $shellrc."
      echo "Run 'source $shellrc' or open a new terminal to update your PATH."
    fi
  fi
}

###############################################################################
# 9. Pull and test Ollama model
###############################################################################
LLM="deepseek-r1"

pull_ollama_model() {
  echo "Pulling Ollama model: $LLM"
  ollama pull "$LLM" || {
    echo "Error pulling Ollama model $LLM."
    exit 1
  }
  echo "Ollama model $LLM downloaded."
}

test_ollama_model() {
  echo "Testing Ollama model: $LLM"
  # Simple test: pipe in "2 + 2 equals" and see if we get any response
  local output
  if ! output=$(echo "2 + 2 equals" | ollama run "$LLM" 2>/dev/null); then
    echo "Error: Failed to run ollama model $LLM."
    exit 1
  fi
  if [ -n "$output" ]; then
    echo "Ollama model test: success."
  else
    echo "Ollama model test: output was empty."
  fi
}

###############################################################################
# 10. Run `fabric --setup` for manual pattern/model configuration
###############################################################################
run_fabric_setup() {
  echo "-----------------------------------------"
  echo "Launching Fabric manual setup..."
  echo "-----------------------------------------"
  echo "**IMPORTANT**: You must configure Fabric's patterns and model here."
  echo "Press ENTER to continue..."
  read -r

  fabric --setup || {
    echo "Error: 'fabric --setup' failed."
    exit 1
  }

  if [ "$interactive" = true ]; then
    read -rp "Have you finished setting up Fabric patterns and chosen a model? (y/n) " confirm
    case "$confirm" in
      [Yy]*) ;;
      *) echo "Setup not confirmed. Exiting."; exit 1 ;;
    esac
  fi
}

###############################################################################
# 11. Test piping with Fabric
###############################################################################
test_fabric_piping() {
  echo "Testing Fabric piping with: 'What is the capital of France?'"
  local response
  response=$(echo "What is the capital of France?" | fabric ask 2>/dev/null || true)

  # We'll do a simple check to see if "Paris" is in the output
  if echo "$response" | grep -iq "paris"; then
    echo "Fabric piping test succeeded (found 'Paris')."
  else
    echo "Fabric piping test did not produce 'Paris' in the output."
    echo "Output was: $response"
    echo "This may be normal depending on your model, but typically we expect 'Paris'."
  fi
}

###############################################################################
# MAIN EXECUTION
###############################################################################
main() {
  # 1) Possibly prompt to update package lists
  if confirm_step "Update package lists with $PM_NAME?"; then
    update_package_lists
  else
    echo "Skipping package list update..."
  fi

  # 2) Install needed dependencies
  if confirm_step "Install required dependencies (git, curl, go, ollama)?"; then
    install_dependencies
  else
    echo "Skipping dependency installation..."
  fi

  # 3) Install or build Fabric
  if confirm_step "Clone and install Fabric from GitHub?"; then
    install_fabric
    export_paths
  else
    echo "Skipping Fabric installation..."
    exit 0
  fi

  # 4) Pull and test Ollama model
  if confirm_step "Pull and test the Ollama model '$LLM'?"; then
    pull_ollama_model
    test_ollama_model
  else
    echo "Skipping Ollama model setup..."
  fi

  # 5) Fabric manual setup
  if confirm_step "Run 'fabric --setup' to configure patterns/models?"; then
    run_fabric_setup
  else
    echo "Skipping 'fabric --setup'..."
  fi

  # 6) Test piping
  if confirm_step "Test piping with 'fabric ask'?"; then
    test_fabric_piping
  else
    echo "Skipping piping test..."
  fi

  echo ""
  echo "========================================="
  echo "Fabric Setup Complete!"
  echo "========================================="
  echo "If you installed Go and Fabric for the first time, open a new terminal"
  echo "or run 'source ~/.bashrc' (or '~/.zshrc') to ensure your PATH is updated."
  echo ""
}

main
