#!/bin/bash
# ethlab.sh - Ethical Hacking Lab for Termux
# USE ONLY ON SYSTEMS YOU OWN OR HAVE WRITTEN PERMISSION TO TEST

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
BLINK='\033[5m'
BOLD='\033[1m'
NC='\033[0m'

LOG_DIR="$HOME/ethlab_logs"
REPORT_DIR="$HOME/ethlab_reports"
mkdir -p "$LOG_DIR" "$REPORT_DIR"

SAVED_TARGET=""
SAVED_LOGFILE=""
WORDLIST_DIR="$HOME/ethlab_wordlists"
mkdir -p "$WORDLIST_DIR"

# ─── MATRIX RAIN INTRO (short) ────────────────────────────────────────────────────
matrix_intro() {
  local chars='01アイウエオカキクケコサシスセソタチツテトナニヌネノ'
  local cols=$(tput cols 2>/dev/null || echo 60)
  echo -e "${GREEN}"
  for i in $(seq 1 4); do
    local line=''
    for j in $(seq 1 $((cols / 2))); do
      local idx=$(( RANDOM % ${#chars} ))
      line+="${chars:$idx:1} "
    done
    echo "$line"
    sleep 0.07
  done
  echo -e "${NC}"
  sleep 0.2
}

# ─── TYPING EFFECT ──────────────────────────────────────────────────────────────
type_text() {
  local text="$1" color="$2"
  echo -ne "${color}"
  for ((i=0; i<${#text}; i++)); do
    echo -ne "${text:$i:1}"
    sleep 0.03
  done
  echo -e "${NC}"
}

banner() {
  clear
  matrix_intro
  echo -e "${GREEN}${BOLD}"
  echo '  ███████╗████████╗██╗  ██╗██╗      █████╗ ██████╗ '
  echo '  ██╔════╝╚══██╔══╝██║  ██║██║     ██╔══██╗██╔══██╗'
  echo '  █████╗     ██║   ███████║██║     ███████║██████╔╝'
  echo '  ██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗'
  echo '  ███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝'
  echo '  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ '
  echo -e "${NC}"
  echo -e "${RED}${BOLD}  ██╗  ██╗ ██████╗ ██████╗ ██╗  ██╗██╗██╗  ██╗ █████╗ ██╗     ██╗${NC}"
  echo -e "${RED}${BOLD}  ██║  ██║██╔════╝██╔════╝ ██║ ██╔╝██║██║  ██║██╔══██╗██║     ██║${NC}"
  echo -e "${RED}${BOLD}  ███████║██║  ███╗██║  ███╗█████╔╝ ██║██║  ██║██║  ██║██║     ██║${NC}"
  echo -e "${RED}${BOLD}  ██╔══██║██║   ██║██║   ██║██╔═██╗ ██║██║  ██║██║  ██║██║     ██║${NC}"
  echo -e "${RED}${BOLD}  ██║  ██║╚██████╔╝╚██████╔╝██║  ██╗██║╚█████╔╝╚█████╔╝███████╗██║${NC}"
  echo -e "${RED}${BOLD}  ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝ ╚════╝  ╚════╝ ╚══════╝╚═╝${NC}"
  echo ""
  echo -e "${GREEN}╔$(printf '═%.0s' $(seq 1 68))╗${NC}"
  echo -e "${GREEN}║${NC}${BOLD}${WHITE}   ☠  ETHICAL HACKING LAB  |  Authorized Testing Only  ☠   ${NC}${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}${DIM}   Host: $(hostname) | User: $(whoami) | $(date '+%Y-%m-%d %H:%M')        ${NC}${GREEN}║${NC}"
  echo -e "${GREEN}╚$(printf '═%.0s' $(seq 1 68))╝${NC}"
  echo ""
  [[ -n "$SAVED_TARGET" ]] && echo -e "  ${CYAN}► Active Target: ${BOLD}$SAVED_TARGET${NC}\n"
}

# ─── TOOL CHECKER ───────────────────────────────────────────────────────────
check_tools() {
  TOOLS=(nmap curl wget hydra sqlmap nikto nc openssl whois dig traceroute tcpdump aircrack-ng airodump-ng aireplay-ng arp-scan iwlist)
  echo -e "${BOLD}[TOOL STATUS]${NC}"
  for t in "${TOOLS[@]}"; do
    if command -v "$t" &>/dev/null; then
      echo -e "  ${GREEN}[✓]${NC} $t"
    else
      echo -e "  ${RED}[✗]${NC} $t ${YELLOW}(not installed)${NC}"
    fi
  done
  echo ""
}

get_target() {
  if [[ -n "$SAVED_TARGET" ]]; then
    echo -ne "${CYAN}[?] Use saved target '${SAVED_TARGET}' ? [Y/n]: ${NC}"
    read USE_SAVED
    if [[ -z "$USE_SAVED" || "$USE_SAVED" =~ ^[Yy]$ ]]; then
      TARGET="$SAVED_TARGET"
      LOGFILE="$SAVED_LOGFILE"
      echo -e "${GREEN}[+] Target: $TARGET | Log: $LOGFILE${NC}\n"
      return 0
    fi
  fi
  echo -ne "${CYAN}[?] Enter target IP or domain: ${NC}"
  read TARGET
  if [[ -z "$TARGET" ]]; then
    echo -e "${RED}[-] No target provided.${NC}"
    return 1
  fi
  LOGFILE="$LOG_DIR/${TARGET//\//_}_$(date +%Y%m%d_%H%M%S).log"
  SAVED_TARGET="$TARGET"
  SAVED_LOGFILE="$LOGFILE"
  echo -e "${GREEN}[+] Target: $TARGET | Log: $LOGFILE${NC}\n"
}

confirm() {
  echo -ne "${RED}[!] Confirm you own or have permission to test $TARGET [yes/no]: ${NC}"
  read CONFIRM
  [[ "$CONFIRM" == "yes" ]]
}

run_cmd() {
  echo -e "${YELLOW}[>] Running: $1${NC}"
  eval "$1" 2>&1 | tee -a "$LOGFILE"
  echo -e "${GREEN}[+] Done.${NC}\n"
}

# ─── WORDLIST GENERATOR ─────────────────────────────────────────────────────
wordlist_gen() {
  echo -e "${BOLD}[WORDLIST GENERATOR]${NC}"
  PS3=$'\n[?] Choose: '
  options=(
    "Generate common passwords list"
    "Generate username list"
    "Generate web directory list"
    "Combine two wordlists"
    "View saved wordlists"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1)
        OUT="$WORDLIST_DIR/passwords_$(date +%s).txt"
        cat > "$OUT" <<'WEOF'
password
123456
admin
password123
letmein
qwerty
111111
abc123
root
toor
master
welcome
login
pass
test
changeme
default
admin123
password1
1234
WEOF
        echo -e "${GREEN}[+] Saved: $OUT ($(wc -l < $OUT) entries)${NC}"
        ;;
      2)
        OUT="$WORDLIST_DIR/usernames_$(date +%s).txt"
        cat > "$OUT" <<'WEOF'
admin
root
user
test
guest
operator
manager
www
web
ftp
mail
postmaster
info
support
WEOF
        echo -e "${GREEN}[+] Saved: $OUT ($(wc -l < $OUT) entries)${NC}"
        ;;
      3)
        OUT="$WORDLIST_DIR/webdirs_$(date +%s).txt"
        cat > "$OUT" <<'WEOF'
admin
login
backup
config
test
api
phpinfo.php
.env
wp-admin
robots.txt
uploads
images
js
css
include
lib
vendor
.git
.htaccess
web.config
server-status
WEOF
        echo -e "${GREEN}[+] Saved: $OUT ($(wc -l < $OUT) entries)${NC}"
        ;;
      4)
        echo -ne "${CYAN}[?] First wordlist path: ${NC}"; read WL1
        echo -ne "${CYAN}[?] Second wordlist path: ${NC}"; read WL2
        OUT="$WORDLIST_DIR/combined_$(date +%s).txt"
        cat "$WL1" "$WL2" | sort -u > "$OUT"
        echo -e "${GREEN}[+] Combined: $OUT ($(wc -l < $OUT) unique entries)${NC}"
        ;;
      5)
        echo -e "${CYAN}[*] Wordlists in $WORDLIST_DIR:${NC}"
        ls -lh "$WORDLIST_DIR" 2>/dev/null || echo "None yet."
        ;;
      6) break ;;
    esac
  done
}

# ─── NORMAL SCAN ────────────────────────────────────────────────────────────
normal_scan() {
  get_target || return
  confirm || { echo "Aborted."; return; }
  echo -e "${BOLD}[NORMAL SCAN]${NC}"

  PS3=$'\n[?] Choose: '
  options=(
    "Ping / Host Discovery"
    "Basic Port Scan (Top 100)"
    "WHOIS Lookup"
    "DNS Lookup"
    "HTTP Headers Check"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1) run_cmd "ping -c 4 $TARGET" ;;
      2) run_cmd "nmap -F $TARGET" ;;
      3) run_cmd "whois $TARGET" ;;
      4) run_cmd "nslookup $TARGET && dig $TARGET" ;;
      5) run_cmd "curl -sI $TARGET" ;;
      6) break ;;
    esac
  done
}

