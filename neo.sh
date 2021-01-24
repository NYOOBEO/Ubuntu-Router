#!/bin/bash

lannic="enp2s0"
wannic="enp3s0"
lancdir="192.168.1.0/24"
v2rayconfig="/mnt/wdc/router/v2ray/config.json"

#Mount the 2 hard drives;
mkdir /mnt/wdc
mkdir /mnt/backup
cp /etc/fstab  /etc/fstab.bak
echo "/dev/disk/by-uuid/2f9a57e5-4159-48b0-8fc4-4ffb22dd60e1 /mnt/wdc ext4 defaults 0 0" >> /etc/fstab
echo "/dev/disk/by-uuid/8a13ed2b-b32d-4da4-8a5d-9c63e12af3a8 /mnt/backup auto defaults 0 0" >> /etc/fstab
mount -a
chmod 777 -R /mnt/wdc
chmod 777 -R /mnt/backup

#open ip4 forwarding, TCP BBR and prevent security issues;
cp /etc/sysctl.conf  /etc/sysctl.conf.bak
echo net/ipv4/ip_forward=1 >> /etc/sysctl.conf

# Protect from IP Spoofing  
echo net.ipv4.conf.all.rp_filter = 1 >> /etc/sysctl.conf
echo net.ipv4.conf.default.rp_filter = 1 >> /etc/sysctl.conf

# Ignore ICMP broadcast requests
echo net.ipv4.icmp_echo_ignore_broadcasts = 1 >> /etc/sysctl.conf

# Protect from bad icmp error messages
echo net.ipv4.icmp_ignore_bogus_error_responses = 1 >> /etc/sysctl.conf

# Disable source packet routing
echo net.ipv4.conf.all.accept_source_route = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.default.accept_source_route = 0 >> /etc/sysctl.conf


# Turn on exec shield
echo kernel.exec-shield = 1 >> /etc/sysctl.conf
echo kernel.randomize_va_space = 1 >> /etc/sysctl.conf

# Block SYN attacks
echo net.ipv4.tcp_syncookies = 1 >> /etc/sysctl.conf
echo net.ipv4.tcp_max_syn_backlog = 2048 >> /etc/sysctl.conf
echo net.ipv4.tcp_synack_retries = 1 >> /etc/sysctl.conf
echo net.ipv4.tcp_syn_retries = 5 >> /etc/sysctl.conf

# Log Martians  
echo net.ipv4.conf.all.log_martians = 1 >> /etc/sysctl.conf
echo net.ipv4.icmp_ignore_bogus_error_responses = 1 >> /etc/sysctl.conf

# Ignore send redirects
echo net.ipv4.conf.all.send_redirects = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.default.send_redirects = 0 >> /etc/sysctl.conf

# Ignore ICMP redirects
echo net.ipv4.conf.all.accept_redirects = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.default.accept_redirects = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.all.secure_redirects = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.default.secure_redirects = 0 >> /etc/sysctl.conf

#enable ARP for same subnet in OpenConnect VPN
echo net.ipv4.conf.all.proxy_arp=1 >> /etc/sysctl.conf

#increase maximum file size that the system can handle
echo fs.file-max=5000000 >> /etc/sysctl.conf

# This will increase the amount of memory available for socket input/output queues
echo net.ipv4.tcp_tw_reuse = 1 >> /etc/sysctl.conf
echo net.core.rmem_default = 256960 >> /etc/sysctl.conf
echo net.core.rmem_max = 33554432 >> /etc/sysctl.conf
echo net.ipv4.tcp_rmem = 10240 87380 33554432 >> /etc/sysctl.conf
echo net.core.wmem_default = 256960 >> /etc/sysctl.conf
echo net.core.wmem_max = 33554432 >> /etc/sysctl.conf
echo net.ipv4.tcp_wmem = 10240 87380 33554432 >> /etc/sysctl.conf
echo net.ipv4.tcp_mem = 33554432 33554432 33554432 >> /etc/sysctl.conf
echo net.core.optmem_max = 87380 >> /etc/sysctl.conf
echo net.ipv4.tcp_rfc1337 = 1 >> /etc/sysctl.conf
echo net.ipv4.tcp_fin_timeout = 10 >> /etc/sysctl.conf

