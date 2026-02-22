#!/bin/bash
# ============================================================
#  СКРИПТ НАСТРОЙКИ HQ-RTR — Модуль 1
# ============================================================
export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "      НАСТРОЙКА HQ-RTR — Модуль 1"
echo "========================================"
echo ""

read -p "Имя хоста [hq-rtr.au-team.irpo]: " HOSTNAME
HOSTNAME=${HOSTNAME:-hq-rtr.au-team.irpo}

read -p "Часовой пояс [Asia/Novosibirsk]: " TIMEZONE
TIMEZONE=${TIMEZONE:-Asia/Novosibirsk}

echo ""
echo "--- WAN интерфейс (в сторону ISP) ---"
read -p "Имя WAN интерфейса [ens19]: " WAN_IF
WAN_IF=${WAN_IF:-ens19}
read -p "IP с маской [172.16.1.2/28]: " WAN_IP
WAN_IP=${WAN_IP:-172.16.1.2/28}
read -p "Шлюз по умолчанию [172.16.1.1]: " WAN_GW
WAN_GW=${WAN_GW:-172.16.1.1}

echo ""
echo "--- LAN интерфейс (в сторону HQ офиса) ---"
read -p "Имя LAN интерфейса [ens20]: " LAN_IF
LAN_IF=${LAN_IF:-ens20}

echo ""
echo "--- VLAN 100 (HQ-SRV) ---"
read -p "VID VLAN [100]: " VLAN100_VID
VLAN100_VID=${VLAN100_VID:-100}
read -p "IP с маской [192.168.100.1/27]: " VLAN100_IP
VLAN100_IP=${VLAN100_IP:-192.168.100.1/27}

echo ""
echo "--- VLAN 200 (HQ-CLI, DHCP) ---"
read -p "VID VLAN [200]: " VLAN200_VID
VLAN200_VID=${VLAN200_VID:-200}
read -p "IP с маской [192.168.200.1/27]: " VLAN200_IP
VLAN200_IP=${VLAN200_IP:-192.168.200.1/27}

echo ""
echo "--- VLAN 999 (Management) ---"
read -p "VID VLAN [999]: " VLAN999_VID
VLAN999_VID=${VLAN999_VID:-999}
read -p "IP с маской [192.168.99.1/29]: " VLAN999_IP
VLAN999_IP=${VLAN999_IP:-192.168.99.1/29}

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
read -p "TUNLOCAL (локальный WAN IP) [172.16.1.2]: " TUN_LOCAL
TUN_LOCAL=${TUN_LOCAL:-172.16.1.2}
read -p "TUNREMOTE (WAN IP BR-RTR) [172.16.2.2]: " TUN_REMOTE
TUN_REMOTE=${TUN_REMOTE:-172.16.2.2}
read -p "IP туннеля gre1 с маской [172.16.100.2/29]: " TUN_IP
TUN_IP=${TUN_IP:-172.16.100.2/29}

echo ""
echo "--- OSPF ---"
read -p "OSPF Router-ID [172.16.1.1]: " OSPF_ID
OSPF_ID=${OSPF_ID:-172.16.1.1}
read -p "OSPF сеть туннеля [172.16.100.0/29]: " OSPF_TUN
OSPF_TUN=${OSPF_TUN:-172.16.100.0/29}
read -p "OSPF сеть VLAN100 [192.168.100.0/27]: " OSPF_V100
OSPF_V100=${OSPF_V100:-192.168.100.0/27}
read -p "OSPF сеть VLAN200 [192.168.200.0/27]: " OSPF_V200
OSPF_V200=${OSPF_V200:-192.168.200.0/27}
read -p "OSPF ключ аутентификации [pass1234]: " OSPF_KEY
OSPF_KEY=${OSPF_KEY:-pass1234}