# ─── MEDIUM SCAN ────────────────────────────────────────────────────────────
medium_scan() {
  get_target || return
  confirm || { echo "Aborted."; return; }
  echo -e "${BOLD}[MEDIUM SCAN]${NC}"

  PS3=$'\n[?] Choose: '
  options=(
    "Full Port Scan (1-65535)"
    "Service & Version Detection"
    "OS Detection"
    "Traceroute"
    "Subdomain Enumeration (dig)"
    "SSL/TLS Certificate Info"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1) run_cmd "nmap -p- --open -T4 $TARGET" ;;
      2) run_cmd "nmap -sV -sC -T4 $TARGET" ;;
      3) run_cmd "nmap -O $TARGET" ;;
      4) run_cmd "traceroute $TARGET" ;;
      5) run_cmd "dig axfr $TARGET && dig +short $TARGET ANY" ;;
      6) run_cmd "openssl s_client -connect $TARGET:443 </dev/null 2>/dev/null | openssl x509 -noout -text" ;;
      7) break ;;
    esac
  done
}

# ─── HARD SCAN ──────────────────────────────────────────────────────────────
hard_scan() {
  get_target || return
  confirm || { echo "Aborted."; return; }
  echo -e "${BOLD}[HARD SCAN]${NC}"

  PS3=$'\n[?] Choose: '
  options=(
    "Aggressive Nmap Scan (-A)"
    "Vulnerability Script Scan (nmap --script vuln)"
    "Web Directory Brute-Force (curl wordlist)"
    "Nikto Web Scan"
    "Banner Grabbing (netcat)"
    "SMB Enumeration"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1) run_cmd "nmap -A -T4 $TARGET" ;;
      2) run_cmd "nmap --script vuln $TARGET" ;;
      3)
        WORDLIST="/data/data/com.termux/files/usr/share/wordlists/dirb/common.txt"
        if [[ ! -f "$WORDLIST" ]]; then
          echo -e "${YELLOW}[!] Wordlist not found. Using built-in short list.${NC}"
          WORDLIST="/tmp/shortlist.txt"
          echo -e "admin\nlogin\nbackup\nconfig\ntest\napi\nphpinfo.php\n.env\nwp-admin\nrobots.txt" > "$WORDLIST"
        fi
        while IFS= read -r dir; do
          CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET/$dir")
          [[ "$CODE" != "404" ]] && echo "[$CODE] http://$TARGET/$dir" | tee -a "$LOGFILE"
        done < "$WORDLIST"
        ;;
      4) run_cmd "nikto -h $TARGET" ;;
      5)
        echo -ne "${CYAN}[?] Port to grab banner from (e.g. 80): ${NC}"
        read PORT
        run_cmd "echo '' | nc -w 3 $TARGET $PORT"
        ;;
      6) run_cmd "nmap -p 445 --script smb-enum-shares,smb-enum-users $TARGET" ;;
      7) break ;;
    esac
  done
}

