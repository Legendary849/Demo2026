# Инструкция к демэкзамену

## Модуль 1

### 1. Настройка имени у всех устройств

```bash
hostnamectl set-hostname isp.au-team.irpo
hostnamectl set-hostname hq-rtr.au-team.irpo
hostnamectl set-hostname br-rtr.au-team.irpo
hostnamectl set-hostname hq-srv.au-team.irpo
hostnamectl set-hostname hq-cli.au-team.irpo
hostnamectl set-hostname br-srv.au-team.irpo
```

### 2. Настройка часового пояса на всех устройствах

```bash
timedatectl set-timezone Asia/Novosibirsk
```

Если не установлено:
```bash
apt-get install tzdata
```

### 3. Настройка сети для JEOS

#### Рисунок 1 - Настройка в Proxmox для ISP

В Proxmox необходимо настроить сетевые интерфейсы для ISP.

**ISP - Настройка интерфейса ens19 (DHCP):**

```bash
mkdir -p /etc/net/ifaces/ens19
nano /etc/net/ifaces/ens19/options
```

Содержимое файла:
```
TYPE=eth
DISABLED=no
BOOTPROTO=dhcp
CONFIG_IPV4=yes
```

**ISP - Настройка интерфейса ens20:**

```bash
mkdir -p /etc/net/ifaces/ens20
nano /etc/net/ifaces/ens20/options
```

Содержимое файла:
```
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
```

```bash
nano /etc/net/ifaces/ens20/ipv4address
```

Содержимое:
```
172.16.1.1/28
```

**ISP - Настройка интерфейса ens21:**

```bash
mkdir -p /etc/net/ifaces/ens21
nano /etc/net/ifaces/ens21/options
```

Содержимое файла:
```
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
```

```bash
nano /etc/net/ifaces/ens21/ipv4address
```

Содержимое:
```
172.16.2.1/28
```

**Перезагрузка сети и установка пакетов:**

```bash
systemctl restart network
apt-get update -y && apt-get install iptables mc
```

### 4. Настройка NAT на JEOS

```bash
iptables -t nat -A POSTROUTING -o ens19 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables
```

### 5. Включить пересылку пакетов на JEOS

```bash
nano /etc/net/sysctl.conf
```

Добавить строку:
```
net.ipv4.ip_forward = 1
```

```bash
systemctl restart network
```

### 6. Настройка сети для HQ-RTR

#### Рисунок 2 - Включаем поддержку VLAN в сети hqnet

В Proxmox для виртуальной машины HQ-RTR необходимо включить поддержку VLAN на сетевом интерфейсе, подключенном к hqnet.

#### Рисунок 3 - Настройка сети для hq-rtr

**HQ-RTR - Интерфейс ens19:**

```bash
mkdir -p /etc/net/ifaces/ens19
nano /etc/net/ifaces/ens19/options
```

Содержимое:
```
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
```

```bash
nano /etc/net/ifaces/ens19/ipv4address
```

Содержимое:
```
172.16.1.2/28
```

```bash
nano /etc/net/ifaces/ens19/ipv4route
```

Содержимое:
```
default via 172.16.1.1
```

**HQ-RTR - Интерфейс ens20 (основной):**

```bash
mkdir -p /etc/net/ifaces/ens20
nano /etc/net/ifaces/ens20/options
```

Содержимое:
```
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
```

**HQ-RTR - VLAN 100:**

```bash
mkdir -p /etc/net/ifaces/ens20.100
nano /etc/net/ifaces/ens20.100/options
```

Содержимое:
```
TYPE=vlan
HOST=ens20
VID=100
DISABLED=no
BOOTPROTO=static
ONBOOT=yes
CONFIG_IPV4=yes
```

```bash
nano /etc/net/ifaces/ens20.100/ipv4address
```

Содержимое:
```
192.168.100.1/27
```

**HQ-RTR - VLAN 200:**

```bash
mkdir -p /etc/net/ifaces/ens20.200
nano /etc/net/ifaces/ens20.200/options
```

Содержимое:
```
TYPE=vlan
HOST=ens20
VID=200
DISABLED=no
BOOTPROTO=static
ONBOOT=yes
CONFIG_IPV4=yes
```

```bash
nano /etc/net/ifaces/ens20.200/ipv4address
```

Содержимое:
```
192.168.200.1/27
```

**HQ-RTR - VLAN 999:**

```bash
mkdir -p /etc/net/ifaces/ens20.999
nano /etc/net/ifaces/ens20.999/options
```

Содержимое:
```
TYPE=vlan
HOST=ens20
VID=999
DISABLED=no
BOOTPROTO=static
ONBOOT=yes
CONFIG_IPV4=yes
```

```bash
nano /etc/net/ifaces/ens20.999/ipv4address
```

Содержимое:
```
192.168.99.1/29
```

### 7. Настройка DNS для HQ-RTR

```bash
nano /etc/resolv.conf
```

Содержимое:
```
nameserver 77.88.8.8
```

### 8. Настройка NAT для офиса HQ

```bash
iptables -t nat -A POSTROUTING -o ens19 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables
```

### 9. Включить пересылку пакетов на HQ-RTR

```bash
nano /etc/net/sysctl.conf
```

Добавить:
```
net.ipv4.ip_forward = 1
```

```bash
systemctl restart network
```

### 10. Настройка сети для BR-RTR

#### Рисунок 4 - Настройка сети для br-rtr

**BR-RTR - Интерфейс ens19:**

```bash
mkdir -p /etc/net/ifaces/ens19
nano /etc/net/ifaces/ens19/options
```

Содержимое:
```
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
```

```bash
nano /etc/net/ifaces/ens19/ipv4address
```

Содержимое:
```
172.16.2.2/28
```

```bash
nano /etc/net/ifaces/ens19/ipv4route
```

Содержимое:
```
default via 172.16.2.1
```

**BR-RTR - Интерфейс ens20:**

```bash
mkdir -p /etc/net/ifaces/ens20
nano /etc/net/ifaces/ens20/options
```

Содержимое:
```
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
```

```bash
nano /etc/net/ifaces/ens20/ipv4address
```

Содержимое:
```
192.168.1.1/28
```

### 11. Настройка DNS для BR-RTR

```bash
nano /etc/resolv.conf
```

Содержимое:
```
nameserver 77.88.8.8
```

```bash
systemctl restart network
```

### 12. Настройка NAT для офиса BR

```bash
iptables -t nat -A POSTROUTING -o ens19 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables
```

### 13. Включение пересылки пакетов

```bash
nano /etc/net/sysctl.conf
```

Добавить:
```
net.ipv4.ip_forward = 1
```

```bash
systemctl restart network
```

### 14. Создание локальных учетных записей на HQ-RTR

```bash
useradd net_admin
passwd net_admin
# Пароль: P@ssw0rd
usermod -a -G wheel net_admin
nano /etc/sudoers
```

Добавить строку:
```
WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL
```

### 15. Создание локальных учётных записей на BR-RTR

```bash
useradd net_admin
passwd net_admin
# Пароль: P@ssw0rd
usermod -a -G wheel net_admin
nano /etc/sudoers
```

Добавить строку:
```
WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL
```

### 16. Настройка HQ-SRV

```bash
mkdir -p /etc/net/ifaces/ens19
nano /etc/net/ifaces/ens19/options
```

Содержимое:
```
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
```

```bash
nano /etc/net/ifaces/ens19/ipv4address
```

Содержимое:
```
192.168.100.2/27
```

```bash
nano /etc/net/ifaces/ens19/ipv4route
```

Содержимое:
```
default via 192.168.100.1
```

### 17. Настройка DNS на HQ-SRV

```bash
nano /etc/resolv.conf
```

Содержимое:
```
nameserver 77.88.8.8
```

```bash
systemctl restart network
```

### 18. Создание локальных учётных записей на HQ-SRV

```bash
useradd sshuser -u 2026
passwd sshuser
# Пароль: P@ssw0rd
usermod -a -G wheel sshuser
nano /etc/sudoers
```

Добавить строку:
```
WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL
```

### 19. Настройка BR-SRV

```bash
mkdir -p /etc/net/ifaces/ens19
nano /etc/net/ifaces/ens19/options
```

Содержимое:
```
TYPE=eth
DISABLED=no
BOOTPROTO=static
CONFIG_IPV4=yes
```

```bash
nano /etc/net/ifaces/ens19/ipv4address
```

Содержимое:
```
192.168.1.2/28
```

```bash
nano /etc/net/ifaces/ens19/ipv4route
```

Содержимое:
```
default via 192.168.1.1
```

### 20. Настройка DNS для BR-SRV

```bash
nano /etc/resolv.conf
```

Содержимое:
```
nameserver 77.88.8.8
```

```bash
systemctl restart network
```

### 21. Создание учётной записи sshuser на BR-SRV

```bash
useradd sshuser -u 2026
passwd sshuser
# Пароль: P@ssw0rd
usermod -a -G wheel sshuser
nano /etc/sudoers
```

Добавить строку:
```
WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL
```

### 22. Настройка безопасного удалённого доступа на серверах HQ-SRV и BR-SRV

```bash
nano /etc/openssh/sshd_config
```

Изменить/добавить следующие параметры:
```
Port 2026
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

HostKey /etc/openssh/ssh_host_rsa_key
HostKey /etc/openssh/ssh_host_ecdsa_key
HostKey /etc/openssh/ssh_host_ed25519_key

# Logging
SyslogFacility AUTHPRIV
LogLevel INFO

# Authentication
LoginGraceTime 2m
PermitRootLogin without-password
StrictModes yes
MaxAuthTries 2
MaxSessions 10

# Banner
Banner /etc/openssh/banner
```

Редактировать баннер:
```bash
echo "Authorized access only" > /etc/openssh/banner
systemctl restart sshd
```

**Проверка подключения с ISP:**
```bash
ssh -p 2026 sshuser@172.16.1.2  # Для HQ-SRV
ssh -p 2026 sshuser@172.16.2.2  # Для BR-SRV
```

### 23. Настройка динамической маршрутизации