echo ""
echo "--- DHCP сервер (для VLAN200 / HQ-CLI) ---"
read -p "Подсеть DHCP [192.168.200.0]: " DHCP_SUBNET
DHCP_SUBNET=${DHCP_SUBNET:-192.168.200.0}
read -p "Маска подсети [255.255.255.224]: " DHCP_MASK
DHCP_MASK=${DHCP_MASK:-255.255.255.224}
read -p "Шлюз для клиентов [192.168.200.1]: " DHCP_ROUTER
DHCP_ROUTER=${DHCP_ROUTER:-192.168.200.1}
read -p "DNS для клиентов (IP HQ-SRV) [192.168.100.2]: " DHCP_DNS
DHCP_DNS=${DHCP_DNS:-192.168.100.2}
read -p "Домен [au-team.irpo]: " DHCP_DOMAIN
DHCP_DOMAIN=${DHCP_DOMAIN:-au-team.irpo}
read -p "Начало пула DHCP [192.168.200.2]: " DHCP_START
DHCP_START=${DHCP_START:-192.168.200.2}
read -p "Конец пула DHCP [192.168.200.14]: " DHCP_END
DHCP_END=${DHCP_END:-192.168.200.14}
read -p "default-lease-time [21600]: " DHCP_LEASE
DHCP_LEASE=${DHCP_LEASE:-21600}
read -p "max-lease-time [43200]: " DHCP_MAX_LEASE
DHCP_MAX_LEASE=${DHCP_MAX_LEASE:-43200}
read -p "MAC адрес HQ-CLI (для фиксации IP) [bc:24:11:ea:72:f3]: " DHCP_MAC
DHCP_MAC=${DHCP_MAC:-bc:24:11:ea:72:f3}
read -p "Фиксированный IP для HQ-CLI [192.168.200.14]: " DHCP_FIXED_IP
DHCP_FIXED_IP=${DHCP_FIXED_IP:-192.168.200.14}
read -p "Интерфейс для dhcpd [ens20.200]: " DHCP_IF
DHCP_IF=${DHCP_IF:-ens20.200}

echo ""
echo "========================================"
echo " Начинаю настройку..."
echo "========================================"

# 1. Hostname
echo "[1/9] Имя хоста..."
hostnamectl set-hostname "$HOSTNAME"
echo "  OK: $HOSTNAME"

# 2. Timezone
echo "[2/9] Часовой пояс..."
timedatectl set-timezone "$TIMEZONE" 2>/dev/null || {
    apt-get install -y tzdata 2>/dev/null || true
    timedatectl set-timezone "$TIMEZONE" 2>/dev/null || true
}
echo "  OK: $TIMEZONE"

# 3. WAN
echo "[3/9] WAN интерфейс..."
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

# 4. LAN + VLAN (у роутера нет шлюза на LAN — он сам является шлюзом)
echo "[4/9] LAN и VLAN..."
mkdir -p /etc/net/ifaces/"$LAN_IF"
cat > /etc/net/ifaces/"$LAN_IF"/options <<EOF
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
EOF

# VLAN100
mkdir -p /etc/net/ifaces/"$LAN_IF"."$VLAN100_VID"
cat > /etc/net/ifaces/"$LAN_IF"."$VLAN100_VID"/options <<EOF
TYPE=vlan
HOST=$LAN_IF
VID=$VLAN100_VID
DISABLED=no
BOOTPROTO=static
ONBOOT=yes
CONFIG_IPV4=yes
EOF
echo "$VLAN100_IP" > /etc/net/ifaces/"$LAN_IF"."$VLAN100_VID"/ipv4address
echo "  VLAN$VLAN100_VID = $VLAN100_IP"

# VLAN200
mkdir -p /etc/net/ifaces/"$LAN_IF"."$VLAN200_VID"
cat > /etc/net/ifaces/"$LAN_IF"."$VLAN200_VID"/options <<EOF
TYPE=vlan
HOST=$LAN_IF
VID=$VLAN200_VID
DISABLED=no
BOOTPROTO=static
ONBOOT=yes
CONFIG_IPV4=yes
EOF
echo "$VLAN200_IP" > /etc/net/ifaces/"$LAN_IF"."$VLAN200_VID"/ipv4address
echo "  VLAN$VLAN200_VID = $VLAN200_IP"

