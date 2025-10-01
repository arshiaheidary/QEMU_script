#!/bin/bash 
set -euo pipefail

# Set environment for QEMU GTK to avoid XDG_RUNTIME_DIR error (only if exists)
if [ -d "/run/user/$(id -u)" ]; then
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
fi
export DISPLAY="${DISPLAY:-:0}"

# check required commands
for cmd in qemu-img qemu-system-x86_64; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is not installed or not in PATH. Please install it and retry."
    exit 1
  fi
done

read -p " you like download kvn qemu and ... ?(yes,no)" ans_2
if [ "$ans_2" = "yes" ];then
  sudo apt update && sudo apt install -y \
    qemu-kvm qemu-system-x86 qemu-utils \
    libvirt-daemon-system libvirt-clients \
    bridge-utils virt-manager cpu-checker \
    ovmf virt-viewer spice-client-gtk
  sudo usermod -aG kvm $USER
fi

echo "┌────────────────────────────────────────────────────────────────────────────┐"
echo "│ 🚀 Hi, I am QEMU and I am ready to launch your VM!                         │"
echo "│  👉 Quick notes:                                                           │"  
echo "│     - RAM must be in MB (minimum: 512 MB)                                  │"
echo "│     - Disk size in GB (minimum: 15 GB)                                     │"
echo "│     - Do not use duplicate VM names                                        │"
echo "│     - Place your ISO in ~/ before installation                             │"
echo "│     - Please dont run script with sudo                                     │"
echo "│     - If QEMU does not work correctly, please log out and log back in once.│"
echo "└────────────────────────────────────────────────────────────────────────────┘"

#available cpu core
cpu_core=$(nproc)

# directory for VMs
QEMU_DIR="${HOME%/}"/QEMU
mkdir -p "$QEMU_DIR"


# action selection
echo "┌───────────────┬──────────────────────────────────────────────┐"
echo "│ Action        │ Description                                  │"
echo "├───────────────┼──────────────────────────────────────────────┤"
echo "│ 1- Create VM  │ Setting up a new virtual machine             │"
echo "│ 2- Delete VM  │ Removing an existing virtual machine         │"
echo "│ 3- Run VM     │ Start the virtual machine (from disk)        │"
echo "│ 4- VM info    │ Show VM info (file exists?)                  │"
echo "└───────────────┴──────────────────────────────────────────────┘"

read -rp "please type a number ? " ans
# validate ans
until [[ "$ans" =~ ^[1-4]$ ]]; do
  read -rp "Please enter 1, 2, 3, or 4: " ans
done



if [ "$ans" -eq 1  ];then 
  # input name ram cpu core iso address disk size 
  
  # vm name 
  echo "________________________________________"
  read -rp "1- VM NAME ? " name
  echo "________________________________________"
  
  disk_address="$QEMU_DIR/$name.qcow2"

  # check vm name collision
  while [ -f "$disk_address" ]; do
    echo "Error: VM name '$name' is already used (file exists: $disk_address)."
    read -rp "please enter different VM name: " name
    disk_address="$QEMU_DIR/$name.qcow2"
  done

  # cpu core 
  echo "________________________________________"
  read -rp "2- CPU (cores) ? " cpu
  echo "________________________________________"
  # validate cpu cores
  while true; do
    if ! [[ "$cpu" =~ ^[0-9]+$ ]]; then
      read -rp "CPU cores must be a number. Please type again: " cpu
      continue
    fi
    if [ "$cpu" -lt 1 ]; then
      read -rp "CPU cores must be at least 1. Please type again: " cpu
      continue
    fi
    if [ "$cpu" -gt "$cpu_core" ]; then
      read -rp "Your system has $cpu_core cores. Enter a number <= $cpu_core: " cpu
      continue
    fi
    break
  done
  
  # ran 
  echo "________________________________________"
  read -rp "3- RAM (M) ? " ram
  echo "________________________________________"
  # validate RAM  
  while true; do
    if ! [[ "$ram" =~ ^[0-9]+$ ]]; then
      read -rp "RAM must be a number (MB). Please type again: " ram
      continue
    fi
    if [ "$ram" -lt 512 ]; then
      read -rp "RAM too small (min 512M). Please type again: " ram
      continue
    fi
    break
  done

  # disk size 
  echo "________________________________________"
  read -rp "4- DISK SIZE (G) ? " disk_size
  echo "________________________________________"
  
  # validate disk size (GB)
  while true; do
    if ! [[ "$disk_size" =~ ^[0-9]+$ ]]; then
      read -rp "Disk size must be a number (GB). Please type again: " disk_size
      continue
    fi
    if [ "$disk_size" -lt 15 ]; then
      read -rp "Disk size too small (min 15G). Please type again: " disk_size
      continue
    fi
    break
  done

  # ISO file 
  echo "___________________________________________________________"
  echo "| please type file address like this: /home/USER/...       |"
  echo "___________________________________________________________"
  read -rp "6- ISO ADDRESS ? " iso
  
  # check iso file
  if [ ! -f "$iso" ]; then
    echo "Error: ISO file not found at $iso"
    exit 1
  fi

  #  print table
  printf "┌─────────────┬──────────────────────────────────────────────┐\n"
  printf "│ %-11s │ %-40s │\n" "Parameter" "Value"
  printf "├─────────────┼──────────────────────────────────────────────┤\n"
  printf "│ %-11s │ %-40s │\n" "VM Name" "$name"
  printf "│ %-11s │ %-40s │\n" "RAM" "${ram}M"
  printf "│ %-11s │ %-40s │\n" "CPU Cores" "$cpu"
  printf "│ %-11s │ %-40s │\n" "Disk Size" "${disk_size}G"
  printf "│ %-11s │ %-40s │\n" "ISO File" "$iso"
  printf "└─────────────┴──────────────────────────────────────────────┘\n"


  echo "#############################"
  echo "#   start creating new VM   #"
  echo "#############################"
  qemu-img create -f qcow2 "$disk_address" "${disk_size}G"

  qemu-system-x86_64 \
    -enable-kvm \
    -m "${ram}M" \
    -smp "$cpu" \
    -cdrom "$iso" \
    -boot d \
    -drive file="$disk_address",format=qcow2,if=virtio \
    -display gtk,gl=on \
    -vga virtio \
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
    -audiodev pa,id=snd0 \
    -device ich9-intel-hda -device hda-output,audiodev=snd0
