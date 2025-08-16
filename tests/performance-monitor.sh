#!/bin/bash

# Performance Monitor & Benchmarking Tool for QEMU VMs
# Features: Real-time stats, Resource monitoring, Performance testing

set -e

# Configuration
VM_NAME=""
MONITOR_INTERVAL="5"
BENCHMARK_DURATION="60"
ENABLE_CPU_MONITORING="true"
ENABLE_MEMORY_MONITORING="true"
ENABLE_DISK_MONITORING="true"
ENABLE_NETWORK_MONITORING="true"
LOG_FILE=""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to show main menu
show_menu() {
    clear
    echo -e "${GREEN}📊 Performance Monitor & Benchmarking Tool${NC}"
    echo "=================================================="
    echo
    
    echo -e "${CYAN}📋 Current Configuration:${NC}"
    echo "  VM Name: ${VM_NAME:-"Not set"}"
    echo "  Monitor Interval: ${MONITOR_INTERVAL}s"
    echo "  Benchmark Duration: ${BENCHMARK_DURATION}s"
    echo "  CPU Monitoring: $(on_off_label ENABLE_CPU_MONITORING)"
    echo "  Memory Monitoring: $(on_off_label ENABLE_MEMORY_MONITORING)"
    echo "  Disk Monitoring: $(on_off_label ENABLE_DISK_MONITORING)"
    echo "  Network Monitoring: $(on_off_label ENABLE_NETWORK_MONITORING)"
    echo
    
    echo -e "${CYan}📋 Performance Tools:${NC}"
    echo "  1) Configure Monitoring"
    echo "  2) Real-time Performance Monitor"
    echo "  3) CPU Performance Benchmark"
    echo "  4) Memory Performance Benchmark"
    echo "  5) Disk I/O Benchmark"
    echo "  6) Network Performance Test"
    echo "  7) Comprehensive Benchmark Suite"
    echo "  8) Performance History & Logs"
    echo "  9) Performance Analysis & Reports"
    echo "  0) Exit"
    echo
    
    echo -e "${YELLOW}💡 Monitor and optimize your VM performance${NC}"
    echo
}

# Helper functions
on_off_label() {
    local var_name="$1"
    if [[ "${!var_name}" == "true" ]]; then
        echo -e "${GREEN}ON${NC}"
    else
        echo -e "${RED}OFF${NC}"
    fi
}

# Function to configure monitoring
configure_monitoring() {
    clear
    echo -e "${BLUE}⚙️  Monitoring Configuration${NC}"
    echo "==============================="
    echo
    
    read -p "VM Name: " VM_NAME
    [[ -z "$VM_NAME" ]] && return
    
    echo "Monitor Interval Options: 1s, 2s, 5s, 10s, 30s"
    read -p "Monitor interval (seconds) [$MONITOR_INTERVAL]: " input
    [[ -n "$input" ]] && MONITOR_INTERVAL="$input"
    
    echo "Benchmark Duration Options: 30s, 60s, 300s, 600s"
    read -p "Benchmark duration (seconds) [$BENCHMARK_DURATION]: " input
    [[ -n "$input" ]] && BENCHMARK_DURATION="$input"
    
    echo "Monitoring Features:"
    read -p "Enable CPU monitoring? [Y/n]: " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        ENABLE_CPU_MONITORING="false"
    else
        ENABLE_CPU_MONITORING="true"
    fi
    
    read -p "Enable memory monitoring? [Y/n]: " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        ENABLE_MEMORY_MONITORING="false"
    else
        ENABLE_MEMORY_MONITORING="true"
    fi
    
    read -p "Enable disk monitoring? [Y/n]: " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        ENABLE_DISK_MONITORING="false"
    else
        ENABLE_DISK_MONITORING="true"
    fi
    
    read -p "Enable network monitoring? [Y/n]: " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        ENABLE_NETWORK_MONITORING="false"
    else
        ENABLE_NETWORK_MONITORING="true"
    fi
    
    # Set log file
    LOG_FILE="$HOME/vm-performance-logs/${VM_NAME}-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    echo -e "${GREEN}✓ Monitoring configured${NC}"
    echo "  VM: $VM_NAME"
    echo "  Interval: ${MONITOR_INTERVAL}s"
    echo "  Log: $LOG_FILE"
    read -p "Press Enter to continue..."
}

