#!/bin/bash

# FAAI.sh - Script to automate the installation of ollama with the LLM llama3.2, as well as setup fabric.
           # Designed for debian systems.

           # KBS [admin AT dtrh DOT net]

# Initial step tracker
STEP=1

# Exit immediately on any error
set -e

# Logging setup - logs to both console and a log file
LOGFILE="/tmp/FuckingAwesome-AI.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Colors for output formatting
declare -A COLORS
COLORS=(
  [GREEN]="\e[32m" [BGREEN]="\e[1;32m"
  [RED]="\e[31m" [BRED]="\e[1;31m"
  [YELLOW]="\e[33m" [BYELLOW]="\e[1;33m"
  [CYAN]="\e[36m" [BCYAN]="\e[1;36m"
  [RESET]="\e[0m"
)

# Utility function to output formatted text with color and style
function cEcho() {
  local title=$1
  local color=${2:-blue}
  local style=${3:-bold}

  # ANSI escape codes for colors and styles
  local -A colors=(['red']='[91m' ['green']='[92m' ['blue']='[94m' ['white']='[97m')
  local -A styles=(['bold']='1' ['underline']='4')

  # Validate and apply color and style
  if [[ ${colors[$color]} ]]; then
    echo -e "\033${styles[$style]}${colors[$color]}$title\033[0m"
  else
    echo "Invalid color or style specified. Using default."
    echo -e "\033${styles[$style]}${colors['blue']}[INFO]: $title\033[0m"
    return 1
  fi
}

# Output a title with a step number and formatting
function title() {
  cEcho "\n${STEP} - $1\n====================================" red bold
  ((STEP++))
}

# Error handler: prints error message and exits
function error_exit() {
  echo -e "${COLORS[RED]}Error: $1${COLORS[RESET]}" >&2
  exit 1
}

# Check if required commands are available in the system
function chkDep() {
  local command_name="$1"
  
  if command -v "$command_name" &> /dev/null; then
    status="YES"
    location=$(command -v "$command_name")
    flag=1
  else
    status="NO"
    location="N/A"
    flag=0
  fi

  # Color-coded output based on availability
  if [[ $flag -eq 1 ]]; then
    printf "%-20s ${COLORS[GREEN]}%s${COLORS[RESET]}  %s\n" "$command_name" "$status" "$location"
  else
    printf "%-20s ${COLORS[RED]}%s${COLORS[RESET]}  %s\n" "$command_name" "$status" "$location"
  fi
}

# Check for missing dependencies and install them if needed
function chkDeps() {
  title "Checking for missing dependencies:"
  local command_array=("$@")

  for command in "${command_array[@]}"; do
    chkDep "$command"
    sleep 0.5
  done

  local missing=()
  for command in "${command_array[@]}"; do
    if [ $? -eq 127 ]; then
      missing+=("$command")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    printf "\n${COLORS[RED]}Non-existent commands:${COLORS[RESET]}\n"
    for command in "${missing[@]}"; do
      printf "%s\n" "$command"
    done
    # Try to install missing dependencies
    for dep in "${missing[@]}"; do
      sudo apt install -y "$dep" || error_exit "Failed to install $dep"
    done
  fi
}

# Determine the system's architecture
function chkArch() {
  title "Checking System Architecture..."
  local arch=$(uname -m)
  if [ -z "$arch" ]; then
    error_exit "Unable to determine system architecture"
  fi
  echo "$arch"
}

# Determine the system's OS
function chkOS() {
  title "Checking System OS..."
  local os=$(uname -s)
  if [ -z "$os" ]; then
    error_exit "Unable to determine system OS"
  fi
  echo "$os"
}

# Check network status
function chkNetwork() {
  title "Checking Network Status..."
  local net_info=$(ip addr show | grep -o '^\S*\S*' | cut -d'/' -f1)
  if [ -z "$net_info" ]; then
    error_exit "Unable to detect network"
  fi
  echo "$net_info"
}

# Update and upgrade the system
function sysUpdate() {
  title "Updating System..."
  local update_output
  update_output=$(sudo apt-get update && sudo apt-get upgrade -y)
  if [ $? -eq 0 ]; then
    echo "$update_output"
  else
    error_exit "System update failed"
  fi
}

# Install ollama and necessary models
function install_ollama() {
  title "Installing Ollama and llama3.2"
  curl -fsSL https://ollama.com/install.sh | sh || error_exit "Failed to install Ollama"
  sleep 1
  ollama pull llama3.2 || error_exit "Failed to pull llama3.2"
  sleep 1

  # Ensure Ollama API is running
  nmap -sV localhost -p11434 || error_exit "Failed to verify Ollama API status"
  
  title "Testing llama3.2 instance"
  ollama run llama3.2 || error_exit "Failed to run llama3.2 instance"
}

# Install Fabric
function install_fabric() {
  title "Installing Fabric..."
  go install github.com/danielmiessler/fabric@latest || error_exit "Failed to install Fabric"
  fabric --setup || error_exit "Failed to setup Fabric"
}

# Run Fabric with an example command
function fabric_example() {
  title "Running Fabric Example..."
  fabric -y "https://www.youtube.com/watch?v=_CJwu3Z4lYk" --stream --pattern extract_wisdom || error_exit "Failed to run Fabric example"
}

# Setup environment and execute all tasks
function setup() {
  export PATH="$PATH:$HOME/go/bin"
  title "Setting up the environment"

  chkArch
  chkOS
  chkNetwork
  sysUpdate
  chkDeps "${commands[@]}"
  install_ollama
  install_fabric
  fabric_example
}

# Array of required commands to check for dependencies
commands=(go ollama curl nmap)

# Execute setup
setup
