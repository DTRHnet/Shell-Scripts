#!/usr/bin/env bash
set -e

# =======================
# L2DK.sh - Live to Drive (Kali)
# DTRH.net | admin [at] dtrh [dot] net
# =======================

# --------- Colors ---------
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
MAGENTA="\033[35m"
RESET="\033[0m"

# --------- Banner ---------
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ___     _______ ______   ___ ___         __    "
    echo " |   |   |       |   _  \\ |   Y   ) .-----|  |--."
    echo " |.  |   |___|   |.  |   \\|.  1  /__|__ --|     |"
    echo " |.  |___ /  ___/|.  |    |.  _  |__|_____|__|__|"
    echo " |:  1   |:  1  \\|:  1    |:  |   \\              "
    echo " |::.. . |::.. . |::.. . /|::.| .  )             "
    echo "  ------- ------- ------   --- ---               "
    echo -e "${GREEN}Live to Drive (Kali) L2DK.sh"
    echo -e "${YELLOW}DTRH.net | admin [at] dtrh [dot] net"
    echo -e "${MAGENTA}Summary: Copies Kali Live to internal drive for full persistent use"
    echo -e "${RESET}"
    sleep 3
}

# --------- Progress Bar ---------
progress_bar() {
    local duration=$1
    local message=$2
    echo -n "${CYAN}$message [${RESET}"
    for i in {1..20}; do
        echo -n "${GREEN}#${RESET}"
        sleep $(echo "$duration / 20" | bc -l)
    done
    echo -e "${CYAN}] Done${RESET}"
}

# --------- Yes/No prompt ---------
ask_yn() {
    local prompt="$1"
    while true; do
        read -rp "$(echo -e ${YELLOW}$prompt${RESET}) " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo -e "${RED}Please answer Yy or Nn.${RESET}";;
        esac
    done
}

# --------- Drive selection using fzf ---------
select_drive() {
    echo -e "${CYAN}Use arrow keys to select the target drive:${RESET}"
    lsblk -dno NAME,SIZE,MODEL | awk '{print $1 " - " $2}' | fzf --border --prompt="Select drive: " --height 10 > /tmp/selected_drive.txt
    TARGET=$(cat /tmp/selected_drive.txt)
    TARGET_DRIVE=$(echo $TARGET | awk '{print $1}')
    echo -e "${GREEN}Selected drive: /dev/$TARGET_DRIVE${RESET}"
}

select_partition() {
    echo -e "${CYAN}Select partition on /dev/$TARGET_DRIVE:${RESET}"
    lsblk -no NAME,SIZE,FSTYPE /dev/$TARGET_DRIVE | tail -n +2 | fzf --border --prompt="Select partition: " --height 10 > /tmp/selected_partition.txt
    PARTITION=$(cat /tmp/selected_partition.txt)
    PART_PATH="/dev/$(echo $PARTITION | awk '{print $1}')"
    echo -e "${GREEN}Selected partition: $PART_PATH${RESET}"
}

# --------- Main script ---------
show_banner
sudo apt-get install fzf > /dev/null

# Step 1: Detect drives
if ask_yn "Do you want to detect and select a drive?"; then
    select_drive
fi

# Step 2: Detect partitions
if ask_yn "Do you want to detect and select a partition?"; then
    select_partition
fi

# Step 3: Format partition
if ask_yn "Do you want to format $PART_PATH as ext4? WARNING: this will erase all data!"; then
    echo -e "${RED}Formatting $PART_PATH...${RESET}"
    mkfs.ext4 -F $PART_PATH
fi

# Step 4: Mount and copy root
MOUNT_POINT="/mnt/kali-root"
mkdir -p $MOUNT_POINT
echo -e "${CYAN}Mounting $PART_PATH at $MOUNT_POINT...${RESET}"
mount $PART_PATH $MOUNT_POINT

if ask_yn "Do you want to copy the current Kali Live system to $PART_PATH?"; then
    echo -e "${GREEN}Copying files...${RESET}"
    progress_bar 15 "Copying system"
    rsync -aAXHv --exclude={"/mnt/*","/media/*","/proc/*","/sys/*","/dev/*","/run/*","/tmp/*","/usr/lib/live/*"} / $MOUNT_POINT
fi

# Step 5: Final summary before execution
clear
echo -e "${MAGENTA}--------------------------------------------"
echo -e "${CYAN}Summary of planned actions:${RESET}"
echo -e "${YELLOW}Target Drive:${RESET} /dev/$TARGET_DRIVE"
echo -e "${YELLOW}Target Partition:${RESET} $PART_PATH"
echo -e "${YELLOW}Mount Point:${RESET} $MOUNT_POINT"
echo -e "${YELLOW}Format:${RESET} yes"
echo -e "${YELLOW}Copy Kali Live System:${RESET} yes"
echo -e "${MAGENTA}--------------------------------------------"

if ! ask_yn "Proceed with installation?"; then
    echo -e "${RED}Aborted by user.${RESET}"
    exit 1
fi

if ! ask_yn "Are you 100% sure? This will overwrite the partition!"; then
    echo -e "${RED}Aborted by user.${RESET}"
    exit 1
fi

# Step 6: Prepare special dirs for chroot
mkdir -p $MOUNT_POINT/{proc,sys,dev,run,boot/efi}
mount --bind /dev $MOUNT_POINT/dev
mount --bind /proc $MOUNT_POINT/proc
mount --bind /sys $MOUNT_POINT/sys
mount --bind /run $MOUNT_POINT/run

# Mount EFI if exists
EFI_PART="/dev/sda1"
if [[ -b "$EFI_PART" ]]; then
    mkdir -p $MOUNT_POINT/boot/efi
    mount $EFI_PART $MOUNT_POINT/boot/efi
fi

# Setup fstab
UUID_ROOT=$(blkid -s UUID -o value $PART_PATH)
UUID_EFI=$(blkid -s UUID -o value $EFI_PART)
cat <<EOF > $MOUNT_POINT/etc/fstab
UUID=$UUID_ROOT / ext4 defaults 0 1
UUID=$UUID_EFI /boot/efi vfat defaults 0 1
tmpfs /tmp tmpfs defaults,nosuid 0 0
EOF

# Install GRUB
echo -e "${CYAN}Installing GRUB...${RESET}"
chroot $MOUNT_POINT bash -c "
apt update
apt install -y grub-efi-amd64
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Kali
update-grub
"

echo -e "${GREEN}✅ Live-to-Drive installation complete!${RESET}"
echo "Reboot and boot from the internal disk."
df -h