#### 23.1 Настройка туннеля GRE и OSPF на HQ-RTR

Создать каталог для интерфейса туннеля:
```bash
mkdir -p /etc/net/ifaces/gre1
nano /etc/net/ifaces/gre1/options
```

Содержимое:
```
TUNLOCAL=172.16.1.2
TUNREMOTE=172.16.2.2
TUNTYPE=gre
TYPE=iptun
TUNTTL=64
TUNMTU=1476
TUNOPTIONS='ttl 64'
```

Создать файл:
```bash
nano /etc/net/ifaces/gre1/ipv4address
```

Содержимое:
```
172.16.100.2/29
```

Перезагрузить сеть и проверить интерфейс:
```bash
systemctl restart network
ip a
```

Установить пакет FRR:
```bash
apt-get install frr -y
systemctl enable --now frr
nano /etc/frr/daemons
```

Найти строку `ospfd=no` и изменить на `ospfd=yes`

Настроить OSPF:
```bash
vtysh
show running-config
conf t
router ospf
ospf router-id 172.16.1.1
passive-interface default
network 172.16.100.0/29 area 0
network 192.168.100.0/27 area 0
network 192.168.200.0/27 area 0
exit
interface gre1
no ip ospf passive
ip ospf authentication
ip ospf authentication-key pass1234
do wr
```

Перезагрузить FRR:
```bash
systemctl restart frr
```

#### 23.2 Настройка туннеля GRE и OSPF на BR-RTR

Создать каталог:
```bash
mkdir -p /etc/net/ifaces/gre1
nano /etc/net/ifaces/gre1/options
```

Содержимое:
```
TUNLOCAL=172.16.2.2
TUNREMOTE=172.16.1.2
TUNTYPE=gre
TYPE=iptun
TUNTTL=64
TUNMTU=1476
TUNOPTIONS='ttl 64'
```

Настройка IP-адреса туннеля:
```bash
nano /etc/net/ifaces/gre1/ipv4address
```

Содержимое:
```
172.16.100.1/29
```

Перезагрузить сеть:
```bash
systemctl restart network
ip a
```

Установка OSPF:
```bash
apt-get install frr -y
systemctl enable --now frr
nano /etc/frr/daemons
```

Изменить `ospfd=no` на `ospfd=yes`

```bash
vtysh
show running-config
conf t
router ospf
ospf router-id 172.16.2.1
passive-interface default
network 172.16.100.0/29 area 0
network 192.168.1.0/28 area 0
exit
interface gre1
no ip ospf passive
ip ospf authentication
ip ospf authentication-key pass1234
```

Перезагрузить сеть:
```bash
systemctl restart network
```

Проверить соседей:
```bash
vtysh
show ip ospf neighbor
```

Перезагрузить FRR:
```bash
systemctl restart frr
```

### 24. Настройка DHCP на HQ-RTR

Установка:
```bash
apt-get install dhcp-server
systemctl enable --now dhcpd
```

**Редактирование конфигурационного файла:**
```bash
nano /etc/dhcp/dhcpd.conf
```

Содержимое:
```
# dhcpd.conf(5) for further configuration
ddns-update-style none;

subnet 192.168.200.0 netmask 255.255.255.224 {
    option routers 192.168.200.1;
    option subnet-mask 255.255.255.224;
    option nis-domain "au-team.irpo";
    option domain-name "au-team.irpo";
    option domain-name-servers 192.168.100.2;
    
    range dynamic-bootp 192.168.200.2 192.168.200.14;
    
    default-lease-time 21600;
    max-lease-time 43200;
    
    host boss {
        hardware ethernet bc:24:11:60:72:f3;
        fixed-address 192.168.200.14;
    }
}
```

**Настройка интерфейса для DHCP:**
```bash
nano /etc/sysconfig/dhcpd
```

Содержимое:
```
DHCPDARGS="ens20.200"

# Default value if chroot mode disabled
CHROOT="-j -cf /var/lib/dhcp/dhcpdstate/dhcpd.leases"
```

Перезапустить службу:
```bash
systemctl restart dhcpd
```

**Проверка на клиенте HQ-CLI:**

На HQ-CLI настроить сетевой интерфейс на получение IP-адреса по DHCP и проверить получение адреса.

### 25. Настройка DNS на HQ-SRV

Установка:
```bash
apt-get install dnsmasq
```

Создать файл конфигурации:
```bash
nano /etc/dnsmasq.d/name.conf
```

Содержимое:
```
domain=au-team.irpo
no-resolv
server=77.88.8.8
server=77.88.8.3
interface=ens19
address=/hq-srv.au-team.irpo/192.168.100.2
address=/hq-rtr.au-team.irpo/192.168.100.1
address=/hq-rtr.au-team.irpo/192.168.200.1
address=/hq-rtr.au-team.irpo/192.168.99.1
address=/hq-cli.au-team.irpo/192.168.200.14
address=/br-rtr.au-team.irpo/192.168.1.1
address=/br-srv.au-team.irpo/192.168.1.2
address=/docker.au-team.irpo/172.16.1.1
address=/web.au-team.irpo/172.16.2.1
ptr-record=1.100.168.192.in-addr.arpa,hq-rtr.au-team.irpo
ptr-record=2.100.168.192.in-addr.arpa,hq-srv.au-team.irpo
ptr-record=1.200.168.192.in-addr.arpa,hq-rtr.au-team.irpo
ptr-record=14.200.168.192.in-addr.arpa,hq-cli.au-team.irpo
```

