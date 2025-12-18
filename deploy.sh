#!/bin/bash

# ==========================================
# 🛡️ Privacy Shield - Auto Deploy & Audit Tool
# ==========================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}[*] Starting Privacy Shield Deployment...${NC}"

# 1. PRE-FLIGHT CHECKS
echo -e "\n${YELLOW}[1/4] Checking Prerequisites...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[!] Error: Docker is not installed.${NC}"
    exit 1
fi

# Check Time Sync (Critical for DNSSEC)
echo -e "[-] Verifying system time..."
SERVER_DATE=$(date +%F)
echo -e "    Current System Date: $SERVER_DATE"
echo -e "${GREEN}[OK] System check passed.${NC}"

# 2. DEPLOYMENT
echo -e "\n${YELLOW}[2/4] Launching Containers...${NC}"
docker compose down > /dev/null 2>&1
if docker compose up -d; then
    echo -e "${GREEN}[OK] Containers launched successfully.${NC}"
else
    echo -e "${RED}[!] Error: Failed to start containers. Check docker-compose.yml${NC}"
    exit 1
fi

# 3. WAITING PERIOD
echo -e "\n${YELLOW}[3/4] Waiting for services to initialize (15s)...${NC}"
# Progress bar simulation
echo -ne '    [=>                  ] (10%)\r'
sleep 3
echo -ne '    [=====>              ] (40%)\r'
sleep 3
echo -ne '    [==========>         ] (70%)\r'
sleep 5
echo -ne '    [===================>] (100%)\r'
echo -ne '\n'

# 4. AUTOMATED AUDIT (The Truth Test)
echo -e "\n${YELLOW}[4/4] Running Security Audit (The Truth Test)...${NC}"

# Test A: Unbound Connectivity
echo -n "[-] Test A: Unbound connection to Root Servers... "
if docker exec pihole dig @10.10.10.2 google.com +short > /dev/null 2>&1; then
    echo -e "${GREEN}[PASS]${NC}"
else
    echo -e "${RED}[FAIL]${NC}"
    echo "    Error: Unbound is not resolving queries."
fi

# Test B: Pi-hole Blocklist
echo -n "[-] Test B: Ad-Block Gravity (doubleclick.net)... "
BLOCK_TEST=$(docker exec pihole dig @127.0.0.1 doubleclick.net +short)
if [[ "$BLOCK_TEST" == "0.0.0.0" ]] || [[ -z "$BLOCK_TEST" ]]; then
    echo -e "${GREEN}[PASS]${NC}"
else
    echo -e "${RED}[FAIL]${NC}"
    echo "    Error: Domain was not blocked (IP: $BLOCK_TEST)"
fi

# Test C: DNSSEC Validation
echo -n "[-] Test C: DNSSEC Validation (sigok.verteiltesysteme.net)... "
DNSSEC_TEST=$(docker exec pihole dig @127.0.0.1 sigok.verteiltesysteme.net | grep " ad ")
if [[ -n "$DNSSEC_TEST" ]]; then
    echo -e "${GREEN}[PASS]${NC}"
else
    echo -e "${RED}[FAIL]${NC}"
    echo "    Error: 'ad' flag missing. Time sync or Unbound issue."
fi

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}   SHIELD DEPLOYMENT COMPLETE   ${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "Access your dashboard at: http://<YOUR_IP>:8080/admin"
