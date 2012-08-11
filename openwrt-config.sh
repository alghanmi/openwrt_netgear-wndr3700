#!/bin/sh

## Network Configuration
. network.conf

## Fix Missing DNS Servers
uci set network.lan.dns="$DNS_SERVERS"
uci commit
/etc/init.d/network restart

## Update & Install Packages
opkg update
opkg install qos-scripts ddns-scripts miniupnpd uhttpd-mod-tls curl l7-protocols kmod-leds-wndr3700-usb luci-ssl luci-app-qos

## System Configuration
uci set system.@system[0].hostname="$HOST_NAME"
uci set system.@system[0].zonename="$TIMEZONE_NAME"
uci set system.@system[0].timezone="$TIMEZONE"

## IP Address
uci set network.lan.ipaddr="$HOST_IP_ADDRESS"
uci set network.lan.netmask="$HOST_NETMASK"

## Remove Default Wireless Setup
uci delete wireless.@wifi-iface[1]
uci delete wireless.@wifi-iface[0]

## Radio [2GHz]
uci set wireless.radio0.hwmode=11ng
uci set wireless.radio0.htmode=HT40-
uci set wireless.radio0.txpower=22
uci set wireless.radio0.channel=6
uci delete wireless.radio0.disabled

## Wifi [2GHz]
uci add wireless wifi-iface
uci set wireless.@wifi-iface[-1].device=radio0
uci set wireless.@wifi-iface[-1].mode=ap
uci set wireless.@wifi-iface[-1].ssid="$WIFI1_SSID"
uci set wireless.@wifi-iface[-1].key="$WIFI1_KEY"
uci set wireless.@wifi-iface[-1].encryption=psk-mixed
uci set wireless.@wifi-iface[-1].network=lan

## Create DHCP & Hostname list
DEVICE_LIST=$(cat $DEVICES_FILE | grep -v '^#\|^$')
IFS=$'\12'
for d in $DEVICE_LIST
	do
		d_host=$(echo $d | awk '{ print $1 }')
		d_ip=$(echo $d | awk '{ print $2 }')
		d_mac=$(echo $d | awk '{ print $3 }')	
		
		if [ -n "$d_host" -a -n "$d_mac" -a -n "$d_ip" ]; then
			uci add dhcp host
			uci set dhcp.@host[-1].name=$d_host
			uci set dhcp.@host[-1].mac=$d_mac
			uci set dhcp.@host[-1].ip=$d_ip
		fi
		
		if [ -n "$d_host" -a -n "$d_ip" ]; then
			uci add dhcp domain
			uci set dhcp.@domain[-1].name=$d_host
			uci set dhcp.@domain[-1].ip=$d_ip
		fi
	done

## Firewall Redirects
uci add firewall redirect
uci set firewall.@redirect[0]._name=ssh_desktop
uci set firewall.@redirect[-1].src=wan
uci set firewall.@redirect[-1].src_dport="$REDIRECT_EXTERNAL_PORT"
uci set firewall.@redirect[-1].dest_ip="$REDIRECT_INTERNAL_IP"
uci set firewall.@redirect[-1].dest_port="$REDIRECT_INTERNAL_PORT"
uci set firewall.@redirect[-1].proto=tcp

## Disable uhttp on port 80
uci delete uhttpd.main.listen_http

## uhttpd Keys
uci set uhttpd.px5g.commonname="$HOST_NAME"
uci set uhttpd.px5g.days=3650
uci set uhttpd.px5g.country=US
uci set uhttpd.px5g.state="California"
uci set uhttpd.px5g.location="Los Angeles"
rm -f /etc/uhttpd.crt /etc/uhttpd.key

## SSH Setup
uci set dropbear.@dropbear[0].RootPasswordAuth=off
uci set dropbear.@dropbear[0].Port=51270
uci set dropbear.@dropbear[0].PasswordAuth=off
uci set dropbear.@dropbear[0].Interface=lan

## SSH Autharized Keys
echo $SSH_KEY > /etc/dropbear/authorized_keys

## QoS
uci set qos.wan.upload="$UPLOAD_SPEED"		# Upload speed in kBits/s
uci set qos.wan.download="$DOWNLOAD_SPEED"	# Download speed in kBits/s
uci set qos.wan.enabled=1
uci set qos.wan.overhead=1

## Add NameCheap.com DDNS
echo "" >> /usr/lib/ddns/services
echo "# Namecheap.com Dynamic DNS Service" >> /usr/lib/ddns/services
echo "\"namecheap.com\" \"http://dynamicdns.park-your-domain.com/update?host=[USERNAME]&domain=[DOMAIN]&password=[PASSWORD]&ip=[IP]\""  >> /usr/lib/ddns/services
echo "\"namecheap.com (ssl)\" \"https://dynamicdns.park-your-domain.com/update?host=[USERNAME]&domain=[DOMAIN]&password=[PASSWORD]&ip=[IP]\""  >> /usr/lib/ddns/services

## Install GeoTrust & Equifax Certificates
mkdir -p /etc/ssl/certs
curl http://www.geotrust.com/resources/root_certificates/certificates/GeoTrust_Global_CA.pem -o /etc/ssl/certs/GeoTrust_Global_CA.pem
curl http://www.geotrust.com/resources/root_certificates/certificates/Equifax_Secure_Certificate_Authority.pem -o /etc/ssl/certs/Equifax_Secure_Certificate_Authority.pem

## Personal DDNS
# Debug DDNS via:
#	/usr/lib/ddns/dynamic_dns_updater.sh myddns
uci set ddns.myddns.interface=wan
uci set ddns.myddns.service_name="$DDNS_SERVICE"
uci set ddns.myddns.username="$DDNS_USER"
uci set ddns.myddns.password="$DDNS_PASSWORD"
uci set ddns.myddns.domain="$DDNS_DOMAIN"
uci set ddns.myddns.ip_source=web
uci set ddns.myddns.ip_url=http://queryip.net/ip/
uci set ddns.myddns.check_interval=30
uci set ddns.myddns.check_unit=minutes
uci set ddns.myddns.force_interval=12
uci set ddns.myddns.force_unit=hours
uci set ddns.myddns.enabled=1
uci set ddns.myddns.use_https=1
uci set ddns.myddns.cacert=/etc/ssl/certs/GeoTrust_Global_CA.pem

## Enable Services
/etc/init.d/uhttpd enable
/etc/init.d/miniupnpd enable
/etc/init.d/qos enable

## Commit Changes
uci commit
echo "**** Restarting Router ****"

## Reboot after first setup
reboot
