#auto installer SSH + OpenVPN + SSLH Multi Port 

apt-get update -y
apt-get upgrade -y

# initializing var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";

# Delete Acount SSH Expired
echo "================  Auto deleted Account Expired ======================"
wget -O /usr/local/bin/userdelexpired "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/userdelexpired" && chmod +x /usr/local/bin/userdelexpired

#tambahan installer 
apt-get -y install gcc
apt-get -y install make
apt-get install cmake -y
apt-get -y install git
apt-get -y install wget
apt-get install screen -y
apt-get -y install unzip
apt-get -y install zip
apt-get -y install curl
apt-get -y install unrar ca-certificates
apt-get -y install iptables-persistent

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
systemctl daemon-reload
systemctl start rc-local

# detail nama perusahaan
country=ID
state=Semarang
locality=JawaTengah
organization=hidessh
organizationalunit=HideSSH
commonname=hidessh.com
email=admin@hidessh.com

cd
# set time GMT +7 jakarta
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# set locale SSH
echo "=================  Setting Port SSH ======================"
cd
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 80' /etc/ssh/sshd_config
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

echo "================  install Dropbear ======================"
echo "========================================================="

# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=44/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 77 "/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/ssh restart
/etc/init.d/dropbear restart


# install webserver
apt-get -y install nginx

# install webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/acillsadank/install/master/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Setup by HideSSH</pre>" > /home/vps/public_html/index.html
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/acillsadank/install/master/vps.conf"

# install openvpn
apt-get -y install openvpn easy-rsa openssl iptables
cp -r /usr/share/easy-rsa/ /etc/openvpn
mkdir /etc/openvpn/easy-rsa/keys
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY="ID"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE="JAWATENGAH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY="SEMARANG"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_ORG="Fort-Funston"|export KEY_ORG="HIDESSH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_EMAIL="admin@hidessh.com"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU="MyOrganizationalUnit"|export KEY_OU="HideSSH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_NAME="EasyRSA"|export KEY_NAME="HideSSH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU=changeme|export KEY_OU="HideSSH"|' /etc/openvpn/easy-rsa/vars

# Create Diffie-Helman Pem
openssl dhparam -out /etc/openvpn/dh2048.pem 2048

# Create PKI
cd /etc/openvpn/easy-rsa
cp openssl-1.0.0.cnf openssl.cnf
. ./vars
./clean-all
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca $*

# Create key server
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server server

# Setting KEY CN
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" client

# cp /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} /etc/openvpn
cd
cp /etc/openvpn/easy-rsa/keys/server.crt /etc/openvpn/server.crt
cp /etc/openvpn/easy-rsa/keys/server.key /etc/openvpn/server.key
cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/ca.crt
chmod +x /etc/openvpn/ca.crt


# server settings
#config openvpn server
cd /etc/openvpn/
wget -O /etc/openvpn/server-tcp-1194.conf "https://raw.githubusercontent.com/4hidessh/hidessh/main/OVPN/server-tcp-1194.conf"
wget -O /etc/openvpn/server-udp-1194.conf "https://raw.githubusercontent.com/4hidessh/hidessh/main/OVPN/server-udp-1194.conf"

#config tcp
wget -O /etc/openvpn/client-tcp-1194.ovpn "https://raw.githubusercontent.com/4hidessh/hidessh/main/OVPN/client-tcp-1194.conf"
sed -i $MYIP2 /etc/openvpn/client-tcp-1194.ovpn;
echo '<ca>' >> /etc/openvpn/client-tcp-1194.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-tcp-1194.ovpn
echo '</ca>' >> /etc/openvpn/client-tcp-1194.ovpn
cp client-tcp-1194.ovpn /home/vps/public_html/
#config udp
wget -O /etc/openvpn/client-udp-1194.ovpn "https://raw.githubusercontent.com/4hidessh/hidessh/main/OVPN/client-udp-1194.conf"
sed -i $MYIP2 /etc/openvpn/client-udp-1194.ovpn;
echo '<ca>' >> /etc/openvpn/client-udp-1194.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-udp-1194.ovpn
echo '</ca>' >> /etc/openvpn/client-udp-1194.ovpn
cp client-udp-1194.ovpn /home/vps/public_html/
#config ssl tcp
wget -O /etc/openvpn/client-tcp-ssl.ovpn "https://raw.githubusercontent.com/4hidessh/hidessh/main/OVPN/client-tcp-ssl.conf"
echo '<ca>' >> /etc/openvpn/client-tcp-ssl.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-tcp-ssl.ovpn
echo '</ca>' >> /etc/openvpn/client-tcp-ssl.ovpn
cp client-tcp-ssl.ovpn /home/vps/public_html/
#config ssl udp
wget -O /etc/openvpn/client-udp-ssl.ovpn "https://raw.githubusercontent.com/4hidessh/hidessh/main/OVPN/client-udp-ssl.conf"
echo '<ca>' >> /etc/openvpn/client-udp-ssl.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-udp-ssl.ovpn
echo '</ca>' >> /etc/openvpn/client-udp-ssl.ovpn
cp client-udp-ssl.ovpn /home/vps/public_html/

# Restart OpenVPN
/etc/init.d/openvpn restart
service openvpn start
service openvpn status



# set ipv4 forward
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf


iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i eth0 -m state --state
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o tun+ -m state

