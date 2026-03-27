#!/bin/bash
# setup.sh - Install required tools for the ethical hacking lab

echo "[*] Updating packages..."
pkg update -y && pkg upgrade -y

echo "[*] Installing core tools..."
pkg install -y nmap netcat-openbsd curl wget git python3 openssh hydra dnsutils whois

echo "[*] Installing Python tools..."
pip install requests scapy

echo "[*] Installing additional tools..."
pkg install -y masscan sqlmap nikto

echo "[+] Setup complete. Run: bash ethlab.sh"
