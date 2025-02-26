#!/usr/bin/env bash

# Exit immediately on error, treat unset variables as errors, and propagate pipe failures
set -euo pipefail

# Variables initialization for option flags
interactive=false
auto=false

# Usage function to display help
usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -a, --auto         Run automatic installation without prompts."
    echo "  -I, --interactive  Run interactive installation with step-by-step prompts."
    echo "  -h, --help         Show this help message and exit."
    echo ""
    echo "This script installs required packages on Linux, macOS, or Android (Termux)."
    echo "It detects your OS/distribution and uses the appropriate package manager:"
    echo "apt, dnf/yum, pacman, emerge, xbps, or Homebrew. If no mode is specified,"
    echo "it defaults to interactive mode. Windows is not supported."
}

# Parse command-line options
while [ $# -gt 0 ]; do
    case "$1" in
        -a|--auto)
            auto=true
            ;;
        -I|--interactive)
            interactive=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "Error: Unknown option '$1'" >&2
            usage
            exit 1
            ;;
        *)
            break  # stop processing options when a non-option argument is encountered
            ;;
    esac
    shift
done

# Ensure mutually exclusive options are not both set
if [ "$interactive" = true ] && [ "$auto" = true ]; then
    echo "Error: --interactive and --auto cannot be used together." >&2
    usage
    exit 1
fi

# Default to interactive mode if neither -a nor -I was provided
if [ "$interactive" = false ] && [ "$auto" = false ]; then
    interactive=true
fi

# Determine OS type using uname
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    msys*|mingw*|cygwin*|windows*)
        echo "Error: This script is not supported on Windows." >&2
        exit 1
        ;;
esac

# Initialize variables for OS name and package manager
OS_NAME=""    # Descriptive OS name
PM=""         # Package manager key (e.g., apt, dnf, yum, pacman, brew, emerge, xbps)
PM_NAME=""    # Human-readable name for the package manager (for prompts)
PM_CMD=""     # Actual command for the package manager if needed (e.g., "apt-get" vs "apt")

# Detect platform (Linux distro, macOS, or Termux)
if [ "$OS" = "linux" ]; then
    # Check for Termux on Android
    if command -v termux-setup-storage >/dev/null 2>&1; then  
        # termux-setup-storage exists only in Termux [oai_citation_attribution:5‡reddit.com](https://www.reddit.com/r/termux/comments/co46qw/how_to_detect_in_a_bash_script_that_im_in_termux/#:~:text=%E2%80%A2)
        OS_NAME="Android (Termux)"
        PM="apt"
        PM_NAME="APT"
        PM_CMD="apt-get"
        # Termux uses apt (via the pkg command). No sudo needed in Termux.
        # Note for Termux users about proot-distro:
        if command -v proot-distro >/dev/null 2>&1; then
            echo "Note: 'proot-distro' is installed. If you intended to run this script inside a proot-distro Linux environment, please run this script there (within the distro)."
        fi
    else
        OS_NAME="Linux"
        # Identify Linux distribution via /etc/os-release
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                debian|ubuntu|linuxmint|elementary|pop*)
                    PM="apt"
                    PM_NAME="APT"
                    PM_CMD="apt-get"
                    ;;
                fedora|rhel|centos|rocky|alma*)
                    # Fedora, RHEL, CentOS, Rocky, AlmaLinux
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
                    echo "Error: Unsupported Linux distribution ('$ID')." >&2
                    exit 1
                    ;;
            esac
        else
            # Fallback: detect by existence of package manager commands
            if command -v apt-get >/dev/null 2>&1; then
                PM="apt";    PM_NAME="APT";     PM_CMD="apt-get"
            elif command -v dnf >/dev/null 2>&1; then
                PM="dnf";   PM_NAME="DNF";    PM_CMD="dnf"
            elif command -v yum >/dev/null 2>&1; then
                PM="yum";   PM_NAME="YUM";    PM_CMD="yum"
            elif command -v pacman >/dev/null 2>&1; then
                PM="pacman"; PM_NAME="Pacman"; PM_CMD="pacman"
            elif command -v emerge >/dev/null 2>&1; then
                PM="emerge"; PM_NAME="Portage"; PM_CMD="emerge"
            elif command -v xbps-install >/dev/null 2>&1; then
                PM="xbps";  PM_NAME="XBPS";   PM_CMD="xbps-install"
            else
                echo "Error: No supported package manager found on this Linux system." >&2
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
        echo "Error: Homebrew is not installed. Please install Homebrew (https://brew.sh) and re-run this script." >&2
        exit 1
    fi
else
    # This covers any other OS (shouldn't happen due to earlier case)
    echo "Error: Unsupported OS type '$OS'. This script supports Linux, macOS, and Termux (Android) only." >&2
    exit 1
fi

echo "Detected OS: $OS_NAME"