iptables -A OUTPUT -o tun+ -j ACCEPT


#firewall
ifes="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)";


iptables -t nat -I POSTROUTING -o $ifes -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o $ifes -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.200.0/24 -o $ifes -j MASQUERADE

iptables -t nat -A POSTROUTING -o ens3 -s 192.168.100.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o ens3 -s 192.168.200.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE


iptables -I INPUT 1 -i tun0 -j ACCEPT
iptables -I FORWARD 1 -i $ifes -o tun0 -j ACCEPT
iptables -I FORWARD 1 -i tun0 -o $ifes -j ACCEPT
iptables -I INPUT 1 -i $ifes -p udp --dport 1194 -j ACCEPT
iptables -I INPUT 1 -i $ifes -p tcp --dport 1194 -j ACCEPT

iptables-save
netfilter-persistent save
netfilter-persistent reload























# install squid3
echo "================  konfigurasi Squid3 ======================"
cd
apt-get -y install squid3
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/squid3.conf"
sed -i $MYIP2 /etc/squid/squid.conf;
/etc/init.d/squid restart

echo "=================  install stunnel  ====================="
echo "========================================================="

# install stunnel
apt-get install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[dropbear]
accept = 222
connect = 127.0.0.1:22
[dropbear]
accept = 444
connect = 127.0.0.1:44
[dropbear]
accept = 443
connect = 127.0.0.1:77
[dropbear]
accept = 111
connect = 127.0.0.1:1194


END

echo "=================  membuat Sertifikat OpenSSL ======================"
echo "========================================================="
#membuat sertifikat
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart

#install Dns Server
echo "=================  DNS Server ======================"
apt-get install resolvconf -y
wget -O /etc/resolvconf/resolv.conf.d/head "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/dns" && chmod +x /etc/resolvconf/resolv.conf.d/head


cd
# common password debian 
wget -O /etc/pam.d/common-password "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/common-password-deb9"
chmod +x /etc/pam.d/common-password


# Custom Banner SSH

echo "================  Banner ======================"
wget -O /etc/issue.net "https://github.com/idtunnel/sshtunnel/raw/master/debian9/banner-custom.conf"
chmod +x /etc/issue.net

echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
echo "DROPBEAR_BANNER="/etc/issue.net"" >> /etc/default/dropbear


# Instal DDOS Flate
if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi
clear
echo; echo 'Installing DOS-Deflate 0.6'; echo
echo; echo -n 'Downloading source files...'
wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
echo -n '.'
wget -q -O /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
echo -n '.'
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
echo -n '.'
wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
cp -s /usr/local/ddos/ddos.sh /usr/local/sbin/ddos
echo '...done'
echo; echo -n 'Creating cron to run script every minute.....(Default setting)'
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1
echo '.....done'
echo; echo 'Installation has completed.'
echo 'Config file is at /usr/local/ddos/ddos.conf'
echo 'Please send in your comments and/or suggestions to zaf@vsnl.com'

echo "================= Auto Installer Disable badVPN V 3  ======================"
# buat directory badvpn
cd /usr/bin
mkdir build
cd build
wget https://github.com/ambrop72/badvpn/archive/1.999.130.tar.gz
tar xvzf 1.999.130.tar.gz
cd badvpn-1.999.130
cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1 -DBUILD_UDPGW=1
make install
make -i install

cd
# auto start badvpn single port
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10' /etc/rc.local
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 20 

cd
# permition
chmod +x /usr/local/bin/badvpn-udpgw
chmod +x /usr/local/share/man/man7/badvpn.7
chmod +x /usr/local/bin/badvpn-tun2socks
chmod +x /usr/local/share/man/man8/badvpn-tun2socks.8
chmod +x /usr/bin/build


cd

sed -i '$ i\iptables -t nat -A POSTROUTING -o ens3 -s 192.168.100.0/24 -j MASQUERADE' /etc/rc.local
sed -i '$ i\iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE' /etc/rc.local
sed -i '$ i\iptables -t nat -A POSTROUTING -o ens3 -s 192.168.200.0/24 -j MASQUERADE' /etc/rc.local
sed -i '$ i\iptables -t nat -A POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE' /etc/rc.local
chmod +x /etc/rc.local


# download script
cd /usr/bin
wget -O menu "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/menu.sh"
wget -O usernew "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/usernew.sh"
wget -O trial "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/trial.sh"
wget -O hapus "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/hapus.sh"
wget -O cek "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/user-login.sh"
wget -O member "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/user-list.sh"
wget -O jurus69 "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/restart.sh"
wget -O speedtest "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/speedtest_cli.py"
wget -O info "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/info.sh"
wget -O about "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/about.sh"
wget -O delete "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/delete.sh"

echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot

chmod +x menu
chmod +x usernew
chmod +x trial
chmod +x hapus
chmod +x cek
chmod +x member
chmod +x jurus69
chmod +x speedtest
chmod +x info
chmod +x about
chmod +x delete

cd
#unzip semua file 
cd /home/vps/public_html
zip config.zip client-tcp-1194.ovpn client-udp-1194.ovpn client-tcp-ssl.ovpn client-udp-ssl.ovpn

service openvpn start
service openvpn enable
service openvpn restart
service ssh restart
service dropbear restart

# autoreboot 12 jam

echo "================  Auto Reboot ======================"
echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot
