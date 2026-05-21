#!/bin/bash
# ============================================================
#  cPanel Server Statistics Report
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

DIVIDER="${DIM}──────────────────────────────────────────────────────${RESET}"

print_header() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║        cPanel Server Statistics Report           ║${RESET}"
    echo -e "${BOLD}${CYAN}  ║        $(date '+%Y-%m-%d %H:%M:%S')                      ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════╝${RESET}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BOLD}${YELLOW}  ► $1${RESET}"
    echo -e "  ${DIVIDER}"
}

human_bytes() {
    local B=$1
    if [ "$B" -ge 1099511627776 ] 2>/dev/null; then
        echo "$(echo "scale=1; $B/1099511627776" | bc)TB"
    elif [ "$B" -ge 1073741824 ] 2>/dev/null; then
        echo "$(echo "scale=1; $B/1073741824" | bc)GB"
    elif [ "$B" -ge 1048576 ] 2>/dev/null; then
        echo "$(echo "scale=1; $B/1048576" | bc)MB"
    elif [ "$B" -ge 1024 ] 2>/dev/null; then
        echo "$(echo "scale=1; $B/1024" | bc)KB"
    else
        echo "${B}B"
    fi
}

rank_color() {
    case $1 in
        1) echo "${RED}${BOLD}" ;;
        2) echo "${YELLOW}${BOLD}" ;;
        3) echo "${GREEN}${BOLD}" ;;
        *) echo "${RESET}" ;;
    esac
}

# ── Server Overview ──────────────────────────────────────────
server_overview() {
    print_section "SERVER OVERVIEW"

    printf "  ${BOLD}%-20s${RESET} %s\n" "Hostname:"       "$(hostname)"
    printf "  ${BOLD}%-20s${RESET} %s\n" "Uptime:"         "$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
    printf "  ${BOLD}%-20s${RESET} %s\n" "Load Average:"   "$(uptime | awk -F'load average:' '{print $2}' | xargs)"
    printf "  ${BOLD}%-20s${RESET} %s\n" "Total Accounts:" "$(ls /var/cpanel/users/ 2>/dev/null | wc -l)"
    printf "  ${BOLD}%-20s${RESET} %s\n" "cPanel Version:" "$(cat /usr/local/cpanel/version 2>/dev/null || echo N/A)"
    echo ""
    printf "  ${BOLD}%-20s${RESET} %s / %s used  (%s free)\n" "RAM:" \
        "$(free -h | awk '/^Mem:/{print $3}')" \
        "$(free -h | awk '/^Mem:/{print $2}')" \
        "$(free -h | awk '/^Mem:/{print $4}')"
    printf "  ${BOLD}%-20s${RESET} %s\n" "CPU Cores:" "$(nproc)"
    echo ""
    echo -e "  ${BOLD}Disk Partitions:${RESET}"
    df -h --output=target,size,used,avail,pcent 2>/dev/null | \
        grep -vE 'tmpfs|udev|Use%' | \
        while read -r line; do
            PCT=$(echo "$line" | awk '{print $5}' | tr -d '%')
            if [ -n "$PCT" ] && [ "$PCT" -ge 90 ] 2>/dev/null; then
                echo -e "    ${RED}$line${RESET}"
            elif [ -n "$PCT" ] && [ "$PCT" -ge 75 ] 2>/dev/null; then
                echo -e "    ${YELLOW}$line${RESET}"
            else
                echo -e "    ${GREEN}$line${RESET}"
            fi
        done
}

# ── Top 10 Disk Usage ────────────────────────────────────────
top_disk() {
    print_section "TOP 10 ACCOUNTS BY DISK USAGE"
    printf "  ${BOLD}%-5s  %-22s  %s${RESET}\n" "Rank" "Account" "Disk Used"
    echo -e "  ${DIVIDER}"

    # repquota col 3 = used blocks (1 block = 1KB on most systems)
    RANK=1
    repquota -a 2>/dev/null | \
        grep -vE '^\*|^-|^Block|^User|^$|^root|^bin|^nobody|^cpanel|^mail' | \
        awk '{if ($3+0 > 0) print $3, $1}' | \
        sort -rn | head -10 | \
        while read -r BLOCKS ACCOUNT; do
            BYTES=$(( BLOCKS * 1024 ))
            SIZE=$(human_bytes "$BYTES")
            COLOR=$(rank_color $RANK)
            printf "  ${COLOR}%-5s  %-22s  %s${RESET}\n" "#$RANK" "$ACCOUNT" "$SIZE"
            RANK=$((RANK + 1))
        done
}