# ─── EXTRA / ADVANCED ───────────────────────────────────────────────────────
extra_scan() {
  get_target || return
  confirm || { echo "Aborted."; return; }
  echo -e "${BOLD}[EXTRA / ADVANCED]${NC}"

  PS3=$'\n[?] Choose: '
  options=(
    "SSH Brute-Force (hydra)"
    "FTP Brute-Force (hydra)"
    "HTTP Basic Auth Brute-Force (hydra)"
    "SQL Injection Test (sqlmap)"
    "Firewall / IDS Evasion Scan (nmap)"
    "Stealth SYN Scan"
    "Network Packet Sniff (tcpdump 30s)"
    "Custom Nmap Flags"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1)
        echo -ne "${CYAN}[?] Username: ${NC}"; read UNAME
        echo -ne "${CYAN}[?] Wordlist path: ${NC}"; read WL
        run_cmd "hydra -l $UNAME -P $WL ssh://$TARGET"
        ;;
      2)
        echo -ne "${CYAN}[?] Username: ${NC}"; read UNAME
        echo -ne "${CYAN}[?] Wordlist path: ${NC}"; read WL
        run_cmd "hydra -l $UNAME -P $WL ftp://$TARGET"
        ;;
      3)
        echo -ne "${CYAN}[?] Username: ${NC}"; read UNAME
        echo -ne "${CYAN}[?] Wordlist path: ${NC}"; read WL
        echo -ne "${CYAN}[?] Login URL path (e.g. /login): ${NC}"; read LPATH
        run_cmd "hydra -l $UNAME -P $WL http-get://$TARGET/$LPATH"
        ;;
      4)
        echo -ne "${CYAN}[?] Full URL (e.g. http://target/page?id=1): ${NC}"; read SQURL
        run_cmd "sqlmap -u \"$SQURL\" --batch --level=2"
        ;;
      5) run_cmd "nmap -f --mtu 24 -D RND:5 -T2 $TARGET" ;;
      6) run_cmd "nmap -sS -T2 $TARGET" ;;
      7)
        echo -ne "${CYAN}[?] Interface (e.g. wlan0): ${NC}"; read IFACE
        run_cmd "timeout 30 tcpdump -i $IFACE host $TARGET -w $LOG_DIR/capture_$(date +%s).pcap"
        ;;
      8)
        echo -ne "${CYAN}[?] Enter nmap flags + target (e.g. -sU -p 53 target): ${NC}"; read CUSTOM
        run_cmd "nmap $CUSTOM"
        ;;
      9) break ;;
    esac
  done
}

# ─── NETWORK RECON ──────────────────────────────────────────────────────────
network_recon() {
  echo -e "${BOLD}[NETWORK RECON]${NC}"
  PS3=$'\n[?] Choose: '
  options=(
    "Discover Live Hosts (nmap ping sweep)"
    "ARP Scan Local Network"
    "Map Network Topology (traceroute all hops)"
    "Find Default Gateway & Routes"
    "DNS Zone Transfer Attempt"
    "Reverse DNS Lookup"
    "Check for Open Proxies"
    "Scan Common UDP Ports"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1)
        echo -ne "${CYAN}[?] Network range (e.g. 192.168.1.0/24): ${NC}"; read RANGE
        LOGFILE="$LOG_DIR/netrecon_$(date +%Y%m%d_%H%M%S).log"
        run_cmd "nmap -sn $RANGE"
        ;;
      2)
        echo -ne "${CYAN}[?] Interface (e.g. wlan0): ${NC}"; read IFACE
        LOGFILE="$LOG_DIR/netrecon_$(date +%Y%m%d_%H%M%S).log"
        run_cmd "arp-scan --interface=$IFACE --localnet 2>/dev/null || arp -a"
        ;;
      3)
        get_target || break
        run_cmd "traceroute -n $TARGET"
        ;;
      4)
        LOGFILE="$LOG_DIR/netrecon_$(date +%Y%m%d_%H%M%S).log"
        run_cmd "ip route show && ip neigh show"
        ;;
      5)
        get_target || break
        run_cmd "dig axfr @$TARGET $TARGET 2>/dev/null || host -t axfr $TARGET"
        ;;
      6)
        get_target || break
        run_cmd "dig -x $TARGET +short && nmap -sn --script reverse-index $TARGET 2>/dev/null"
        ;;
      7)
        get_target || break
        run_cmd "nmap -p 8080,3128,1080,8888,9050 --open $TARGET"
        ;;
      8)
        get_target || break
        run_cmd "nmap -sU -p 53,67,68,69,123,161,500 --open -T4 $TARGET"
        ;;
      9) break ;;
    esac
  done
}

