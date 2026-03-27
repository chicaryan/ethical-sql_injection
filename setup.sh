#!/bin/bash
# setup.sh - Install required tools for the ethical hacking lab

echo "[*] Updating packages..."
pkg update -y && pkg upgrade -y

echo "[*] Installing core tools..."
pkg install -y nmap netcat-openbsd curl wget git python3 openssh dnsutils whois

echo "[*] Installing Python tools..."
pip install requests scapy

echo "[*] Installing additional tools..."
pkg install -y masscan sqlmap nikto

echo "[*] Installing hydra from source..."
pkg install -y clang make libssl openssl
cd /tmp && git clone https://github.com/vanhauser-thc/thc-hydra.git 2>/dev/null || true
cd /tmp/thc-hydra && ./configure && make && make install
echo "[+] Hydra installed"

echo "[+] Setup complete. Run: bash ethlab.sh"
