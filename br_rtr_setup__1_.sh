#!/bin/bash
# ============================================================
#  СКРИПТ НАСТРОЙКИ BR-RTR — Модуль 1
# ============================================================
export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "      НАСТРОЙКА BR-RTR — Модуль 1"
echo "========================================"
echo ""

read -p "Имя хоста [br-rtr.au-team.irpo]: " HOSTNAME
HOSTNAME=${HOSTNAME:-br-rtr.au-team.irpo}

read -p "Часовой пояс [Asia/Novosibirsk]: " TIMEZONE
TIMEZONE=${TIMEZONE:-Asia/Novosibirsk}

echo ""
echo "--- WAN интерфейс (в сторону ISP) ---"
read -p "Имя WAN интерфейса [ens19]: " WAN_IF
WAN_IF=${WAN_IF:-ens19}
read -p "IP с маской [172.16.2.2/28]: " WAN_IP
WAN_IP=${WAN_IP:-172.16.2.2/28}
read -p "Шлюз по умолчанию [172.16.2.1]: " WAN_GW
WAN_GW=${WAN_GW:-172.16.2.1}

echo ""
echo "--- LAN интерфейс (в сторону BR офиса) ---"
read -p "Имя LAN интерфейса [ens20]: " LAN_IF
LAN_IF=${LAN_IF:-ens20}
read -p "IP с маской [192.168.1.1/28]: " LAN_IP
LAN_IP=${LAN_IP:-192.168.1.1/28}

echo ""
echo "--- DNS ---"
read -p "DNS сервер [77.88.8.8]: " DNS
DNS=${DNS:-77.88.8.8}

echo ""
echo "--- Локальная учётная запись ---"
read -p "Имя пользователя [net_admin]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-net_admin}
read -s -p "Пароль [P@ssw0rd]: " ADMIN_PASS
echo ""
ADMIN_PASS=${ADMIN_PASS:-P@ssw0rd}

echo ""
echo "--- GRE туннель ---"
read -p "TUNLOCAL (локальный WAN IP) [172.16.2.2]: " TUN_LOCAL
TUN_LOCAL=${TUN_LOCAL:-172.16.2.2}
read -p "TUNREMOTE (WAN IP HQ-RTR) [172.16.1.2]: " TUN_REMOTE
TUN_REMOTE=${TUN_REMOTE:-172.16.1.2}
read -p "IP туннеля gre1 с маской [172.16.100.1/29]: " TUN_IP
TUN_IP=${TUN_IP:-172.16.100.1/29}

echo ""
echo "--- OSPF ---"
read -p "OSPF Router-ID [172.16.2.1]: " OSPF_ID
OSPF_ID=${OSPF_ID:-172.16.2.1}
read -p "OSPF сеть туннеля [172.16.100.0/29]: " OSPF_TUN
OSPF_TUN=${OSPF_TUN:-172.16.100.0/29}
read -p "OSPF сеть LAN BR [192.168.1.0/28]: " OSPF_LAN
OSPF_LAN=${OSPF_LAN:-192.168.1.0/28}
read -p "OSPF ключ аутентификации [pass1234]: " OSPF_KEY
OSPF_KEY=${OSPF_KEY:-pass1234}

echo ""
echo "========================================"
echo " Начинаю настройку..."
echo "========================================"

# 1. Hostname
echo "[1/8] Имя хоста..."
hostnamectl set-hostname "$HOSTNAME"
echo "  OK: $HOSTNAME"

# 2. Timezone
echo "[2/8] Часовой пояс..."
timedatectl set-timezone "$TIMEZONE" 2>/dev/null || {
    apt-get install -y tzdata 2>/dev/null || true
    timedatectl set-timezone "$TIMEZONE" 2>/dev/null || true
}
echo "  OK: $TIMEZONE"

# 3. WAN
echo "[3/8] WAN интерфейс..."
mkdir -p /etc/net/ifaces/"$WAN_IF"
cat > /etc/net/ifaces/"$WAN_IF"/options <<EOF
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
EOF
echo "$WAN_IP" > /etc/net/ifaces/"$WAN_IF"/ipv4address
echo "default via $WAN_GW" > /etc/net/ifaces/"$WAN_IF"/ipv4route
echo "  $WAN_IF = $WAN_IP, GW = $WAN_GW"