# ─── WEB APP TESTING ─────────────────────────────────────────────────────────
webapp_test() {
  get_target || return
  confirm || { echo "Aborted."; return; }
  echo -e "${BOLD}[WEB APP TESTING]${NC}"
  PS3=$'\n[?] Choose: '
  options=(
    "Full HTTP Methods Check"
    "Check Security Headers"
    "Find Login Pages"
    "Test for Open Redirect"
    "Check robots.txt & sitemap.xml"
    "Detect WAF (Web App Firewall)"
    "Cookie & Session Analysis"
    "Test CORS Misconfiguration"
    "Scan HTTPS/TLS Ciphers"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1) run_cmd "curl -s -o /dev/null -D - -X OPTIONS http://$TARGET/ | grep -i allow" ;;
      2)
        run_cmd "curl -sI http://$TARGET | grep -iE 'x-frame|x-xss|content-security|strict-transport|x-content-type|referrer-policy'"
        ;;
      3)
        for path in login signin admin wp-login.php administrator user/login auth; do
          CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET/$path")
          [[ "$CODE" != "404" && "$CODE" != "000" ]] && echo "[$CODE] http://$TARGET/$path" | tee -a "$LOGFILE"
        done
        ;;
      4)
        run_cmd "curl -sI 'http://$TARGET/?url=http://example.com' | grep -i location"
        ;;
      5)
        run_cmd "curl -s http://$TARGET/robots.txt"
        run_cmd "curl -s http://$TARGET/sitemap.xml | grep -o '<loc>[^<]*' | sed 's/<loc>//' | head -20"
        ;;
      6) run_cmd "nmap -p 80,443 --script http-waf-detect,http-waf-fingerprint $TARGET" ;;
      7)
        run_cmd "curl -sI http://$TARGET | grep -iE 'set-cookie|cookie'"
        ;;
      8)
        run_cmd "curl -sI -H 'Origin: https://evil.com' http://$TARGET | grep -i 'access-control'"
        ;;
      9)
        run_cmd "nmap --script ssl-enum-ciphers -p 443 $TARGET"
        ;;
      10) break ;;
    esac
  done
}

# ─── DEFENSE CHECKER ─────────────────────────────────────────────────────────
defense_check() {
  echo -e "${BOLD}[DEFENSE CHECKER - Test your own defenses]${NC}"
  echo -e "${YELLOW}[*] Run on your own system to verify security controls.${NC}\n"
  LOGFILE="$LOG_DIR/defense_$(date +%Y%m%d_%H%M%S).log"
  PS3=$'\n[?] Choose: '
  options=(
    "Check Firewall Rules (iptables)"
    "Check SSH Hardening"
    "Check for Weak File Permissions"
    "Check Listening Services"
    "Check Failed Login Attempts"
    "Check for Rootkits (basic)"
    "Check DNS Leak"
    "Verify SSL Certificate Expiry"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1) run_cmd "iptables -L -n -v 2>/dev/null || nft list ruleset 2>/dev/null" ;;
      2)
        run_cmd "grep -E 'PermitRootLogin|PasswordAuthentication|Port|AllowUsers|MaxAuthTries' /etc/ssh/sshd_config 2>/dev/null"
        ;;
      3)
        run_cmd "find /etc /home /root -maxdepth 3 -perm -o+w -type f 2>/dev/null | head -20"
        ;;
      4) run_cmd "ss -tulnp" ;;
      5)
        run_cmd "grep 'Failed password' /var/log/auth.log 2>/dev/null | tail -20 || logcat 2>/dev/null | grep -i 'fail' | tail -20"
        ;;
      6)
        run_cmd "find / -name '.*' -type f -not -path '/proc/*' -not -path '/sys/*' 2>/dev/null | grep -v '.cache\|.config\|.local' | head -20"
        ;;
      7)
        run_cmd "curl -s https://ifconfig.me && dig +short myip.opendns.com @resolver1.opendns.com"
        ;;
      8)
        echo -ne "${CYAN}[?] Domain to check SSL expiry: ${NC}"; read SSLDOM
        run_cmd "echo | openssl s_client -connect $SSLDOM:443 2>/dev/null | openssl x509 -noout -dates"
        ;;
      9) break ;;
    esac
  done
}

# ─── WIRELESS SCAN ─────────────────────────────────────────────────────────
wireless_scan() {
  echo -e "${BOLD}[WIRELESS SCAN]${NC}"
  echo -e "${RED}[!] Requires root/monitor mode. Use on your own WiFi only.${NC}\n"

  PS3=$'\n[?] Choose: '
  options=(
    "List WiFi Interfaces"
    "Scan Nearby Networks (iwlist)"
    "Show Connected Clients (arp-scan)"
    "Check WiFi Signal Strength"
    "Capture Handshake (airodump-ng)"
    "Deauth Test (aireplay-ng) - YOUR network only"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1) run_cmd "ip link show" ;;
      2)
        echo -ne "${CYAN}[?] Interface (e.g. wlan0): ${NC}"; read IFACE
        run_cmd "iwlist $IFACE scan 2>/dev/null | grep -E 'ESSID|Address|Quality|Channel'"
        ;;
      3)
        echo -ne "${CYAN}[?] Interface (e.g. wlan0): ${NC}"; read IFACE
        run_cmd "arp-scan --interface=$IFACE --localnet 2>/dev/null || arp -a"
        ;;
      4)
        echo -ne "${CYAN}[?] Interface (e.g. wlan0): ${NC}"; read IFACE
        run_cmd "iwconfig $IFACE 2>/dev/null || iw dev $IFACE link"
        ;;
      5)
        echo -ne "${CYAN}[?] Interface in monitor mode (e.g. wlan0mon): ${NC}"; read IFACE
        echo -ne "${CYAN}[?] BSSID of YOUR network: ${NC}"; read BSSID
        echo -ne "${CYAN}[?] Channel: ${NC}"; read CH
        CAPFILE="$LOG_DIR/handshake_$(date +%s)"
        run_cmd "timeout 60 airodump-ng -c $CH --bssid $BSSID -w $CAPFILE $IFACE"
        ;;
      6)
        echo -ne "${CYAN}[?] Interface in monitor mode: ${NC}"; read IFACE
        echo -ne "${CYAN}[?] BSSID of YOUR network: ${NC}"; read BSSID
        echo -ne "${CYAN}[?] Client MAC to deauth (or 'FF:FF:FF:FF:FF:FF' for all): ${NC}"; read CMAC
        run_cmd "aireplay-ng --deauth 5 -a $BSSID -c $CMAC $IFACE"
        ;;
      7) break ;;
    esac
  done
}

