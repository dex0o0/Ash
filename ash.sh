#! /usr/bin/env bash

set -mu

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$REAL_USER")
TRASH_DIR="$USER_HOME/.local/share/Trash"

perror() {
  echo -e "[${RED}ERROR${NC}] ${YELLOW}$1${NC}"
}

say() {
  echo -e "${GREEN}==>${NC} ${YELLOW}$1${NC}"
}

success() {
  echo -e "[${GREEN}+${NC}] ${GREEN}$1${NC}"
}

if [[ $EUID -ne 0 ]]; then
  perror "Please Run as sudo"
  exit 1
fi

pacman_cache() {
  say "Cleaning Pacman cache..."

  if ls /var/cache/pacman/pkg/download-* &>/dev/null; then
    say "Removing incomplete download files from cache.."
    rm -rfd /var/cache/pacman/pkg/download-*
  fi

  if command -v paccache &>/dev/null; then
    paccache -r -k 2
    paccache -rk0
  else
    say "paccache not found. Using basic pacman clean..."
    pacman -Scc
  fi
  success "Pacman cache cleared successfully"
}

yay_cache() {
  say "Cleaning yay cache..."
  if command -v yay &>/dev/null; then
    echo -e "y\ny\ny" | yay -Sc --noconfirm &>/dev/null
    success "Pacman cache cleared successfully"
  else
    perror "yay is not installed on this system"
  fi
}

orphan_pack() {
  say "Checking for orphan packages..."
  orphan=$(pacman -Qtdq)
  if [ -z "$orphan" ]; then
    success "No orphan packages found"
  else
    say "Found orphan packages:"
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
  say "Cleaning Systemd journal logs..."

  journalctl --vacuum-time=2weeks &>/dev/null
  if [ -d /var/lib/systemd/coredump ]; then
    rm -rf /var/lib/systemd/coredump/*
  fi
  success "System logs cleaned"
}

user_cache() {
  if [ -d "$USER_HOME/.cache" ]; then
    cache_size=$(du -sh "$USER_HOME/.cache" 2>/dev/null | cut -f1)
    say "Current user cache size:${BLUE}$cache_size${NC}"
    echo -ne "${YELLOW}Do you want to clear ~/.cache completely? (y/N):${NC}"
    read -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
      sudo -u "$REAL_USER" rm -rf "$USER_HOME/.cache"/*
      success "User cache cleared"
    else
      echo -e "${BLUE}Skipped${NC}"
    fi
  else
    perror "~/.cache directory not found."
  fi
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
  say "Runing ALL cleaning processes..."
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
echo -e "${YELLOW}==================================${NC}"
echo -e "${GREEN}a system clear for Arch linux${NC}"
echo -e "${YELLOW}==================================${NC}\n"

echo -e "${GREEN}1${NC}: ${BLUE}Pacman Cache${NC}"
echo -e "${GREEN}2${NC}: ${BLUE}yay Cache${NC}"
echo -e "${GREEN}3${NC}: ${BLUE}Orphan Packages${NC}"
echo -e "${GREEN}4${NC}: ${BLUE}System Logs${NC}"
echo -e "${GREEN}5${NC}: ${BLUE}User Cache${NC}"
echo -e "${GREEN}6${NC}: ${BLUE}Trash Clear${NC}"
echo -e "${GREEN}7${NC}: ${BLUE}Clear All${NC}"

echo -ne "\n${YELLOW}What is your choice${NC}?"
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
