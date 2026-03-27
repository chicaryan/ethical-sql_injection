# Ethical Hacking Lab (Termux)

> ⚠️ LEGAL NOTICE: Only use this on systems you own or have explicit written permission to test.
> Unauthorized use is illegal and unethical.

---

## 📲 Install & Run in Termux (from GitHub)

### Step 1 — Install Termux
Download **Termux** from [F-Droid](https://f-droid.org/packages/com.termux/) (recommended, not Play Store).

### Step 2 — Open Termux and run:

```bash
# Allow storage access
termux-setup-storage

# Install git
pkg install git -y

# Clone the repo
git clone https://github.com/chicaryan/ethical-sql_injection.git

# Enter the folder
cd ethical-sql_injection

# Give execute permission
chmod +x setup.sh ethlab.sh

# Install all tools
bash setup.sh

# Run the lab
bash ethlab.sh
```

---

## 📤 How to Push to GitHub (first time)

```bash
# On your PC or inside Termux:
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/chicaryan/ethical-sql_injection.git
git push -u origin main
```

---

## 🔧 Scan Categories

| #  | Category           | Tools Used                              | Use Case                          |
|----|--------------------|-----------------------------------------|-----------------------------------|
|  1 | Normal             | ping, nmap -F, whois, dig, curl         | Quick recon, low noise            |
|  2 | Medium             | nmap full, -sV -sC, -O, openssl         | Deeper recon, service fingerprint |
|  3 | Hard               | nmap -A, vuln scripts, nikto, nc        | Active scanning, web testing      |
|  4 | Extra/Advanced     | hydra, sqlmap, tcpdump, evasion         | Exploitation, brute-force         |
|  5 | Network Recon      | nmap, arp-scan, dig, traceroute         | Host discovery, topology mapping  |
|  6 | Web App Testing    | curl, nmap scripts, openssl             | Headers, WAF, CORS, TLS, cookies  |
|  7 | Wireless Scan      | iwlist, airodump-ng, aireplay-ng        | WiFi recon, handshake capture     |
|  8 | Post-Exploit       | find, ss, grep, crontab, ps             | Local privesc & exposure checks   |
|  9 | Defense Checker    | iptables, ss, openssl, dig              | Audit your own defenses           |
| 10 | Password Cracker   | hashcat, john, md5sum, sha256sum        | Hash cracking & identification    |
| 11 | Exploit Checker    | nmap scripts, curl                      | CVE checks, exposed files/creds   |
| 12 | Phishing Awareness | dig, curl, bash                         | SPF/DKIM, templates, typosquats   |
| 13 | Auto Scan          | nmap, curl, whois, dig                  | Full automated recon in one shot  |
| 14 | Wordlist Tools     | bash built-in                           | Generate & manage wordlists       |
| 15 | Generate Report    | bash + HTML                             | Auto HTML report from all logs    |

---

## 🛠️ Tools Installed by setup.sh

| Tool          | Install Command                  |
|---------------|----------------------------------|
| nmap          | `pkg install nmap`               |
| hydra         | `pkg install hydra`              |
| nikto         | `pkg install nikto`              |
| sqlmap        | `pkg install sqlmap`             |
| netcat        | `pkg install netcat-openbsd`     |
| aircrack-ng   | `pkg install aircrack-ng`        |
| arp-scan      | `pkg install arp-scan`           |
| masscan       | `pkg install masscan`            |
| python3       | `pkg install python3`            |
| git           | `pkg install git`                |
| curl/dig/wget | included in setup.sh             |

---

## 📁 Logs & Reports

- Scan logs → `~/ethlab_logs/`
- HTML reports → `~/ethlab_reports/` (open in any browser)

---

## 💡 Tips

- Run `setup.sh` once before first use
- Use a local VM or home router as your test target
- `.pcap` capture files can be opened with Wireshark on PC
- Add custom wordlists to `/sdcard/wordlists/` for brute-force tests
- The lab remembers your last target — no need to re-enter between scans
- Wireless scans require monitor mode: `airmon-ng start wlan0`
