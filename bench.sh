#!/usr/bin/env bash

set -euo pipefail
TMPDIR=$(mktemp -d -t bench-XXXX)
trap 'rm -rf "$TMPDIR"' EXIT

LINE="------------------------------------------------------------"
NC='\033[0m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'

tick="${GREEN}✓${NC}"
cross="${RED}✗${NC}"

colorize() {
    local value="$1"
    local mode="$2"
    case "$mode" in
        good) echo -e "${GREEN}${value}${NC}" ;;
        bad)  echo -e "${RED}${value}${NC}" ;;
        warn) echo -e "${YELLOW}${value}${NC}" ;;
        *)    echo -e "${CYAN}${value}${NC}" ;;
    esac
}

kv() {
    local key="$1"
    local value="$2"
    local mode="${3:-}"
    if [[ "$value" == "N/A" ]]; then mode="bad"; fi
    printf " %-18s : %s\n" "$key" "$(colorize "$value" "$mode")"
}

print_header() {
    echo -e "${CYAN}${LINE}${NC}"
    echo -e "   🚀 ${GREEN}bench.sxve.it${NC} — Server Benchmark"
    echo -e "${CYAN}${LINE}${NC}"
}

format_uptime() {
    awk '{printf("%d days, %d hrs, %d mins", int($1/86400), int(($1%86400)/3600), int(($1%3600)/60))}' /proc/uptime
}

sysinfo() {
    echo -e "\n${CYAN} System Info ${NC}\n${CYAN}${LINE}${NC}"

    OS=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2 || uname -o)
    KERNEL=$(uname -r)
    ARCH=$(uname -m)
    CPU=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')
    CORES=$(nproc)
    FREQ=$(awk -F: '/cpu MHz/ {print int($2)" MHz"; exit}' /proc/cpuinfo)
    CACHE=$(awk -F: '/cache size/ {print $2; exit}' /proc/cpuinfo | sed 's/^ //')
    VMX=$(grep -qE 'vmx|svm' /proc/cpuinfo && echo "$tick" || echo "$cross")

    RAM_TOTAL_MB=$(free -m | awk '/Mem:/ {print $2}')
    RAM_USED_MB=$(free -m | awk '/Mem:/ {print $3}')
    RAM_FREE_MB=$((RAM_TOTAL_MB - RAM_USED_MB))
    RAM_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $RAM_TOTAL_MB/1024}")
    RAM_USED_GB=$(awk "BEGIN {printf \"%.1f\", $RAM_USED_MB/1024}")
    RAM_FREE_GB=$(awk "BEGIN {printf \"%.1f\", $RAM_FREE_MB/1024}")

    SWAP_TOTAL_MB=$(free -m | awk '/Swap:/ {print $2}')
    SWAP_USED_MB=$(free -m | awk '/Swap:/ {print $3}')
    SWAP_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $SWAP_TOTAL_MB/1024}")
    SWAP_USED_GB=$(awk "BEGIN {printf \"%.1f\", $SWAP_USED_MB/1024}")

    UPTIME=$(format_uptime)
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')

    if grep -qaE 'docker|lxc' /proc/1/cgroup; then
        VIRT="Container"
    elif [[ -f /proc/user_beancounters || -f /proc/vz ]]; then
        VIRT="OpenVZ"
    elif command -v dmidecode &>/dev/null && dmidecode -s system-product-name | grep -qiE "kvm|vmware|virtualbox"; then
        VIRT="VDS"
    else
        VIRT="Dedicated"
    fi

    kv "OS" "$OS"
    kv "Kernel" "$KERNEL"
    kv "Arch" "$ARCH"
    kv "CPU" "$CPU"
    kv "Cores" "$CORES @ $FREQ"
    kv "CPU Cache" "$CACHE"
    kv "VM-x/AMD-V" "$VMX"
    kv "Virt" "$VIRT"
    kv "RAM Total" "${RAM_TOTAL_GB} GiB"
    kv "RAM Used" "${RAM_USED_GB} GiB" bad
    kv "RAM Free" "${RAM_FREE_GB} GiB" good
    kv "Swap Total" "${SWAP_TOTAL_GB} GiB"
    kv "Swap Used" "${SWAP_USED_GB} GiB" bad
    kv "Uptime" "$UPTIME"
    kv "Load Avg" "$LOAD"
}

