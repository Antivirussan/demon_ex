#!/bin/bash

#назначение ip 

ip a add 10.5.5.10 dev ens33 
ip r add default via 10.5.5.1 

echo "nameserver 77.88.8.8" > /etc/resolv.conf

#установка пакетов
apt-get update 
apt-get install -y NetworkManager NetworkManager-tui nano iptables-ipv6 frr strongswan 

#настройка интерфейсов и имени

sed -i -e 's/NM_CONTROLED=no/NM_CONTROLED=yes/g' /etc/openssh/sshd_config
systemctl restart network

systemctl enable --now NetworkManager 
nmtui 
exec bash 

ip a del 10.5.5.10 dev ens33 
ip r del default via 10.5.5.1 



#настройка iptables
iptables -t nat -A POSTROUTING -s 172.16.0.0/28 -o ens33 -j MASQUERADE 
iptables-save >> /etc/sysconfig/iptables
ip6tables -t nat -A POSTROUTING -s 2001:db8:acad:e::1/124 -o ens33 -j MASQUERADE
iptables-save >> /etc/sysconfig/ip6tables
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


#тунель 
touch /etc/gre.up
chmod +x /etc/gre.up

echo "ip tunnel add tun0 mode gre local 5.5.5.10 remote 4.4.4.10 ttl 65" >> /etc/gre.up
echo "ip link set tun0 up" >> /etc/gre.up
echo "ip a add 10.10.0.2/30 dev tun0" >> /etc/gre.up
echo "ip a add 2001:db8:acad:f::2/127 dev tun0" >> /etc/gre.up

echo "@reboot root /etc/gre.up" >> /etc/crontab


#пользователи 
useradd network_admin
passwd network_admin 
useradd branch_admin
passwd branch_admin

#ipsec

echo "conn left-to-right" >> /etc/strongswan/ipsec.conf
echo "  auto=start" >> /etc/strongswan/ipsec.conf
echo "  type=tunnel" >> /etc/strongswan/ipsec.conf
echo "  keyexchange=ikev2" >> /etc/strongswan/ipsec.conf
echo "  authby=secret" >> /etc/strongswan/ipsec.conf
echo "  ike=3des-sha1-modp2048" >> /etc/strongswan/ipsec.conf
echo "  esp=aes-sha1" >> /etc/strongswan/ipsec.conf
echo "  left=10.5.5.10" >> /etc/strongswan/ipsec.conf
echo "  right=10.4.4.10" >> /etc/strongswan/ipsec.conf
echo "  leftprotoport=gre" >> /etc/strongswan/ipsec.conf
echo "  rightprotoport=gre" >> /etc/strongswan/ipsec.conf


echo "10.5.5.10 10.4.4.10 : PSL «QWERTYUIOPASDFGHJKL»" >> /etc/strongswan/ipsec.secret

systemctl enable --now iptables.service 

#frr

sed -i -e 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
sed -i -e 's/ospf6d=no/ospf6d=yes/g' /etc/frr/daemons

systemctl enable --now frr