Запустить службу:
```bash
systemctl enable --now dnsmasq
```

Установить утилиты DNS (на всех устройствах):
```bash
apt-get install bind-utils
```

Проверка:
```bash
nslookup hq-srv.au-team.irpo
```

**Промежуточный этап для клиента:**

На HQ-CLI необходимо настроить использование DNS-сервера на HQ-SRV (192.168.100.2).

---

## Модуль 2

### 1. Настройка контроллера домена Samba DC на сервере BR-SRV

**Задание:**
- Имя домена: `au-team.irpo`
- Ввести в домен машину HQ-CLI
- Создать 5 пользователей для офиса HQ: hquser1, hquser2, hquser3, hquser4, hquser5
- Создать группу hq, ввести в группу созданных пользователей
- Пользователи группы hq должны иметь право аутентифицироваться на HQ-CLI
- Пользователи группы hq должны иметь возможность повышать привилегии для выполнения команд: cat, grep, id

**BR-SRV:**

Установка Samba DC:
```bash
apt-get update && apt-get install -y task-samba-dc
```

Восстановление к начальному состоянию:
```bash
rm -f /etc/samba/smb.conf
rm -rf /var/lib/samba
rm -rf /var/cache/samba
mkdir -p /var/lib/samba/sysvol
```

Развертывание домена:
```bash
samba-tool domain provision
```

**Параметры при развертывании:**
```
Realm [AU-TEAM.IRPO]:
Domain [AU-TEAM]:
Server Role (dc, member, standalone) [dc]:
DNS backend (SAMBA_INTERNAL, BIND9_FLATFILE, BIND9_DLZ, NONE) [SAMBA_INTERNAL]:
DNS forwarder IP address (write 'none' to disable forwarding) [77.88.8.8]: 192.168.100.2
Administrator password: [введите надежный пароль]
Retype password: [повторите пароль]
```

> Пароль администратора должен быть не менее 7 символов и содержать символы минимум трёх групп из четырёх: верхний регистр, нижний регистр, цифры, специальные символы.

**Результат развертывания:**
```
Server Role: active directory domain controller
Hostname: br-srv
NetBIOS Domain: AU-TEAM
DNS Domain: au-team.irpo
DOMAIN SID: S-1-5-21-3779736722-240538183-1985...
```

Включить и добавить в автозагрузку:
```bash
systemctl enable --now samba
```

Настройка Kerberos:
```bash
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
systemctl restart samba
```

Настройка DNS:
```bash
echo "search au-team.irpo" > /etc/net/ifaces/ens19/resolv.conf
echo "nameserver 127.0.0.1" >> /etc/net/ifaces/ens19/resolv.conf
systemctl restart network
```

**Проверка работоспособности домена:**

Проверка конфигурации DNS:
```bash
host au-team.irpo
host -t SRV _kerberos._udp.au-team.irpo
host -t SRV _ldap._tcp.au-team.irpo
host br-srv.au-team.irpo
```

**Ожидаемый результат:**
```
au-team.irpo has address 192.168.1.2
_kerberos._udp.au-team.irpo has SRV record 0 100 88 br-srv.au-team.irpo
_ldap._tcp.au-team.irpo has SRV record 0 100 389 br-srv.au-team.irpo
br-srv.au-team.irpo has address 192.168.1.2
```

Проверка Kerberos (имя домена в верхнем регистре):
```bash
kinit administrator@AU-TEAM.IRPO
klist
```

Создание группы hq:
```bash
samba-tool group add hq
```

Создание пользователей:
```bash
samba-tool user add hquser1 P@ssw0rd
samba-tool user add hquser2 P@ssw0rd
samba-tool user add hquser3 P@ssw0rd
samba-tool user add hquser4 P@ssw0rd
samba-tool user add hquser5 P@ssw0rd
```

Отключение срока действия пароля:
```bash
samba-tool user setexpiry hquser1 --noexpiry
samba-tool user setexpiry hquser2 --noexpiry
samba-tool user setexpiry hquser3 --noexpiry
samba-tool user setexpiry hquser4 --noexpiry
samba-tool user setexpiry hquser5 --noexpiry
```

Добавление пользователей в группу:
```bash
samba-tool group addmembers hq hquser1
samba-tool group addmembers hq hquser2
samba-tool group addmembers hq hquser3
samba-tool group addmembers hq hquser4
samba-tool group addmembers hq hquser5
```

Проверка:
```bash
samba-tool group listmembers hq
```

**HQ-CLI:**

Проверить, что доменное имя резольвится:
```bash
nslookup au-team.irpo
```

Установить пакет для ввода в домен:
```bash
apt-get update && apt-get install -y task-auth-ad-sssd
```

> Использовать Центр Управления Системой (ЦУС) для ввода HQ-CLI в домен AU-TEAM.IRPO

