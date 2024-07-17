#!/bin/bash

# Color codes and emoji definitions
source "$(dirname "$0")/colors_and_emojis.sh"

# Paths
VAULT_SECRET="$HOME/.ansible-vault/vault.secret"
DOTFILES_DIR="$HOME/.dotfiles"
INVENTORY_FILE="$DOTFILES_DIR/inventory"
SSH_DIR="$HOME/.ssh"
IS_FIRST_RUN="$HOME/.dotfiles_run"
DOTFILES_LOG="$HOME/.dotfiles.log"
GROUP_VARS_FILE="$DOTFILES_DIR/group_vars/all.yml"
# Exit on any error
set -e

# Function to set and display task header
function _task {
  if [[ -n "$TASK" ]]; then
    printf "%b%b [✓] %b%s%b\n" "$OVERWRITE" "$LGREEN" "$LGREEN" "$TASK" "$NC"
  fi
  TASK=$1
  printf "%b [ ] %s\n%b" "$LBLACK" "$TASK" "$LRED"
}

# Function to execute a command and handle errors
function _cmd {
  [[ ! -f "$DOTFILES_LOG" ]] && touch "$DOTFILES_LOG"
  : >"$DOTFILES_LOG"
  if eval "$1" 1>/dev/null 2>"$DOTFILES_LOG"; then
    return 0
  fi
  printf "%b%b [X] %b%s%b\n" "$OVERWRITE" "$LRED" "$LRED" "$TASK" "$NC"
  while read -r line; do
    printf "      %s\n" "$line"
  done <"$DOTFILES_LOG"
  printf "\n"
  rm "$DOTFILES_LOG"
  exit 1
}

# Function to clear current task
function _clear_task {
  TASK=""
}

# Function to mark task as done
function _task_done {
  printf "%b%b [✓] %b%s%b\n" "$OVERWRITE" "$LGREEN" "$LGREEN" "$TASK" "$NC"
  _clear_task
}

# Function to print error messages
function print_error {
  printf "%b %b%s%b\n" "$X_MARK" "$RED" "$1" "$NC"
}

# Function to print success messages
function print_success {
  printf "%b %b%s%b\n" "$CHECK_MARK" "$GREEN" "$1" "$NC"
}
# Function to print warning messages
function print_warning {
  printf "%b %b%s%b\n" "$WARNING" "$YELLOW" "$1" "$NC"
}
# Function to print info messages
function print_info {
  printf "%b %b%s%b\n" "$ARROW" "$CYAN" "$1" "$NC"
}

# Usage function
function usage {
  echo "Usage: $0 [-r role1,role2,...] [--roles role1,role2,...] [-h] [--help]"
  echo
  echo "Options:"
  echo "  -r, --roles    Specify the roles to run, separated by commas"
  echo "  -h, --help     Display this help message"
}

# Function to update Ansible Galaxy
function update_ansible_galaxy {
  local os=$1
  local os_requirements=""
  _task "Updating Ansible Galaxy"
  if [[ -f "$DOTFILES_DIR/requirements/$os.yml" ]]; then
    _task "Updating Ansible Galaxy with OS Config: $os"
    os_requirements="$DOTFILES_DIR/requirements/$os.yml"
  fi
  _cmd "ansible-galaxy install -r $DOTFILES_DIR/requirements/common.yml $os_requirements"
}

# Check if VAULT_SECRET exists, is not empty, and can correctly decrypt existing variables
function check_vault_secret {
  _task "Checking Ansible Vault secret"
  local vault_dir
  vault_dir=$(dirname "$VAULT_SECRET")
  local temp_vault_file
  temp_vault_file=$(mktemp)
  local is_valid=false

  # Ensure ansible-vault is installed
  if ! command -v ansible-vault &>/dev/null; then
    print_error "ansible-vault could not be found. Please install Ansible."
    exit 1
  fi

  # Extract the first encrypted part of the group_vars file, skipping the first line
  awk 'NR > 1 && /!vault/ {flag=1; next} flag {print; if (NF==0) exit}' "$GROUP_VARS_FILE" | head -n 6 >"$temp_vault_file"

  # Remove any leading spaces or tabs from the temporary vault file
  sed -i 's/^[ \t]*//' "$temp_vault_file"

  # Create vault directory if it doesn't exist
  if [[ ! -d "$vault_dir" ]]; then
    mkdir -p "$vault_dir"
  fi

  while [ "$is_valid" = false ]; do
    if [[ ! -f "$VAULT_SECRET" || ! -s "$VAULT_SECRET" ]]; then
      print_warning "Ansible Vault secret is missing or empty."
      read -srp "Please enter your Ansible Vault secret: " vault_secret
      echo
      if [[ -z "$vault_secret" ]]; then
        print_error "Vault secret cannot be empty. Please try again."
        continue
      fi
      echo "$vault_secret" >"$VAULT_SECRET"
      chmod 600 "$VAULT_SECRET"
    fi

    # Try to decrypt the known encrypted variable from the temporary vault file
    if ansible-vault view "$temp_vault_file" --vault-password-file "$VAULT_SECRET" >/dev/null 2>&1; then
      is_valid=true
      print_success "Ansible Vault secret is valid."
    else
      print_error "Invalid Ansible Vault secret. Unable to decrypt variables in $GROUP_VARS_FILE"
      rm -f "$VAULT_SECRET"
    fi
  done

  rm -f "$temp_vault_file"
  _task_done
}
