#!/bin/bash
# ============================================================
#   MindwareOS - Arch-based Installation Script
#   "We didn't install an OS. We installed a mindset."
#   curl -sL https://raw.githubusercontent.com/YOURUSERNAME/mindwareos/main/install.sh | bash
# ============================================================

# ─── Colors ───────────────────────────────────────────────
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
CYAN="\e[96m"
PURPLE="\e[95m"
BLUE="\e[94m"
GREEN="\e[92m"
YELLOW="\e[93m"
RED="\e[91m"
WHITE="\e[97m"
BG_PURPLE="\e[45m"
BG_BLUE="\e[44m"

# ─── Globals ──────────────────────────────────────────────
MINDWARE_VERSION="1.0.0"
LOG_FILE="/tmp/mindware-install.log"
TARGET_DISK=""
USERNAME=""
HOSTNAME_VAL=""
ROOT_PASS=""
USER_PASS=""
TIMEZONE="Asia/Kolkata"
LOCALE="en_US.UTF-8"
DESKTOP_ENV=""
INSTALL_AUDIO=false
INSTALL_BLUETOOTH=false
INSTALL_NVIDIA=false
INSTALL_AMD=false
INSTALL_INTEL=false
INSTALL_VIRTUALBOX=false
INSTALL_VMWARE=false
INSTALL_AUR=false
AUR_HELPER="yay"
USE_BTRFS=false
SWAP_SIZE="4G"

# ─── Humorous Quotes ──────────────────────────────────────
QUOTES=(
  "\"Arch Linux: Because you clearly hate yourself just enough, but not too much.\""
  "\"sudo rm -rf /problems — unfortunately, this has never worked for anyone.\""
  "\"It's not a bug, it's a feature. The feature just hasn't been documented yet.\""
  "\"I use Arch btw. (You do now. Congratulations, you've leveled up in insufferability.)\""
  "\"This installer is faster than your ex replying. Probably.\""
  "\"The kernel is compiling. Go touch grass. Actually, don't — come back in 3 minutes.\""
  "\"chmod 777 /your/life — we don't recommend this, but we understand the impulse.\""
  "\"In the beginning, there was nothing. Then God ran pacman -Syu.\""
  "\"MindwareOS: Where your RAM goes to be appreciated.\""
  "\"Error 404: Excuses not found. Let's install this thing.\""
  "\"We're partitioning your disk. Not your life choices — those are already fragmented.\""
  "\"If this installer breaks, it's Arch's fault. If it works, it's our genius.\""
  "\"Installing dependencies... (we promise we're not installing a cryptocurrency miner)\""
  "\"Your BIOS called. It said it's excited to finally do something meaningful.\""
  "\"Fun fact: The 'G' in 'GRUB' stands for 'GRand Unified Bootloader'. The 'G' in 'GNOME' stands for chaos.\""
)