# ─── POST-EXPLOITATION ──────────────────────────────────────────────────────
post_exploit() {
  echo -e "${BOLD}[POST-EXPLOITATION - LOCAL INFO GATHERING]${NC}"
  echo -e "${YELLOW}[*] Run these on a machine you own/control to understand exposure.${NC}\n"

  PS3=$'\n[?] Choose: '
  options=(
    "System Info"
    "Current User & Privileges"
    "List Open Ports (local)"
    "Running Processes"
    "Cron Jobs"
    "SUID Binaries (privilege escalation check)"
    "World-Writable Files"
    "Saved Passwords in Files"
    "Network Connections"
    "Installed Packages"
    "Back"
  )
  POSTLOG="$LOG_DIR/post_exploit_$(date +%Y%m%d_%H%M%S).log"
  LOGFILE="$POSTLOG"
  select opt in "${options[@]}"; do
    case $REPLY in
      1)  run_cmd "uname -a && cat /etc/os-release 2>/dev/null" ;;
      2)  run_cmd "id && whoami && sudo -l 2>/dev/null" ;;
      3)  run_cmd "ss -tulnp || netstat -tulnp 2>/dev/null" ;;
      4)  run_cmd "ps aux" ;;
      5)  run_cmd "crontab -l 2>/dev/null; cat /etc/cron* 2>/dev/null" ;;
      6)  run_cmd "find / -perm -4000 -type f 2>/dev/null" ;;
      7)  run_cmd "find / -writable -type f -not -path '/proc/*' 2>/dev/null | head -40" ;;
      8)  run_cmd "grep -rn 'password\|passwd\|secret\|token' ~/  --include='*.txt' --include='*.conf' --include='*.env' 2>/dev/null | head -30" ;;
      9)  run_cmd "ss -antp || netstat -antp 2>/dev/null" ;;
      10) run_cmd "pkg list-installed 2>/dev/null || dpkg -l 2>/dev/null | head -40" ;;
      11) break ;;
    esac
  done
}

# ─── PASSWORD CRACKER ───────────────────────────────────────────────────────
password_cracker() {
  echo -e "${BOLD}[PASSWORD CRACKER]${NC}"
  echo -e "${YELLOW}[*] Use only on hashes/files you own.${NC}\n"
  LOGFILE="$LOG_DIR/crack_$(date +%Y%m%d_%H%M%S).log"

  PS3=$'\n[?] Choose: '
  options=(
    "Crack MD5 Hash (hashcat)"
    "Crack SHA1 Hash (hashcat)"
    "Crack bcrypt Hash (hashcat)"
    "Crack /etc/shadow (john)"
    "Crack ZIP Password (john)"
    "Identify Hash Type"
    "Generate Hash from String"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1)
        echo -ne "${CYAN}[?] MD5 hash: ${NC}"; read HASH
        echo -ne "${CYAN}[?] Wordlist path: ${NC}"; read WL
        echo "$HASH" > /tmp/hash.txt
        run_cmd "hashcat -m 0 /tmp/hash.txt $WL --force 2>/dev/null || echo 'hashcat not found, try: pkg install hashcat'"
        ;;
      2)
        echo -ne "${CYAN}[?] SHA1 hash: ${NC}"; read HASH
        echo -ne "${CYAN}[?] Wordlist path: ${NC}"; read WL
        echo "$HASH" > /tmp/hash.txt
        run_cmd "hashcat -m 100 /tmp/hash.txt $WL --force 2>/dev/null || echo 'hashcat not found'"
        ;;
      3)
        echo -ne "${CYAN}[?] bcrypt hash: ${NC}"; read HASH
        echo -ne "${CYAN}[?] Wordlist path: ${NC}"; read WL
        echo "$HASH" > /tmp/hash.txt
        run_cmd "hashcat -m 3200 /tmp/hash.txt $WL --force 2>/dev/null || echo 'hashcat not found'"
        ;;
      4)
        echo -ne "${CYAN}[?] Path to shadow file: ${NC}"; read SHADOW
        echo -ne "${CYAN}[?] Wordlist path: ${NC}"; read WL
        run_cmd "john --wordlist=$WL $SHADOW 2>/dev/null || echo 'john not found, try: pkg install john'"
        ;;
      5)
        echo -ne "${CYAN}[?] Path to ZIP file: ${NC}"; read ZIPF
        echo -ne "${CYAN}[?] Wordlist path: ${NC}"; read WL
        run_cmd "zip2john $ZIPF > /tmp/ziphash.txt 2>/dev/null && john --wordlist=$WL /tmp/ziphash.txt"
        ;;
      6)
        echo -ne "${CYAN}[?] Hash to identify: ${NC}"; read HASH
        LEN=${#HASH}
        case $LEN in
          32)  echo -e "${GREEN}[+] Likely MD5 (32 chars)${NC}" | tee -a "$LOGFILE" ;;
          40)  echo -e "${GREEN}[+] Likely SHA1 (40 chars)${NC}" | tee -a "$LOGFILE" ;;
          56)  echo -e "${GREEN}[+] Likely SHA224 (56 chars)${NC}" | tee -a "$LOGFILE" ;;
          64)  echo -e "${GREEN}[+] Likely SHA256 (64 chars)${NC}" | tee -a "$LOGFILE" ;;
          96)  echo -e "${GREEN}[+] Likely SHA384 (96 chars)${NC}" | tee -a "$LOGFILE" ;;
          128) echo -e "${GREEN}[+] Likely SHA512 (128 chars)${NC}" | tee -a "$LOGFILE" ;;
          60)  echo -e "${GREEN}[+] Likely bcrypt (60 chars)${NC}" | tee -a "$LOGFILE" ;;
          *)   echo -e "${YELLOW}[?] Unknown hash type (length: $LEN)${NC}" | tee -a "$LOGFILE" ;;
        esac
        ;;
      7)
        echo -ne "${CYAN}[?] String to hash: ${NC}"; read STR
        echo -e "MD5:    $(echo -n $STR | md5sum | cut -d' ' -f1)" | tee -a "$LOGFILE"
        echo -e "SHA1:   $(echo -n $STR | sha1sum | cut -d' ' -f1)" | tee -a "$LOGFILE"
        echo -e "SHA256: $(echo -n $STR | sha256sum | cut -d' ' -f1)" | tee -a "$LOGFILE"
        ;;
      8) break ;;
    esac
  done
}

