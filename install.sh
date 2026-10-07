#!/usr/bin/env bash
set -Eeuo pipefail
VERSION='1.0.0'; AUTHOR='Oren'; LOG_DIR='/var/log/oren-pterodactyl'; LOG_FILE="$LOG_DIR/installer.log"
[[ $EUID -eq 0 ]] || { echo 'ERROR: Run as root.'; exit 1; }
mkdir -p "$LOG_DIR"; touch "$LOG_FILE"; exec > >(tee -a "$LOG_FILE") 2>&1
if [[ -t 1 ]]; then C_RESET='\033[0m'; C_BLUE='\033[38;5;39m'; C_CYAN='\033[38;5;51m'; C_GREEN='\033[38;5;82m'; C_YELLOW='\033[38;5;220m'; C_RED='\033[38;5;196m'; C_DIM='\033[2m'; C_WHITE='\033[97m'; else C_RESET=''; C_BLUE=''; C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_DIM=''; C_WHITE=''; fi
ok(){ echo -e "${C_GREEN}[✓]${C_RESET} $*"; }; warn(){ echo -e "${C_YELLOW}[!]${C_RESET} $*"; }; err(){ echo -e "${C_RED}[✗]${C_RESET} $*"; }; info(){ echo -e "${C_CYAN}[i]${C_RESET} $*"; }; pause(){ read -r -p 'Press Enter to continue...' _ || true; }; run(){ echo -e "${C_DIM}+ $*${C_RESET}"; "$@"; }
header(){ clear || true; echo -e "${C_BLUE}╔══════════════════════════════════════════════════════════════╗\n║                                                              ║\n║                  O R E N   I N S T A L L E R                ║\n║             Pterodactyl Management Suite v1                  ║\n║                                                              ║\n╚══════════════════════════════════════════════════════════════╝${C_RESET}"; }
detect(){ [[ -r /etc/os-release ]] && . /etc/os-release; OS_NAME="${PRETTY_NAME:-Unknown}"; KERNEL="$(uname -r 2>/dev/null || echo '?')"; CPU="$(nproc 2>/dev/null || echo '?')"; RAM="$(awk '/MemTotal/ {printf "%.1f",$2/1024/1024}' /proc/meminfo 2>/dev/null || echo '?')"; DISK="$(df -h / 2>/dev/null|awk 'NR==2{print $4}')"; [[ -d /var/www/pterodactyl ]] && PANEL='Detected' || PANEL='Not detected'; systemctl is-active --quiet wings 2>/dev/null && WINGS='Running' || WINGS='Not running'; command -v docker >/dev/null 2>&1 && DOCKER="$(docker --version 2>/dev/null|head -1)" || DOCKER='Not installed'; }
status(){ detect; echo " System: $OS_NAME"; echo " Kernel: $KERNEL"; echo " CPU:    $CPU cores"; echo " RAM:    $RAM GB"; echo " Disk:   $DISK free"; echo " Panel:  $PANEL"; echo " Wings:  $WINGS"; echo " Docker: $DOCKER"; echo; }
confirm(){ local a; read -r -p "${1:-Continue?} [y/N]: " a; [[ $a =~ ^[Yy]$ ]]; }

panel(){ while :; do header; echo 'PTERODACTYL PANEL'; cat <<'M'

 [1] Install Pterodactyl Panel
 [2] Update Panel
 [3] Configure Panel
 [4] Configure Database
 [5] Configure Queue Worker
 [6] Configure Cron
 [7] Configure Nginx
 [8] Configure SSL
 [9] Create Admin Account
 [10] Clear Panel Cache
 [11] Repair Panel
 [12] Panel Status
 [13] Panel Logs

 [0] Back
M
 read -r -p ' Select option: ' x; case $x in
 1) header; warn 'Full Panel installation will be added against the selected official Pterodactyl version in the next module pass.'; pause;;
 2) header; [[ -d /var/www/pterodactyl ]] && { cd /var/www/pterodactyl; php artisan optimize:clear || true; ok 'Panel maintenance completed.'; } || err 'Panel not found.'; pause;;
 3|4|5|6|7|8|9) header; info 'Module scaffold ready; configuration will be added without inventing credentials or node tokens.'; pause;;
 10) [[ -d /var/www/pterodactyl ]] && { cd /var/www/pterodactyl; php artisan optimize:clear; ok 'Caches cleared.'; } || err 'Panel not found.'; pause;;
 11) [[ -d /var/www/pterodactyl ]] && { cd /var/www/pterodactyl; chown -R www-data:www-data storage bootstrap/cache; php artisan optimize:clear || true; ok 'Basic repair completed.'; } || err 'Panel not found.'; pause;;
 12) systemctl status nginx --no-pager -l 2>/dev/null || true; pause;;
 13) find /var/www/pterodactyl/storage/logs -type f -printf '%T@ %p\n' 2>/dev/null|sort -nr|head -1|cut -d' ' -f2-|xargs -r tail -80; pause;;
 0) return;; *) warn 'Invalid option.'; sleep 1;; esac; done; }