# ─── Logging ──────────────────────────────────────────────
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"; }
info()    { echo -e "${CYAN}${BOLD}  ❯${RESET} ${WHITE}$*${RESET}"; log "INFO: $*"; }
success() { echo -e "${GREEN}${BOLD}  ✓${RESET} ${GREEN}$*${RESET}"; log "OK: $*"; }
warn()    { echo -e "${YELLOW}${BOLD}  ⚠${RESET} ${YELLOW}$*${RESET}"; log "WARN: $*"; }
error()   { echo -e "${RED}${BOLD}  ✗${RESET} ${RED}$*${RESET}"; log "ERR: $*"; }
step()    { echo -e "\n${BG_PURPLE}${WHITE}${BOLD}  $*  ${RESET}\n"; log "STEP: $*"; }
quote()   {
  local idx=$(( RANDOM % ${#QUOTES[@]} ))
  echo -e "\n${DIM}${PURPLE}  ${QUOTES[$idx]}${RESET}\n"
}

# ─── Banner ───────────────────────────────────────────────
print_banner() {
  clear
  echo -e "${PURPLE}${BOLD}"
  cat << 'BANNER'

  ███╗   ███╗██╗███╗   ██╗██████╗ ██╗    ██╗ █████╗ ██████╗ ███████╗
  ████╗ ████║██║████╗  ██║██╔══██╗██║    ██║██╔══██╗██╔══██╗██╔════╝
  ██╔████╔██║██║██╔██╗ ██║██║  ██║██║ █╗ ██║███████║██████╔╝█████╗  
  ██║╚██╔╝██║██║██║╚██╗██║██║  ██║██║███╗██║██╔══██║██╔══██╗██╔══╝  
  ██║ ╚═╝ ██║██║██║ ╚████║██████╔╝╚███╔███╔╝██║  ██║██║  ██║███████╗
  ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
                                                                        
BANNER
  echo -e "${RESET}"
  echo -e "${CYAN}${BOLD}                          O  S${RESET}"
  echo -e "${DIM}${WHITE}              Arch-based · Built for thinkers · v${MINDWARE_VERSION}${RESET}"
  echo -e "${DIM}${PURPLE}           ──────────────────────────────────────────${RESET}"
  echo -e "${YELLOW}             \"An OS that respects your intelligence.\"${RESET}"
  echo -e "${DIM}${PURPLE}           ──────────────────────────────────────────${RESET}\n"
}

# ─── Fancy Section Header ─────────────────────────────────
section() {
  local title="$1"
  local width=60
  local pad=$(( (width - ${#title} - 2) / 2 ))
  local line=$(printf '─%.0s' $(seq 1 $width))
  echo -e "\n${PURPLE}  ┌${line}┐${RESET}"
  printf "${PURPLE}  │${RESET}${BOLD}${CYAN}%*s%s%*s${RESET}${PURPLE}│${RESET}\n" $pad "" " $title " $pad ""
  echo -e "${PURPLE}  └${line}┘${RESET}\n"
}

# ─── Progress Bar ─────────────────────────────────────────
progress() {
  local msg="$1"
  local cmd="$2"
  echo -ne "${BLUE}  ⟳ ${WHITE}${msg}...${RESET}"
  if eval "$cmd" >> "$LOG_FILE" 2>&1; then
    echo -e "\r${GREEN}  ✓ ${WHITE}${msg}${RESET}${DIM} — done${RESET}"
  else
    echo -e "\r${RED}  ✗ ${WHITE}${msg}${RESET}${DIM} — failed (check $LOG_FILE)${RESET}"
    return 1
  fi
}

# ─── Spinner ──────────────────────────────────────────────
spinner() {
  local pid=$1
  local msg="$2"
  local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
  local i=0
  while kill -0 $pid 2>/dev/null; do
    printf "\r${CYAN}  ${spin:$i:1}${RESET} ${WHITE}${msg}...${RESET}"
    i=$(( (i+1) % ${#spin} ))
    sleep 0.1
  done
  printf "\r${GREEN}  ✓${RESET} ${WHITE}${msg}${RESET}\n"
}

# ─── Prompt Helpers ───────────────────────────────────────
ask() {
  local prompt="$1"
  local var="$2"
  local default="$3"
  echo -ne "${CYAN}  ❯ ${WHITE}${prompt}${RESET}"
  [[ -n "$default" ]] && echo -ne " ${DIM}[${default}]${RESET}"
  echo -ne ": "
  read -r input
  [[ -z "$input" && -n "$default" ]] && input="$default"
  eval "$var=\"$input\""
}

ask_pass() {
  local prompt="$1"
  local var="$2"
  echo -ne "${CYAN}  ❯ ${WHITE}${prompt}${RESET}: "
  read -rs input
  echo
  eval "$var=\"$input\""
}

confirm() {
  local prompt="$1"
  echo -ne "${YELLOW}  ? ${WHITE}${prompt}${RESET} ${DIM}(y/N)${RESET}: "
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

menu() {
  local prompt="$1"
  shift
  local options=("$@")
  echo -e "${CYAN}  ❯ ${WHITE}${prompt}${RESET}"
  for i in "${!options[@]}"; do
    echo -e "    ${PURPLE}[$((i+1))]${RESET} ${options[$i]}"
  done
  echo -ne "${CYAN}  ❯ ${WHITE}Choice${RESET}: "
  read -r choice
  echo $((choice - 1))
}

# ─── Checks ───────────────────────────────────────────────
preflight_checks() {
  section "PRE-FLIGHT CHECKS"
  quote

  # UEFI check
  if [[ -d /sys/firmware/efi ]]; then
    success "UEFI mode detected"
    BOOT_MODE="UEFI"
  else
    warn "BIOS/Legacy mode detected — GRUB will be installed for MBR"
    BOOT_MODE="BIOS"
  fi

  # Internet
  if ping -c 1 archlinux.org &>/dev/null; then
    success "Internet connection alive"
  else
    error "No internet. MindwareOS cannot be downloaded from the void (yet)."
    exit 1
  fi

  # RAM check
  local ram_mb=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 ))
  if (( ram_mb < 1024 )); then
    warn "Only ${ram_mb}MB RAM detected. This might be rough."
  else
    success "RAM: ${ram_mb}MB detected"
  fi

  # Clock sync
  progress "Syncing system clock" "timedatectl set-ntp true"

  # Update mirrors
  progress "Refreshing mirror list" "reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || true"

  success "Pre-flight checks complete. We're cleared for takeoff."
}

# ─── Disk Selection ───────────────────────────────────────
select_disk() {
  section "DISK SELECTION"
  echo -e "${YELLOW}${BOLD}  ⚠  WARNING: The selected disk will be COMPLETELY WIPED.${RESET}"
  echo -e "${DIM}  (MindwareOS is thorough. Maybe too thorough.)${RESET}\n"

  echo -e "${WHITE}  Available disks:${RESET}\n"
  lsblk -d -o NAME,SIZE,MODEL,TYPE | grep disk | while read line; do
    echo -e "    ${PURPLE}→${RESET} $line"
  done
  echo

  ask "Enter disk to install on (e.g. sda, nvme0n1)" TARGET_DISK "sda"
  TARGET_DISK="/dev/${TARGET_DISK}"

  if [[ ! -b "$TARGET_DISK" ]]; then
    error "Disk $TARGET_DISK not found. Did you make it up?"
    exit 1
  fi

  echo -e "\n${RED}${BOLD}  ALL DATA on ${TARGET_DISK} will be destroyed.${RESET}"
  if ! confirm "Are you absolutely, 100%, no-backsies sure?"; then
    warn "Smart choice. Come back when you're ready."
    exit 0
  fi

  if confirm "Use BTRFS with subvolumes? (recommended for snapshots)"; then
    USE_BTRFS=true
    success "BTRFS selected — we're living dangerously (with snapshots as backup)"
  else
    success "ext4 selected — solid, reliable, like your grandmother"
  fi

  ask "Swap size" SWAP_SIZE "4G"
}

# ─── User Setup ───────────────────────────────────────────
setup_user() {
  section "USER & SYSTEM IDENTITY"
  quote

  ask "Username (this is you, your legend, your legacy)" USERNAME "minduser"
  ask "Hostname / Device name (how should the network know you?)" HOSTNAME_VAL "mindware"
  ask "Timezone" TIMEZONE "Asia/Kolkata"
  ask_pass "Root password" ROOT_PASS
  ask_pass "User password for ${USERNAME}" USER_PASS

  success "Identity established: ${USERNAME}@${HOSTNAME_VAL}"
  echo -e "${DIM}  (You can change this later. Unlike your life choices.)${RESET}"
}

# ─── Desktop Environment ──────────────────────────────────
select_desktop() {
  section "DESKTOP ENVIRONMENT"
  echo -e "${DIM}  Choose your visual destiny. No pressure. (There's pressure.)${RESET}\n"

  local idx
  idx=$(menu "Select a Desktop Environment:" \
    "KDE Plasma    — For people who like options. All of them." \
    "GNOME         — Minimalist. Opinionated. Like a designer who went too far." \
    "XFCE          — Light. Fast. Gets the job done and goes home." \
    "i3wm          — Tiling WM. For keyboard warriors and RSI enthusiasts." \
    "Hyprland      — Wayland tiling. Eye candy + productivity. Peak nerd." \
    "MATE          — Classic. Stable. Your dad would approve." \
    "Cinnamon      — Familiar. Comfy. The Linux Mint feeling, without Mint." \
    "Minimal/None  — Just a TTY. You beautiful, masochistic genius.")

  case $idx in
    0) DESKTOP_ENV="kde" ;;
    1) DESKTOP_ENV="gnome" ;;
    2) DESKTOP_ENV="xfce" ;;
    3) DESKTOP_ENV="i3" ;;
    4) DESKTOP_ENV="hyprland" ;;
    5) DESKTOP_ENV="mate" ;;
    6) DESKTOP_ENV="cinnamon" ;;
    7) DESKTOP_ENV="minimal" ;;
    *) DESKTOP_ENV="kde" ;;
  esac

  success "Desktop: ${DESKTOP_ENV} selected. Bold choice."
}