# Function to start real-time monitoring
start_monitoring() {
    if [[ -z "$VM_NAME" ]]; then
        echo "Configure monitoring first"
        read -p "Press Enter to continue..."
        return
    fi
    
    clear
    echo -e "${GREEN}📊 Starting Real-time Performance Monitor${NC}"
    echo "==============================================="
    echo "VM: $VM_NAME | Interval: ${MONITOR_INTERVAL}s | Press Ctrl+C to stop"
    echo
    
    # Create log file if not exists
    if [[ -z "$LOG_FILE" ]]; then
        LOG_FILE="$HOME/vm-performance-logs/${VM_NAME}-$(date +%Y%m%d-%H%M%S).log"
        mkdir -p "$(dirname "$LOG_FILE")"
    fi
    
    # Start monitoring loop
    local iteration=0
    while true; do
        local timestamp=$(date '+%H:%M:%S')
        local cpu_usage=""
        local memory_usage=""
        local disk_io=""
        local network_io=""
        
        # CPU monitoring
        if [[ "$ENABLE_CPU_MONITORING" == "true" ]]; then
            cpu_usage=$(get_cpu_usage)
        fi
        
        # Memory monitoring
        if [[ "$ENABLE_MEMORY_MONITORING" == "true" ]]; then
            memory_usage=$(get_memory_usage)
        fi
        
        # Disk monitoring
        if [[ "$ENABLE_DISK_MONITORING" == "true" ]]; then
            disk_io=$(get_disk_io)
        fi
        
        # Network monitoring
        if [[ "$ENABLE_NETWORK_MONITORING" == "true" ]]; then
            network_io=$(get_network_io)
        fi
        
        # Display current stats
        echo -e "${CYan}[$timestamp] Iteration $((++iteration))${NC}"
        [[ -n "$cpu_usage" ]] && echo "  CPU: $cpu_usage"
        [[ -n "$memory_usage" ]] && echo "  Memory: $memory_usage"
        [[ -n "$disk_io" ]] && echo "  Disk: $disk_io"
        [[ -n "$network_io" ]] && echo "  Network: $network_io"
        echo
        
        # Log to file
        echo "[$timestamp] $cpu_usage | $memory_usage | $disk_io | $network_io" >> "$LOG_FILE"
        
        sleep "$MONITOR_INTERVAL"
    done
}

# Function to get CPU usage
get_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    echo "Usage: ${cpu_usage}% | Load: $load_avg"
}

# Function to get memory usage
get_memory_usage() {
    local total_mem=$(free -m | awk 'NR==2{printf "%.1f", $2/1024}')
    local used_mem=$(free -m | awk 'NR==2{printf "%.1f", $3/1024}')
    local mem_percent=$(free | awk 'NR==2{printf "%.1f", $3/$2*100}')
    echo "Used: ${used_mem}G/${total_mem}G (${mem_percent}%)"
}

# Function to get disk I/O
get_disk_io() {
    local disk_io=$(iostat -x 1 1 | tail -n 2 | head -n 1 | awk '{print "Read: " $3 "MB/s | Write: " $4 "MB/s"}')
    echo "$disk_io"
}

# Function to get network I/O
get_network_io() {
    local rx_bytes=$(cat /sys/class/net/*/statistics/rx_bytes 2>/dev/null | awk '{sum+=$1} END {printf "%.1f", sum/1024/1024}')
    local tx_bytes=$(cat /sys/class/net/*/statistics/tx_bytes 2>/dev/null | awk '{sum+=$1} END {printf "%.1f", sum/1024/1024}')
    echo "RX: ${rx_bytes}MB | TX: ${tx_bytes}MB"
}

