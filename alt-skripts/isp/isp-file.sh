#!/bin/bash

#установка пакетов
apt-get update 
apt-get install -y nano iptables-ipv6 iperf3

#настройка интерфейсов и имени
hostnamectl set-hostname ISP
#exec bash 

mkdir /etc/net/ifaces/ens34
mkdir /etc/net/ifaces/ens35
mkdir /etc/net/ifaces/ens37

sed -i -e 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' /etc/net/ifaces/default/options

touch /etc/net/ifaces/ens34/options
echo "BOOTPROTO=static" >> /etc/net/ifaces/ens34/options
echo "TYPE=eth" >> /etc/net/ifaces/ens34/options
echo "CONFIG_WIRELESS=no" >> /etc/net/ifaces/ens34/options
echo "SYSTEMD_BOOTPROTO=static" >> /etc/net/ifaces/ens34/options
echo "CONFIG_IPV4=yes" >> /etc/net/ifaces/ens34/options
echo "CONFIG_IPV6=yes" >> /etc/net/ifaces/ens34/options
echo "DISABLED=no" >> /etc/net/ifaces/ens34/options
echo "NM_CONTROLED=yes" >> /etc/net/ifaces/ens34/options
echo "SYSTEMD_CONTROLED=no" >> /etc/net/ifaces/ens34/options

cp /etc/net/ifaces/ens34/options /etc/net/ifaces/ens35/options
cp /etc/net/ifaces/ens34/options /etc/net/ifaces/ens37/options

echo "10.4.4.1/24" > /etc/net/ifaces/ens34/ipv4address
echo "10.5.5.1/24" > /etc/net/ifaces/ens35/ipv4address
echo "10.3.3.1/24" > /etc/net/ifaces/ens37/ipv4address

echo "2001:db8:acad:b::1/64" > /etc/net/ifaces/ens34/ipv6address
echo "2001:db8:acad:c::1/64" > /etc/net/ifaces/ens35/ipv6address
echo "2001:db8:acad:a::1/64" > /etc/net/ifaces/ens37/ipv6address

systemctl restart network


#настройка iptables
iptables -t nat -A POSTROUTING -s 10.3.3.0/24 -o ens33 -j MASQUERADE 
iptables -t nat -A POSTROUTING -s 10.4.4.0/24 -o ens33 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.5.5.0/24 -o ens33 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
ip6tables-save > /etc/sysconfig/ip6tables
touch /etc/iptables
echo "systemctl start iptables.service" >> /etc/iptables 
echo "systemctl start ip6tables.service" >> /etc/iptables
chmod +x /etc/iptables
echo "@reboot root /etc/iptables" >> /etc/crontab
systemctl enable --now iptables.service 
systemctl enable --now ip6tables.service 

#настройка sysctl 
sed -i -e 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf
echo "net.ipv6.conf.all.forwarding = 1" >> /etc/net/sysctl.conf
sysctl -p /etc/net/sysctl.conf

#ssh
sed -i -e 's/#Port 22/Port 22/g' /etc/openssh/sshd_config
sed -i -e 's/#PermitRootLogin whithout-password/PermitRootLogin yes/g' /etc/openssh/sshd_config
systemctl restart sshd

reboot