#!/bin/bash

################ Script Info ################		

## Program: This is use for Raspberry Pi Initialization
## Author:  Clumart.G(翅儿学飞)
## Date:    2013-01-02
## Update:  2014010201 None


################ Env Define ################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:~/sbin
LANG=C
export PATH
export LANG

################ Var Setting ################

MyHost="rpi01"
MyDomain="idcsrv.com"
HomeDir="/tmp/autoscript/sysinit/"
SSHPort="22"
RootPass="raspberry"
PiPass="raspberry"
BasePkg=" wget lrzsz sysstat ntpdate expect vim iptables "
AppendPkg=""
MyService="cron networking ssh  "
SrcHost="https://raw.gitbub.com"
SrcPath="/AutoAndEasy/sysinit/master/rpi/"

################ Func Define ################ 
function _info_msg() {
_header
echo -e " |                                                                |"
echo -e " |           Thank you for use sysinit of rpi script!             |"
echo -e " |                                                                |"
echo -e " |                         Version: 1.0                           |"
echo -e " |                                                                |"
echo -e " |                     http://www.idcsrv.com                      |"
echo -e " |                                                                |"
echo -e " |                   Author:翅儿学飞(Clumart.G)                   |"
echo -e " |                    Email:myregs6@gmail.com                     |"
echo -e " |                         QQ:1810836851                          |"
echo -e " |                         QQ群:61749648                          |"
echo -e " |                                                                |"
echo -e " |          Hit [ENTER] to continue or ctrl+c to exit             |"
echo -e " |                                                                |"
printf " o----------------------------------------------------------------o\n"	
 read entcs 
clear
}

function _end_msg() {
echo -e "###################################################################"
echo ""
echo -e "                         Install Finish :)"
echo ""
echo -e "###################################################################"
echo ""
echo ""
_header
echo -e " |                                                                |"
echo -e " |                 Thank you for use this script!                 |"
echo -e " |                                                                |"
echo -e " |             This RaspberryPi has been Initialization!          |"
echo -e " |                                                                |"
echo -e " |                     http://www.idcsrv.com                      |"
echo -e " |                                                                |"
echo -e " |                   Author:翅儿学飞(Clumart.G)                   |"
echo -e " |                    Email:myregs6@gmail.com                     |"
echo -e " |                         QQ:1810836851                          |"
echo -e " |                         QQ群:61749648                          |"
echo -e " |                                                                |"
printf " o----------------------------------------------------------------o\n"
}

function _header() {
	printf " o----------------------------------------------------------------o\n"
	printf " | :: SYSINIT FOR RaspberryPi                 v1.0.0 (2014/01/02) |\n"
	printf " o----------------------------------------------------------------o\n"	
}

function _error_exit() {
    cd
    rm -rf ${HomeDir}
    clear
    printf " o----------------------------------------------------------------o\n"
    printf " | :: Error                                   v1.0.0 (2013-10-28) |\n"
    printf " o----------------------------------------------------------------o\n"        
    printf " Error Message:$1 \n"
    exit 1
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
    echo ""
    echo "'sudo passwd root' can change your root password,and 'su -' login your OS :)"
exit 1
fi

if [ ! -d $HomeDir ]; then
	mkdir -p $HomeDir
fi

cd $HomeDir || _error_exit "Enter ${HomeDir} Faild."

############  System Config  ############

##password Initialization
echo $RootPass | passwd --stdin root
echo $PiPass | passwd --stdin pi

##Set Append DNS
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

##Install Base Soft
#apt install
#updatedb

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
	$Ntpdate pool.ntp.org
	echo "3 3 * * * root $Ntpdate pool.ntp.org >> /dev/null 2>&1" >> /etc/crontab
fi

##Set Hostname
changeconf HOSTNAME = \"${MyHost}.${MyDomain}\" /etc/sysconfig/network

##Set SSH Port & Conf

changeconf Port space $SSHPort /etc/ssh/sshd_config
changeconf ClientAliveInterval space 60 /etc/ssh/sshd_config
changeconf ClientAliveCountMax space 5 /etc/ssh/sshd_config
##create ssh key
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

##Set aliases
##the system default alias in /etc/profile.d/* and /root/.bashrc
echo "##  This is the user alias config by sysinit.sh" >> /etc/bashrc
echo "alias wgets='wget --no-check-certificate'" >> /etc/bashrc
echo "alias vi='vim'" >> /etc/bashrc

##Set default service at poweron
for i in `chkconfig --list|grep 3:|cut -d" " -f1`;do
	chkconfig --level 35 $i off
done
for i in $MyService;do
	chkconfig --level 35 $i on
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
/etc/init.d/iptables save

##Set SeLinux
if [ -f /etc/selinux/config ]; then                                                                    
	sed 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi

############  Soft Config  ############

##vim config

############  Clean Cache  ############
cd
rm -rf ${HomeDir}
_end_msg