# ─── Hardware Detection ───────────────────────────────────
detect_hardware() {
  section "HARDWARE DETECTION"
  info "Sniffing your hardware... (non-invasively, we promise)"

  # GPU
  if lspci 2>/dev/null | grep -qi "nvidia"; then
    INSTALL_NVIDIA=true
    success "NVIDIA GPU detected — preparing to battle with proprietary drivers"
  fi
  if lspci 2>/dev/null | grep -qi "amd\|radeon"; then
    INSTALL_AMD=true
    success "AMD GPU detected — AMDGPU open-source drivers incoming"
  fi
  if lspci 2>/dev/null | grep -qi "intel.*graphics\|uhd graphics\|iris"; then
    INSTALL_INTEL=true
    success "Intel GPU detected — will install mesa + intel-media-driver"
  fi

  # VM detection
  if systemd-detect-virt --quiet 2>/dev/null; then
    local virt=$(systemd-detect-virt 2>/dev/null)
    case "$virt" in
      oracle) INSTALL_VIRTUALBOX=true; warn "VirtualBox detected — installing guest additions" ;;
      vmware) INSTALL_VMWARE=true; warn "VMware detected — installing open-vm-tools" ;;
      *) info "Running in: ${virt}" ;;
    esac
  fi

  # CPU Microcode
  if grep -qi "intel" /proc/cpuinfo 2>/dev/null; then
    CPU_UCODE="intel-ucode"
    success "Intel CPU — intel-ucode will be installed"
  elif grep -qi "amd" /proc/cpuinfo 2>/dev/null; then
    CPU_UCODE="amd-ucode"
    success "AMD CPU — amd-ucode will be installed"
  fi
}

# ─── Audio / Bluetooth ────────────────────────────────────
setup_optional() {
  section "OPTIONAL COMPONENTS"
  quote

  if confirm "Install audio support (PipeWire + PulseAudio compat)?"; then
    INSTALL_AUDIO=true
    success "Audio enabled — your music taste is your own problem"
  fi

  if confirm "Install Bluetooth support?"; then
    INSTALL_BLUETOOTH=true
    success "Bluetooth enabled — connecting to the future (and your headphones)"
  fi

  if confirm "Install AUR helper (yay) for extra packages?"; then
    INSTALL_AUR=true
    success "AUR helper enabled — welcome to the wild west of packaging"
  fi

  if confirm "Install printing support (CUPS)?"; then
    INSTALL_PRINTING=true
    success "CUPS enabled — for when you need to waste paper in style"
  fi
}

# ─── Partition ────────────────────────────────────────────
partition_disk() {
  section "PARTITIONING"
  info "Partitioning ${TARGET_DISK}..."
  echo -e "${DIM}  (This is the point of no return. Your old data is history.)${RESET}\n"

  # Wipe disk
  progress "Wiping disk signatures" "wipefs -af $TARGET_DISK"

  if [[ "$BOOT_MODE" == "UEFI" ]]; then
    # GPT layout: EFI + swap + root
    progress "Creating GPT partition table" "parted -s $TARGET_DISK mklabel gpt"
    progress "Creating EFI partition (512MB)" \
      "parted -s $TARGET_DISK mkpart ESP fat32 1MiB 513MiB && parted -s $TARGET_DISK set 1 esp on"
    progress "Creating swap partition (${SWAP_SIZE})" \
      "parted -s $TARGET_DISK mkpart primary linux-swap 513MiB $((513 + ${SWAP_SIZE%G} * 1024))MiB"
    progress "Creating root partition (rest)" \
      "parted -s $TARGET_DISK mkpart primary ext4 $((513 + ${SWAP_SIZE%G} * 1024))MiB 100%"

    # Detect partition names
    if [[ "$TARGET_DISK" =~ nvme ]]; then
      EFI_PART="${TARGET_DISK}p1"
      SWAP_PART="${TARGET_DISK}p2"
      ROOT_PART="${TARGET_DISK}p3"
    else
      EFI_PART="${TARGET_DISK}1"
      SWAP_PART="${TARGET_DISK}2"
      ROOT_PART="${TARGET_DISK}3"
    fi

    progress "Formatting EFI partition" "mkfs.fat -F32 $EFI_PART"
  else
    # MBR layout
    progress "Creating MBR partition table" "parted -s $TARGET_DISK mklabel msdos"
    progress "Creating swap partition" \
      "parted -s $TARGET_DISK mkpart primary linux-swap 1MiB $((1 + ${SWAP_SIZE%G} * 1024))MiB"
    progress "Creating root partition" \
      "parted -s $TARGET_DISK mkpart primary ext4 $((1 + ${SWAP_SIZE%G} * 1024))MiB 100% && parted -s $TARGET_DISK set 2 boot on"

    if [[ "$TARGET_DISK" =~ nvme ]]; then
      SWAP_PART="${TARGET_DISK}p1"
      ROOT_PART="${TARGET_DISK}p2"
    else
      SWAP_PART="${TARGET_DISK}1"
      ROOT_PART="${TARGET_DISK}2"
    fi
  fi

  # Format root
  if [[ "$USE_BTRFS" == true ]]; then
    progress "Formatting root as BTRFS" "mkfs.btrfs -f -L MindwareOS $ROOT_PART"
    progress "Mounting BTRFS" "mount $ROOT_PART /mnt"
    progress "Creating BTRFS subvolumes" \
      "btrfs su cr /mnt/@ && btrfs su cr /mnt/@home && btrfs su cr /mnt/@snapshots && btrfs su cr /mnt/@var_log"
    progress "Remounting with subvolumes" \
      "umount /mnt && \
       mount -o noatime,compress=zstd,subvol=@ $ROOT_PART /mnt && \
       mkdir -p /mnt/{home,.snapshots,var/log} && \
       mount -o noatime,compress=zstd,subvol=@home $ROOT_PART /mnt/home && \
       mount -o noatime,compress=zstd,subvol=@snapshots $ROOT_PART /mnt/.snapshots && \
       mount -o noatime,compress=zstd,subvol=@var_log $ROOT_PART /mnt/var/log"
  else
    progress "Formatting root as ext4" "mkfs.ext4 -L MindwareOS $ROOT_PART"
    progress "Mounting root" "mount $ROOT_PART /mnt"
  fi

  progress "Setting up swap" "mkswap $SWAP_PART && swapon $SWAP_PART"

  if [[ "$BOOT_MODE" == "UEFI" ]]; then
    progress "Mounting EFI" "mkdir -p /mnt/boot/efi && mount $EFI_PART /mnt/boot/efi"
  fi

  success "Partitioning complete. Disk has been transformed."
}

