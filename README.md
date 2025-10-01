# 🚀 QEMU Virtual Machine Manager Script

Simplify working with **QEMU/KVM** on Debian-based Linux systems with this script.  
Easily **create, delete, run, and inspect virtual machines** without the hassle of long commands.  

---

## 🛠️ Prerequisites

The script automatically installs required dependencies for **Debian-based distributions** (Ubuntu, Debian, Xubuntu, etc.).  

| Dependency | Purpose |
|------------|---------|
| QEMU / KVM | Virtualization engine |
| Virt-Manager | Graphical VM manager |
| Libvirt | VM management daemon |
| Bridge Utilities | Network bridge setup |
| OVMF | UEFI support for VMs |
| SPICE Client | Display management |

> ✅ The script handles installation, so you don’t need to worry about manual setup.

---

## 💡 Features

| Feature | Description |
|---------|-------------|
| Create VM | Quickly set up a new virtual machine |
| Delete VM | Remove unused VMs easily |
| Start/Run VM | Launch a VM without typing long commands |
| Inspect VM | View detailed information about your VMs |
| User-friendly | Similar to VirtualBox, but lighter and faster |

---

## 💻 Usage

Run the script using:

```bash
./vm.sh
