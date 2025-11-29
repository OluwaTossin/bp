#!/bin/bash

###############################################################################
# OWASP ZAP Security Scan Script
# Performs baseline security testing on the BP Calculator application
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TARGET_URL="${1:-http://bp-calculator-staging.eba-gb3zir6t.eu-west-1.elasticbeanstalk.com}"
REPORT_DIR="security-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/zap-report-${TIMESTAMP}.html"
JSON_REPORT="${REPORT_DIR}/zap-report-${TIMESTAMP}.json"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  OWASP ZAP Security Scan${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Target URL: ${TARGET_URL}${NC}"
echo -e "${BLUE}Report: ${REPORT_FILE}${NC}"
echo ""

# Create report directory
mkdir -p "$REPORT_DIR"

# Check if target is reachable
echo -e "${YELLOW}Checking if target is reachable...${NC}"
if ! curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL" | grep -q "200\|302"; then
    echo -e "${RED}✗ Target URL is not reachable: ${TARGET_URL}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Target is reachable${NC}"
echo ""

# Run ZAP baseline scan using Docker
echo -e "${YELLOW}Starting OWASP ZAP baseline scan...${NC}"
echo -e "${BLUE}This may take 2-5 minutes...${NC}"
echo ""

# Run ZAP in Docker with baseline scan
docker run --rm \
    -v "$(pwd)/${REPORT_DIR}:/zap/wrk:rw" \
    -t ghcr.io/zaproxy/zaproxy:stable \
    zap-baseline.py \
    -t "$TARGET_URL" \
    -r "zap-report-${TIMESTAMP}.html" \
    -J "zap-report-${TIMESTAMP}.json" \
    -I \
    -c zap-baseline.conf \
    || SCAN_EXIT_CODE=$?

# ZAP exit codes:
# 0 - No issues found
# 1 - Warning (low/medium issues)
# 2 - High risk issues found
# 3 - Error during scan

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Scan Results${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -f "$JSON_REPORT" ]; then
    # Parse results from JSON report
    HIGH=$(jq -r '.site[0].alerts[] | select(.riskcode=="3") | .name' "$JSON_REPORT" 2>/dev/null | wc -l || echo "0")
    MEDIUM=$(jq -r '.site[0].alerts[] | select(.riskcode=="2") | .name' "$JSON_REPORT" 2>/dev/null | wc -l || echo "0")
    LOW=$(jq -r '.site[0].alerts[] | select(.riskcode=="1") | .name' "$JSON_REPORT" 2>/dev/null | wc -l || echo "0")
    INFO=$(jq -r '.site[0].alerts[] | select(.riskcode=="0") | .name' "$JSON_REPORT" 2>/dev/null | wc -l || echo "0")
    
    echo -e "High Risk Issues:   ${HIGH}"
    echo -e "Medium Risk Issues: ${MEDIUM}"
    echo -e "Low Risk Issues:    ${LOW}"
    echo -e "Informational:      ${INFO}"
    echo ""
    
    if [ "$HIGH" -gt 0 ]; then
        echo -e "${RED}✗ High risk vulnerabilities found!${NC}"
        echo -e "${YELLOW}Review the report: ${REPORT_FILE}${NC}"
        exit 2
    elif [ "$MEDIUM" -gt 0 ]; then
        echo -e "${YELLOW}⚠ Medium risk issues found${NC}"
        echo -e "${YELLOW}Review the report: ${REPORT_FILE}${NC}"
        exit 0  # Don't fail CI on medium issues
    else
        echo -e "${GREEN}✓ No high or medium risk vulnerabilities found${NC}"
        exit 0
    fi
else
    echo -e "${YELLOW}⚠ Could not parse scan results${NC}"
    echo -e "${BLUE}Check the HTML report: ${REPORT_FILE}${NC}"
    exit ${SCAN_EXIT_CODE:-1}
fi
