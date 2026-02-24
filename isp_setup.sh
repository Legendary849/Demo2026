#!/bin/bash
# ============================================================
#  СКРИПТ НАСТРОЙКИ ISP — Модуль 1
# ============================================================
export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "       НАСТРОЙКА ISP — Модуль 1"
echo "========================================"
echo ""

read -p "Имя хоста [isp.au-team.irpo]: " HOSTNAME
HOSTNAME=${HOSTNAME:-isp.au-team.irpo}

read -p "Часовой пояс [Asia/Novosibirsk]: " TIMEZONE
TIMEZONE=${TIMEZONE:-Asia/Novosibirsk}

echo ""
echo "--- WAN интерфейс (интернет, DHCP) ---"
read -p "Имя WAN интерфейса [ens19]: " WAN_IF
WAN_IF=${WAN_IF:-ens19}

echo ""
echo "--- Интерфейс в сторону HQ-RTR ---"
read -p "Имя интерфейса [ens20]: " HQ_IF
HQ_IF=${HQ_IF:-ens20}
read -p "IP с маской [172.16.1.1/28]: " HQ_IP
HQ_IP=${HQ_IP:-172.16.1.1/28}

echo ""
echo "--- Интерфейс в сторону BR-RTR ---"
read -p "Имя интерфейса [ens21]: " BR_IF
BR_IF=${BR_IF:-ens21}
read -p "IP с маской [172.16.2.1/28]: " BR_IP
BR_IP=${BR_IP:-172.16.2.1/28}

echo ""
read -p "DNS сервер [77.88.8.8]: " DNS
DNS=${DNS:-77.88.8.8}

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

mkdir -p /etc/net/ifaces/"$WAN_IF"
cat > /etc/net/ifaces/"$WAN_IF"/options <<EOF
TYPE=eth
DISABLED=no
BOOTPROTO=dhcp
CONFIG_IPV4=yes
EOF
echo "  $WAN_IF -> DHCP (WAN)"

mkdir -p /etc/net/ifaces/"$HQ_IF"
cat > /etc/net/ifaces/"$HQ_IF"/options <<EOF
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
EOF
echo "$HQ_IP" > /etc/net/ifaces/"$HQ_IF"/ipv4address
echo "  $HQ_IF = $HQ_IP"

mkdir -p /etc/net/ifaces/"$BR_IF"
cat > /etc/net/ifaces/"$BR_IF"/options <<EOF
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
EOF
echo "$BR_IP" > /etc/net/ifaces/"$BR_IF"/ipv4address
echo "  $BR_IF = $BR_IP"

# 4. DNS
echo "[4/6] DNS..."
echo "nameserver $DNS" > /etc/resolv.conf
echo "  nameserver $DNS"

# 5. Сеть + пакеты
echo "[5/6] Сеть + пакеты..."
systemctl restart network 2>/dev/null || true
apt-get update -y
apt-get install -y iptables mc
echo "  OK"

# 6. ip_forward + NAT
echo "[6/6] ip_forward и NAT..."
mkdir -p /etc/net
sed -i "/net.ipv4.ip_forward/d" /etc/net/sysctl.conf 2>/dev/null
echo "net.ipv4.ip_forward = 1" >> /etc/net/sysctl.conf
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
systemctl restart network 2>/dev/null || true

# Сброс старых правил iptables перед добавлением новых
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X 2>/dev/null || true
iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE
mkdir -p /etc/sysconfig
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables 2>/dev/null || true
systemctl restart iptables 2>/dev/null || true
echo "  ip_forward=1, NAT на $WAN_IF — OK"

echo ""
echo "========================================"
echo " ISP ГОТОВ"
echo " Hostname : $HOSTNAME"
echo " WAN      : $WAN_IF (DHCP)"
echo " HQ       : $HQ_IF = $HQ_IP"
echo " BR       : $BR_IF = $BR_IP"
echo " DNS      : $DNS"
echo "========================================"