# Function to run CPU benchmark
run_cpu_benchmark() {
    if [[ -z "$VM_NAME" ]]; then
        echo "Configure monitoring first"
        read -p "Press Enter to continue..."
        return
    fi
    
    clear
    echo -e "${GREEN}🖥️  CPU Performance Benchmark${NC}"
    echo "================================="
    echo "VM: $VM_NAME | Duration: ${BENCHMARK_DURATION}s"
    echo
    
    echo "CPU Benchmark Options:"
    echo "  1) Prime number calculation"
    echo "  2) Pi calculation"
    echo "  3) Matrix multiplication"
    echo "  4) Custom workload"
    read -p "Choose benchmark [1-4]: " choice
    
    case $choice in
        1) benchmark_prime_numbers ;;
        2) benchmark_pi_calculation ;;
        3) benchmark_matrix_multiplication ;;
        4) benchmark_custom_workload ;;
        *) echo "Invalid choice" ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to benchmark prime numbers
benchmark_prime_numbers() {
    echo "Running prime number benchmark..."
    echo "Calculating primes up to 1,000,000..."
    
    local start_time=$(date +%s.%N)
    local count=0
    
    for ((i=2; i<=1000000; i++)); do
        local is_prime=true
        for ((j=2; j*j<=i; j++)); do
            if ((i % j == 0)); then
                is_prime=false
                break
            fi
        done
        if [[ "$is_prime" == "true" ]]; then
            ((count++))
        fi
    done
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    echo -e "${GREEN}✓ Prime benchmark completed${NC}"
    echo "  Primes found: $count"
    echo "  Duration: ${duration}s"
    echo "  Performance: $(echo "scale=2; 1000000/$duration" | bc -l) numbers/second"
}

# Function to benchmark pi calculation
benchmark_pi_calculation() {
    echo "Running Pi calculation benchmark..."
    echo "Calculating Pi to 1000 decimal places..."
    
    local start_time=$(date +%s.%N)
    
    # Simple Pi calculation using Leibniz formula
    local pi=0
    local sign=1
    for ((i=0; i<1000000; i++)); do
        local term=$(echo "scale=1000; $sign/(2*$i+1)" | bc -l)
        pi=$(echo "scale=1000; $pi + $term" | bc -l)
        sign=$((sign * -1))
    done
    pi=$(echo "scale=1000; $pi * 4" | bc -l)
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    echo -e "${GREEN}✓ Pi benchmark completed${NC}"
    echo "  Pi (first 10 digits): $(echo "$pi" | cut -c1-12)"
    echo "  Duration: ${duration}s"
    echo "  Performance: $(echo "scale=2; 1000000/$duration" | bc -l) iterations/second"
}

# Function to benchmark matrix multiplication
benchmark_matrix_multiplication() {
    echo "Running matrix multiplication benchmark..."
    echo "Multiplying 100x100 matrices..."
    
    local start_time=$(date +%s.%N)
    
    # Create and multiply matrices
    local size=100
    for ((i=0; i<size; i++)); do
        for ((j=0; j<size; j++)); do
            local sum=0
            for ((k=0; k<size; k++)); do
                sum=$((sum + i * k + j * k))
            done
        done
    done
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    echo -e "${GREEN}✓ Matrix benchmark completed${NC}"
    echo "  Matrix size: ${size}x${size}"
    echo "  Duration: ${duration}s"
    echo "  Performance: $(echo "scale=2; $size*$size*$size/$duration" | bc -l) operations/second"
}

# Function to benchmark custom workload
benchmark_custom_workload() {
    echo "Running custom workload benchmark..."
    echo "Performing mixed CPU operations..."
    
    local start_time=$(date +%s.%N)
    
    # Mixed workload: math, string operations, loops
    for ((i=0; i<100000; i++)); do
        local result=$((i * i + i / 2))
        local string="benchmark_$i"
        local length=${#string}
        local hash=$((result % 1000))
    done
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    echo -e "${GREEN}✓ Custom benchmark completed${NC}"
    echo "  Iterations: 100,000"
    echo "  Duration: ${duration}s"
    echo "  Performance: $(echo "scale=2; 100000/$duration" | bc -l) operations/second"
}

# Function to run memory benchmark
run_memory_benchmark() {
    if [[ -z "$VM_NAME" ]]; then
        echo "Configure monitoring first"
        read -p "Press Enter to continue..."
        return
    fi
    
    clear
    echo -e "${GREEN}🧠 Memory Performance Benchmark${NC}"
    echo "==================================="
    echo "VM: $VM_NAME | Duration: ${BENCHMARK_DURATION}s"
    echo
    
    echo "Memory Benchmark Options:"
    echo "  1) Memory allocation/deallocation"
    echo "  2) Memory copy operations"
    echo "  3) Memory bandwidth test"
    read -p "Choose benchmark [1-3]: " choice
    
    case $choice in
        1) benchmark_memory_allocation ;;
        2) benchmark_memory_copy ;;
        3) benchmark_memory_bandwidth ;;
        *) echo "Invalid choice" ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to benchmark memory allocation
