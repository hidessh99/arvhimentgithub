#!/bin/bash
# By HideSSH
# Tunneling SSH Websocket + Stunnel + SSLH
# ==================================================

# initializing var
export DEBIAN_FRONTEND=noninteractive
MYIP=$(wget -qO- icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
NET=$(ip -o $ANU -4 route show to default | awk '{print $5}');
source /etc/os-release
ver=$VERSION_ID

#detail nama perusahaan
country=ID
state=Indonesia
locality=Indonesia
organization=hideSSH
organizationalunit=hidessh.com
commonname=hidessh.com
email=admin@hidessh.com

cd
# common password debian 
wget -O /etc/pam.d/common-password "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/common-password-deb9"
chmod +x /etc/pam.d/common-password

# go to root
cd

# Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# Ubah izin akses
chmod +x /etc/rc.local

# enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#update
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y

# install wget and curl
apt -y install wget curl

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# install
apt-get --reinstall --fix-missing install -y bzip2 gzip coreutils wget screen rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl neofetch git lsof
echo "clear" >> .profile
echo "neofetch" >> .profile
echo "echo Selamat Datang HideSSH !" >> .profile
echo "echo Ketik menu untuk melihat list" >> .profile
echo "echo VPSmu Terinstall AutoScript by HideSSh" >> .profile
echo "echo Terimakasih !" >> .profile

# install webserver
apt -y install nginx
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://adiscript.vercel.app/vpn/nginx.conf"
mkdir -p /home/vps/public_html
wget -O /etc/nginx/conf.d/vps.conf "https://adiscript.vercel.app/vpn/vps.conf"
/etc/init.d/nginx restart

# install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "https://adiscript.vercel.app/vpn/badvpn-udpgw64"
chmod +x /usr/bin/badvpn-udpgw
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500' /etc/rc.local
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500

# setting port ssh
cd
sed -i '/Port 22/a Port 77' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

# install dropbear
apt -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=44/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 88 -p 69"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/dropbear restart

# install squid
cd
apt -y install squid3
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/4hidessh/hidessh/main/config/squid2"
sed -i $MYIP2 /etc/squid/squid.conf

# install stunnel
apt install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 444
connect = 127.0.0.1:44

[OpenSSH]
accept = 222
connect = 127.0.0.1:22

[openvpn]
accept = 442
connect = 127.0.0.1:1194

[stunnelws]
accept = 443
connect = 700

END

# make a certificate
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart


# install fail2ban
apt -y install fail2ban

# Custom Banner SSH
echo "================  Banner ======================"
wget -O /etc/issue.net "https://github.com/idtunnel/sshtunnel/raw/master/debian9/banner-custom.conf"
chmod +x /etc/issue.net

echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
echo "DROPBEAR_BANNER="/etc/issue.net"" >> /etc/default/dropbear

#install sslh
apt-get install sslh -y

#konfigurasi
#port 333
wget -O /etc/default/sslh "https://raw.githubusercontent.com/4hidessh/hidessh/main/sslh/sslh1"
service sslh restart


# download script
cd /usr/bin
wget -O add-host "https://adiscript.vercel.app/vpn/add-host.sh"
wget -O addhost1 "https://raw.githubusercontent.com/4hidessh/cuy1/main/tambah/addhost1.sh"
wget -O about "https://adiscript.vercel.app/vpn/about.sh"
wget -O menu "https://adiscript.vercel.app/vpn/menu.sh"
wget -O usernew "https://adiscript.vercel.app/vpn/usernew.sh"
wget -O trial "https://adiscript.vercel.app/vpn/trial.sh"
wget -O hapus "https://adiscript.vercel.app/vpn/hapus.sh"
wget -O member "https://adiscript.vercel.app/vpn/member.sh"
wget -O delete "https://adiscript.vercel.app/vpn/delete.sh"
wget -O cek "https://adiscript.vercel.app/vpn/cek.sh"
wget -O restart "https://adiscript.vercel.app/vpn/restart.sh"
wget -O speedtest "https://adiscript.vercel.app/vpn/speedtest_cli.py"
wget -O info "https://adiscript.vercel.app/vpn/info.sh"
wget -O ram "https://adiscript.vercel.app/vpn/ram.sh"
wget -O renew "https://adiscript.vercel.app/vpn/renew.sh"
wget -O autokill "https://adiscript.vercel.app/vpn/autokill.sh"
wget -O ceklim "https://adiscript.vercel.app/vpn/ceklim.sh"
wget -O tendang "https://adiscript.vercel.app/vpn/tendang.sh"
wget -O clear-log "https://adiscript.vercel.app/vpn/clear-log.sh"
wget -O change-port "https://adiscript.vercel.app/vpn/change.sh"
wget -O port-ovpn "https://adiscript.vercel.app/vpn/port-ovpn.sh"
wget -O port-ssl "https://adiscript.vercel.app/vpn/port-ssl.sh"
wget -O port-wg "https://adiscript.vercel.app/vpn/port-wg.sh"
wget -O port-tr "https://adiscript.vercel.app/vpn/port-tr.sh"
wget -O port-sstp "https://adiscript.vercel.app/vpn/port-sstp.sh"
wget -O port-squid "https://adiscript.vercel.app/vpn/port-squid.sh"
wget -O port-ws "https://adiscript.vercel.app/vpn/port-ws.sh"
wget -O port-vless "https://adiscript.vercel.app/vpn/port-vless.sh"
wget -O wbmn "https://adiscript.vercel.app/vpn/webmin.sh"
wget -O xp "https://adiscript.vercel.app/vpn/xp.sh"
wget -O kernel-updt "https://adiscript.vercel.app/vpn/kernel-update.sh"
wget -O ganti-host "https://adiscript.vercel.app/vpn/cnhost.sh"
chmod +x add-host 
chmod +x addhost1
chmod +x menu
chmod +x usernew
chmod +x trial
chmod +x hapus
chmod +x member
chmod +x delete
chmod +x cek
chmod +x restart
chmod +x speedtest
chmod +x info
chmod +x about
chmod +x autokill
chmod +x tendang
chmod +x ceklim
chmod +x ram
chmod +x renew
chmod +x clear-log
chmod +x change-port
chmod +x port-ovpn
chmod +x port-ssl
chmod +x port-wg
chmod +x port-sstp
chmod +x port-tr
chmod +x port-squid
chmod +x port-ws
chmod +x port-vless
chmod +x wbmn
chmod +x xp
chmod +x kernel-updt
chmod +x ganti-host

cd
# iptables-persistent
echo "================  Firewall ======================"
apt install iptables-persistent -y
wget https://raw.githubusercontent.com/4hidessh/hidessh/main/security/torrent
chmod +x torrent
bash torrent
netfilter-persistent save
netfilter-persistent reload 


cd
# Delete Acount SSH Expired
echo "================  Auto deleted Account Expired ======================"
wget -O /usr/local/bin/userdelexpired "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/userdelexpired" && chmod +x /usr/local/bin/userdelexpired



#auto reboot server
echo "0 5 * * * root clear-log && reboot" >> /etc/crontab
echo "0 0 * * * root xp" >> /etc/crontab

# remove unnecessary files
cd
apt autoclean -y
apt -y remove --purge unscd
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove bind9*;
apt-get -y remove sendmail*
apt autoremove -y
# finishing
cd
chown -R www-data:www-data /home/vps/public_html
/etc/init.d/nginx restart
/etc/init.d/cron restart
/etc/init.d/ssh restart
/etc/init.d/dropbear restart
/etc/init.d/fail2ban restart
/etc/init.d/stunnel4 restart
/etc/init.d/squid restart
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500

history -c
echo "unset HideSSH" >> /etc/profile

#hapus file
cd
rm -f /root/ssh.sh

apt install dnsutils jq -y
apt-get install net-tools -y
apt-get install tcpdump -y
apt-get install dsniff -y
apt install grepcidr -y

# Instal DDOS Flate
#wget https://github.com/jgmdev/ddos-deflate/archive/master.zip -O ddos.zip
#unzip ddos.zip
#cd ddos-deflate-master
#./install.sh

# finihsing
clear