# Determine if sudo is needed (for Linux/macOS, except Termux or when already root)
SUDO=""
if [ "$OS_NAME" = "Android (Termux)" ]; then
    SUDO=""  # Termux doesn't require sudo for package management
elif [ "$(id -u)" -ne 0 ]; then
    # Use sudo if not running as root (for Linux and macOS package managers that need root)
    if [ "$PM" != "brew" ]; then
        SUDO="sudo"
    fi
fi

# Define the packages to install (can be edited as needed)
COMMON_PACKAGES="git curl"

# Notify mode
if [ "$interactive" = true ]; then
    echo "Running in **interactive** mode. You will be prompted for each step."
else
    echo "Running in **automatic** mode. Proceeding without prompts..."
fi

# Interactive mode: confirm each step
do_update=true
do_install=true
if [ "$interactive" = true ]; then
    # Step 1: Ask to update package list
    if [ -n "$PM_NAME" ]; then
        read -rp "Update package list using $PM_NAME? [Y/n] " resp
    else
        read -rp "Update package list? [Y/n] " resp
    end
    case "$resp" in
        [Nn]*)
            do_update=false
            echo "Skipped updating package lists."
            ;;
        *)
            do_update=true
            ;;
    esac

    # Step 2: Ask to install packages
    read -rp "Install required packages ($COMMON_PACKAGES) using $PM_NAME? [Y/n] " resp
    case "$resp" in
        [Nn]*)
            do_install=false
            echo "Skipped package installation."
            ;;
        *)
            do_install=true
            ;;
    esac

    # If user chose not to install, exit (since main purpose is aborted)
    if [ "$do_install" = false ]; then
        echo "No packages were installed. Exiting."
        exit 0
    fi
fi

# Function: update package repositories (if not skipped)
perform_update() {
    case "$PM" in
        apt)
            echo "Updating package lists via apt..."
            $SUDO apt-get update || { echo "Error: 'apt-get update' failed." >&2; exit 1; }
            ;;
        dnf)
            echo "Refreshing package metadata via dnf..."
            $SUDO dnf -y makecache || { echo "Error: 'dnf makecache' failed." >&2; exit 1; }
            ;;
        yum)
            echo "Refreshing package metadata via yum..."
            $SUDO yum makecache -y || { echo "Error: 'yum makecache' failed." >&2; exit 1; }
            ;;
        pacman)
            echo "Updating package database via pacman..."
            $SUDO pacman -Sy --noconfirm || { echo "Error: 'pacman -Sy' failed." >&2; exit 1; }
            ;;
        brew)
            echo "Updating Homebrew formulas..."
            brew update || { echo "Error: 'brew update' failed." >&2; exit 1; }
            ;;
        emerge)
            echo "Syncing Portage tree via emerge..."
            $SUDO emerge --sync || { echo "Error: 'emerge --sync' failed." >&2; exit 1; }
            ;;
        xbps)
            echo "Updating XBPS repository index..."
            $SUDO xbps-install -S || { echo "Error: 'xbps-install -S' failed." >&2; exit 1; }
            ;;
    esac
}

# Function: install packages (if not skipped)
perform_install() {
    case "$PM" in
        apt)
            echo "Installing packages ($COMMON_PACKAGES) via apt..."
            $SUDO apt-get install -y $COMMON_PACKAGES || { echo "Error: 'apt-get install' failed." >&2; exit 1; }
            ;;
        dnf)
            echo "Installing packages ($COMMON_PACKAGES) via dnf..."
            $SUDO dnf install -y $COMMON_PACKAGES || { echo "Error: 'dnf install' failed." >&2; exit 1; }
            ;;
        yum)
            echo "Installing packages ($COMMON_PACKAGES) via yum..."
            $SUDO yum install -y $COMMON_PACKAGES || { echo "Error: 'yum install' failed." >&2; exit 1; }
            ;;
        pacman)
            echo "Installing packages ($COMMON_PACKAGES) via pacman..."
            $SUDO pacman -S --noconfirm $COMMON_PACKAGES || { echo "Error: 'pacman -S' failed." >&2; exit 1; }
            ;;
        brew)
            echo "Installing packages ($COMMON_PACKAGES) via Homebrew..."
            brew install $COMMON_PACKAGES || { echo "Error: 'brew install' failed." >&2; exit 1; }
            ;;
        emerge)
            echo "Installing packages ($COMMON_PACKAGES) via Portage..."
            $SUDO emerge $COMMON_PACKAGES || { echo "Error: 'emerge' installation failed." >&2; exit 1; }
            ;;
        xbps)
            echo "Installing packages ($COMMON_PACKAGES) via XBPS..."
            $SUDO xbps-install -y $COMMON_PACKAGES || { echo "Error: 'xbps-install' failed." >&2; exit 1; }
            ;;
    esac
}

# Execute update step if allowed
if [ "$do_update" = true ]; then
    perform_update
fi

# Execute install step if allowed
if [ "$do_install" = true ]; then
    perform_install
fi

echo "All done! The installation script completed successfully."