После ввода в домен **обязательно перезагрузить** виртуальную машину HQ-CLI:
```bash
reboot
```

Установка библиотеки libnss-role:
```bash
apt-get install -y libnss-role
```

Связывание доменной группы с локальной:
```bash
roleadd hq wheel
```

Проверка:
```bash
grep hq /etc/role
```

Редактирование /etc/sudoers:
```bash
vim /etc/sudoers
```

Добавить:
```
Cmnd_Alias SHELLCMD = /bin/cat, /bin/grep, /usr/bin/id
WHEEL_USERS ALL=(ALL:ALL) SHELLCMD
```

**Проверка:**

Вход под пользователем группы hq:
```bash
su - hquser1@au-team.irpo
```

Проверка sudo для разрешенных команд:
```bash
sudo cat /etc/passwd
sudo grep root /etc/passwd
sudo id
```

Проверка sudo для запрещенных команд:
```bash
sudo ls  # Должна быть ошибка доступа
```

### 2. Настройка файлового хранилища на сервере HQ-SRV

**Задание:**
- Создать RAID 0 из двух дисков размером 1 Гб
- Имя устройства: md0
- Файловая система: ext4
- Автомонтирование в папку /raid

**HQ-SRV:**

Установка mdadm:
```bash
apt-get update && apt-get install -y mdadm
```

Просмотр дисков:
```bash
lsblk
```

**Результат:**
```
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
sda      8:0    0  20G  0 disk
├─sda1   8:1    0 491M  0 part [SWAP]
└─sda2   8:2    0 19.5G 0 part /
sdb      8:16   0   1G  0 disk
sdc      8:32   0   1G  0 disk
sr0     11:0    1 1024M 0 rom
```

Зануление суперблоков:
```bash
mdadm --zero-superblock --force /dev/sdb /dev/sdc
```

Создание RAID-массива:
```bash
mdadm --create --verbose /dev/md0 -l 0 -n 2 /dev/sdb /dev/sdc
```

Подтвердите создание, нажав `y`.

Проверка:
```bash
cat /proc/mdstat
mdadm --detail /dev/md0
```

Сохранение конфигурации:
```bash
mdadm --detail --scan --verbose | tee -a /etc/mdadm.conf
```

Создание файловой системы:
```bash
mkfs.ext4 /dev/md0
```

Редактирование fstab:
```bash
vim /etc/fstab
```

Добавить:
```
/dev/md0 /raid ext4 defaults 0 0
```

Создание каталога и монтирование:
```bash
mkdir /raid
mount -av
```

**Результат:**
```
/raid : successfully mounted
```

Проверка:
```bash
df -h
```

**Результат:**
```
/dev/md0       2.0G   24K  1.9G   1% /raid
```

### 3. Настройка сервера NFS на HQ-SRV

**Задание:**
- Папка общего доступа: /raid/nfs
- Доступ для чтения и записи для сети HQ-CLI
- На HQ-CLI автомонтирование в /mnt/nfs

**HQ-SRV:**

Установка пакетов:
```bash
apt-get install -y nfs-server nfs-utils
```

Создание директории:
```bash
mkdir /raid/nfs
chmod 777 /raid/nfs
```

Редактирование exports:
```bash
vim /etc/exports
```

Добавить:
```
/raid/nfs 192.168.200.0/27(rw,no_root_squash)
```

Экспорт файловой системы:
```bash
exportfs -arv
```

**Результат:**
```
exporting 192.168.200.0/27:/raid/nfs
```

Запуск службы:
```bash
systemctl enable --now nfs-server
```

**HQ-CLI:**

Установка пакетов:
```bash
apt-get update && apt-get install -y nfs-utils nfs-clients
```

Создание директории:
```bash
mkdir /mnt/nfs
chmod 777 /mnt/nfs
```

Редактирование fstab:
```bash
vim /etc/fstab
```

Добавить:
```
192.168.100.2:/raid/nfs /mnt/nfs nfs defaults 0 0
```

Монтирование:
```bash
mount -av
```

**Результат:**
```
/mnt/nfs : successfully mounted
```

Проверка:
```bash
df -h
```

**Проверка записи:**

На HQ-CLI:
```bash
touch /mnt/nfs/test_file.txt
echo "Test from HQ-CLI" > /mnt/nfs/test_file.txt
```

На HQ-SRV:
```bash
cat /raid/nfs/test_file.txt
```

### 4. Настройка службы сетевого времени на базе Chrony на ISP

**Задание:**
- Вышестоящий сервер NTP - на выбор (pool.ntp.org)
- Стратум сервера - 5
- Клиенты: HQ-SRV, HQ-CLI, BR-RTR, BR-SRV

**ISP:**

Редактирование конфигурации:
```bash
vim /etc/chrony.conf
```

Добавить/изменить:
```
# Use public servers from the pool.ntp.org project
pool pool.ntp.org iburst
server ntp0.ntp-servers.net iburst prefer minstratum 4

local stratum 5

allow 0.0.0.0/0
```

Перезапуск:
```bash
systemctl restart chronyd
```

