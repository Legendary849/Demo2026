#!/bin/bash
# ============================================================
#  СКРИПТ НАСТРОЙКИ HQ-CLI — Модуль 1
# ============================================================
export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "      НАСТРОЙКА HQ-CLI — Модуль 1"
echo "========================================"
echo ""

read -p "Имя хоста [hq-cli.au-team.irpo]: " HOSTNAME
HOSTNAME=${HOSTNAME:-hq-cli.au-team.irpo}

read -p "Часовой пояс [Asia/Novosibirsk]: " TIMEZONE
TIMEZONE=${TIMEZONE:-Asia/Novosibirsk}

echo ""
echo "--- Сеть (HQ-CLI получает IP по DHCP от HQ-RTR) ---"
read -p "Имя интерфейса [ens19]: " NET_IF
NET_IF=${NET_IF:-ens19}

echo ""
echo "========================================"
echo " Начинаю настройку..."
echo "========================================"

# 1. Hostname
echo "[1/4] Имя хоста..."
hostnamectl set-hostname "$HOSTNAME"
echo "  OK: $HOSTNAME"

# 2. Timezone
echo "[2/4] Часовой пояс..."
timedatectl set-timezone "$TIMEZONE" 2>/dev/null || {
    apt-get install -y tzdata 2>/dev/null || true
    timedatectl set-timezone "$TIMEZONE" 2>/dev/null || true
}
echo "  OK: $TIMEZONE"

# 3. Сеть DHCP
echo "[3/4] Настройка сети (DHCP)..."
mkdir -p /etc/net/ifaces/"$NET_IF"
cat > /etc/net/ifaces/"$NET_IF"/options <<EOF
TYPE=eth
DISABLED=no
BOOTPROTO=dhcp
CONFIG_IPV4=yes
EOF
systemctl enable --now network 2>/dev/null || true
systemctl restart network 2>/dev/null || true
echo "  $NET_IF переведён в DHCP"
echo ""
echo "  Текущий IP адрес:"
ip addr show "$NET_IF" | grep "inet " || echo "  (IP ещё не получен, подождите...)"

# 4. Пакеты
echo "[4/4] Установка пакетов..."
apt-get update -y
apt-get install -y bind-utils 2>/dev/null || true
echo "  bind-utils установлен"

echo ""
echo "========================================"
echo " HQ-CLI ГОТОВ"
echo " Hostname : $HOSTNAME"
echo " Timezone : $TIMEZONE"
echo " Сеть     : $NET_IF (DHCP от HQ-RTR)"
echo ""
echo " Ожидаемый IP: 192.168.200.2-192.168.200.14"
echo " Фиксированный IP для boss: 192.168.200.14"
echo "========================================"
