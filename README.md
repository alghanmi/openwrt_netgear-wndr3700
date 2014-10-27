# OpenWRT Setup on Netgear WNDR3700

This is a guide on how to install and configure the latest stable [OpenWRT](https://openwrt.org/) firmware on the [Netgear WNDR3700](http://www.netgear.com/home/products/networking/wifi-routers/wndr3700.aspx) wireless dual-band gigabit router. Please read the disclaimer section before attempting to use this guide.

> OpenWrt is a highly extensible GNU/Linux distribution for embedded devices. Unlike many other distributions for these routers, OpenWrt is built from the ground up to be a full-featured, easily modifiable operating system for your router. In practice, this means that you can have all the features you need with none of the bloat, powered by a Linux kernel that's more recent than most other distributions.
-- [OpenWRT Wiki](http://wiki.openwrt.org/about/start)

Currently, the latest OpenWRT stable release is [Barrier Breaker 14.07](http://downloads.openwrt.org/barrier_breaker/14.07/). The firmware for the WNDR3700 is in the [`ar71xx/generic`](http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/) directory:
  + openwrt-ar71xx-generic-wndr3700-squashfs-factory-NA.img
  + openwrt-ar71xx-generic-wndr3700-squashfs-factory.img
  + openwrt-ar71xx-generic-wndr3700-squashfs-sysupgrade.bin
  + openwrt-ar71xx-generic-wndr3700v2-squashfs-factory.img
  + openwrt-ar71xx-generic-wndr3700v2-squashfs-sysupgrade.bin

Unlike OpenWRT [Backfire 10.3](http://downloads.openwrt.org/backfire/10.03.1/), there are two seprate images for the WNDR3700. Check the [Determining Your WNDR3700 version](#determining-your-wndr3700-version) section for details on how to check which version you own. Also, the [jffs2](http://wiki.openwrt.org/doc/techref/filesystems#jffs2) images offered in [Attitude Adjustment 12.09](http://downloads.openwrt.org/attitude_adjustment/12.09/) are no longer offered in the current release. Only [squashfs](http://wiki.openwrt.org/doc/techref/filesystems#squashfs)-based images are made available now.

## Pre-Requisites
Before flashing your WNDR3700, you will need to [determine the correction hardware version](#determining-your-wndr3700-version), backup your current configuration, read the OpenWRT documentation on the flashing of your hardware.

#### Determining Your WNDR3700 Version
Apparently, there are three versions of WNDR3700. The version could be determined through notation on the product packaging or via the initial factory firmware. I am a proud owner of a **v1**. You would need to know which version your own because each version required a different firmware. This Netgear Forums post illustrates how to distinguish between v1 and v2 of the WNDR3700: [Netgear Forums - 3700 box pics how to tell v1 or v2](http://forum1.netgear.com/showthread.php?t=62784).

#### Backup of Current Configuration Backup
If your device is currently using a version of OpenWRT, you can backup your configuration by either:

1. Backing up all your configuration files
```
tar czvf /tmp/openwrt-$(uci get system.@system[0].hostname)_$(date -I).tar.gz /etc/config /lib/config
```

1. Exporting your [UCI](http://wiki.openwrt.org/doc/uci) configuration
```
uci export > /tmp/openwrt-$(uci get system.@system[0].hostname)_$(date -I).uci.conf
```

### OpenWRT on WNDR3700 Documentation
Follows is a list of resources on how to install and configure OpenWRT on your device. I would recommend first time users to 
+ [OpenWRT Wiki - Netgear WNDR3700 and WNDR37AV](http://wiki.openwrt.org/toh/netgear/wndr3700)
+ [OpenWRT Wiki - OpenWRT Configuration](http://wiki.openwrt.org/doc/howto/basic.config)
+ [OpenWRT Wiki - OpenWRT Sysupgrade](http://wiki.openwrt.org/doc/howto/generic.sysupgrade)
+ [OpenWRT Forum - Best Settings, Tips, Tricks, Tweaks (for WNDR3700)](https://forum.openwrt.org/viewtopic.php?id=34062)

## Flashing Firmware
1. Update `device.list` to contain a listing of all network hosts including mac addresses, desired hostname and IP address. This is only needed if you desire to specify hostnames and ip address for such devices

1. Edit `network.conf` to your liking. Make sure to edit the SSID (i.e. network name) and key.

1. Upgrade your Firmware. ssh to your router and run the following commands:

```bash
#Move to temp directory
cd /tmp

#Download file and checksum
curl -sLO http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/openwrt-ar71xx-generic-wndr3700-squashfs-sysupgrade.bin
wget http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/md5sums
curl -sL http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/md5sums | grep openwrt-ar71xx-generic-wndr3700-squashfs-sysupgrade.bin > openwrt-ar71xx-generic-wndr3700-squashfs-sysupgrade.bin.md5

#Check file integrity
md5sum -c openwrt-ar71xx-generic-wndr3700-squashfs-sysupgrade.bin.md5

#Perform upgrade
sysupgrade -n -v openwrt-ar71xx-generic-wndr3700-squashfs-sysupgrade.bin
```

The `-n` option is used when you don't wish save configuration between flashes.

## Configuring Your Device
1. Initial login - Initially, you login to your device using telnet and only use that to reset your password. After that, you use SSH to access the machine. The default ip for OpenWRT is `192.168.1.1`
```bash
telnet 192.168.1.1
passwd
exit
```

1. Transfer `openwrt-config.sh`, `network.conf` and `device.list` to the router
```
scp openwrt-config.sh network.conf device.list root@192.168.1.1:
```

1. Login using SSH and run the configuration script
```bash
ssh -l root 192.168.1.1
sh openwrt-config.sh
```

1. *Enjoy!!!*

###Notes
####Dynamic DNS
The script adds support for [CloudFlare.com](https://www.cloudflare.com) client API and [NameCheap.com](https://www.namecheap.com/) DDNS service over SSL (NameCheap non-SSL support is already included). In order to support SSL, the script manually installed the required root certificates to make the DDNS service work. In your `network.conf` file, you should choose the appropriate certificate for the service you are using. Namely:
  + [NameCheap.com](https://www.namecheap.com/support/knowledgebase/category.aspx/11/dynamic-dns): [`GeoTrust_Global_CA.pem`](https://www.geotrust.com/resources/root-certificates/)
  + [CloudFlare.com](https://www.cloudflare.com/resources-downloads): [`GlobalSign_Root_R1.pem`](https://www.globalsign.com/repository/ca-certificates/)

If you wish to debug the DDNS service, you can run the following command
```bash
/usr/lib/ddns/dynamic_dns_updater.sh myddns
```

### Disclaimer
Although I am a proponent of custom firmware, I must mention that you should take extreme caution when flashing a device and you should do that at your own risk since it may result in undesirable consequences such as bricking your device if not done properly.

### License
See the [LICENSE](https://raw.github.com/alghanmi/openwrt_netgear-wndr3700/master/LICENSE) file.
