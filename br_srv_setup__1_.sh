#!/bin/bash
# ============================================================
#  СКРИПТ НАСТРОЙКИ BR-SRV — Модуль 1
# ============================================================
export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "      НАСТРОЙКА BR-SRV — Модуль 1"
echo "========================================"
echo ""

read -p "Имя хоста [br-srv.au-team.irpo]: " HOSTNAME
HOSTNAME=${HOSTNAME:-br-srv.au-team.irpo}

read -p "Часовой пояс [Asia/Novosibirsk]: " TIMEZONE
TIMEZONE=${TIMEZONE:-Asia/Novosibirsk}

echo ""
echo "--- Сетевой интерфейс ---"
read -p "Имя интерфейса [ens19]: " NET_IF
NET_IF=${NET_IF:-ens19}
read -p "IP с маской [192.168.1.2/28]: " NET_IP
NET_IP=${NET_IP:-192.168.1.2/28}
read -p "Шлюз [192.168.1.1]: " NET_GW
NET_GW=${NET_GW:-192.168.1.1}

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
echo "========================================"
echo " Начинаю настройку..."
echo "========================================"

# 1. Hostname
echo "[1/6] Имя хоста..."
hostnamectl set-hostname "$HOSTNAME"
echo "  OK: $HOSTNAME"

# 2. Timezone
echo "[2/6] Часовой пояс..."
timedatectl set-timezone "$TIMEZONE" 2>/dev/null || {
    apt-get install -y tzdata 2>/dev/null || true
    timedatectl set-timezone "$TIMEZONE" 2>/dev/null || true
}
echo "  OK: $TIMEZONE"

# 3. Сеть
echo "[3/6] Настройка сети..."
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
echo "[4/6] Пользователь $SSH_USER (uid=$SSH_UID)..."
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
echo "[5/6] Настройка SSH..."
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

# Перезапуск — имя сервиса может быть sshd или ssh
systemctl enable --now sshd 2>/dev/null || systemctl enable --now ssh 2>/dev/null || true
systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || true
echo "  Port=$SSH_PORT, AllowUsers=$SSH_USER, MaxAuthTries=$MAX_AUTH — OK"
echo "  Баннер: $BANNER"

# 6. bind-utils
echo "[6/6] bind-utils..."
apt-get install -y bind-utils 2>/dev/null || true
echo "  bind-utils установлен"

echo ""
echo "========================================"
echo " BR-SRV ГОТОВ"
echo " Hostname  : $HOSTNAME"
echo " IP        : $NET_IF = $NET_IP (GW: $NET_GW)"
echo " SSH       : порт $SSH_PORT, user $SSH_USER"
echo "========================================"