diskinfo() {
    echo -e "\n${CYAN} Disk Info ${NC}\n${CYAN}${LINE}${NC}"
    DISK_TOTAL=$(df -h / | awk 'END{print $2}')
    DISK_USED=$(df -h / | awk 'END{print $3}')
    DISK_FREE=$(df -h / | awk 'END{print $4}')
    IO_SPEED=$(dd if=/dev/zero of="$TMPDIR/testfile" bs=1M count=512 conv=fdatasync status=none 2>&1 | grep -o '[0-9.]\+ MB/s' || echo "N/A")

    kv "Disk Total" "$DISK_TOTAL"
    kv "Disk Used" "$DISK_USED" bad
    kv "Disk Free" "$DISK_FREE" good
    kv "I/O Speed" "$IO_SPEED"
}

netinfo() {
    echo -e "\n${CYAN} Network ${NC}\n${CYAN}${LINE}${NC}"

    IPV4=$(curl -s4 --max-time 5 ifconfig.co || echo "N/A")
    IPV6=$(curl -s6 --max-time 5 ifconfig.co || echo "N/A")
    
    if command -v ping &>/dev/null; then
        PING=$(ping -c1 -w2 8.8.8.8 | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1" ms"}' || echo "N/A")
    else
        PING="N/A"
    fi

    kv "IPv4" "${IPV4:-N/A}"
    kv "IPv6" "${IPV6:-N/A}"
    kv "Ping 8.8.8.8" "$PING"

    echo -e "\n${CYAN} Speedtest (Ookla) ${NC}\n${CYAN}${LINE}${NC}"

    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ARCHSTR="x86_64" ;;
        aarch64|arm64) ARCHSTR="aarch64" ;;
        *) echo "Unsupported arch: $ARCH"; exit 1 ;;
    esac

    URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${ARCHSTR}.tgz"
    curl -sL "$URL" -o "$TMPDIR/speedtest.tgz"
    tar -xzf "$TMPDIR/speedtest.tgz" -C "$TMPDIR"
    chmod +x "$TMPDIR/speedtest"

    run_speedtest() {
        local server_id="$1"
        local region="$2"
        echo -ne "${CYAN}Testing ${region}... ${NC}"

        local result=$("$TMPDIR/speedtest" --accept-license --accept-gdpr --server-id="$server_id" -f json 2>/dev/null)
        if [[ -n "$result" ]]; then
            local latency=$(echo "$result" | grep -oP '(?<="latency":)[0-9.]+' | awk '{printf "%.2f ms", $1}')
            local download=$(echo "$result" | grep -oP '(?<="download":{"bandwidth":)[0-9]+' | awk '{printf "%.2f Mbps", $1*8/1e6}')
            local upload=$(echo "$result" | grep -oP '(?<="upload":{"bandwidth":)[0-9]+' | awk '{printf "%.2f Mbps", $1*8/1e6}')
            local loss=$(echo "$result" | grep -oP '(?<="packetLoss":)[0-9.]+' | awk '{printf "%.1f%%", $1}')

            echo -e "${GREEN}✓${NC}"
            kv "  Latency" "$latency"
            kv "  Download" "$download"
            kv "  Upload" "$upload"
            kv "  Packet Loss" "$loss"
        else
            echo -e "${RED}✗ Failed${NC}"
        fi
        echo ""
    }

    # Тесты по регионам (server-id нужно заранее проверить на speedtest.net)
    run_speedtest "" "Nearest"
    run_speedtest "30847" "Europe (Frankfurt)"
    run_speedtest "14771" "Russia (Saint Petersburg)"
    run_speedtest "43860" "USA (Dallas)"
    run_speedtest "6527"  "Asia (Singapore)"
}


finish() {
    echo -e "\n${GREEN}✅ Benchmark complete. $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}${LINE}${NC}"
}

print_header
sysinfo
diskinfo
netinfo
finish
