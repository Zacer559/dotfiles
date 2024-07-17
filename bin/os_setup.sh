#!/bin/bash

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Function to setup Ubuntu
function ubuntu_setup {
  install_package "ansible" "sudo apt-get install -y ansible"
  install_package "python3" "sudo apt-get install -y python3"
  install_package "python3-pip" "sudo apt-get install -y python3-pip"
  install_package "python3-watchdog" "sudo apt-get install -y python3-watchdog"
}

# Function to setup Arch-based systems
function arch_setup {
  install_package "ansible" "sudo pacman -S --noconfirm ansible"
  install_package "python3" "sudo pacman -S --noconfirm python3"
  install_package "python-pip" "sudo pacman -S --noconfirm python-pip"
  install_package "python-watchdog" "sudo pacman -S --noconfirm python-watchdog"
  install_package "openssh" "sudo pacman -S --noconfirm openssh"

  _task "Setting Locale"
  _cmd "sudo localectl set-locale LANG=en_US.UTF-8"
}

# Function to install a package if it's not already installed
function install_package {
  local package_name=$1
  local install_command=$2

  if ! is_package_installed "$package_name"; then
    _task "Installing $package_name"
    _cmd "$install_command"
  fi
}

# Function to check if a package is installed
function is_package_installed {
  local package_name=$1

  case $ID in
  ubuntu)
    dpkg -s "$package_name" >/dev/null 2>&1
    ;;
  endeavouros | arch | manjaro)
    pacman -Q "$package_name" >/dev/null 2>&1
    ;;
  *)
    return 1
    ;;
  esac
}

# Function to detect and setup OS
function detect_and_setup_os {
  source /etc/os-release
  _task "Loading Setup for detected OS: $ID"
  case $ID in
  ubuntu)
    ubuntu_setup
    ;;
  endeavouros | arch | manjaro)
    arch_setup
    ;;
  *)
    _task "Unsupported OS"
    _cmd "echo 'Unsupported OS'"
    ;;
  esac
}