# ─── Base System Install ──────────────────────────────────
install_base() {
  section "BASE SYSTEM INSTALLATION"
  quote

  local base_pkgs="base base-devel linux linux-firmware linux-headers"
  [[ -n "$CPU_UCODE" ]] && base_pkgs="$base_pkgs $CPU_UCODE"
  [[ "$USE_BTRFS" == true ]] && base_pkgs="$base_pkgs btrfs-progs"

  local core_pkgs="networkmanager grub efibootmgr os-prober \
    nano vim git wget curl sudo bash-completion \
    htop neofetch man-db man-pages \
    openssh reflector \
    zip unzip tar gzip bzip2 xz \
    python python-pip nodejs npm \
    ttf-liberation noto-fonts noto-fonts-emoji \
    pipewire-alsa pipewire-jack lib32-pipewire"

  info "Installing base system (this will take a few minutes)..."
  info "Grab a coffee. Or contemplate your existence. Your call."

  progress "Installing base packages" "pacstrap -K /mnt $base_pkgs $core_pkgs"

  success "Base system installed. We have a foundation."
}

# ─── Fstab ────────────────────────────────────────────────
generate_fstab() {
  progress "Generating fstab" "genfstab -U /mnt >> /mnt/etc/fstab"
  success "fstab generated — the OS now knows where things live"
}

# ─── Chroot Configuration ─────────────────────────────────
configure_system() {
  section "SYSTEM CONFIGURATION"

  info "Entering the matrix (arch-chroot)..."

  # Build the chroot script
  cat > /mnt/mindware-chroot.sh << CHROOT
#!/bin/bash
set -e

# ── Timezone & Locale ──
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc
sed -i 's/#${LOCALE}/${LOCALE}/' /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

# ── Hostname ──
echo "${HOSTNAME_VAL}" > /etc/hostname
cat >> /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME_VAL}.localdomain ${HOSTNAME_VAL}
EOF

# ── Users ──
echo "root:${ROOT_PASS}" | chpasswd
useradd -m -G wheel,audio,video,storage,optical,network,power -s /bin/bash "${USERNAME}"
echo "${USERNAME}:${USER_PASS}" | chpasswd
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# ── NetworkManager ──
systemctl enable NetworkManager

# ── Pacman config (colors + parallel downloads) ──
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
sed -i '/\[options\]/a ILoveCandy' /etc/pacman.conf

# ── MindwareOS Branding ──
cat > /etc/mindwareos-release << 'BRAND'
NAME="MindwareOS"
VERSION="${MINDWARE_VERSION}"
ID=mindwareos
ID_LIKE=arch
PRETTY_NAME="MindwareOS ${MINDWARE_VERSION} (Arch Linux)"
HOME_URL="https://github.com/YOURUSERNAME/mindwareos"
DOCUMENTATION_URL="https://wiki.archlinux.org"
LOGO=mindware-logo
BRAND

# link os-release
cp /etc/mindwareos-release /etc/os-release

# ── MOTD ──
cat > /etc/motd << 'MOTD'

  ╔══════════════════════════════════════════════════════╗
  ║            Welcome to  MindwareOS  v1.0              ║
  ║        "An OS that respects your intelligence."      ║
  ╠══════════════════════════════════════════════════════╣
  ║  mind install <pkg>    → install a package           ║
  ║  mind update           → full system update          ║
  ║  mind search <term>    → search packages             ║
  ║  mind remove <pkg>     → remove a package            ║
  ║  mind clean            → clean package cache         ║
  ║  mind info             → show system info            ║
  ╚══════════════════════════════════════════════════════╝

MOTD

# ── 'mind' CLI wrapper (alias system) ──
cat > /usr/local/bin/mind << 'MINDCLI'
#!/bin/bash
# MindwareOS package manager wrapper
# "mind" is smarter than "sudo pacman". Allegedly.

RESET="\e[0m"; BOLD="\e[1m"; CYAN="\e[96m"; GREEN="\e[92m"
YELLOW="\e[93m"; RED="\e[91m"; PURPLE="\e[95m"

mind_banner() {
  echo -e "\n${PURPLE}${BOLD}  MindwareOS Package Manager${RESET} ${CYAN}— mind v1.0${RESET}\n"
}

case "\$1" in
  install|i)
    shift
    mind_banner
    echo -e "${CYAN}  Installing: ${GREEN}\$*${RESET}\n"
    sudo pacman -S "\$@"
    ;;
  remove|rm|uninstall)
    shift
    mind_banner
    echo -e "${YELLOW}  Removing: ${RED}\$*${RESET}\n"
    sudo pacman -Rns "\$@"
    ;;
  update|upgrade|u)
    mind_banner
    echo -e "${CYAN}  Updating the entire system...${RESET}"
    echo -e "${PURPLE}  (May your packages never conflict.)${RESET}\n"
    sudo pacman -Syu
    ;;
  search|s)
    shift
    mind_banner
    echo -e "${CYAN}  Searching for: ${GREEN}\$*${RESET}\n"
    pacman -Ss "\$@"
    ;;
  clean|cc)
    mind_banner
    echo -e "${CYAN}  Cleaning package cache...${RESET}"
    sudo pacman -Sc
    ;;
  info)
    mind_banner
    neofetch
    ;;
  aur)
    shift
    if command -v yay &>/dev/null; then
      mind_banner
      echo -e "${CYAN}  AUR: Installing ${GREEN}\$*${RESET}\n"
      yay -S "\$@"
    else
      echo -e "${RED}  AUR helper not installed. Run: mind install yay${RESET}"
    fi
    ;;
  help|--help|-h|"")
    mind_banner
    echo -e "  ${BOLD}Usage:${RESET} mind <command> [args]\n"
    echo -e "  ${CYAN}install <pkg>${RESET}    Install a package"
    echo -e "  ${CYAN}remove  <pkg>${RESET}    Remove a package"
    echo -e "  ${CYAN}update${RESET}           Update all packages"
    echo -e "  ${CYAN}search  <term>${RESET}   Search packages"
    echo -e "  ${CYAN}clean${RESET}            Clean package cache"
    echo -e "  ${CYAN}info${RESET}             Show system info"
    echo -e "  ${CYAN}aur <pkg>${RESET}        Install from AUR\n"
    echo -e "  ${PURPLE}  \"Simplicity is the ultimate sophistication.\" — MindwareOS${RESET}\n"
    ;;
  *)
    echo -e "${RED}  Unknown command: \$1${RESET}. Try: mind help"
    ;;
esac
MINDCLI
chmod +x /usr/local/bin/mind

# ── neofetch config (MindwareOS branding) ──
mkdir -p /home/${USERNAME}/.config/neofetch
cat > /home/${USERNAME}/.config/neofetch/config.conf << 'NEOCONF'
print_info() {
    info title
    info underline
    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "Resolution" resolution
    info "DE" de
    info "WM" wm
    info "Terminal" term
    info "CPU" cpu
    info "GPU" gpu
    info "Memory" memory
    info cols
}
distro_shorthand="off"
os_arch="on"
kernel_shorthand="on"
cpu_brand="on"
cpu_speed="on"
cpu_cores="logical"
gpu_brand="on"
memory_percent="on"
image_backend="ascii"
ascii_distro="arch"
ascii_bold="on"
colors=(4 6 1 8 8 6)
NEOCONF

# ── MindwareOS ASCII art for neofetch ──
cat > /home/${USERNAME}/.config/neofetch/ascii.txt << 'ASCII'
        ████████████████
      ██  MINDWARE  OS  ██
     ██  ──────────────  ██
    ██   "Think Different"  ██
     ██  (No, not Apple.)  ██
      ██                  ██
        ████████████████
ASCII

# ── Bash profile branding ──
cat >> /home/${USERNAME}/.bashrc << 'BASHRC'

# ── MindwareOS ──
export MINDWARE_VERSION="1.0.0"

# Colors
export PS1='\[\e[95m\][\[\e[96m\]\u\[\e[95m\]@\[\e[94m\]\h\[\e[95m\]]\[\e[97m\] \W \[\e[92m\]❯\[\e[0m\] '

# Aliases — the 'mind' way
alias install='mind install'
alias update='mind update'
alias search='mind search'
alias remove='mind remove'
alias clean='mind clean'

# Quality of life
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ..='cd ..'
alias ...='cd ../..'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# MindwareOS greet
echo ""
echo -e "\e[95m  Welcome back, \$(whoami). The machine missed you.\e[0m"
echo -e "\e[90m  Type 'mind help' to see available commands.\e[0m"
echo ""
BASHRC

chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config
chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

# ── Wallpaper via SVG (fallback for all DEs) ──
mkdir -p /usr/share/mindwareos
cat > /usr/share/mindwareos/wallpaper.svg << 'WALLSVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0d0d1a;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#1a0a2e;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#0a1628;stop-opacity:1" />
    </linearGradient>
    <radialGradient id="glow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" style="stop-color:#7c3aed;stop-opacity:0.3" />
      <stop offset="100%" style="stop-color:#0d0d1a;stop-opacity:0" />
    </radialGradient>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <rect width="1920" height="1080" fill="url(#glow)"/>
  <!-- Grid lines -->
  <g stroke="#ffffff" stroke-opacity="0.03" stroke-width="1">
    <line x1="0" y1="108" x2="1920" y2="108"/>
    <line x1="0" y1="216" x2="1920" y2="216"/>
    <line x1="0" y1="324" x2="1920" y2="324"/>
    <line x1="0" y1="432" x2="1920" y2="432"/>
    <line x1="0" y1="540" x2="1920" y2="540"/>
    <line x1="0" y1="648" x2="1920" y2="648"/>
    <line x1="0" y1="756" x2="1920" y2="756"/>
    <line x1="0" y1="864" x2="1920" y2="864"/>
    <line x1="0" y1="972" x2="1920" y2="972"/>
    <line x1="192" y1="0" x2="192" y2="1080"/>
    <line x1="384" y1="0" x2="384" y2="1080"/>
    <line x1="576" y1="0" x2="576" y2="1080"/>
    <line x1="768" y1="0" x2="768" y2="1080"/>
    <line x1="960" y1="0" x2="960" y2="1080"/>
    <line x1="1152" y1="0" x2="1152" y2="1080"/>
    <line x1="1344" y1="0" x2="1344" y2="1080"/>
    <line x1="1536" y1="0" x2="1536" y2="1080"/>
    <line x1="1728" y1="0" x2="1728" y2="1080"/>
  </g>
  <!-- Decorative dots -->
  <circle cx="960" cy="500" r="180" fill="none" stroke="#7c3aed" stroke-opacity="0.2" stroke-width="1"/>
  <circle cx="960" cy="500" r="280" fill="none" stroke="#5b21b6" stroke-opacity="0.1" stroke-width="1"/>
  <circle cx="960" cy="500" r="380" fill="none" stroke="#4c1d95" stroke-opacity="0.07" stroke-width="1"/>
  <!-- Main logo text -->
  <text x="960" y="490" font-family="monospace" font-size="96" font-weight="bold"
        fill="#e2d9f3" text-anchor="middle" opacity="0.9">MindwareOS</text>
  <text x="960" y="558" font-family="monospace" font-size="22"
        fill="#a78bfa" text-anchor="middle" opacity="0.7">An OS that respects your intelligence.</text>
  <text x="960" y="600" font-family="monospace" font-size="14"
        fill="#7c3aed" text-anchor="middle" opacity="0.5">v1.0.0  ·  Arch-based  ·  Built for thinkers</text>
  <!-- Corner accent -->
  <text x="40" y="1060" font-family="monospace" font-size="12"
        fill="#4c1d95" opacity="0.5">MindwareOS v1.0.0</text>
  <text x="1880" y="1060" font-family="monospace" font-size="12"
        fill="#4c1d95" opacity="0.5" text-anchor="end">think.differently();</text>
</svg>
WALLSVG

# ── Avatar / profile picture (SVG) ──
cat > /usr/share/mindwareos/avatar.svg << 'AVATARSVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <defs>
    <linearGradient id="avatarBg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#7c3aed;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#1d4ed8;stop-opacity:1" />
    </linearGradient>
  </defs>
  <circle cx="100" cy="100" r="100" fill="url(#avatarBg)"/>
  <text x="100" y="115" font-family="monospace" font-size="60" font-weight="bold"
        fill="white" text-anchor="middle">MW</text>
  <text x="100" y="150" font-family="monospace" font-size="12"
        fill="rgba(255,255,255,0.7)" text-anchor="middle">MindwareOS</text>
</svg>
AVATARSVG

# Copy avatar to user home
cp /usr/share/mindwareos/avatar.svg /home/${USERNAME}/.face
chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.face

CHROOT

  # Audio section
  if [[ "$INSTALL_AUDIO" == true ]]; then
    cat >> /mnt/mindware-chroot.sh << 'AUDIOCHROOT'
# ── Audio (PipeWire) ──
pacman -S --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack \
  wireplumber pavucontrol pamixer
systemctl enable --global pipewire pipewire-pulse wireplumber
AUDIOCHROOT
  fi

  # Bluetooth
  if [[ "$INSTALL_BLUETOOTH" == true ]]; then
    cat >> /mnt/mindware-chroot.sh << 'BTCHROOT'
# ── Bluetooth ──
pacman -S --noconfirm bluez bluez-utils
systemctl enable bluetooth
BTCHROOT
  fi

  # GPU Drivers
  if [[ "$INSTALL_NVIDIA" == true ]]; then
    cat >> /mnt/mindware-chroot.sh << 'NVIDIACHROOT'
# ── NVIDIA Drivers ──
pacman -S --noconfirm nvidia nvidia-utils nvidia-settings lib32-nvidia-utils
# Add nvidia modules to initramfs
sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
NVIDIACHROOT
  fi

  if [[ "$INSTALL_AMD" == true ]]; then
    cat >> /mnt/mindware-chroot.sh << 'AMDCHROOT'
# ── AMD Drivers ──
pacman -S --noconfirm mesa vulkan-radeon libva-mesa-driver mesa-vdpau lib32-mesa lib32-vulkan-radeon
AMDCHROOT
  fi

  if [[ "$INSTALL_INTEL" == true ]]; then
    cat >> /mnt/mindware-chroot.sh << 'INTELCHROOT'
# ── Intel Drivers ──
pacman -S --noconfirm mesa vulkan-intel intel-media-driver lib32-mesa lib32-vulkan-intel
INTELCHROOT
  fi

  # VM Guest tools
  if [[ "$INSTALL_VIRTUALBOX" == true ]]; then
    cat >> /mnt/mindware-chroot.sh << 'VBOXCHROOT'
pacman -S --noconfirm virtualbox-guest-utils
systemctl enable vboxservice
VBOXCHROOT
  fi

  if [[ "$INSTALL_VMWARE" == true ]]; then
    cat >> /mnt/mindware-chroot.sh << 'VMWCHROOT'
pacman -S --noconfirm open-vm-tools xf86-video-vmware
systemctl enable vmtoolsd vmware-vmblock-fuse
VMWCHROOT
  fi

  # Desktop environment
  case "$DESKTOP_ENV" in
    kde)
      cat >> /mnt/mindware-chroot.sh << 'KDECHROOT'
# ── KDE Plasma ──
pacman -S --noconfirm plasma plasma-wayland-session kde-applications-meta \
  sddm sddm-kcm firefox konsole dolphin kate ark okular spectacle \
  gwenview kdeconnect power-profiles-daemon packagekit-qt5
systemctl enable sddm
# KDE wallpaper
mkdir -p /usr/share/wallpapers/MindwareOS/contents/images
cp /usr/share/mindwareos/wallpaper.svg /usr/share/wallpapers/MindwareOS/contents/images/1920x1080.svg
cat > /usr/share/wallpapers/MindwareOS/metadata.json << KDEWP
{"KPlugin":{"Name":"MindwareOS","Description":"MindwareOS default wallpaper"}}
KDEWP
KDECHROOT
      ;;
    gnome)
      cat >> /mnt/mindware-chroot.sh << 'GNOMECHROOT'
