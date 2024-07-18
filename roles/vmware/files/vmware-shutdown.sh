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

    # First attempt: Graceful shutdown for all VMs
    while read -r vm; do
        log "Attempting to gracefully shut down VM: $vm"
        vmrun stop "$vm" soft
    done <<< "$VMS"

    # Wait and check (up to 5 minutes)
    for i in {1..30}; do
        REMAINING_VMS=$(vmrun list | grep -v "Total running VMs:")
        if [ -z "$REMAINING_VMS" ]; then
            log "All VMs have been successfully shut down"
            return 0
        fi
        log "Waiting for VMs to shut down (attempt $i of 30)"
        sleep 10
    done

    # Second attempt: Try graceful shutdown again for remaining VMs
    log "Some VMs are still running. Attempting graceful shutdown again."
    while read -r vm; do
        log "Re-attempting graceful shutdown for VM: $vm"
        vmrun stop "$vm" soft
    done <<< "$REMAINING_VMS"

    # Final wait and check (up to 2 more minutes)
    for i in {1..12}; do
        FINAL_VMS=$(vmrun list | grep -v "Total running VMs:")
        if [ -z "$FINAL_VMS" ]; then
            log "All VMs have been successfully shut down after second attempt"
            return 0
        fi
        log "Waiting for remaining VMs to shut down (final attempt $i of 12)"
        sleep 10
    done

    # If there are still VMs running, log them but don't force stop
    if [ -n "$FINAL_VMS" ]; then
        log "WARNING: The following VMs could not be shut down gracefully:"
        while read -r vm; do
            log "  - $vm"
        done <<< "$FINAL_VMS"
        log "Manual intervention may be required for these VMs"
    fi
}

# Main execution
log "Starting VMware shutdown script"
shutdown_vms
log "VMware shutdown script completed"