# VLAN999
mkdir -p /etc/net/ifaces/"$LAN_IF"."$VLAN999_VID"
cat > /etc/net/ifaces/"$LAN_IF"."$VLAN999_VID"/options <<EOF
TYPE=vlan
HOST=$LAN_IF
VID=$VLAN999_VID
DISABLED=no
BOOTPROTO=static
ONBOOT=yes
CONFIG_IPV4=yes
EOF
echo "$VLAN999_IP" > /etc/net/ifaces/"$LAN_IF"."$VLAN999_VID"/ipv4address
echo "  VLAN$VLAN999_VID = $VLAN999_IP"

# 5. DNS + сеть + пакеты
echo "[5/9] DNS, сеть, пакеты..."
echo "nameserver $DNS" > /etc/resolv.conf
systemctl restart network 2>/dev/null || true
apt-get update -y
apt-get install -y iptables mc
echo "  OK"

# 6. ip_forward + NAT
echo "[6/9] ip_forward и NAT..."
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
echo "  ip_forward=1, NAT на $WAN_IF — OK"

# 7. Пользователь
echo "[7/9] Пользователь $ADMIN_USER..."
if ! id "$ADMIN_USER" &>/dev/null; then
    useradd "$ADMIN_USER"
fi
echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd
usermod -a -G wheel "$ADMIN_USER" 2>/dev/null || true
apt-get install -y sudo
grep -qxF 'WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL' /etc/sudoers || \
    echo 'WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
echo "  $ADMIN_USER создан, добавлен в wheel — OK"

# 8. GRE + FRR OSPF
echo "[8/9] GRE туннель и OSPF..."
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
systemctl restart frr 2>/dev/null || true

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
 network $OSPF_V100 area 0
 network $OSPF_V200 area 0
exit
!
end
EOF

systemctl restart frr 2>/dev/null || true
echo "  FRR OSPF настроен — OK"

# 9. DHCP сервер
echo "[9/9] DHCP сервер..."
apt-get install -y dhcp-server 2>/dev/null || apt-get install -y isc-dhcp-server

mkdir -p /etc/dhcp
cat > /etc/dhcp/dhcpd.conf <<EOF
# dhcpd.conf
ddns-update-style none;

subnet $DHCP_SUBNET netmask $DHCP_MASK {
    option routers $DHCP_ROUTER;
    option subnet-mask $DHCP_MASK;

    option nis-domain "$DHCP_DOMAIN";
    option domain-name "$DHCP_DOMAIN";
    option domain-name-servers $DHCP_DNS;

    range dynamic-bootp $DHCP_START $DHCP_END;
    default-lease-time $DHCP_LEASE;
    max-lease-time $DHCP_MAX_LEASE;
    host boss
    {
        hardware ethernet $DHCP_MAC;
        fixed-address $DHCP_FIXED_IP;
    }
}
EOF

mkdir -p /etc/sysconfig
sed -i "/^DHCPDARGS=/d" /etc/sysconfig/dhcpd 2>/dev/null
echo "DHCPDARGS=\"$DHCP_IF\"" >> /etc/sysconfig/dhcpd

systemctl enable --now dhcpd 2>/dev/null || true
systemctl restart dhcpd 2>/dev/null || true
echo "  DHCP на $DHCP_IF, пул $DHCP_START-$DHCP_END — OK"

echo ""
echo "========================================"
echo " HQ-RTR ГОТОВ"
echo " Hostname  : $HOSTNAME"
echo " WAN       : $WAN_IF = $WAN_IP (GW: $WAN_GW)"
echo " VLAN$VLAN100_VID    : $VLAN100_IP"
echo " VLAN$VLAN200_VID    : $VLAN200_IP"
echo " VLAN$VLAN999_VID    : $VLAN999_IP"
echo " GRE       : gre1 = $TUN_IP"
echo " OSPF ID   : $OSPF_ID"
echo " DHCP      : $DHCP_SUBNET/$DHCP_MASK на $DHCP_IF"
echo " Пользоват.: $ADMIN_USER"
echo "========================================"