# ── GNOME ──
pacman -S --noconfirm gnome gnome-extra gdm firefox gnome-tweaks
systemctl enable gdm
# Set wallpaper via dconf defaults
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/00-mindware << DCONF
[org/gnome/desktop/background]
picture-uri='file:///usr/share/mindwareos/wallpaper.svg'
picture-uri-dark='file:///usr/share/mindwareos/wallpaper.svg'
picture-options='zoom'
DCONF
dconf update 2>/dev/null || true
GNOMECHROOT
      ;;
    xfce)
      cat >> /mnt/mindware-chroot.sh << 'XFCECHROOT'
# ── XFCE ──
pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter \
  firefox thunar mousepad ristretto xarchiver
systemctl enable lightdm
XFCECHROOT
      ;;
    i3)
      cat >> /mnt/mindware-chroot.sh << 'I3CHROOT'
# ── i3wm ──
pacman -S --noconfirm i3-wm i3blocks i3status i3lock dmenu lightdm \
  lightdm-gtk-greeter xorg xorg-xinit alacritty feh picom polybar \
  firefox rofi dunst
systemctl enable lightdm
# i3 config with MindwareOS branding
mkdir -p /home/${USERNAME}/.config/i3
cat > /home/${USERNAME}/.config/i3/config << I3CONF
# MindwareOS i3 config
set $mod Mod4
font pango:monospace 10
floating_modifier $mod
bindsym $mod+Return exec alacritty
bindsym $mod+d exec dmenu_run
bindsym $mod+Shift+q kill
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec i3-nagbar -t warning -m 'Exit MindwareOS i3?' -B 'Yes' 'i3-msg exit'
# Colorscheme — MindwareOS purple
set $bg     #0d0d1a
set $accent #7c3aed
set $light  #e2d9f3
client.focused          $accent $accent $light $accent $accent
client.unfocused        $bg     $bg     #666666 $bg     $bg
exec --no-startup-id feh --bg-scale /usr/share/mindwareos/wallpaper.svg
I3CONF
I3CHROOT
      ;;
    hyprland)
      cat >> /mnt/mindware-chroot.sh << 'HYPRCHROOT'
# ── Hyprland ──
pacman -S --noconfirm hyprland waybar wofi kitty firefox \
  xdg-desktop-portal-hyprland qt5-wayland qt6-wayland polkit-gnome \
  grim slurp wl-clipboard mako sddm
systemctl enable sddm
mkdir -p /home/${USERNAME}/.config/hypr
cat > /home/${USERNAME}/.config/hypr/hyprland.conf << HYPRCONF
# MindwareOS Hyprland config
monitor=,preferred,auto,1
exec-once = waybar & mako & swaybg -i /usr/share/mindwareos/wallpaper.svg
input { kb_layout = us; follow_mouse = 1; touchpad { natural_scroll = yes } }
general {
  gaps_in = 5; gaps_out = 10; border_size = 2
  col.active_border = rgba(7c3aedff) rgba(1d4ed8ff) 45deg
  col.inactive_border = rgba(1a0a2eff)
  layout = dwindle
}
decoration { rounding = 10; blur { enabled = true; size = 8; passes = 2 } drop_shadow = yes }
animations { enabled = yes; bezier = mindware, 0.05, 0.9, 0.1, 1.05 }
$mainMod = SUPER
bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive
bind = $mainMod, D, exec, wofi --show drun
HYPRCONF
HYPRCHROOT
      ;;
    mate)
      cat >> /mnt/mindware-chroot.sh << 'MATECHROOT'
pacman -S --noconfirm mate mate-extra lightdm lightdm-gtk-greeter firefox
systemctl enable lightdm
MATECHROOT
      ;;
    cinnamon)
      cat >> /mnt/mindware-chroot.sh << 'CINCHROOT'
pacman -S --noconfirm cinnamon lightdm lightdm-gtk-greeter firefox nemo
systemctl enable lightdm
CINCHROOT
      ;;
    minimal)
      info "Minimal install — no DE. You monster. We respect you."
      ;;
  esac

  # GRUB
  cat >> /mnt/mindware-chroot.sh << GRUBCHROOT

# ── GRUB Bootloader ──
pacman -S --noconfirm grub efibootmgr os-prober

if [[ -d /sys/firmware/efi ]]; then
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=MindwareOS
else
  grub-install --target=i386-pc ${TARGET_DISK}
fi

# GRUB Branding
sed -i 's/GRUB_DISTRIBUTOR="Arch"/GRUB_DISTRIBUTOR="MindwareOS"/' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
cat >> /etc/default/grub << GRUBEOF
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE=menu
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3"
GRUBEOF

grub-mkconfig -o /boot/grub/grub.cfg

GRUBCHROOT

  # AUR helper
  if [[ "$INSTALL_AUR" == true ]]; then
    cat >> /mnt/mindware-chroot.sh << AURCHROOT
# ── AUR Helper (yay) ──
cd /tmp
git clone https://aur.archlinux.org/yay-bin.git
chown -R ${USERNAME}:${USERNAME} yay-bin
cd yay-bin
sudo -u ${USERNAME} makepkg -si --noconfirm
cd /
rm -rf /tmp/yay-bin
# Add yay alias via mind
echo 'alias yaur="yay -S"' >> /home/${USERNAME}/.bashrc
AURCHROOT
  fi

  # Mkinitcpio
  cat >> /mnt/mindware-chroot.sh << 'MKCHROOT'
# ── Initramfs ──
mkinitcpio -P

# ── Final Branding: issue file ──
cat > /etc/issue << 'ISSUE'

  ╔══════════════════════════════════════╗
  ║          M i n d w a r e O S        ║
  ║    "An OS that respects your IQ."   ║
  ╚══════════════════════════════════════╝
  \l