Проверка:
```bash
chronyc tracking
chronyc sources
```

**HQ-RTR:**

Настройка клиента:
```bash
vim /etc/chrony.conf
```

Добавить:
```
server 172.16.1.1 iburst
```

Перезапуск:
```bash
systemctl restart chronyd
```

Проверка:
```bash
chronyc tracking
chronyc sources
```

**BR-RTR:**

Аналогично HQ-RTR, но использовать адрес ISP (172.16.2.1):
```bash
vim /etc/chrony.conf
```

Добавить:
```
server 172.16.2.1 iburst
```

Перезапуск:
```bash
systemctl restart chronyd
```

**Ожидаемый результат для BR-RTR:**
```
Reference ID    : AC100201 (_gateway)
Stratum         : 6
Ref time (UTC)  : Tue Feb 03 04:18:12 2026
System time     : 0.000017896 seconds fast of NTP time
```

**HQ-CLI, HQ-SRV:**

Настройка аналогична, использовать адрес HQ-RTR (192.168.100.1 или 192.168.200.1).

**BR-SRV:**

Использовать адрес BR-RTR (192.168.1.1).

### 5. Настройка Ansible на сервере BR-SRV

**Задание:**
- Файл инвентаря должен включать: HQ-SRV, HQ-CLI, HQ-RTR, BR-RTR
- Рабочий каталог: /etc/ansible
- Все машины должны отвечать pong на команду ping

**BR-SRV:**

Установка:
```bash
apt-get update && apt-get install -y ansible sshpass
```

Редактирование файла инвентаря:
```bash
vim /etc/ansible/hosts
```

Содержимое:
```ini
[Servers]
HQ-SRV ansible_host=192.168.100.2

[Routers]
HQ-RTR ansible_host=172.16.100.2
BR-RTR ansible_host=192.168.1.1

[Clients]
HQ-CLI ansible_host=192.168.200.14

[Servers:vars]
ansible_user=sshuser
ansible_password=P@ssw0rd
ansible_port=2026

[Routers:vars]
ansible_user=net_admin
ansible_password=P@ssw0rd
ansible_port=22

[Clients:vars]
ansible_user=user
ansible_password=1

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

Редактирование ansible.cfg:
```bash
vim /etc/ansible/ansible.cfg
```

Содержимое:
```ini
[defaults]
inventory = /etc/ansible/hosts
host_key_checking = False
```

Установка дополнительных пакетов:
```bash
apt-get install -y python3-module-pip
pip3 install ansible-pylibssh
```

**Проверка:**
```bash
ansible all -m ping
```

### 6. Развертывание веб-приложения testapp с Docker на BR-SRV

**Задание:**
- Использовать образы site_latest и mariadb_latest
- Контейнер testapp
- Контейнер db
- База данных testdb, пользователь testc, пароль P@ssw0rd
- Порт приложения 8080

**BR-SRV:**

Установка:
```bash
apt-get install -y docker-engine docker-compose-v2
systemctl enable --now docker.service
```

Монтирование ISO:
```bash
mount /dev/sr0 /mnt/
```

Импорт образов:
```bash
docker load < /mnt/docker/site_latest.tar
docker load < /mnt/docker/mariadb_latest.tar
```

Проверка:
```bash
docker images
```

Создание compose.yaml:
```bash
vim /root/compose.yaml
```

Содержимое:
```yaml
services:
  database:
    container_name: db
    image: mariadb:10.11
    restart: always
    ports:
      - "3306:3306"
    environment:
      MARIADB_DATABASE: "testdb"
      MARIADB_USER: "testc"
      MARIADB_PASSWORD: "P@ssw0rd"
      MARIADB_ROOT_PASSWORD: "toor"
  app:
    container_name: testapp
    image: site:latest
    restart: always
    ports:
      - "8080:8000"
    environment:
      DB_TYPE: "maria"
      DB_HOST: "192.168.1.2"
      DB_PORT: "3306"
      DB_NAME: "testdb"
      DB_USER: "testc"
      DB_PASS: "P@ssw0rd"
    depends_on:
      - database
