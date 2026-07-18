#! /usr/bin/env bash

set -mu

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
WHITE='\033[97m'
BOLD='\033[1m'
NC='\033[0m'
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$REAL_USER")
TRASH_DIR="$USER_HOME/.local/share/Trash"

perror() {
  echo -e "[${RED}ERROR${NC}] ${YELLOW}$1${NC}"
}

wsay() {
  echo -e "${GREEN}==>${NC} ${BOLD}${WHITE}$1${NC}"
}

warning() {
  echo -e "${GREEN}==>${NC} ${BOLD}${YELLOW}$1${NC}"
}

success() {
  echo -e "[${GREEN}+${NC}] ${GREEN}$1${NC}\n"
}

if [[ $EUID -ne 0 ]]; then
  perror "Please Run as sudo"
  exit 1
fi

pacman_cache() {
  wsay "Cleaning Pacman cache..."

  if ls /var/cache/pacman/pkg/download-* &>/dev/null; then
    wsay "Removing incomplete download files from cache.."
    find /var/cache/pacman/pkg/ -maxdepth 1 -type d -name "download-*" -exec rm -rf {} + &>/dev/null
  fi

  if command -v paccache &>/dev/null; then
    paccache -r -k 2
    paccache -rk0
  else
    wsay "paccache not found. Using basic pacman clean..."
    pacman -Scc
  fi
  success "Pacman cache cleared successfully"
}

remove() {
  sudo -u "$REAL_USER" rm -rf "$1"
  wsay "removed $1"
}

user_cache() {

  if [ -d "$USER_HOME/.cache" ]; then
    CACHE_DIR="$USER_HOME/.cache/yay"
    cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)

    if [[ -d "$CACHE_DIR" ]]; then
      wsay "Current user yay cache size:${BLUE}$cache_size${NC}"
      echo -ne "${YELLOW}Do you want to clear ~/.cache/yay completely? (y/N):${NC}"
      read -r confirm
      if [[ $confirm =~ ^[Yy]$ ]]; then
        sudo -u "$REAL_USER" find "$CACHE_DIR" -mindepth 1 -delete 2>/dev/null
      else
        echo -e "${BLUE}Skipped${NC}"
      fi
      success "yay cache directory contents cleared"
    fi
  else
    warning "~/.cache directory not found."
  fi
  warning "~/.cache/yay directory not found"
}

yay_cache() {
  wsay "Cleaning yay cache..."
  if command -v yay &>/dev/null; then
    echo -e "y\ny\ny" | yay -Sc --noconfirm &>/dev/null
    success "Pacman cache cleared successfully"
  else
    perror "yay is not installed on this system"
  fi
}

orphan_pack() {
  wsay "Checking for orphan packages..."
  orphan=$(pacman -Qtdq)
  if [ -z "$orphan" ]; then
    success "No orphan packages found"
  else
    wsay "Found orphan packages:"
    echo "$orphan"
    echo -ne "Do you want to remove them? (y/N):"
    read -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
      pacman -Rns $orphan
      success "Orphan removed."
    else
      echo -e "${BLUE}Skipped removal.${NC}"
    fi
  fi
}

logs() {
  wsay "Cleaning Systemd journal logs..."

  journalctl --vacuum-time=2weeks &>/dev/null
  if [ -d /var/lib/systemd/coredump ]; then
    rm -rf /var/lib/systemd/coredump/*
  fi
  success "System logs cleaned"
}

trash_clear() {
  if [ -d "$TRASH_DIR" ]; then
    sudo -u "$REAL_USER" rm -rf "$TRASH_DIR"/*
    success "Trash emptied"
  else
    success "Trash is already empty or doesn't exist."
  fi
}

all() {
  wsay "Runing ALL cleaning processes..."
  pacman_cache
  yay_cache
  orphan_pack
  logs
  user_cache
  trash_clear
  success "All system cleaning processes completed successfully"
}

clear
sleep 0.02

figlet -f slant "ASH"

echo -e "${GREEN}1${NC}: ${BLUE}Pacman Cache${NC}"
echo -e "${GREEN}2${NC}: ${BLUE}yay Cache${NC}"
echo -e "${GREEN}3${NC}: ${BLUE}Orphan Packages${NC}"
echo -e "${GREEN}4${NC}: ${BLUE}System Logs${NC}"
echo -e "${GREEN}5${NC}: ${BLUE}yay Cache (force delete)${NC}"
echo -e "${GREEN}6${NC}: ${BLUE}Trash Clear${NC}"
echo -e "${GREEN}7${NC}: ${BLUE}Clear All${NC}"

echo -ne "\n${WHITE}${BOLD}What is your choice${NC}? "
read choice

case "$choice" in
1)
  pacman_cache
  ;;
2)
  yay_cache
  ;;
3)
  orphan_pack
  ;;
4)
  logs
  ;;
5)
  user_cache
  ;;
6)
  trash_clear
  ;;
7)
  all
  ;;
*)
  echo -e "${YELLOW}-------${NC}${RED}Unknown input${NC}${YELLOW}-------${NC}"
  ;;
esac