# 4. LAN (у роутера нет шлюза на LAN — он сам является шлюзом)
echo "[4/8] LAN интерфейс..."
mkdir -p /etc/net/ifaces/"$LAN_IF"
cat > /etc/net/ifaces/"$LAN_IF"/options <<EOF
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
EOF
echo "$LAN_IP" > /etc/net/ifaces/"$LAN_IF"/ipv4address
echo "  $LAN_IF = $LAN_IP"

# 5. DNS + сеть + пакеты
echo "[5/8] DNS, сеть, пакеты..."
echo "nameserver $DNS" > /etc/resolv.conf
systemctl restart network 2>/dev/null || true
apt-get update -y
apt-get install -y iptables mc
echo "  OK"

# 6. ip_forward + NAT
echo "[6/8] ip_forward и NAT..."
mkdir -p /etc/net
sed -i "/net.ipv4.ip_forward/d" /etc/net/sysctl.conf 2>/dev/null
echo "net.ipv4.ip_forward = 1" >> /etc/net/sysctl.conf
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
systemctl restart network 2>/dev/null || true

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

# 7. Пользователь
echo "[7/8] Пользователь $ADMIN_USER..."
if ! id "$ADMIN_USER" &>/dev/null; then
    useradd "$ADMIN_USER"
fi
echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd
usermod -a -G wheel "$ADMIN_USER" 2>/dev/null || true
apt-get install -y sudo
grep -qxF 'WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL' /etc/sudoers || \
    echo 'WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
systemctl enable --now sshd 2>/dev/null || systemctl enable --now ssh 2>/dev/null || true
systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || true
echo "  $ADMIN_USER создан, добавлен в wheel — OK"

# 8. GRE + FRR OSPF
echo "[8/8] GRE туннель и OSPF..."
mkdir -p /etc/net/ifaces/gre1
cat > /etc/net/ifaces/gre1/options <<EOF
TUNLOCAL=$TUN_LOCAL
TUNREMOTE=$TUN_REMOTE
TUNTYPE=gre
TYPE=iptun
TUNTTL=64
TUNMTU=1476
TUNOPTIONS='ttl 64'
EOF
echo "$TUN_IP" > /etc/net/ifaces/gre1/ipv4address
echo "  gre1: $TUN_LOCAL -> $TUN_REMOTE, IP=$TUN_IP"

systemctl restart network 2>/dev/null || true

apt-get install -y frr
# Активируем ospfd в /etc/frr/daemons
sed -i 's/ospfd=.*/ospfd=yes/' /etc/frr/daemons 2>/dev/null || true
mkdir -p /var/log/frr
systemctl enable --now frr 2>/dev/null || true

# Определяем версию FRR автоматически
FRR_VERSION=$(vtysh -c "show version" 2>/dev/null | grep -oP 'FRRouting \K[0-9.]+' || echo "10.2.2")

cat > /etc/frr/frr.conf <<EOF
frr version $FRR_VERSION
frr defaults traditional
hostname $HOSTNAME
log file /var/log/frr/frr.log
no ipv6 forwarding
!
interface gre1
 ip ospf authentication
 ip ospf authentication-key $OSPF_KEY
 no ip ospf passive
exit
!
router ospf
 ospf router-id $OSPF_ID
 passive-interface default
 network $OSPF_TUN area 0
 network $OSPF_LAN area 0
exit
!
end
EOF

systemctl enable frr 2>/dev/null || true
systemctl restart frr 2>/dev/null || true
echo "  FRR OSPF настроен — OK"

echo ""
echo "========================================"
echo " BR-RTR ГОТОВ"
echo " Hostname  : $HOSTNAME"
echo " WAN       : $WAN_IF = $WAN_IP (GW: $WAN_GW)"
echo " LAN       : $LAN_IF = $LAN_IP"
echo " GRE       : gre1 = $TUN_IP"
echo " OSPF ID   : $OSPF_ID"
echo " Пользоват.: $ADMIN_USER"
echo "========================================"