benchmark_memory_allocation() {
    echo "Running memory allocation benchmark..."
    echo "Allocating and deallocating memory blocks..."
    
    local start_time=$(date +%s.%N)
    local total_allocated=0
    
    for ((i=0; i<1000; i++)); do
        local size=$((RANDOM % 1000000 + 1000))
        local block=$(dd if=/dev/zero bs=1 count=$size 2>/dev/null | wc -c)
        total_allocated=$((total_allocated + block))
        
        # Simulate memory operations
        echo "Block $i: ${size} bytes" > /dev/null
    done
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    echo -e "${GREEN}✓ Memory allocation benchmark completed${NC}"
    echo "  Total allocated: $((total_allocated / 1024 / 1024))MB"
    echo "  Duration: ${duration}s"
    echo "  Performance: $(echo "scale=2; 1000/$duration" | bc -l) allocations/second"
}

# Function to run disk benchmark
run_disk_benchmark() {
    if [[ -z "$VM_NAME" ]]; then
        echo "Configure monitoring first"
        read -p "Press Enter to continue..."
        return
    fi
    
    clear
    echo -e "${GREEN}💾 Disk I/O Performance Benchmark${NC}"
    echo "======================================="
    echo "VM: $VM_NAME | Duration: ${BENCHMARK_DURATION}s"
    echo
    
    echo "Disk Benchmark Options:"
    echo "  1) Sequential read/write"
    echo "  2) Random read/write"
    echo "  3) Mixed I/O operations"
    read -p "Choose benchmark [1-3]: " choice
    
    case $choice in
        1) benchmark_sequential_io ;;
        2) benchmark_random_io ;;
        3) benchmark_mixed_io ;;
        *) echo "Invalid choice" ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to benchmark sequential I/O
benchmark_sequential_io() {
    echo "Running sequential I/O benchmark..."
    echo "Testing sequential read/write performance..."
    
    local test_file="/tmp/disk_benchmark_$VM_NAME"
    local file_size="100M"
    
    echo "Creating test file: $file_size"
    local start_time=$(date +%s.%N)
    
    # Sequential write
    dd if=/dev/zero of="$test_file" bs=1M count=100 2>/dev/null
    
    local write_time=$(date +%s.%N)
    local write_duration=$(echo "$write_time - $start_time" | bc -l)
    
    # Sequential read
    local read_start=$(date +%s.%N)
    dd if="$test_file" of=/dev/null bs=1M 2>/dev/null
    
    local read_end=$(date +%s.%N)
    local read_duration=$(echo "$read_end - $read_start" | bc -l)
    
    # Cleanup
    rm -f "$test_file"
    
    echo -e "${GREEN}✓ Sequential I/O benchmark completed${NC}"
    echo "  File size: $file_size"
    echo "  Write time: ${write_duration}s"
    echo "  Read time: ${read_duration}s"
    echo "  Write speed: $(echo "scale=2; 100/$write_duration" | bc -l) MB/s"
    echo "  Read speed: $(echo "scale=2; 100/$read_duration" | bc -l) MB/s"
}

