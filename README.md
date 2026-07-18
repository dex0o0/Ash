# ASH (Arch System Helper)

`ASH` is a lightweight, fast, and interactive system maintenance and cleanup script written in Bash, tailored specifically for **Arch Linux** users. It helps you keep your system lean, fast, and free of unnecessary caches, orphan packages, and bloated logs with just a single command.

---

## Features

- **Pacman Cache Cleaner:** Safely cleans Pacman cache, retaining only the latest installed packages (prevents `Error reading fd 7` by auto-cleaning incomplete downloads).
- **Yay Cache Cleaner:** Purges AUR build caches under user directories and syncs packages without nagging password prompts.
  Interactive cleanup of your local `~/.cache/yay` directory.
- **Orphan Sweeper:** Automatically detects and removes unused orphan packages (`nosave`).
- **Systemd Log Vacuum:** Clears archived Systemd journals to reclaim disk space.
- **Trash Can Emptier:** Instantly empties your user trash.
- **All-in-One Execution:** Run all cleaning routines in one go!

---

## Installation & Usage

### 1. Clone the repository

```bash
git clone https://github.com/dex0o0/Ash.git
cd Ash
```

### 2. Make the script executable

```bash
chmod +x ash.sh
```

### 3. Run ASH

```bash
sudo ./ash.sh
```

## Requirements

- **OS**: Arch Linux (or any Arch-based distribution like EndeavourOS,Manjaro,etc.)
- **AUR Helper**: `yay` (optional,but highly recommended for AUR cache cleaning)
- **Privileges**: `sudo` access