```

Запуск:
```bash
docker compose up -d
```

**Результат:**
```
[+] Running 3/3
Network root_default  Created
Container db          Started
Container testapp     Started
```

Проверка:
```bash
docker ps
```

Проверка доступа к приложению:
```bash
curl http://192.168.1.2:8080
```

### 7. Развертывание веб-приложения на HQ-SRV

**Задание:**
- Веб-сервер Apache
- СУБД MariaDB
- Импорт dump.sql в базу webdb
- Пользователь web с паролем P@ssw0rd

**HQ-SRV:**

Установка LAMP:
```bash
apt-get install -y lamp-server
```

Монтирование ISO:
```bash
mount /dev/sr0 /mnt/
```

Копирование файлов:
```bash
cp /mnt/web/index.php /var/www/html
cp /mnt/web/logo.png /var/www/html
```

Редактирование index.php:
```bash
vim /var/www/html/index.php
```

Указать правильные учетные данные для подключения к БД:
```php
$servername = "localhost";
$username = "web";
$password = "P@ssw0rd";
$dbname = "webdb";
```

Запуск MariaDB:
```bash
systemctl enable --now mariadb
```

Настройка базы данных:
```bash
mariadb -u root
```

```sql
CREATE DATABASE webdb;
CREATE USER 'web'@'localhost' IDENTIFIED BY 'P@ssw0rd';
GRANT ALL PRIVILEGES ON webdb.* TO 'web'@'localhost' WITH GRANT OPTION;
EXIT;
```

Импорт дампа:
```bash
mariadb -u web -p -D webdb < /mnt/web/dump.sql
```

Запуск Apache:
```bash
systemctl enable --now httpd2
```

Проверка:
```bash
curl http://192.168.100.2
```

### 8. Настройка статической трансляции портов на маршрутизаторах

**Задание:**
- Проброс порта 8080 на BR-RTR → testapp на BR-SRV
- Проброс порта 8080 на HQ-RTR → веб-приложение на HQ-SRV
- Проброс порта 2026 на HQ-RTR → SSH на HQ-SRV
- Проброс порта 2026 на BR-RTR → SSH на BR-SRV

**HQ-RTR:**

```bash
# Проброс 8080 → 80 (веб-приложение HQ-SRV)
iptables -t nat -A PREROUTING -p tcp -d 172.16.1.2 --dport 8080 \
-j DNAT --to-destination 192.168.100.2:80
iptables -A FORWARD -p tcp -d 192.168.100.2 --dport 80 -j ACCEPT

# Проброс 2026 → 2026 (SSH HQ-SRV)
iptables -t nat -A PREROUTING -p tcp -d 172.16.1.2 --dport 2026 \
-j DNAT --to-destination 192.168.100.2:2026
iptables -A FORWARD -p tcp -d 192.168.100.2 --dport 2026 -j ACCEPT

iptables-save > /etc/sysconfig/iptables
```

**BR-RTR:**

```bash
# Проброс 8080 → 8080 (testapp)
iptables -t nat -A PREROUTING -p tcp -d 172.16.2.2 --dport 8080 \
-j DNAT --to-destination 192.168.1.2:8080
iptables -A FORWARD -p tcp -d 192.168.1.2 --dport 8080 -j ACCEPT

# Проброс 2026 → 2026 (SSH BR-SRV)
iptables -t nat -A PREROUTING -p tcp -d 172.16.2.2 --dport 2026 \
-j DNAT --to-destination 192.168.1.2:2026
iptables -A FORWARD -p tcp -d 192.168.1.2 --dport 2026 -j ACCEPT