ISSUE

cat > /etc/issue.net << 'ISSUENET'
MindwareOS v1.0.0 - Arch-based
"An OS that respects your intelligence."
ISSUENET

echo "MindwareOS chroot configuration complete."
MKCHROOT

  chmod +x /mnt/mindware-chroot.sh
  progress "Running chroot configuration" "arch-chroot /mnt /mindware-chroot.sh"
  success "System configured inside chroot"
}

# ─── Cleanup ──────────────────────────────────────────────
cleanup() {
  section "CLEANUP"

  progress "Removing install script from target" "rm -f /mnt/mindware-chroot.sh"
  progress "Unmounting filesystems" \
    "umount -R /mnt 2>/dev/null || true; swapoff -a 2>/dev/null || true"

  success "Cleanup complete. Your disk is now MindwareOS property."
}

# ─── Final Screen ─────────────────────────────────────────
final_screen() {
  clear
  echo -e "${PURPLE}${BOLD}"
  cat << 'FINAL'

  ╔═══════════════════════════════════════════════════════════════╗
  ║                                                               ║
  ║        🧠  MindwareOS Installation Complete!  🧠             ║
  ║                                                               ║
  ╠═══════════════════════════════════════════════════════════════╣
  ║                                                               ║
  ║   Your machine has been upgraded from "just a computer"       ║
  ║   to an actual  M I N D W A R E  experience.                 ║
  ║                                                               ║
  ║   ✓  Base system installed                                    ║
  ║   ✓  Hardware drivers configured                             ║
  ║   ✓  Desktop environment ready                               ║
  ║   ✓  'mind' package manager active                           ║
  ║   ✓  MindwareOS branding applied                             ║
  ║   ✓  Bootloader (GRUB) installed                             ║
  ║                                                               ║
  ╠═══════════════════════════════════════════════════════════════╣
  ║                                                               ║
  ║   After reboot, remember:                                     ║
  ║     mind install <pkg>   → install packages                  ║
  ║     mind update          → update everything                  ║
  ║     mind help            → show all commands                  ║
  ║                                                               ║
  ╠═══════════════════════════════════════════════════════════════╣
  ║                                                               ║
  ║   "The computer is a bicycle for the mind."                  ║
  ║   — Steve Jobs (We built the bicycle. You ride it now.)      ║
  ║                                                               ║
  ╚═══════════════════════════════════════════════════════════════╝

FINAL
  echo -e "${RESET}"
  echo -e "${CYAN}  Remove installation media and press ENTER to reboot...${RESET}"
  read -r
  reboot
}

# ─── Summary Before Install ───────────────────────────────
show_summary() {
  section "INSTALLATION SUMMARY"
  echo -e "  ${BOLD}${WHITE}System:${RESET}"
  echo -e "    ${CYAN}Disk:${RESET}        ${TARGET_DISK}"
  echo -e "    ${CYAN}Filesystem:${RESET}  $( [[ "$USE_BTRFS" == true ]] && echo "BTRFS" || echo "ext4" )"
  echo -e "    ${CYAN}Swap:${RESET}        ${SWAP_SIZE}"
  echo -e "    ${CYAN}Boot mode:${RESET}   ${BOOT_MODE}"
  echo -e "\n  ${BOLD}${WHITE}Identity:${RESET}"
  echo -e "    ${CYAN}Hostname:${RESET}    ${HOSTNAME_VAL}"
  echo -e "    ${CYAN}Username:${RESET}    ${USERNAME}"
  echo -e "    ${CYAN}Timezone:${RESET}    ${TIMEZONE}"
  echo -e "\n  ${BOLD}${WHITE}Software:${RESET}"
  echo -e "    ${CYAN}Desktop:${RESET}     ${DESKTOP_ENV}"
  echo -e "    ${CYAN}Audio:${RESET}       $( [[ "$INSTALL_AUDIO" == true ]] && echo "PipeWire" || echo "None" )"
  echo -e "    ${CYAN}Bluetooth:${RESET}   $( [[ "$INSTALL_BLUETOOTH" == true ]] && echo "Yes" || echo "No" )"
  echo -e "    ${CYAN}AUR Helper:${RESET}  $( [[ "$INSTALL_AUR" == true ]] && echo "yay" || echo "No" )"
  echo -e "\n  ${BOLD}${WHITE}GPU Drivers:${RESET}"
  [[ "$INSTALL_NVIDIA" == true ]] && echo -e "    ${GREEN}✓${RESET} NVIDIA (proprietary)"
  [[ "$INSTALL_AMD" == true ]]    && echo -e "    ${GREEN}✓${RESET} AMD (AMDGPU/Mesa)"
  [[ "$INSTALL_INTEL" == true ]]  && echo -e "    ${GREEN}✓${RESET} Intel (Mesa)"
  echo

  if ! confirm "Everything look good? Begin installation?"; then
    warn "Installation cancelled. Come back when you're ready."
    exit 0
  fi
}

# ─── Main Entrypoint ──────────────────────────────────────
main() {
  # Init log
  echo "MindwareOS Installation Log — $(date)" > "$LOG_FILE"

  print_banner
  echo -e "${WHITE}  This script will install MindwareOS on your machine.${RESET}"
  echo -e "${DIM}  All actions are logged to: ${LOG_FILE}${RESET}\n"
  quote

  if ! confirm "Ready to begin? (This will format a disk)"; then
    echo -e "\n${YELLOW}  See you on the other side. 👋${RESET}\n"
    exit 0
  fi

  preflight_checks
  select_disk
  setup_user
  select_desktop
  detect_hardware
  setup_optional
  show_summary

  echo -e "\n${BG_PURPLE}${WHITE}${BOLD}  🚀 Starting MindwareOS installation...  ${RESET}\n"
  quote

  partition_disk
  install_base
  generate_fstab
  configure_system
  cleanup
  final_screen
}

main "$@"
