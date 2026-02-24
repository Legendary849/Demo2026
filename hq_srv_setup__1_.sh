#!/bin/bash
# ============================================================
#  СКРИПТ НАСТРОЙКИ HQ-SRV — Модуль 1
# ============================================================
export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "      НАСТРОЙКА HQ-SRV — Модуль 1"
echo "========================================"
echo ""

read -p "Имя хоста [hq-srv.au-team.irpo]: " HOSTNAME
HOSTNAME=${HOSTNAME:-hq-srv.au-team.irpo}

read -p "Часовой пояс [Asia/Novosibirsk]: " TIMEZONE
TIMEZONE=${TIMEZONE:-Asia/Novosibirsk}

echo ""
echo "--- Сетевой интерфейс ---"
read -p "Имя интерфейса [ens19]: " NET_IF
NET_IF=${NET_IF:-ens19}
read -p "IP с маской [192.168.100.2/27]: " NET_IP
NET_IP=${NET_IP:-192.168.100.2/27}
read -p "Шлюз [192.168.100.1]: " NET_GW
NET_GW=${NET_GW:-192.168.100.1}

echo ""
read -p "DNS сервер [77.88.8.8]: " DNS
DNS=${DNS:-77.88.8.8}

echo ""
echo "--- Учётная запись пользователя ---"
read -p "Имя пользователя [sshuser]: " SSH_USER
SSH_USER=${SSH_USER:-sshuser}
read -p "UID пользователя [2026]: " SSH_UID
SSH_UID=${SSH_UID:-2026}
read -s -p "Пароль [P@ssw0rd]: " SSH_PASS
echo ""
SSH_PASS=${SSH_PASS:-P@ssw0rd}

echo ""
echo "--- SSH настройки ---"
read -p "SSH порт [2026]: " SSH_PORT
SSH_PORT=${SSH_PORT:-2026}
read -p "MaxAuthTries [2]: " MAX_AUTH
MAX_AUTH=${MAX_AUTH:-2}
read -p "Текст баннера [Authorized access only]: " BANNER
BANNER=${BANNER:-Authorized access only}

echo ""
echo "--- dnsmasq (DNS сервер) ---"
read -p "Домен [au-team.irpo]: " DOMAIN
DOMAIN=${DOMAIN:-au-team.irpo}
read -p "Внешний DNS 1 [77.88.8.8]: " EXT_DNS1
EXT_DNS1=${EXT_DNS1:-77.88.8.8}
read -p "Внешний DNS 2 [77.88.8.3]: " EXT_DNS2
EXT_DNS2=${EXT_DNS2:-77.88.8.3}
read -p "Интерфейс dnsmasq [ens19]: " DNS_IF
DNS_IF=${DNS_IF:-ens19}

echo ""
echo "--- A-записи DNS ---"
read -p "IP hq-srv.au-team.irpo [192.168.100.2]: " A_HQSRV
A_HQSRV=${A_HQSRV:-192.168.100.2}
read -p "IP hq-rtr.au-team.irpo (VLAN200/клиентская) [192.168.200.1]: " A_HQRTR
A_HQRTR=${A_HQRTR:-192.168.200.1}
read -p "IP hq-cli.au-team.irpo [192.168.200.14]: " A_HQCLI
A_HQCLI=${A_HQCLI:-192.168.200.14}
read -p "IP br-rtr.au-team.irpo [192.168.1.1]: " A_BRRTR
A_BRRTR=${A_BRRTR:-192.168.1.1}
read -p "IP br-srv.au-team.irpo [192.168.1.2]: " A_BRSRV
A_BRSRV=${A_BRSRV:-192.168.1.2}
read -p "IP docker.au-team.irpo [172.16.1.1]: " A_DOCKER
A_DOCKER=${A_DOCKER:-172.16.1.1}
read -p "IP web.au-team.irpo [172.16.2.1]: " A_WEB
A_WEB=${A_WEB:-172.16.2.1}

echo ""
echo "========================================"
echo " Начинаю настройку..."
echo "========================================"

# 1. Hostname
echo "[1/7] Имя хоста..."
hostnamectl set-hostname "$HOSTNAME"
echo "  OK: $HOSTNAME"

# 2. Timezone
echo "[2/7] Часовой пояс..."
timedatectl set-timezone "$TIMEZONE" 2>/dev/null || {
    apt-get install -y tzdata 2>/dev/null || true
    timedatectl set-timezone "$TIMEZONE" 2>/dev/null || true
}
echo "  OK: $TIMEZONE"

# 3. Сеть
echo "[3/7] Настройка сети..."
mkdir -p /etc/net/ifaces/"$NET_IF"
cat > /etc/net/ifaces/"$NET_IF"/options <<EOF
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
EOF
echo "$NET_IP" > /etc/net/ifaces/"$NET_IF"/ipv4address
echo "default via $NET_GW" > /etc/net/ifaces/"$NET_IF"/ipv4route

echo "nameserver $DNS" > /etc/resolv.conf