iptables-save > /etc/sysconfig/iptables
```

**Проверка из ISP:**

Проверка доступа к веб-приложению HQ-SRV:
```bash
curl http://172.16.1.2:8080
```

Проверка доступа к testapp:
```bash
curl http://172.16.2.2:8080
```

Проверка SSH к HQ-SRV:
```bash
ssh -p 2026 sshuser@172.16.1.2
```

Проверка SSH к BR-SRV:
```bash
ssh -p 2026 sshuser@172.16.2.2
```

### 9. Настройка Nginx как обратного прокси-сервера на ISP

**Задание:**
- При обращении по web.au-team.irpo → веб-приложение на HQ-SRV
- При обращении по docker.au-team.irpo → testapp

**ISP:**

Установка:
```bash
apt-get install -y nginx
```

Редактирование конфигурации:
```bash
vim /etc/nginx/sites-available.d/default.conf
```

Содержимое:
```nginx
server {
    listen 80;
    server_name web.au-team.irpo;
    location / {
        proxy_pass http://172.16.1.2:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name docker.au-team.irpo;
    location / {
        proxy_pass http://172.16.2.2:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Создание символической ссылки:
```bash
ln -s /etc/nginx/sites-available.d/default.conf /etc/nginx/sites-enabled.d/
```

Проверка конфигурации:
```bash
nginx -t
```

Запуск службы:
```bash
systemctl enable --now nginx
```

**HQ-CLI:**

Добавить записи в /etc/hosts (если DNS не настроен должным образом):
```bash
vim /etc/hosts
```

Добавить:
```
172.16.1.1 web.au-team.irpo
172.16.2.1 docker.au-team.irpo
```

Или добавить записи на DNS-сервере BR-SRV:
```bash
samba-tool dns add br-srv au-team.irpo web A 172.16.1.1 -U administrator
samba-tool dns add br-srv au-team.irpo docker A 172.16.2.1 -U administrator
```

Проверка доступа с браузера на HQ-CLI:
- http://web.au-team.irpo
- http://docker.au-team.irpo

### 10. Настройка web-based аутентификации на ISP

**Задание:**
- При обращении к web.au-team.irpo требуется аутентификация
- Логин: WEB, пароль: P@ssw0rd
- Файл хранилища: /etc/nginx/.htpasswd

**ISP:**

Установка:
```bash
apt-get install -y apache2-htpasswd
```

Создание пользователя:
```bash
htpasswd -c /etc/nginx/.htpasswd WEB
# Пароль: P@ssw0rd
```

Редактирование конфигурации:
```bash
vim /etc/nginx/sites-available.d/default.conf
```

Изменить блок server для web.au-team.irpo:
```nginx
server {
    listen 80;
    server_name web.au-team.irpo;
    location / {
        proxy_pass http://172.16.1.2:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        auth_basic "Restricted area";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}

server {
    listen 80;
    server_name docker.au-team.irpo;
    location / {
        proxy_pass http://172.16.2.2:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Проверка и перезапуск:
```bash
nginx -t
systemctl restart nginx
```

**Проверка с HQ-CLI:**

При обращении к http://web.au-team.irpo должно появиться окно аутентификации:
- Имя пользователя: WEB
- Пароль: P@ssw0rd

### 11. Установка Яндекс Браузера на HQ-CLI

**HQ-CLI:**

Установка:
```bash
apt-get install -y yandex-browser-stable
```

Или использовать **Центр Приложений** (графический интерфейс).

---

## Дополнительная информация

### Проверка работоспособности систем

**Проверка RAID:**
```bash
cat /proc/mdstat
mdadm --detail /dev/md0
```

**Проверка NFS:**
```bash
showmount -e 192.168.100.2
```

**Проверка Samba DC:**
```bash
samba-tool domain level show
samba-tool user list
samba-tool group list
```

**Проверка Docker:**
```bash
docker ps
docker logs testapp
docker logs db
```

**Проверка маршрутизации OSPF:**
```bash
vtysh
show ip ospf neighbor
show ip route ospf
```

### Устранение неполадок

**Проблемы с сетью:**
```bash
ip a
ip route
ping 8.8.8.8
```

**Проблемы с DNS:**
```bash
nslookup au-team.irpo
dig au-team.irpo
cat /etc/resolv.conf
```

**Проблемы с firewall:**
```bash
iptables -L -n -v
iptables -t nat -L -n -v
```

---

## Заключение

Данная инструкция содержит все необходимые команды и конфигурации для выполнения демонстрационного экзамена по модулям 1 и 2, включая:

- Настройку сетевой инфраструктуры
- Конфигурацию маршрутизаторов и серверов
- Развертывание служб (DNS, DHCP, NTP, NFS)
- Настройку Active Directory (Samba DC)
- Конфигурацию Docker-контейнеров
- Настройку веб-сервисов и обратного прокси
- Автоматизацию с помощью Ansible

Все команды проверены и готовы к использованию.

---

## Шпаргалка: Работа с кодировками файлов

### Задание 6 (Docker)
Образы загружаем как есть, ничего не конвертируем:
```bash
docker load < /mnt/docker/site_latest.tar
docker load < /mnt/docker/mariadb_latest.tar
```

### Задание 7 (LAMP)

**Шаг 1. Монтируем диск и проверяем кодировку:**
```bash
mount /dev/sr0 /mnt
file -bi /mnt/web/index.php
file -bi /mnt/web/dump.sql
```

**Шаг 2. Конвертация текстовых файлов в зависимости от кодировки:**

Если **UTF-16**:
```bash
iconv -f UTF-16 -t UTF-8 /mnt/web/index.php > /var/www/html/index.php
iconv -f UTF-16 -t UTF-8 /mnt/web/dump.sql > /tmp/dump.sql
```

Если **CP1251** (Windows Cyrillic):
```bash
iconv -f CP1251 -t UTF-8 /mnt/web/index.php > /var/www/html/index.php
iconv -f CP1251 -t UTF-8 /mnt/web/dump.sql > /tmp/dump.sql
```

Если **CP866** (DOS Cyrillic):
```bash
iconv -f CP866 -t UTF-8 /mnt/web/index.php > /var/www/html/index.php
iconv -f CP866 -t UTF-8 /mnt/web/dump.sql > /tmp/dump.sql
```

Если **ISO-8859-1**:
```bash
iconv -f ISO-8859-1 -t UTF-8 /mnt/web/index.php > /var/www/html/index.php
iconv -f ISO-8859-1 -t UTF-8 /mnt/web/dump.sql > /tmp/dump.sql
```

Если **KOI8-R**:
```bash
iconv -f KOI8-R -t UTF-8 /mnt/web/index.php > /var/www/html/index.php
iconv -f KOI8-R -t UTF-8 /mnt/web/dump.sql > /tmp/dump.sql
```

Если **ASCII** или уже **UTF-8** (просто копируем):
```bash
cp /mnt/web/index.php /var/www/html/
cp /mnt/web/dump.sql /tmp/
```

**Шаг 3. Бинарные файлы (всегда просто копируем):**
```bash
cp /mnt/web/logo.png /var/www/html/
```

**Шаг 4. Проверка результата:**
```bash
echo "=== Проверка index.php ==="
file -bi /var/www/html/index.php
head -5 /var/www/html/index.php

echo "=== Проверка dump.sql ==="
file -bi /tmp/dump.sql
head -5 /tmp/dump.sql
```

**Шаг 5. Импорт БД:**
```bash
mariadb -u web -p -D webdb < /tmp/dump.sql
```

**Правило:** Конвертируем только текстовые файлы (.php, .sql, .txt). Бинарные (.png, .jpg, .tar) и Docker-образы просто копируем!
