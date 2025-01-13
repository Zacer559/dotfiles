#!/bin/bash

# Exit on any error
set -e

BTRFS_ROOT="/tmp/btrfs-root"
LUKS_DEVICE="/dev/mapper/luks-4c5bfc34-1605-4116-8e4d-5f145e6e8175"
SNAP_DIR="_btrbk_snap"
RESTIC_REPO="/mnt/veracrypt2/restic-repo"
RESTIC_SOURCE="/mnt/veracrypt1"

# Function for cleanup
cleanup() {
  echo "Performing cleanup..."

  # Delete btrbk snapshots if they exist
  if [ -d "$BTRFS_ROOT/$SNAP_DIR" ]; then
    echo "Cleaning up btrbk snapshots..."
    sudo find "$BTRFS_ROOT/$SNAP_DIR" -maxdepth 1 -name "@*" -exec sudo btrfs subvolume delete {} \;
  fi

  if mountpoint -q "$BTRFS_ROOT"; then
    sudo umount "$BTRFS_ROOT"
  fi
  sudo rm -rf "$BTRFS_ROOT"
}

# Function to handle errors
error_handler() {
  echo "Error occurred on line $1"
  cleanup
  exit 1
}

# Set up error handling
trap 'error_handler $LINENO' ERR

# Ensure clean state
cleanup

echo "Creating mount point..."
sudo mkdir -p "$BTRFS_ROOT"

echo "Mounting BTRFS root..."
sudo mount "$LUKS_DEVICE" "$BTRFS_ROOT" -o subvolid=5

echo "Creating snapshot directory if it doesn't exist..."
if [ ! -d "$BTRFS_ROOT/$SNAP_DIR" ]; then
  sudo btrfs subvolume create "$BTRFS_ROOT/$SNAP_DIR"
fi

echo "Running btrbk backup..."
sudo btrbk run

echo "Running restic backup..."

# Run restic backup with error handling
if ! restic -r "$RESTIC_REPO" backup "$RESTIC_SOURCE"; then
  echo "Restic backup failed!"
  error_handler $LINENO
fi

echo "Restic backup completed successfully!"

# Clean up
cleanup

echo "All done!"
