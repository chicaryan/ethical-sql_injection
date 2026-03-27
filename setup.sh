#!/bin/bash
# setup.sh - Install required tools for the ethical hacking lab

echo "[*] Updating packages..."
pkg update -y && pkg upgrade -y

echo "[*] Installing core tools..."
pkg install -y nmap netcat-openbsd curl wget git python3 openssh dnsutils whois

echo "[*] Installing Python tools..."
pip install requests scapy

echo "[*] Installing sqlmap..."
pip install sqlmap

echo "[*] Installing nikto..."
pkg install -y perl
cd /tmp && git clone https://github.com/sullo/nikto.git 2>/dev/null || true
echo "alias nikto='perl /tmp/nikto/program/nikto.pl'" >> ~/.bashrc

echo "[*] Installing masscan from source..."
pkg install -y clang make
cd /tmp && git clone https://github.com/robertdavidgraham/masscan.git 2>/dev/null || true
cd /tmp/masscan && make
cp /tmp/masscan/bin/masscan $PREFIX/bin/masscan
echo "[+] masscan, sqlmap, nikto installed"

echo "[*] Installing hydra from source..."
pkg install -y clang make libssl openssl
cd /tmp && git clone https://github.com/vanhauser-thc/thc-hydra.git 2>/dev/null || true
cd /tmp/thc-hydra && ./configure && make && make install
echo "[+] Hydra installed"

echo "[+] Setup complete. Run: bash ethlab.sh"