systemctl restart network 2>/dev/null || true
echo "  $NET_IF = $NET_IP, GW = $NET_GW"

# 4. Пользователь
echo "[4/7] Пользователь $SSH_USER (uid=$SSH_UID)..."
if ! id "$SSH_USER" &>/dev/null; then
    useradd -u "$SSH_UID" "$SSH_USER"
else
    echo "  Пользователь уже существует, обновляю пароль"
fi
echo "$SSH_USER:$SSH_PASS" | chpasswd
usermod -a -G wheel "$SSH_USER" 2>/dev/null || true
apt-get install -y sudo
grep -qxF 'WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL' /etc/sudoers || \
    echo 'WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
echo "  $SSH_USER (uid=$SSH_UID) — OK"

# 5. SSH
echo "[5/7] Настройка SSH..."
if [ -f /etc/openssh/sshd_config ]; then
    SSHD_CONF="/etc/openssh/sshd_config"
    BANNER_PATH="/etc/openssh/banner"
else
    SSHD_CONF="/etc/ssh/sshd_config"
    BANNER_PATH="/etc/ssh/banner"
fi

sed -i "/^#*Port /d" "$SSHD_CONF" && echo "Port $SSH_PORT" >> "$SSHD_CONF"
sed -i "/^#*AllowUsers /d" "$SSHD_CONF" && echo "AllowUsers $SSH_USER" >> "$SSHD_CONF"
sed -i "/^#*MaxAuthTries /d" "$SSHD_CONF" && echo "MaxAuthTries $MAX_AUTH" >> "$SSHD_CONF"
echo "$BANNER" > "$BANNER_PATH"
sed -i "/^#*Banner /d" "$SSHD_CONF" && echo "Banner $BANNER_PATH" >> "$SSHD_CONF"

systemctl enable --now sshd 2>/dev/null || systemctl enable --now ssh 2>/dev/null || true
systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || true
echo "  Port=$SSH_PORT, AllowUsers=$SSH_USER, MaxAuthTries=$MAX_AUTH — OK"
echo "  Баннер: $BANNER"

# 6. dnsmasq
echo "[6/7] Настройка dnsmasq..."

# Если папка /etc/dnsmasq.d существует, но пакет не установлен (повторный запуск) —
# удаляем папку, иначе установка упадёт с ошибкой cpio: rename
if [ -d /etc/dnsmasq.d ] && ! rpm -q dnsmasq &>/dev/null 2>&1; then
    rm -rf /etc/dnsmasq.d
fi

apt-get install -y dnsmasq

# Функция: IP -> PTR запись
ip_to_ptr() {
    local IP=$1
    local O1 O2 O3 O4
    IFS='.' read -r O1 O2 O3 O4 <<< "$IP"
    echo "$O4.$O3.$O2.$O1.in-addr.arpa"
}

PTR_HQSRV=$(ip_to_ptr "$A_HQSRV")
PTR_HQRTR=$(ip_to_ptr "$A_HQRTR")
PTR_HQCLI=$(ip_to_ptr "$A_HQCLI")

# Папку НЕ создаём вручную — пакет dnsmasq создаёт её сам при установке
cat > /etc/dnsmasq.d/hq-srv.conf <<EOF
domain=$DOMAIN
no-resolv
server=$EXT_DNS1
server=$EXT_DNS2
interface=$DNS_IF
# Прямые A-записи
address=/hq-srv.$DOMAIN/$A_HQSRV
address=/hq-rtr.$DOMAIN/$A_HQRTR
address=/hq-cli.$DOMAIN/$A_HQCLI
address=/br-rtr.$DOMAIN/$A_BRRTR
address=/br-srv.$DOMAIN/$A_BRSRV
address=/docker.$DOMAIN/$A_DOCKER
address=/web.$DOMAIN/$A_WEB
# Обратные PTR-записи
ptr-record=$PTR_HQSRV,hq-srv.$DOMAIN
ptr-record=$PTR_HQRTR,hq-rtr.$DOMAIN
ptr-record=$PTR_HQCLI,hq-cli.$DOMAIN
EOF

systemctl enable --now dnsmasq 2>/dev/null || true
systemctl restart dnsmasq 2>/dev/null || true
echo "  dnsmasq запущен, домен $DOMAIN — OK"

# 7. bind-utils
echo "[7/7] bind-utils..."
apt-get install -y bind-utils 2>/dev/null || true
echo "  bind-utils установлен"
echo "  Проверка: nslookup hq-srv.$DOMAIN"
nslookup hq-srv."$DOMAIN" 2>/dev/null || true

echo ""
echo "========================================"
echo " HQ-SRV ГОТОВ"
echo " Hostname  : $HOSTNAME"
echo " IP        : $NET_IF = $NET_IP (GW: $NET_GW)"
echo " SSH       : порт $SSH_PORT, user $SSH_USER"
echo " DNS       : dnsmasq, домен $DOMAIN"
echo "========================================"