#Enable TCP BBR
echo net.core.default_qdisc=fq >> /etc/sysctl.conf
echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.tcp_available_congestion_control
lsmod | grep bbr

#Add NAT to ufw;
cp /etc/ufw/before.rules   /etc/ufw/before.rules.bak
echo -e "*nat\n:POSTROUTING ACCEPT [0:0]\n-A POSTROUTING -s ${lancdir} -o ${wannic} -j MASQUERADE\nCOMMIT" >> /etc/ufw/before.rules.new
cat /etc/ufw/before.rules >> /etc/ufw/before.rules.new
mv /etc/ufw/before.rules.new /etc/ufw/before.rules

#ufw rules for applications and network routing;
ufw default allow routed
ufw default deny incoming
ufw default allow outgoing
ufw allow in on ${wannic} to any port 4443 proto tcp
ufw allow in on ${wannic} to any port 1030 proto udp
ufw allow in on ${wannic} to any port 80 proto tcp
ufw allow in on ${wannic} to any port 443 proto tcp
ufw allow in on ${wannic} to any port 6881 proto tcp
ufw allow in on ${wannic} to any port 6881 proto udp
ufw allow in on ${wannic} to any port 2573 proto tcp
ufw allow in on ${wannic} to any port 1688 proto tcp
ufw allow from ${lancdir}
ufw allow 53/udp
ufw allow 67/udp
ufw allow 68/udp

#restart ufw;
ufw disable
ufw enable -y

# Check and install software updates;
echo | add-apt-repository ppa:poplite/qbittorrent-enhanced
apt update
apt upgrade -y

#install software;
#Samba for file sharing;
#Qbittorrent-nox-enhanced for torrent and magnet download;
#Jellyfin for internal media play;
#AdGuardHome for DNS and DHCP server;
#Install prerequisites for Calibre-Web;
wget https://static.adguard.com/adguardhome/release/AdGuardHome_linux_amd64.tar.gz
tar xvf AdGuardHome_linux_amd64.tar.gz
mv AdGuardHome  /usr/share/
chmod 777 -R /usr/share/AdGuardHome
/usr/share/AdGuardHome/AdGuardHome -s install
sudo apt install apt-transport-https
wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo apt-key add -
echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list
sudo apt update
sudo apt install jellyfin qbittorrent-enhanced-nox ocserv python3-pip -y
pip3 install babel flask flask_login flask_babel flask_principal sqlalchemy pycountry tornado unidecode Wand tornado requests pytz PyPDF2 iso-639 backports_abc singledispatch lxml rarfile 

#V2ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

#KMS
wget --no-check-certificate https://github.com/teddysun/across/raw/master/kms.sh && chmod +x kms.sh && ./kms.sh

#updated config files
mv /usr/local/etc/v2ray/config.json  /usr/local/etc/v2ray/config.json.bak
cp ${v2rayconfig}  /usr/local/etc/v2ray
cp /mnt/wdc/router/ocserv/*  /etc/ocserv

#Add services on boot up;
wget https://github.com/yuhaohbmc/neorouter/blame/main/rc-local.service  -P  /etc/systemd/system
wget https://raw.githubusercontent.com/yuhaohbmc/neorouter/main/calibre.service -P  /etc/systemd/system
wget https://raw.githubusercontent.com/yuhaohbmc/neorouter/main/rc.local -P /etc
chmod +x /etc/rc.local

#enable and reload all the services
ln -s /lib/systemd/system/rc-local.service /etc/systemd/system/
systemctl enable jellyfin
systemctl enable ocserv
systemctl enable AdGuardHome
systemctl enable qbittorrent-enhanced-nox
systemctl enable v2ray
systemctl restart AdGuardHome
systemctl restart ocserv
systemctl restart jellyfin
systemctl restart qbittorrent-enhanced-nox
systemctl restart v2ray
systemctl enable calibre
systemctl start calibre


# Install BT Panel for Website Hosting and SSL;
curl -sSO http://download.bt.cn/install/install_panel.sh && bash install_panel.sh 