# ─── EXPLOIT CHECKER ─────────────────────────────────────────────────────────
exploit_checker() {
  get_target || return
  confirm || { echo "Aborted."; return; }
  echo -e "${BOLD}[EXPLOIT CHECKER]${NC}"
  echo -e "${YELLOW}[*] Checks for known CVEs and misconfigs on your target.${NC}\n"

  PS3=$'\n[?] Choose: '
  options=(
    "Check EternalBlue MS17-010 (SMB)"
    "Check Shellshock (CVE-2014-6271)"
    "Check Heartbleed (CVE-2014-0160)"
    "Check Anonymous FTP Login"
    "Check Telnet Open"
    "Check Default HTTP Credentials"
    "Check for Exposed .git Directory"
    "Check for Exposed .env File"
    "Check for Open MongoDB / Redis"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1) run_cmd "nmap -p 445 --script smb-vuln-ms17-010 $TARGET" ;;
      2) run_cmd "curl -sI -A '() { :;}; echo; echo VULNERABLE' http://$TARGET/cgi-bin/test.cgi 2>/dev/null | grep -i 'VULNERABLE' || echo 'Not vulnerable or cgi-bin not found'" ;;
      3) run_cmd "nmap -p 443 --script ssl-heartbleed $TARGET" ;;
      4) run_cmd "nmap -p 21 --script ftp-anon $TARGET" ;;
      5) run_cmd "nmap -p 23 --open $TARGET && echo '' | nc -w 3 $TARGET 23" ;;
      6)
        for cred in admin:admin admin:password root:root admin:1234 admin: user:user; do
          U=$(echo $cred | cut -d: -f1)
          P=$(echo $cred | cut -d: -f2)
          CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$U:$P" "http://$TARGET/")
          [[ "$CODE" == "200" ]] && echo -e "${RED}[!] Default creds work: $cred${NC}" | tee -a "$LOGFILE"
        done
        ;;
      7)
        CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET/.git/HEAD")
        [[ "$CODE" == "200" ]] && echo -e "${RED}[!] .git directory EXPOSED!${NC}" | tee -a "$LOGFILE" \
          || echo -e "${GREEN}[+] .git not exposed${NC}" | tee -a "$LOGFILE"
        ;;
      8)
        CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET/.env")
        [[ "$CODE" == "200" ]] && echo -e "${RED}[!] .env file EXPOSED!${NC}" | tee -a "$LOGFILE" \
          || echo -e "${GREEN}[+] .env not exposed${NC}" | tee -a "$LOGFILE"
        ;;
      9)
        run_cmd "nmap -p 27017 --open $TARGET && nmap -p 6379 --open $TARGET"
        ;;
      10) break ;;
    esac
  done
}

# ─── AUTO SCAN ───────────────────────────────────────────────────────────────
auto_scan() {
  get_target || return
  confirm || { echo "Aborted."; return; }
  echo -e "${BOLD}[AUTO SCAN - Full Automated Recon]${NC}"
  echo -e "${YELLOW}[*] Runs all recon stages automatically and saves to one log.${NC}\n"
  LOGFILE="$LOG_DIR/autoscan_${TARGET//\//_}_$(date +%Y%m%d_%H%M%S).log"

  echo -e "${CYAN}[1/7] Ping & Host Discovery${NC}"
  run_cmd "ping -c 2 $TARGET"

  echo -e "${CYAN}[2/7] Fast Port Scan${NC}"
  run_cmd "nmap -F --open $TARGET"

  echo -e "${CYAN}[3/7] Service & Version Detection${NC}"
  run_cmd "nmap -sV -sC -T4 --open $TARGET"

  echo -e "${CYAN}[4/7] OS Detection${NC}"
  run_cmd "nmap -O $TARGET 2>/dev/null"

  echo -e "${CYAN}[5/7] Vulnerability Scripts${NC}"
  run_cmd "nmap --script vuln $TARGET"

  echo -e "${CYAN}[6/7] HTTP Headers & Web Check${NC}"
  run_cmd "curl -sI http://$TARGET"
  run_cmd "curl -s http://$TARGET/robots.txt"

  echo -e "${CYAN}[7/7] WHOIS & DNS${NC}"
  run_cmd "whois $TARGET 2>/dev/null | head -30"
  run_cmd "dig $TARGET ANY +short"

  echo -e "${GREEN}[+] Auto scan complete. Log: $LOGFILE${NC}"
  echo -ne "${CYAN}[?] Generate HTML report now? [y/N]: ${NC}"
  read DOREPORT
  [[ "$DOREPORT" =~ ^[Yy]$ ]] && generate_report
}

