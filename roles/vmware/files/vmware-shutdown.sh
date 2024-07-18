#!/bin/bash

# Function to log messages
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/vmware-shutdown.log
}

# Function to gracefully shut down VMs
shutdown_vms() {
  log "Starting VM shutdown process"

  # Get a list of running VMs
  VMS=$(vmrun list | grep -v "Total running VMs:")

  # Shutdown each VM
  while read -r vm; do
    log "Attempting to gracefully shut down VM: $vm"
    vmrun stop "$vm" soft
  done <<<"$VMS"

  # Wait for all VMs to shut down (adjust timeout as needed)
  timeout=300
  while [ $timeout -gt 0 ] && [ -n "$(vmrun list | grep -v 'Total running VMs:')" ]; do
    sleep 1
    ((timeout--))
  done

  # Force stop any remaining VMs
  REMAINING_VMS=$(vmrun list | grep -v "Total running VMs:")
  while read -r vm; do
    log "Force stopping VM: $vm"
    vmrun stop "$vm" hard
  done <<<"$REMAINING_VMS"

  log "VM shutdown process completed"
}

# Main execution
log "Starting VMware shutdown script"
shutdown_vms
log "VMware shutdown script completed"
