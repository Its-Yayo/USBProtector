#!/bin/bash

if [ "$(id -u)" != "0" ]; then
    echo "[x] Run this script as root: sudo $0"
    exit 1
fi

if [ "$(id -u)" != "0" ]; then
    echo "[x] Are you superuser? Run this script as root: sudo $0"
    exit 1
fi

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo "[x] Could not detect the distribution."
        exit 1
    fi
}

install_uhubctl() {
    case $DISTRO in
        "debian"|"ubuntu"|"linuxmint")
            apt update && apt install -y uhubctl
            ;;
        "arch"|"manjaro"|"endeavouros")
            pacman -Sy --noconfirm uhubctl
            ;;
        *)
            echo "[x] Unsupported distribution. Install uhubctl manually."
            exit 1
            ;;
    esac

    if ! command -v uhubctl &>/dev/null; then
        echo "[x] Failed to install uhubctl."
        exit 1
    fi
}

disable_usb_power() {
    echo "[x] Disabling USB power..."
    uhubctl -a off 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "[x] USB power disabled."
    else
        echo "[x] Your hardware does not support USB power control."
        echo "    Using alternative method (disabling USB kernel modules)..."
        disable_kernel_modules
    fi
}

disable_kernel_modules() {
    echo "[x] Disabling USB kernel modules..."
    # Remove USB kernel modules
    modprobe -r usb_storage ehci_hcd ohci_hcd uhci_hcd xhci_hcd 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "[x] USB kernel modules disabled."
        echo "[x] All USB devices will stop working."
    else
        echo "[x] Failed to disable kernel modules. Check your system configuration."
    fi
}

revert_changes() {
    echo "[x] Reverting changes..."
    modprobe usb_storage ehci_hcd ohci_hcd uhci_hcd xhci_hcd 2>/dev/null
    uhubctl -a on 2>/dev/null
    echo "[x] USB power restored."
}

menu() {
    echo "
      _    _  ____  ____      _____          ___
     | |  | |/ ___|| __ )    / ___|___  _ __ | |_ _ __ ___ | ! !_ _   __     
     | |  | |\___ \|  _ \   | |   / _ \| '_ \| __| '__/ _ \| | | _ \ '__|   
     | |__| | ___) | |_) |  | |__| (_) | | | | |_| | | (_) | | | __/ |  
      \____/ |____/|____/____\____\___/|_| |_|\__|_|  \___/|_|_\___|_|     
                                                                        v0.01

    Made by: Elyayoveloz

    Choose.
    1) Protect USB ports (disable power)
    2) Protect USB ports (disable kernel modules)
    3) Revert changes
    4) Exit
    "
    read -p "Choose an option: " option

    case $option in
        1)
            detect_distro
            install_uhubctl
            disable_usb_power
            ;;
        2)
            disable_kernel_modules
            ;;
        3)
            revert_changes
            ;;
        4)
            exit 0
            ;;
        *)
            echo "[x] Invalid option."
            ;;
    esac
}

menu