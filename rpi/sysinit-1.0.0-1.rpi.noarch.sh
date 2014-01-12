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
aptupdate="enable"
BasePkg=" wget lrzsz sysstat ntpdate expect vim mlocate "
AppendPkg=" tzdata ntpdate "
MyService=" bootlogs ifplugd rsyslog sudo cron dbus dphys-swapfile sysstat rc.local rmnologin networking ssh  "
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

printf " o----------------------------------------------------------------o\n"
printf " |                                                                |\n"
printf " |              This Script Need Internet Connect.                |\n"
printf " |          Hit [ENTER] to continue or ctrl+c to exit             |\n"
printf " |                                                                |\n"
printf " o----------------------------------------------------------------o\n"  
read entcs 

if [ ! -d $HomeDir ]; then
	mkdir -p $HomeDir
fi

cd $HomeDir || _error_exit "Enter ${HomeDir} Faild."

############  System Config  ############

##password Initialization;
echo "root:${RootPass}" | chpasswd
echo "pi:${PiPass}" | chpasswd

##Set Hostname
echo "${MyHost}.${MyDomain}" > /etc/hostname

##Set Language ,Language list in /usr/share/i18n/SUPPORTED
echo "LANG=en_US.UTF-8" > /etc/default/locale
changeconf en_US.UTF-8 space UTF-8 /etc/locale.gen
locale-gen

##init 3
sed -i 's/id:2:initdefault:/id:3:initdefault:/g' /etc/inittab

##Set SeLinux
if [ -f /etc/selinux/config ]; then                                                                    
    changeconf SELINUX = disabled /etc/selinux/config
fi

##Set Append DNS
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

##Install Base Soft
if [ "x${aptupdate}" == "xenable" ]; then
    apt-get update
fi
apt-get -y install $BasePkg
#Append Packge install
apt-get -y install $AppendPkg
#updatedb
updatedb

##Set timezone
rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

##Set ntp
if [ -z "`whereis ntpdate |cut -d' ' -f2|grep '/'`" ]; then
    echo "the ntp soft need install! I'm Installing ...";
    apt-get -y install ntpdate
fi
Ntpdate=`whereis ntpdate |cut -d' ' -f2`
$Ntpdate pool.ntp.org
echo "$Ntpdate pool.ntp.org >> /dev/null 2>&1" >> /etc/rc.local
echo "3 3 * * * root $Ntpdate pool.ntp.org >> /dev/null 2>&1" >> /etc/crontab

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

##Set default service at poweron
cd /etc/rc3.d/
for i in `ls S*`;do 
    j=`echo $i|sed "s/^S/K/g"`;
    mv $i $j;
done
k=`ls K*`
for i in $MyService;do
    if [ `echo $k|grep $i |wc -l ` -gt 0 ]; then
        i=`ls K*|grep $i|head -n1`;
        j=`echo $i|sed "s/^K/S/g"`;
        mv $i $j;
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
iptables-save

############  Soft Config  ############

##Set aliases
##the system default alias in /etc/profile.d/* and /root/.bashrc
cat >> /etc/bash.bashrc << \EOF
##  This is the user alias config by sysinit.sh
alias wgets='wget --no-check-certificate'
alias vi='vim'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias vi='vim'
alias l.='ls -d .* --color=auto'
alias ll='ls -l --color=auto'
alias ls='ls --color=auto'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'
EOF

##mnt dir
mkdir -p /mnt/sys
mkdir -p /mnt/program
mkdir -p /mnt/soft
mkdir -p /mnt/file

##vim config
echo "You can config vim by https://github.com/AutoAndEasy/vimstyle"

############  Clean Cache  ############
cd
rm -rf ${HomeDir}
_end_msg
