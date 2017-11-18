#!/bin/bash

################ Script Info ################		

## Program: This is use for Linux System Initialization
## Author:chier xuefei
## Date:2017-01-29
## Update:20170129 create this.
## Update:20171118 add software; fix hostname; fix iptables save; fix service disable

################ Env Define ################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:~/sbin
LANG=C
export PATH
export LANG

################ Var Setting ################

MyHost="localhost"
MyDomain="localdomain"
HomeDir="/tmp/sysinit/"
SSHPort="22"
BasePkg=" wget lrzsz sysstat ntpdate net-snmp expect vim-enhanced firewalld policycoreutils iptables iptables-services rsyslog mlocate cronie"
AppendPkg="tmux screen git tzdata net-tools tcpdump traceroute bind-utils gcc gcc-c++ make automake autoconf patch libtool"
MyService="sshd rsyslog rc-local crond iptables snmpd network"
SrcHost="https://raw.gitbub.com"
SrcPath="/AutoAndEasy/sysinit/master/rhel7/"

################ Func Define ################ 
function _info_msg() {
_header
echo -e " |                                                                |"
echo -e " |                Thank you for use sysinit script!               |"
echo -e " |                                                                |"
echo -e " |                         Version: 1.0                           |"
echo -e " |                                                                |"
echo -e " |                     http://www.madadm.com                      |"
echo -e " |                                                                |"
echo -e " |                   Author:翅儿学飞(chier xuefei)                |"
echo -e " |                      Email:myregs@126.com                      |"
echo -e " |                         QQ:1810836851                          |"
echo -e " |                         QQ群:61749648                          |"
echo -e " |                                                                |"
echo -e " |          Hit [ENTER] to continue or ctrl+c to exit             |"
echo -e " |                                                                |"
printf " o----------------------------------------------------------------o\n"	
 read entcs 
clear
}

function _header() {
	printf " o----------------------------------------------------------------o\n"
	printf " | :: SYSINIT                                 v1.0.0 (2017/01/29) |\n"
	printf " o----------------------------------------------------------------o\n"	
}

##Program Function

function changeconf() {
#use method: changeconf attribute hyphen value file
#Note: if hyphen is space then use the string 'space' replace ' '
	CC_Attr=$1
	CC_Value=$3
	CC_File=$4
	CC_Hyphen=$2
	if [ $CC_Hyphen == "space" ];then
		CC_Hyphen=" "
	fi
	if [ -z "`grep ^${CC_Attr} ${CC_File}`" ]; then
		if [ -z "`grep ^#${CC_Attr} ${CC_File}`" ]; then
			echo "${CC_Attr}${CC_Hyphen}${CC_Value}" >> ${CC_File}
		else
			sed -i "/^#${CC_Attr}/a\\${CC_Attr}${CC_Hyphen}${CC_Value}" ${CC_File}
		fi
	else
		sed -i "s/^${CC_Attr}.*/${CC_Attr}${CC_Hyphen}${CC_Value}/g" ${CC_File}
	fi
}

################ Main ################
clear
_info_msg

if [ `id -u` != "0" ]; then
	echo -e "You need to be be the root user to run this script.\nWe also suggest you use a direct root login, not su -, sudo etc..."
exit 1
fi

##############    Main    ##############

if [ ! -d $HomeDir ]; then
	mkdir -p $HomeDir
fi

cd $HomeDir || exit 1

############  System Config  ############
##Set Append DNS
echo -e "\n" >> /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

##Install Base Soft
yum -y install $BasePkg
if [ ! -z "$AppendPkg" ]; then
	yum -y install $AppendPkg
fi
updatedb

##Set timezone
if [ -f /usr/share/zoneinfo/Asia/Shanghai ]; then
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
else
	wget --no-check-certificate ${SrcHost}${SrcPath}usr/share/zoneinfo/Asia/Shanghai
	\cp Shanghai /etc/localtime
fi

##Set ntp
if [ -z "`whereis ntpdate |cut -d' ' -f2|grep '/'`" ]; then
	echo "the ntp soft need install!";
else
	Ntpdate=`whereis ntpdate |cut -d' ' -f2`
	$Ntpdate 0.us.pool.ntp.org
	echo "3 * * * * root $Ntpdate 0.us.pool.ntp.org >> /dev/null 2>&1" >> /etc/crontab
fi

##Set Hostname
changeconf HOSTNAME = \"${MyHost}.${MyDomain}\" /etc/sysconfig/network
echo ${MyHost}.${MyDomain} > /etc/hostname

##Set SSH Port & Conf
changeconf Port space ${SSHPort} /etc/ssh/sshd_config
changeconf ClientAliveInterval space 60 /etc/ssh/sshd_config
changeconf ClientAliveCountMax space 5 /etc/ssh/sshd_config

##create ssh key
if [ ! -f /root/.ssh/authorized_keys ]; then
    rm -rf /root/.ssh
expect << EOF
spawn bash -c "ssh-keygen -t dsa"
match_max 100000
expect -exact "Generating public/private dsa key pair.\r
Enter file in which to save the key (/root/.ssh/id_dsa):"
send -- "\r"
expect -exact "\r
Enter passphrase (empty for no passphrase): "
send -- "\r"
expect -exact "\r
Enter same passphrase again: "
send -- "\r"
expect eof
EOF
    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
fi

##Set aliases
##the system default alias in /etc/profile.d/* and /root/.bashrc
echo "##  This is the user alias config by sysinit.sh" >> /etc/bashrc
echo "alias wgets='wget --no-check-certificate'" >> /etc/bashrc
echo "alias vi='vim'" >> /etc/bashrc

##Set default service at poweron
for i in `systemctl -t service list-unit-files |cut -d' ' -f1 |grep 'service$' |grep -v @`;do
    systemctl disable ${i}
done
for i in $MyService;do
    if [ ! -z "`systemctl -t service list-unit-files |grep ${i}.service`" ]; then
        systemctl enable ${i}.service
    else
        echo "Service ${i} not find!"
    fi
done

##Set Iptables
iptables -F
iptables -X
iptables -Z
iptables -A INPUT -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport $SSHPort -j ACCEPT        #ssh
iptables -A OUTPUT -p tcp --sport $SSHPort -j ACCEPT
iptables -A INPUT -j DROP
iptables -A OUTPUT -j DROP
iptables -A FORWARD -j DROP
service iptables save

##Set SeLinux
if [ -f /etc/selinux/config ]; then                                                                    
	sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi

############  Soft Config  ############

##vim config
echo '"############# User Define ############' >> /etc/vimrc
echo 'set ts=4' >> /etc/vimrc
echo 'set expandtab' >> /etc/vimrc
echo 'set autoindent' >> /etc/vimrc

############  Clean Cache  ############
rm -rf ${HomeDir}