fi

if [ "$ans" -eq 3 ]; then
  
  echo "________________________________________"
  read -rp "1- VM NAME ? " name
  echo "________________________________________"
  read -rp "2- CPU (cores) ? " cpu
  echo "________________________________________"
  read -rp "3- RAM (M) ? " ram
  echo "________________________________________"

  # print table
  printf "┌─────────────┬──────────────────────────────────────────────┐\n"
  printf "│ %-11s │ %-40s │\n" "Parameter" "Value"
  printf "├─────────────┼──────────────────────────────────────────────┤\n"
  printf "│ %-11s │ %-40s │\n" "VM Name" "$name"
  printf "│ %-11s │ %-40s │\n" "RAM" "${ram}M"
  printf "│ %-11s │ %-40s │\n" "CPU Cores" "$cpu"
  printf "└─────────────┴──────────────────────────────────────────────┘\n"



  disk_address="$QEMU_DIR/$name.qcow2"

  echo "####################"
  echo "#   start run VM   #"
  echo "####################"
  if [ ! -f "$disk_address" ]; then
    echo "Error: Disk image not found: $disk_address"
    exit 1
  fi

  qemu-system-x86_64 \
    -enable-kvm \
    -m "${ram}M" \
    -smp "$cpu" \
    -drive file="$disk_address",format=qcow2,if=virtio \
    -display gtk,gl=on \
    -vga virtio \
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
    -audiodev pa,id=snd0 \
    -device ich9-intel-hda -device hda-output,audiodev=snd0
fi

if [ "$ans" -eq 2 ]; then
  echo "###################################"
  echo "#     start delete file.qcow2     #"
  echo "###################################"
  read -rp "what is your VM name ? " vm_name
  disk_delete="$QEMU_DIR/$vm_name.qcow2"
  if [ ! -f "$disk_delete" ]; then
    echo "File not found: $disk_delete"
    exit 1
  fi
  read -rp "Are you sure you want to delete '$disk_delete'? (yes/no) " confirm
  if [ "$confirm" = "yes" ]; then
    rm -f "$disk_delete"
    echo "Deleted: $disk_delete"
  else
    echo "Aborted."
  fi
fi

if [ "$ans" -eq 4 ]; then
  echo "______________"
  read -p "VM name ? " name_2
  echo " _____________"
  printf "\n"
  disk_address="$QEMU_DIR/$name_2.qcow2"
  printf "\n"
  echo "VM file: $disk_address"
  printf "\n"
  if [ -f "$disk_address" ]; then
    qemu-img info "$disk_address"
  else
    echo "Not found."
  fi
fi
