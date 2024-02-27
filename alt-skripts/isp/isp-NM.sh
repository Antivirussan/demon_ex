#!/bin/bash

#установка пакетов
apt-get update 
apt-get install -y NetworkManager NetworkManager-tui nano iptables-ipv6 iperf3

#настройка интерфейсов и имени
systemctl enable --now NetworkManager 
nmtui 
exec bash 

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
echo "net.ipv6.conf.all.forvarding = 1" >> /etc/net/sysctl.conf
sysctl -p /etc/net/sysctl.conf

#ssh
sed -i -e 's/#Port 22/Port 22/g' /etc/openssh/sshd_config
sed -i -e 's/#PermitRootLogin whithout-password/PermitRootLogin yes/g' /etc/openssh/sshd_config
systemctl restart sshd

#iperf3
iperf3 -s