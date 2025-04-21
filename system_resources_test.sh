#!/bin/bash
# system_resources_test.sh
# Script to check system resources and exit with appropriate code if thresholds are exceeded

# Define thresholds
CPU_THRESHOLD=90    # CPU usage threshold (%)
MEM_THRESHOLD=90    # Memory usage threshold (%)
DISK_THRESHOLD=90   # Disk usage threshold (%)

# Initialize exit code
EXIT_CODE=0

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check CPU usage
check_cpu() {
    log_message "Checking CPU usage..."
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
    
    log_message "Current CPU usage: ${CPU_USAGE}%"
    
    if [ $CPU_USAGE -gt $CPU_THRESHOLD ]; then
        log_message "WARNING: CPU usage exceeds threshold of ${CPU_THRESHOLD}%"
        return 1
    else
        log_message "CPU usage is within acceptable limits"
        return 0
    fi
}

# Check memory usage
check_memory() {
    log_message "Checking memory usage..."
    
    # Get memory information
    MEM_INFO=$(free -m | grep Mem)
    TOTAL_MEM=$(echo $MEM_INFO | awk '{print $2}')
    USED_MEM=$(echo $MEM_INFO | awk '{print $3}')
    
    # Calculate percentage
    MEM_USAGE=$((USED_MEM * 100 / TOTAL_MEM))
    
    log_message "Current memory usage: ${MEM_USAGE}% (${USED_MEM}MB / ${TOTAL_MEM}MB)"
    
    if [ $MEM_USAGE -gt $MEM_THRESHOLD ]; then
        log_message "WARNING: Memory usage exceeds threshold of ${MEM_THRESHOLD}%"
        return 1
    else
        log_message "Memory usage is within acceptable limits"
        return 0
    fi
}

# Check disk usage
check_disk() {
    log_message "Checking disk usage..."
    
    # Get disk information for root partition
    DISK_USAGE=$(df -h / | grep -v Filesystem | awk '{print $5}' | tr -d '%')
    
    log_message "Current disk usage: ${DISK_USAGE}%"
    
    if [ $DISK_USAGE -gt $DISK_THRESHOLD ]; then
        log_message "WARNING: Disk usage exceeds threshold of ${DISK_THRESHOLD}%"
        return 1
    else
        log_message "Disk usage is within acceptable limits"
        return 0
    fi
}

# Run checks
log_message "Starting system resource check"

# Check CPU
if ! check_cpu; then
    EXIT_CODE=1
fi

# Check memory
if ! check_memory; then
    EXIT_CODE=1
fi

# Check disk
if ! check_disk; then
    EXIT_CODE=1
fi

# Output final results
if [ $EXIT_CODE -eq 0 ]; then
    log_message "All system resources are within acceptable limits"
else
    log_message "One or more system resources exceed acceptable limits"
fi

log_message "System resource check completed with exit code: $EXIT_CODE"

# Exit with appropriate code
exit $EXIT_CODE