wings(){ while :; do header; echo 'NODES & WINGS'; cat <<'M'

 [1] Install Wings
 [2] Update Wings
 [3] Configure Wings
 [4] Generate Node Configuration
 [5] Register Node
 [6] Test Node Connection
 [7] Restart Wings
 [8] Stop Wings
 [9] Wings Status
 [10] Wings Logs
 [11] Repair Wings

 [0] Back
M
 read -r -p ' Select option: ' x; case $x in
 1|2|3|4|5) header; info 'Wings module scaffold ready. Node tokens/config are never guessed.'; pause;; 6) systemctl is-active wings && ok 'Wings is running.' || err 'Wings is not running.'; pause;; 7) systemctl restart wings; pause;; 8) systemctl stop wings; pause;; 9) systemctl status wings --no-pager -l 2>/dev/null||true; pause;; 10) journalctl -u wings -n 100 --no-pager 2>/dev/null||true; pause;; 11) systemctl daemon-reload; systemctl restart wings 2>/dev/null||true; pause;; 0) return;; *) warn 'Invalid option.';; esac; done; }

python_menu(){ while :; do header; echo 'PYTHON'; cat <<'M'

 [1] Python 3.10
 [2] Python 3.11
 [3] Python 3.12
 [4] Python 3.13
 [5] Python 3.14
 [6] Install pip
 [7] Install virtualenv
 [8] Common Python build tools
 [9] Python environment info

 [0] Back
M
 read -r -p ' Select option: ' x; case $x in 1) py=3.10;;2)py=3.11;;3)py=3.12;;4)py=3.13;;5)py=3.14;;6) apt-get update; apt-get install -y python3-pip; pause; continue;;7) apt-get update; apt-get install -y python3-venv; pause; continue;;8) apt-get update; apt-get install -y python3-pip python3-venv build-essential; pause; continue;;9) python3 --version 2>/dev/null||true; python3 -m pip --version 2>/dev/null||true; pause; continue;;0)return;;*)warn 'Invalid option.';continue;;esac; header; if apt-cache show "python$py" >/dev/null 2>&1; then apt-get update; apt-get install -y "python$py" "python$py-venv" "python$py-dev"; ok "Python $py installed."; else warn "Python $py is not in current APT repositories; no unverified repository is added automatically."; fi; pause; done; }
node_menu(){ while :; do header; echo 'NODE.JS'; cat <<'M'

 [1] Node.js 18
 [2] Node.js 20
 [3] Node.js 22
 [4] Node.js 24
 [5] npm
 [6] pnpm
 [7] Yarn
 [8] Node.js environment info

 [0] Back
M
 read -r -p ' Select option: ' x; case $x in 1)ver=18;;2)ver=20;;3)ver=22;;4)ver=24;;5)apt-get update;apt-get install -y npm;pause;continue;;6)corepack enable 2>/dev/null&&corepack prepare pnpm@latest --activate||warn 'Corepack unavailable.';pause;continue;;7)corepack enable 2>/dev/null&&corepack prepare yarn@stable --activate||warn 'Corepack unavailable.';pause;continue;;8)node --version 2>/dev/null||true;npm --version 2>/dev/null||true;pause;continue;;0)return;;*)warn 'Invalid option.';continue;;esac; header; warn "Node.js $ver installer is scaffolded; v1 will use a pinned official repository/source instead of blindly adding one."; pause; done; }
java_menu(){ while :; do header; echo 'JAVA'; printf '\n [1] Java 8\n [2] Java 11\n [3] Java 17\n [4] Java 21\n [5] Java 25\n [6] Java info\n\n [0] Back\n'; read -r -p ' Select option: ' x; case $x in 1)j=8;;2)j=11;;3)j=17;;4)j=21;;5)j=25;;6)java -version 2>&1||true;pause;continue;;0)return;;*)continue;;esac; pkg="openjdk-$j-jdk"; if apt-cache show "$pkg" >/dev/null 2>&1; then apt-get update;apt-get install -y "$pkg"; else warn "$pkg unavailable in current repositories."; fi;pause; done; }
runtime(){ while :; do header; echo 'RUNTIME & LANGUAGES'; printf '\n [1] Python\n [2] Node.js\n [3] Java\n [4] PHP\n [5] Go\n [6] Rust\n [7] Custom Runtime\n\n [0] Back\n'; read -r -p ' Select option: ' x; case $x in 1)python_menu;;2)node_menu;;3)java_menu;;4)apt-get update;apt-get install -y php php-cli php-fpm php-mysql php-curl php-mbstring php-xml php-bcmath php-zip php-gd;pause;;5)header;info 'Go module scaffold ready.';pause;;6)header;info 'Rust module scaffold ready.';pause;;7)header;info 'Custom runtime module scaffold ready.';pause;;0)return;;esac;done; }

