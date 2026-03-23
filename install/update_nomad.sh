#!/bin/bash

# Project N.O.M.A.D. Update Script (macOS)

###################################################################################################################################################################################################

# Script                | Project N.O.M.A.D. Update Script (macOS)
# Version               | 1.0.1
# Author                | Crosstalk Solutions, LLC
# Website               | https://crosstalksolutions.com

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
YELLOW='\033[1;33m'
WHITE_R='\033[39m' # Same as GRAY_R for terminals with white background.
GRAY_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.

NOMAD_DIR="$HOME/project-nomad"

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Functions                                                                                             #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

check_is_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    header_red
    echo -e "${RED}#${RESET} This script is designed to run on macOS only.\\n"
    echo -e "${RED}#${RESET} Please run this script on a macOS system and try again."
    exit 1
  fi
  echo -e "${GREEN}#${RESET} This script is running on macOS.\\n"
}

check_is_bash() {
  if [[ -z "$BASH_VERSION" ]]; then
    header_red
    echo -e "${RED}#${RESET} This script requires bash to run. Please run the script using bash.\\n"
    echo -e "${RED}#${RESET} For example: bash $(basename "$0")"
    exit 1
  fi
    echo -e "${GREEN}#${RESET} This script is running in bash.\\n"
}

get_update_confirmation(){
  read -p "This script will update Project N.O.M.A.D. and its dependencies on your machine. No data loss is expected, but you should always back up your data before proceeding. Are you sure you want to continue? (y/n): " choice
  case "$choice" in
    y|Y )
      echo -e "${GREEN}#${RESET} User chose to continue with the update."
      ;;
    n|N )
      echo -e "${RED}#${RESET} User chose not to continue with the update."
      exit 0
      ;;
    * )
      echo "Invalid Response"
      echo "User chose not to continue with the update."
      exit 0
      ;;
  esac
}

ensure_docker_installed_and_running() {
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}#${RESET} Docker is not installed. This is unexpected, as Project N.O.M.A.D. requires Docker to run. Did you mean to use the install script instead of the update script?"
    exit 1
  fi

  if ! docker info &>/dev/null; then
    echo -e "${RED}#${RESET} Docker is not running. Please open Docker Desktop and wait for it to start, then try again."
    echo -e "${YELLOW}#${RESET} You can open it with: ${WHITE_R}open -a Docker${RESET}"
    exit 1
  fi
}

check_docker_compose() {
  # Check if 'docker compose' (v2 plugin) is available
  if ! docker compose version &>/dev/null; then
    echo -e "${RED}#${RESET} Docker Compose v2 is not installed or not available as a Docker plugin."
    echo -e "${YELLOW}#${RESET} This script requires 'docker compose' (v2), not 'docker-compose' (v1)."
    echo -e "${YELLOW}#${RESET} Docker Desktop for Mac should include Docker Compose v2. Please ensure Docker Desktop is up to date."
    exit 1
  fi
}

ensure_docker_compose_file_exists() {
  if [ ! -f "${NOMAD_DIR}/compose.yml" ]; then
    echo -e "${RED}#${RESET} compose.yml file not found. Please ensure it exists at ${NOMAD_DIR}/compose.yml."
    exit 1
  fi
}

force_recreate() {
  echo -e "${YELLOW}#${RESET} Pulling the latest Docker images..."
  if ! docker compose -p project-nomad -f "${NOMAD_DIR}/compose.yml" pull; then
    echo -e "${RED}#${RESET} Failed to pull the latest Docker images. Please check your network connection and the Docker registry status, then try again."
    exit 1
  fi

  echo -e "${YELLOW}#${RESET} Forcing recreation of containers..."
  if ! docker compose -p project-nomad -f "${NOMAD_DIR}/compose.yml" up -d --force-recreate; then
    echo -e "${RED}#${RESET} Failed to recreate containers. Please check the Docker logs for more details."
    exit 1
  fi
}

get_local_ip() {
  # Try the primary interface first (en0 is typically WiFi or Ethernet on Mac)
  local_ip_address=$(ipconfig getifaddr en0 2>/dev/null)

  # Fallback: try en1
  if [[ -z "$local_ip_address" ]]; then
    local_ip_address=$(ipconfig getifaddr en1 2>/dev/null)
  fi

  # Fallback: parse ifconfig for any non-loopback IPv4 address
  if [[ -z "$local_ip_address" ]]; then
    local_ip_address=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
  fi

  if [[ -z "$local_ip_address" ]]; then
    echo -e "${RED}#${RESET} Unable to determine local IP address. Please check your network configuration."
    # Don't exit if we can't determine the local IP address, it's not critical for the update
  fi
}

success_message() {
  echo -e "${GREEN}#${RESET} Project N.O.M.A.D update completed successfully!\\n"
  echo -e "${GREEN}#${RESET} Installation files are located at ${NOMAD_DIR}\\n\n"
  echo -e "${GREEN}#${RESET} Containers will restart automatically as long as Docker Desktop is running.\\n"
  echo -e "${GREEN}#${RESET} You can now access the management interface at http://localhost:8080 or http://${local_ip_address}:8080\\n"
  echo -e "${GREEN}#${RESET} Thank you for supporting Project N.O.M.A.D!\\n"
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Main Script                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Pre-flight checks
check_is_macos
check_is_bash

# Main update
get_update_confirmation
ensure_docker_installed_and_running
check_docker_compose
ensure_docker_compose_file_exists
force_recreate
get_local_ip
success_message
