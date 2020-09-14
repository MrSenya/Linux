#!/bin/bash

## Variables
ifcfg=/etc/sysconfig/network-scripts/ifcfg-
net=/etc/network/interfaces
netplan=/etc/netplan/01-netcfg.yaml
resconf=/etc/resolv.conf
network=/etc/sysconfig/network
selinux=/etc/selinux/config
timezone=/usr/share/zoneinfo/Europe/Kiev
echo -n "Введите версию ОС: "
read os
echo -n "Введите имя сервера: "
read server
echo -n "Введите IP адрес сервера: "
read firstIp
echo -n "Введите адрес шлюза: "
read gatewayIp
echo -n "Введите маску подсети: "
read maskIp
echo -n "Введите пароль сервера: "
read serverPass
## end

osname=`echo "${os}" |cut -d ' ' -f1`
osver=`echo "${os}" |cut -d ' ' -f2`
if [ "$osname" == "CentOS" ] || [ "$osname" == "Fedora" ]; then
        choice=1
elif [ "$osname" == "Debian" ] || [ "$osname" == "Ubuntu" ]; then
        choice=2
elif [ "$osname" == "FreeBSD" ]; then
        choice=3
fi

case $choice in
        1)
        ## Set hostname and ip address
        host=${server}
        ip=${firstIp}
        ## End

        ## Update system and install necessary services
        yum -y update
        yum -y install mc ntp tcpdump ethtool iftop net-tools
        ## end

        ## Configure local time
        rm -f /etc/localtime
        ln -s $timezone /etc/localtime
        ntpdate -b pool.ntp.org
        ## end

        ## Disable SELINUX
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/' $selinux
        setenfoce 0
        ## end
	
	## Disable not required services
        chkconfig --del autofs 2> /dev/null
        chkconfig --del avahi-* 2> /dev/null
        chkconfig --del cups 2> /dev/null
        chkconfig --del gpm 2> /dev/null
        chkconfig --del firstboot 2> /dev/null
        chkconfig --del hidd 2> /dev/null
        chkconfig --del ip6tables 2> /dev/null
        chkconfig --del mdmonitor 2> /dev/null
        chkconfig --del netfs 2> /dev/null
        chkconfig --del nfs 2> /dev/null
        chkconfig --del nfslock 2> /dev/null
        chkconfig --del rpcbind 2> /dev/null
        chkconfig --del rpcgssd 2> /dev/null
        chkconfig --del rpcidmapd  2> /dev/null
        ## end

        ## Configure network interface and resolv.conf
        centos6()
        {
        rm -f /etc/sysconfig/network
        echo "NETWORKING=yes" >> /etc/sysconfig/network
        echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
        echo "HOSTNAME=${host}.ds.hosting.ua" >> /etc/sysconfig/network
        echo "GATEWAY=${gatewayIp}" >>/etc/sysconfig/network
        ethX=`ifconfig | head -1 | cut -d ' ' -f1`
        rm -f ${ifcfg}$ethX 2> /dev/null
        echo "DEVICE=$ethX" >> ${ifcfg}$ethX
        echo "IPADDR=$ip" >> ${ifcfg}$ethX
        echo "NETMASK=${maskIp}" >> ${ifcfg}$ethX
        echo "ONBOOT=yes" >> ${ifcfg}$ethX
        echo "TYPE=Ethernet" >> ${ifcfg}$ethX
        rm -f /etc/resolv.conf
        echo "nameserver 194.54.88.52" >> $resconf
        echo "nameserver 8.8.8.8" >> $resconf
        }

	centos7()
        {
        echo "${host}.ds.hosting.ua" > /etc/hostname
        echo 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="*", ATTR{type}=="1", KERNEL=="eth*", NAME="eth0"' >> /etc/udev/rules.d/60-net.rules
        sed '/GRUB_CMDLINE_LINUX/s/"$/ net.ifnames=0 biosdevname=0"/' -i /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg
        ethX=`ip addr | grep enp | cut -d' ' -f2 | cut -d: -f1`
        rm -f ${ifcfg}$ethX 2> /dev/null
        echo "NAME=eth0" > ${ifcfg}eth0
        echo "BOOTPROTO=static" >> ${ifcfg}eth0
        echo "IPADDR=$ip" >> ${ifcfg}eth0
        echo "NETMASK=${maskIp}" >> ${ifcfg}eth0
        echo "GATEWAY=${gatewayIp}" >> ${ifcfg}eth0
        echo "DNS1=194.54.88.52" >> ${ifcfg}eth0
        echo "DNS1=8.8.8.8" >> ${ifcfg}eth0
        echo "ONBOOT=yes" >> ${ifcfg}eth0
        echo "TYPE=Ethernet" >> ${ifcfg}eth0
        }

        if [ "$os" == "CentOS 7" ]; then
        centos7
        else
        centos6
        fi
        ## end

        ## Configure root password
        (
                echo "${serverPass}"
                echo "${serverPass}"
        )| passwd
        ## end.

        ## Make SSH banner
        wget http://194.54.88.145/install/bash_banner -O /root/.bash_banner
        if [ -f /root/.bash_banner ]; then
        echo -e "\t\t\t\t\t\t\t\t Hosting.ua \n \t CPU Threads: `getconf _NPROCESSORS_ONLN`   RAM: `free -m | grep -oP '\d+' | head -n 1` Mb   OS:${os} `uname -m`\n" >> /root/.bash_banner
        echo -e "## bash banner\nif [ -f /root/.bash_banner ]; then\n\tcat /root/.bash_banner;\nfi" >> /root/.bashrc
        fi
        ## end.

        ## Set custom history
        echo 'export HISTTIMEFORMAT="[%d/%m/%y %T]"' >> /etc/profile
        ## end

        ## Set custom prompt
        echo "" >> /etc/profile
        echo "PS1='\[\e[0;34m\][\u@\[\e[0;33m\]\h \W]\[\e[0;37m\]# '" >> /etc/profile
        echo "export PS1" >> /etc/profile
        ## end

        ## Delete postinstall script, clear history and exit
        rm -f ${host}.sh
        echo "shopt -s histappend" >> /root/.bashrc
	echo "PROMPT_COMMAND='history -a'" >> /root/.bashrc
        source /root/.bashrc
        rm -f /root/.bash_history
        reboot
        ;;
        ## End

	2)

        ## Set hostname and ip address
	host=${server}
        ip=${firstIp}
        ## end

        user=`cat /etc/passwd |grep home | awk -F ':' '{print $1}' |grep -v syslog`

        ## Add Debian repo
        if [ "${os}" = "Debian 6"  ]; then
                sed -i 's/deb cdrom/#deb cdrom/' /etc/apt/sources.list
                echo "deb http://http.us.debian.org/debian stable main contrib non-free" >> /etc/apt/sources.list
        elif [ "${os}" = "Debian 5"  ]; then
                sed -i 's/deb cdrom/#deb cdrom/' /etc/apt/sources.list
                echo "deb http://ftp.debian.org/ lenny contrib main non-free" >> /etc/apt/sources.list
        fi
        ## end

        ## Update system and install necessary services
        apt-get -y update
        apt-get -y upgrade
        apt-get -y install openssh-server tcpdump ethtool iptraf arping ntpdate
        ## end

        ## Configure local time
        rm -f /etc/localtime
        ln -s $timezone /etc/localtime
        ntpdate -b pool.ntp.org
        ## end

        ## Configure network interface and resolv.conf

        systemd(){
        sed '/GRUB_HIDDEN_TIMEOUT/s/^/#/' -i /etc/default/grub
        sed '/GRUB_CMDLINE_LINUX/s/quiet splash//' -i /etc/default/grub
        sed '/GRUB_CMDLINE_LINUX/s/"$/ net.ifnames=0 biosdevname=0"/' -i /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
        ethX=eth0
        }

        initd(){
        ethX=`ifconfig | head -1 | cut -d ' ' -f1`
        }

	if [ "$osname" == "Debian" ]; then
                if [ "$osver" -le "8" ]; then
                        initd
                else
                        systemd
                fi
        fi
        if [ "$osname" == "Ubuntu" ]; then
                if [ "$osver" -le "15" ]; then
                        initd
                else
                        systemd
                fi
        fi


        if [ "$osver" -eq "18" ]; then
        #Ubuntu 18+
        rm -f $netplan
        echo -e "network:" >> $netplan
        echo -e "  version: 2" >> $netplan
        echo -e "  renderer: networkd" >> $netplan
        echo -e "  ethernets:" >> $netplan
        echo -e "    ${ethX}:" >> $netplan
        echo -e "     dhcp4: no" >> $netplan
        echo -e "     addresses: [$ip/32]" >> $netplan
        echo -e "     gateway4: ${gatewayIp}" >> $netplan
        echo -e "     nameservers:" >> $netplan
        echo -e "       addresses: [194.54.88.52,8.8.8.8]" >> $netplan
        echo -e "     routes:" >> $netplan
        echo -e "       - to: ${gatewayIp}/32" >> $netplan
        echo -e "         via: 0.0.0.0" >> $netplan
        echo -e "         scope: link" >> $netplan
        echo "${host}.ds.hosting.ua" > /etc/hostname
        else

        #config network intreface
        rm -f $net
        echo "# The loopback network interface" >> $net
        echo "auto lo" >> $net
        echo "iface lo inet loopback" >> $net
        echo "auto $ethX" >> $net
        echo "iface $ethX inet static" >> $net
        echo "address $ip" >> $net
        echo "netmask ${maskIp}" >> $net
        echo "gateway ${gatewayIp}" >> $net
        echo "dns-nameservers 194.54.88.52 8.8.8.8" >> $net
        echo "${host}.ds.hosting.ua" > /etc/hostname
        rm -f $resconf
        echo "nameserver 194.54.88.52" >> $resconf
        echo "nameserver 8.8.8.8" >> $resconf
        fi
        ## end

	## Delete user and home catalog
        user=`cat /etc/passwd |grep home | awk -F ':' '{print $1}' |grep -v syslog`
        userdel $user -r -f
        ## end

        ## Set prompt
        echo "" >> /etc/profile
        echo "PS1='${debian_chroot:+($debian_chroot)}\[\e[0;34m\]\u@\[\e[0;33m\]\h:\w\[\e[0;37m\]# '" >> /etc/profile
        echo "export PS1" >> /etc/profile
        ## end

        ## Set root password
        (
               echo "${serverPass}"
               echo "${serverPass}"
        )| passwd
        ## end

        ## Make SSH banner
        wget http://194.54.88.145/install/bash_banner -O /root/.bash_banner
        if [ -f /root/.bash_banner ]; then
        echo -e "\t\t\t\t\t\t\t\t Hosting.ua \n \t CPU Threads: `getconf _NPROCESSORS_ONLN`   RAM: `free -m | grep -oP '\d+' | head -n 1` Mb   OS:${os} `uname -m`\n" >> /root/.bash_banner
        echo -e "## bash banner\nif [ -f /root/.bash_banner ]; then\n\tcat /root/.bash_banner;\nfi" >> /root/.bashrc
        fi
        ## end.

        ## Set custom history
        echo 'export HISTTIMEFORMAT="[%d/%m/%y %T]"' >> /etc/profile
        ## end

        ## Delete postinstall script, clear history and exit
        rm -f ${host}.sh
        echo "shopt -s histappend" >> /root/.bashrc
        echo "PROMPT_COMMAND='history -a'" >> /root/.bashrc
        source /root/.bashrc
        rm -f /root/.bash_history
        reboot
        ;;
        ## end

	3) # FreeBSD
        echo "### Configuring FreeBSD ###"
        ## Set hostname and ip address
        host=${server}
        ip=${firstIp}
        ## End

        ## Set root password
        echo "${serverPass}" | pw mod user root -h 0
        ## End

        ## Enable SSHd and force fsck
        printf "## Tweak ##\n" >> /etc/rc.conf
        printf "sshd_enable=\"YES\"\n" >> /etc/rc.conf
        printf "fsck_y_enable=\"YES\"\n" >> /etc/rc.conf
        ## End

        ## Configure network interface and resolv.conf
        ethX=`ifconfig | head -1 | cut -d ':' -f 1`
        printf "## Network ##\n" >> /etc/rc.conf
        printf "hostname=\"${host}.ds.hosting.ua\"\n" >> /etc/rc.conf
        printf "ifconfig_${ethX}=\"inet ${ip} netmask ${maskIp}\"\n" >> /etc/rc.conf
        printf "defaultrouter=\"${gatewayIp}\"\n" >> /etc/rc.conf
        printf "## DNS Conf ##\n" >> $resconf
        printf "nameserver 194.54.88.52\n" >> $resconf
        printf "nameserver 8.8.8.8\n" >> $resconf
        ## End

        ## Delete postinstall script, clear history and exit
        rm -f ${host}.sh
        rm -f /root/.history && set history = 0 && set savehist = 0
        reboot
       ;;
        ## End


        *)
        printf " [ WARNING ]     Something wrong !!! OS name dont detected !!! \n \t\t Your need to install server yourself (^_^)\n" ;;
        ## End
esac