# ─── REPORT GENERATOR ───────────────────────────────────────────────────────
generate_report() {
  echo -e "${CYAN}[*] Generating HTML report from all logs...${NC}"
  REPORT="$REPORT_DIR/report_$(date +%Y%m%d_%H%M%S).html"

  cat > "$REPORT" <<EOF
<!DOCTYPE html><html><head>
<meta charset='UTF-8'>
<title>EthLab Report - $(date)</title>
<style>
  body{background:#0d0d0d;color:#00ff88;font-family:monospace;padding:20px}
  h1{color:#ff4444} h2{color:#ffaa00;border-bottom:1px solid #333;padding-bottom:4px}
  pre{background:#111;padding:12px;border-left:3px solid #00ff88;overflow-x:auto;white-space:pre-wrap;word-break:break-all}
  .meta{color:#888;font-size:0.85em} .file{color:#00aaff}
</style></head><body>
<h1>&#x1F4CB; EthLab Scan Report</h1>
<p class='meta'>Generated: $(date) | Host: $(hostname)</p>
EOF

  LOG_COUNT=0
  for f in "$LOG_DIR"/*.log; do
    [[ -f "$f" ]] || continue
    FNAME=$(basename "$f")
    echo "<h2 class='file'>&#x1F4C4; $FNAME</h2>" >> "$REPORT"
    echo "<pre>" >> "$REPORT"
    sed 's/</\&lt;/g; s/>/\&gt;/g' "$f" >> "$REPORT"
    echo "</pre>" >> "$REPORT"
    ((LOG_COUNT++))
  done

  echo "<p class='meta'>Total logs included: $LOG_COUNT</p></body></html>" >> "$REPORT"

  echo -e "${GREEN}[+] Report saved: $REPORT${NC}"
  echo -e "${YELLOW}[*] Transfer to PC and open in browser, or run: termux-open $REPORT${NC}"
}

# ─── PHISHING AWARENESS ─────────────────────────────────────────────────────
phishing_awareness() {
  echo -e "${BOLD}[PHISHING AWARENESS TESTER]${NC}"
  echo -e "${RED}[!] Use ONLY for authorized security awareness training.${NC}\n"
  LOGFILE="$LOG_DIR/phishing_$(date +%Y%m%d_%H%M%S).log"
  PS3=$'\n[?] Choose: '
  options=(
    "Check Domain SPF / DKIM / DMARC"
    "Check Email MX Records"
    "Generate Phishing Email Template"
    "Create Fake Login Page (HTML)"
    "Check for Typosquat Domains"
    "Back"
  )
  select opt in "${options[@]}"; do
    case $REPLY in
      1)
        echo -ne "${CYAN}[?] Domain (e.g. example.com): ${NC}"; read DOMAIN
        run_cmd "dig TXT $DOMAIN | grep -iE 'spf|v=spf'"
        run_cmd "dig TXT _dmarc.$DOMAIN"
        run_cmd "dig TXT default._domainkey.$DOMAIN 2>/dev/null"
        ;;
      2)
        echo -ne "${CYAN}[?] Domain: ${NC}"; read DOMAIN
        run_cmd "dig MX $DOMAIN"
        ;;
      3)
        echo -ne "${CYAN}[?] Company name: ${NC}"; read COMPANY
        OUT="$LOG_DIR/phish_template_$(date +%s).txt"
        cat > "$OUT" <<PEOF
From: IT Security <security@${COMPANY,,}.com>
Subject: Urgent: Verify Your Account

Dear User,

Unusual activity was detected on your account.
Please verify within 24 hours: http://[test-server]/verify

Regards,
${COMPANY} Security Team

[SECURITY AWARENESS TEST - NOT A REAL THREAT]
PEOF
        echo -e "${GREEN}[+] Template: $OUT${NC}" | tee -a "$LOGFILE"
        ;;
      4)
        OUT="$LOG_DIR/fake_login_$(date +%s).html"
        cat > "$OUT" <<'HEOF'
<!DOCTYPE html><html><head><title>Sign In</title>
<style>
body{font-family:Arial;display:flex;justify-content:center;align-items:center;height:100vh;background:#f4f4f4}
.box{background:#fff;padding:30px;border-radius:8px;box-shadow:0 2px 12px rgba(0,0,0,.15);width:320px}
input{width:100%;padding:10px;margin:8px 0;box-sizing:border-box;border:1px solid #ddd;border-radius:4px}
button{width:100%;padding:10px;background:#0078d4;color:#fff;border:none;border-radius:4px;cursor:pointer}
.warn{font-size:11px;color:red;text-align:center;margin-top:10px}
</style></head><body>
<div class="box">
  <h2>Sign In</h2>
  <form method="POST" action="#">
    <input type="text" name="user" placeholder="Username" required>
    <input type="password" name="pass" placeholder="Password" required>
    <button>Sign In</button>
  </form>
  <p class="warn">&#9888; SECURITY AWARENESS TEST</p>
</div></body></html>
HEOF
        echo -e "${GREEN}[+] Fake login page: $OUT${NC}" | tee -a "$LOGFILE"
        ;;
      5)
        echo -ne "${CYAN}[?] Real domain (e.g. google.com): ${NC}"; read REALDOMAIN
        BASE=$(echo "$REALDOMAIN" | sed 's/\..*//')
        echo -e "${YELLOW}[*] Possible typosquats to check:${NC}" | tee -a "$LOGFILE"
        for variant in "${BASE}0" "${BASE}1" "${BASE}-login" "${BASE}-secure" "${BASE}login" "${BASE}verify"; do
          TLD=$(echo "$REALDOMAIN" | grep -o '\..*')
          FULL="${variant}${TLD}"
          IP=$(dig +short "$FULL" 2>/dev/null | head -1)
          [[ -n "$IP" ]] && echo -e "  ${RED}[!] $FULL -> $IP (REGISTERED)${NC}" | tee -a "$LOGFILE" \
            || echo -e "  ${GREEN}[+] $FULL -> not registered${NC}" | tee -a "$LOGFILE"
        done
        ;;
      6) break ;;
    esac
  done
}

# ─── CLEAR LOGS ──────────────────────────────────────────────────────────────
clear_logs() {
  echo -ne "${RED}[!] Delete ALL logs and reports? [yes/no]: ${NC}"
  read CDEL
  if [[ "$CDEL" == "yes" ]]; then
    rm -f "$LOG_DIR"/*.log "$LOG_DIR"/*.pcap "$REPORT_DIR"/*.html
    echo -e "${GREEN}[+] All logs and reports cleared.${NC}"
  else
    echo "Cancelled."
  fi
}

# ─── REPORT VIEWER ──────────────────────────────────────────────────────────
view_logs() {
  echo -e "${CYAN}[*] Saved logs:${NC}"
  ls -lh "$LOG_DIR"
  echo -ne "${CYAN}[?] Enter log filename to view (or Enter to skip): ${NC}"
  read LNAME
  [[ -n "$LNAME" ]] && less "$LOG_DIR/$LNAME"
}

# ─── MAIN MENU ──────────────────────────────────────────────────────────────
while true; do
  banner
  echo -e "${GREEN}┌────────────────────────────────────────────────────────────────────┐${NC}"
  echo -e "${GREEN}│${NC}  ${CYAN}${BOLD}[ RECON & SCANNING ]${NC}$(printf ' %.0s' $(seq 1 47))${GREEN}│${NC}"
  echo -e "${GREEN}├────────────────────────────────────────────────────────────────────┤${NC}"
  echo -e "${GREEN}│${NC}  ${GREEN} 1)${NC} Normal Scan        ${DIM}ping, top ports, whois, dns, headers${NC}"
  echo -e "${GREEN}│${NC}  ${GREEN} 2)${NC} Medium Scan        ${DIM}full ports, versions, OS, SSL, subdomains${NC}"
  echo -e "${GREEN}│${NC}  ${GREEN} 3)${NC} Hard Scan          ${DIM}aggressive, vuln scripts, web dirs, nikto${NC}"
  echo -e "${GREEN}│${NC}  ${GREEN} 4)${NC} Extra/Advanced     ${DIM}brute-force, SQLi, evasion, sniff, custom${NC}"
  echo -e "${GREEN}│${NC}  ${GREEN} 5)${NC} Network Recon      ${DIM}host discovery, ARP, UDP, DNS zone xfer${NC}"
  echo -e "${GREEN}│${NC}  ${GREEN} 6)${NC} Web App Testing    ${DIM}headers, WAF, CORS, TLS, login finder${NC}"
  echo -e "${GREEN}├────────────────────────────────────────────────────────────────────┤${NC}"
  echo -e "${GREEN}│${NC}  ${CYAN}${BOLD}[ EXPLOITATION ]${NC}"
  echo -e "${GREEN}├────────────────────────────────────────────────────────────────────┤${NC}"
  echo -e "${GREEN}│${NC}  ${RED} 7)${NC} Wireless Scan      ${DIM}WiFi recon, clients, handshake capture${NC}"
  echo -e "${GREEN}│${NC}  ${RED} 8)${NC} Post-Exploit       ${DIM}local info gathering, privesc checks${NC}"
  echo -e "${GREEN}│${NC}  ${RED} 9)${NC} Exploit Checker    ${DIM}CVE checks, .git/.env, default creds${NC}"
  echo -e "${GREEN}│${NC}  ${RED}10)${NC} Password Cracker   ${DIM}MD5/SHA1/bcrypt, hash ID, generator${NC}"
  echo -e "${GREEN}├────────────────────────────────────────────────────────────────────┤${NC}"
  echo -e "${GREEN}│${NC}  ${CYAN}${BOLD}[ DEFENSE & AWARENESS ]${NC}"
  echo -e "${GREEN}├────────────────────────────────────────────────────────────────────┤${NC}"
  echo -e "${GREEN}│${NC}  ${YELLOW}11)${NC} Defense Checker    ${DIM}firewall, SSH, permissions, rootkit${NC}"
  echo -e "${GREEN}│${NC}  ${YELLOW}12)${NC} Phishing Awareness ${DIM}SPF/DKIM, templates, typosquat check${NC}"
  echo -e "${GREEN}├────────────────────────────────────────────────────────────────────┤${NC}"
  echo -e "${GREEN}│${NC}  ${CYAN}${BOLD}[ TOOLS & UTILITIES ]${NC}"
  echo -e "${GREEN}├────────────────────────────────────────────────────────────────────┤${NC}"
  echo -e "${GREEN}│${NC}  ${MAGENTA}13)${NC} Auto Scan          ${DIM}full automated recon in one shot${NC}"
  echo -e "${GREEN}│${NC}  ${MAGENTA}14)${NC} Wordlist Tools     ${DIM}generate & manage wordlists${NC}"
  echo -e "${GREEN}│${NC}  ${MAGENTA}15)${NC} Generate Report    ${DIM}HTML report from all logs${NC}"
  echo -e "${GREEN}│${NC}  ${MAGENTA}16)${NC} View Logs          ${DIM}browse saved scan logs${NC}"
  echo -e "${GREEN}│${NC}  ${MAGENTA}17)${NC} Clear Logs         ${DIM}wipe all logs and reports${NC}"
  echo -e "${GREEN}│${NC}  ${MAGENTA}18)${NC} Check Tools        ${DIM}verify installed tools${NC}"
  echo -e "${GREEN}│${NC}  ${MAGENTA}19)${NC} Clear Saved Target"
  echo -e "${GREEN}│${NC}  ${WHITE} 0)${NC} ${RED}Exit${NC}"
  echo -e "${GREEN}└────────────────────────────────────────────────────────────────────┘${NC}"
  echo ""
  echo -ne "${GREEN}▶ ${BOLD}${CYAN}root@ethlab${NC}${GREEN}:~# ${NC}"
  read CHOICE

  case $CHOICE in
     1) normal_scan ;;
     2) medium_scan ;;
     3) hard_scan ;;
     4) extra_scan ;;
     5) network_recon ;;
     6) webapp_test ;;
     7) wireless_scan ;;
     8) post_exploit ;;
     9) exploit_checker ;;
    10) password_cracker ;;
    11) defense_check ;;
    12) phishing_awareness ;;
    13) auto_scan ;;
    14) wordlist_gen ;;
    15) generate_report ;;
    16) view_logs ;;
    17) clear_logs ;;
    18) check_tools ;;
    19) SAVED_TARGET=""; SAVED_LOGFILE=""; echo -e "${YELLOW}[*] Target cleared.${NC}" ;;
     0) echo -e "${GREEN}Goodbye.${NC}"; exit 0 ;;
     *) echo -e "${RED}[-] Invalid choice.${NC}" ;;
  esac

  echo -ne "\n${GREEN}[Press Enter to continue...]${NC}"
  read
done