database(){ while :; do header; echo 'DATABASE'; printf '\n [1] Install MariaDB\n [2] Install Redis\n [3] MariaDB status\n [4] Redis status\n [5] Database diagnostics\n\n [0] Back\n'; read -r -p ' Select option: ' x; case $x in 1)apt-get update;apt-get install -y mariadb-server mariadb-client;pause;;2)apt-get update;apt-get install -y redis-server;pause;;3)systemctl status mariadb --no-pager -l||true;pause;;4)systemctl status redis-server --no-pager -l||true;pause;;5)mysql --version 2>/dev/null||true;redis-server --version 2>/dev/null||true;pause;;0)return;;esac;done; }
web(){ while :; do header; echo 'WEB SERVER'; printf '\n [1] Install Nginx\n [2] Nginx status\n [3] Test config\n [4] Reload\n [5] Restart\n [6] List sites\n [7] Install Certbot\n\n [0] Back\n'; read -r -p ' Select option: ' x; case $x in 1)apt-get update;apt-get install -y nginx;pause;;2)systemctl status nginx --no-pager -l||true;pause;;3)nginx -t;pause;;4)systemctl reload nginx;pause;;5)systemctl restart nginx;pause;;6)ls -la /etc/nginx/sites-enabled 2>/dev/null||true;pause;;7)apt-get update;apt-get install -y certbot python3-certbot-nginx;pause;;0)return;;esac;done; }
docker_menu(){ while :; do header; echo 'DOCKER'; printf '\n [1] Install Docker\n [2] Docker version\n [3] Docker status\n [4] Restart Docker\n [5] Containers\n [6] Images\n [7] Disk usage\n [8] Prune unused resources\n\n [0] Back\n'; read -r -p ' Select option: ' x; case $x in 1)apt-get update;apt-get install -y docker.io;systemctl enable --now docker;pause;;2)docker --version||true;pause;;3)systemctl status docker --no-pager -l||true;pause;;4)systemctl restart docker;pause;;5)docker ps -a;pause;;6)docker images;pause;;7)docker system df;pause;;8)confirm 'Prune unused Docker resources?'&&docker system prune;pause;;0)return;;esac;done; }
security(){ while :; do header; echo 'SECURITY & FIREWALL'; printf '\n [1] Install UFW\n [2] UFW status\n [3] Open port\n [4] Close port\n [5] Install Fail2Ban\n [6] System updates\n [7] Listening ports\n\n [0] Back\n'; read -r -p ' Select option: ' x; case $x in 1)apt-get update;apt-get install -y ufw;pause;;2)ufw status verbose||true;pause;;3)read -r -p 'Port (e.g. 25565/tcp): ' p;[[ $p =~ ^[0-9]+/(tcp|udp)$ ]]&&ufw allow "$p"||warn 'Invalid format.';pause;;4)read -r -p 'Port (e.g. 25565/tcp): ' p;[[ $p =~ ^[0-9]+/(tcp|udp)$ ]]&&ufw delete allow "$p"||warn 'Invalid format.';pause;;5)apt-get update;apt-get install -y fail2ban;pause;;6)apt-get update;apt-get upgrade -y;pause;;7)ss -tulpn;pause;;0)return;;esac;done; }
backup(){ while :; do header; echo 'BACKUP & RESTORE'; printf '\n [1] Backup Panel\n [2] Backup Panel .env\n [3] Backup Wings config\n [4] List backups\n [5] Full config archive\n\n [0] Back\n'; read -r -p ' Select option: ' x; mkdir -p /root/oren-backups; case $x in 1)src=/var/www/pterodactyl;;2)src=/var/www/pterodactyl/.env;;3)src=/etc/pterodactyl;;4)ls -lh /root/oren-backups;pause;continue;;5)tar -czf "/root/oren-backups/full-$(date +%Y%m%d-%H%M%S).tar.gz" /etc/pterodactyl /var/www/pterodactyl/.env 2>/dev/null||true;pause;continue;;0)return;;*)continue;;esac; [[ -e $src ]]&&tar -czf "/root/oren-backups/$(basename "$src")-$(date +%Y%m%d-%H%M%S).tar.gz" "$src"&&ok 'Backup created.'||err 'Source not found.';pause;done; }
maintenance(){ while :; do header; echo 'MAINTENANCE'; printf '\n [1] Failed services\n [2] Restart Pterodactyl services\n [3] Clear Panel cache\n [4] Fix Panel permissions\n [5] Reload systemd\n [6] OREN log\n [7] Uptime\n\n [0] Back\n'; read -r -p ' Select option: ' x; case $x in 1)systemctl --failed --no-pager;pause;;2)systemctl restart nginx 2>/dev/null||true;systemctl restart wings 2>/dev/null||true;systemctl restart pteroq 2>/dev/null||true;pause;;3)panel_cache(){ :; }; [[ -d /var/www/pterodactyl ]]&&{ cd /var/www/pterodactyl;php artisan optimize:clear; }||true;pause;;4)[[ -d /var/www/pterodactyl ]]&&chown -R www-data:www-data /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache;pause;;5)systemctl daemon-reload;pause;;6)tail -100 "$LOG_FILE";pause;;7)uptime;pause;;0)return;;esac;done; }
diagnostics(){ while :; do header; echo 'DIAGNOSTICS'; printf '\n [1] Full system check\n [2] Panel check\n [3] Wings check\n [4] Docker check\n [5] Database check\n [6] Nginx check\n [7] Network check\n [8] Disk/RAM check\n [9] Generate report\n\n [0] Back\n'; read -r -p ' Select option: ' x; case $x in 1)status;systemctl --failed --no-pager;pause;;2)[[ -d /var/www/pterodactyl ]]&&ok 'Panel detected.'||err 'Panel missing.';pause;;3)systemctl is-active wings&&ok 'Wings active.'||err 'Wings inactive.';pause;;4)docker info >/dev/null 2>&1&&ok 'Docker operational.'||err 'Docker unavailable.';pause;;5)systemctl is-active mariadb||true;systemctl is-active redis-server||true;pause;;6)nginx -t;pause;;7)ip -br addr;ss -tulpn|head -50;pause;;8)df -h;free -h;pause;;9)mkdir -p /root/oren-reports;f="/root/oren-reports/report-$(date +%Y%m%d-%H%M%S).txt"; date > "$f"; status >> "$f"; systemctl --failed --no-pager >> "$f"; df -h >> "$f"; free -h >> "$f"; ss -tulpn >> "$f"; ok "Report: $f";pause;;0)return;;esac;done; }
optimization(){ while :; do header; echo 'SERVER OPTIMIZATION'; printf '\n [1] Memory/swap\n [2] Disk\n [3] CPU\n [4] Network\n [5] Docker resources\n [6] Recommended report\n\n [0] Back\n'; read -r -p ' Select option: ' x; case $x in 1)free -h;swapon --show;pause;;2)lsblk;df -h;pause;;3)lscpu|head -30;pause;;4)ip -br addr;ip route;pause;;5)docker system df 2>/dev/null||true;pause;;6)info 'v1 only reports recommendations; it does not apply risky kernel/sysctl tuning automatically.';pause;;0)return;;esac;done; }
advanced(){ while :; do header; echo 'ADVANCED TOOLS'; printf '\n [1] Systemd services\n [2] Environment info (secrets redacted)\n [3] Listening ports\n [4] Package search\n [5] Custom command\n\n [0] Back\n'; read -r -p ' Select option: ' x; case $x in 1)systemctl list-units --type=service --state=running --no-pager|head -80;pause;;2)env|sort|sed -E 's/(TOKEN|PASSWORD|SECRET|KEY)=.*/\1=[REDACTED]/I';pause;;3)ss -tulpn;pause;;4)read -r -p 'Search: ' q;apt-cache search "$q"|head -30;pause;;5)read -r -p 'Command: ' c;confirm 'Execute as root?'&&bash -lc "$c";pause;;0)return;;esac;done; }
main(){ while :; do header; status; echo 'CATEGORIES'; cat <<'M'

 [1] Pterodactyl Panel
 [2] Nodes & Wings
 [3] Runtime & Languages
 [4] Database
 [5] Web Server
 [6] Docker
 [7] Security & Firewall
 [8] Backup & Restore
 [9] Maintenance
 [10] Diagnostics
 [11] Server Optimization
 [12] Advanced Tools

 [0] Exit
M
 read -r -p ' Select category: ' x; case $x in 1)panel;;2)wings;;3)runtime;;4)database;;5)web;;6)docker_menu;;7)security;;8)backup;;9)maintenance;;10)diagnostics;;11)optimization;;12)advanced;;0)echo 'Goodbye from OREN.';exit 0;;*)warn 'Invalid option.';sleep 1;;esac;done; }
main
