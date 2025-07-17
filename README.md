# 🚀 bench.sxve.it — Server Benchmark

# IN PROGRESS. MAY CONTAIN ERRORS.

A lightweight Bash script to benchmark your server hardware and network in one command.  
No dependencies, no installation — just run via `wget | bash`.
---
## 🛠️ Usage

Run on any Linux server:

```bash
wget -qO- bench.sxve.it | bash
```
---

## 📋 Features

✅ Detects and displays:  
- **System**
  - OS, Kernel, Architecture
  - CPU model, cores, frequency, cache
  - Virtualization type: VDS / Dedicated / Container
  - VM‑x/AMD‑V support
  - RAM & Swap (total, used, free)  
  - Uptime, Load Average

✅ **Disk**
  - Total / Used / Free space
  - Disk I/O speed

✅ **Network**
  - Public IPv4 and IPv6
  - Ping to 8.8.8.8
  - Speedtest by Ookla (Nearest, Europe, Russia, USA, Asia)

✅ Color‑coded, easy‑to‑read output


---

## 📊 Example Output

```
------------------------------------------------------------
   🚀 bench.sxve.it — Server Benchmark
------------------------------------------------------------

 System Info 
------------------------------------------------------------
 OS                 : Ubuntu 22.04.4 LTS
 Kernel             : 6.11.0-29-generic
 Arch               : x86_64
 CPU                : Intel(R) Xeon(R) CPU E5-2670 v3
 Cores              : 24 @ 2600MHz
 CPU Cache          : 30 MB
 VM-x/AMD-V         : ✓
 Virt               : VDS
 RAM Total          : 64.0 GiB
 RAM Used           : 12.3 GiB
 RAM Free           : 51.7 GiB
 Swap Total         : 4.0 GiB
 Swap Used          : 0.0 GiB
 Uptime             : 5 days, 4 hrs, 12 mins
 Load Avg           : 0.15, 0.20, 0.18

 Disk Info 
------------------------------------------------------------
 Disk Total         : 500G
 Disk Used          : 120G
 Disk Free          : 380G
 I/O Speed          : 435 MB/s

 Network 
------------------------------------------------------------
 IPv4               : 203.0.113.42
 IPv6               : N/A
 Ping 8.8.8.8       : 4.37 ms

 Speedtest (Ookla) 
------------------------------------------------------------
 Testing Nearest... ✓
   Latency          : 1.37 ms
   Download         : 938.40 Mbps
   Upload           : 939.05 Mbps
   Packet Loss      : 0.0%

 Testing Europe (Frankfurt)... ✓
   Latency          : 23.12 ms
   Download         : 832.75 Mbps
   Upload           : 821.50 Mbps
   Packet Loss      : 0.0%
...
```

---

## 📄 License

MIT License — free to use, modify, and distribute.