# ── Top 10 Bandwidth ─────────────────────────────────────────
top_bandwidth() {
    print_section "TOP 10 ACCOUNTS BY BANDWIDTH (Current Month)"
    printf "  ${BOLD}%-5s  %-22s  %s${RESET}\n" "Rank" "Account"
    echo -e "  ${DIVIDER}"

    # Bandwidth files are SQLite: /var/cpanel/bandwidth/<user>.sqlite
    # Table bandwidth_daily has columns: timestamp, bytes (unix epoch per day)
    # Sum bytes for current month using timestamp range

    if ! command -v sqlite3 &>/dev/null; then
        echo -e "  ${RED}sqlite3 not found — install with: yum install sqlite${RESET}"
        return
    fi

    MONTH_START=$(date -d "$(date +%Y-%m-01)" +%s)
    MONTH_END=$(date -d "$(date -d 'next month' +%Y-%m-01)" +%s 2>/dev/null || \
                date -d "+1 month" +%s)
    TMPBW=$(mktemp)

    for DBFILE in /var/cpanel/bandwidth/*.sqlite; do
        [ -f "$DBFILE" ] || continue
        ACCOUNT=$(basename "$DBFILE" .sqlite)
        BYTES=$(sqlite3 "$DBFILE" \
            "SELECT COALESCE(SUM(bytes),0) FROM bandwidth_daily \
             WHERE timestamp >= ${MONTH_START} AND timestamp < ${MONTH_END};" \
            2>/dev/null)
        [ -z "$BYTES" ] && BYTES=0
        echo "$BYTES $ACCOUNT"
    done | sort -rn | head -10 > "$TMPBW"

    RANK=1
    while read -r BYTES ACCOUNT && [ "$RANK" -le 10 ]; do
        SIZE=$(human_bytes "$BYTES")
        COLOR=$(rank_color $RANK)
        printf "  ${COLOR}%-5s  %-22s  %s${RESET}\n" "#$RANK" "$ACCOUNT"
        RANK=$((RANK + 1))
    done < "$TMPBW"

    rm -f "$TMPBW"
}

# ── Top 10 Database Usage (cPanel style per user) ────────────────────────────────────
top_databases() {
    print_section "TOP 10 ACCOUNTS BY DATABASE SIZE (CPANEL STYLE)"

    printf "  %-5s  %-22s  %s\n" "Rank" "Account" "Size"
    echo -e "  ${DIVIDER}"

    TMP=$(mktemp)

    mysql -N -B -e "
        SELECT 
            SUBSTRING_INDEX(table_schema,'_',1) AS account,
            SUM(data_length + index_length) AS size
        FROM information_schema.tables
        GROUP BY table_schema
        ORDER BY size DESC
        LIMIT 10;
    " 2>/dev/null | while read -r ACCOUNT SIZE; do
        echo "$SIZE $ACCOUNT"
    done > "$TMP"

    RANK=1
    while read -r BYTES ACCOUNT && [ "$RANK" -le 10 ]; do
        SIZE=$(human_bytes "$BYTES")
        COLOR=$(rank_color "$RANK")

        printf "  ${COLOR}%-5s  %-22s  %s${RESET}\n" \
            "#$RANK" "$ACCOUNT" "$SIZE"

        RANK=$((RANK + 1))
    done < "$TMP"

    rm -f "$TMP"
}
# ── Suspended Accounts ───────────────────────────────────────
account_alerts() {
    print_section "ACCOUNT ALERTS"

    SUSPENDED=$(ls /var/cpanel/suspended/ 2>/dev/null | wc -l)
    echo -e "  ${BOLD}Suspended accounts:${RESET} ${RED}${SUSPENDED}${RESET}"
    if [ "$SUSPENDED" -gt 0 ]; then
        ls /var/cpanel/suspended/ 2>/dev/null | while read -r ACC; do
            REASON=$(cat "/var/cpanel/suspended/$ACC" 2>/dev/null || echo "No reason given")
            echo -e "    ${DIM}• $ACC — $REASON${RESET}"
        done
    fi
}

# ── Footer ───────────────────────────────────────────────────
print_footer() {
    echo ""
    echo -e "  ${DIVIDER}"
    echo -e "  ${DIM}Report generated: $(date)  |  Server: $(hostname)${RESET}"
    echo ""
}

# ── Main ─────────────────────────────────────────────────────
print_header
server_overview
top_disk
top_bandwidth
top_databases
account_alerts
print_footer