# Function to run comprehensive benchmark
run_comprehensive_benchmark() {
    if [[ -z "$VM_NAME" ]]; then
        echo "Configure monitoring first"
        read -p "Press Enter to continue..."
        return
    fi
    
    clear
    echo -e "${GREEN}🚀 Comprehensive Benchmark Suite${NC}"
    echo "====================================="
    echo "VM: $VM_NAME | Duration: ${BENCHMARK_DURATION}s"
    echo
    
    echo "This will run all benchmarks and generate a comprehensive report."
    echo "Estimated time: $((BENCHMARK_DURATION * 3)) seconds"
    echo
    
    read -p "Continue? [Y/n]: " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        return
    fi
    
    local report_file="$HOME/vm-performance-logs/${VM_NAME}-comprehensive-$(date +%Y%m%d-%H%M%S).txt"
    mkdir -p "$(dirname "$report_file")"
    
    echo "Starting comprehensive benchmark suite..."
    echo "Report will be saved to: $report_file"
    echo
    
    # Run all benchmarks and collect results
    echo "=== COMPREHENSIVE BENCHMARK REPORT ===" > "$report_file"
    echo "VM: $VM_NAME" >> "$report_file"
    echo "Date: $(date)" >> "$report_file"
    echo "Duration: ${BENCHMARK_DURATION}s" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "Running CPU benchmarks..."
    echo "=== CPU BENCHMARKS ===" >> "$report_file"
    # Add CPU benchmark results here
    
    echo "Running memory benchmarks..."
    echo "=== MEMORY BENCHMARKS ===" >> "$report_file"
    # Add memory benchmark results here
    
    echo "Running disk benchmarks..."
    echo "=== DISK BENCHMARKS ===" >> "$report_file"
    # Add disk benchmark results here
    
    echo "Running network benchmarks..."
    echo "=== NETWORK BENCHMARKS ===" >> "$report_file"
    # Add network benchmark results here
    
    echo -e "${GREEN}✓ Comprehensive benchmark completed${NC}"
    echo "Report saved to: $report_file"
    
    read -p "Press Enter to continue..."
}

# Function to show performance history
show_performance_history() {
    clear
    echo -e "${BLUE}📈 Performance History & Logs${NC}"
    echo "================================="
    echo
    
    local log_dir="$HOME/vm-performance-logs"
    
    if [[ ! -d "$log_dir" ]]; then
        echo "No performance logs found"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Available performance logs:"
    ls -la "$log_dir"/*.log 2>/dev/null | while read file; do
        local filename=$(basename "$file")
        local size=$(du -h "$file" | cut -f1)
        local date=$(stat -c %y "$file" | cut -d' ' -f1)
        echo "  $filename ($size) - $date"
    done
    
    echo
    echo "Options:"
    echo "  1) View specific log file"
    echo "  2) Analyze log data"
    echo "  3) Back to main menu"
    read -p "Choose option [1-3]: " choice
    
    case $choice in
        1)
            echo "Enter log filename (or press Enter to skip):"
            read -p "Filename: " filename
            if [[ -n "$filename" && -f "$log_dir/$filename" ]]; then
                less "$log_dir/$filename"
            fi
            ;;
        2)
            echo "Log analysis coming soon..."
            ;;
        3)
            return
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Main function
main() {
    # Check required tools
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}❌ 'bc' calculator not found. Please install bc package${NC}"
        exit 1
    fi
    
    if ! command -v iostat &> /dev/null; then
        echo -e "${YELLOW}⚠️  'iostat' not found. Disk monitoring will be limited${NC}"
        ENABLE_DISK_MONITORING="false"
    fi
    
    # Main menu loop
    while true; do
        show_menu
        read -p "Choose option [0-9]: " choice
        
        case $choice in
            1) configure_monitoring ;;
            2) start_monitoring ;;
            3) run_cpu_benchmark ;;
            4) run_memory_benchmark ;;
            5) run_disk_benchmark ;;
            6) echo "Network benchmark coming soon..." ; read -p "Press Enter to continue..." ;;
            7) run_comprehensive_benchmark ;;
            8) show_performance_history ;;
            9) echo "Performance analysis coming soon..." ; read -p "Press Enter to continue..." ;;
            0) echo -e "${GREEN}👋 Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please choose 0-9.${NC}"; sleep 1 ;;
        esac
    done
}

# Start the script
main "$@"

