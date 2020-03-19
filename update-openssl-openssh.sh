#!/bin/bash
# Author:  黄国鹏 <365978824@163.com>
#
# Notes: Update openssh for CentOS/RedHat 4.x-7.x
#
# Project home page:
#       https://github.com/huangguopeng/update-openssl-openssh
clear
export LANG="en_US.UTF-8"

#脚本变量
DATE=`date "+%Y%m%d"`
PREFIX="/usr/local"
ZLIB_VERSION="zlib-1.2.11"
OPENSSL_VERSION="openssl-1.0.2t"
OPENSSH_VERSION="openssh-8.1p1"

ZLIB_DOWNLOAD="http://zlib.net/$ZLIB_VERSION.tar.gz" 
OPENSSL_DOWNLOAD="https://www.openssl.org/source/$OPENSSL_VERSION.tar.gz" 
OPENSSH_DOWNLOAD="https://openbsd.hk/pub/OpenBSD/OpenSSH/portable/$OPENSSH_VERSION.tar.gz" 
UNSUPPORTED_SYSTEM=`cat /etc/redhat-release | grep "release 3" | wc -l`

LOG_PATH=`pwd`
LOG="${LOG_PATH}/update-openssh-$DATE.log"

#创建日志文件
if [ -e ${LOG} ];then
rm -f ${LOG}
fi
touch ${LOG}

#检查用户
if [ $(id -u) != 0 ]; then
echo -e "当前登陆用户为普通用户，必须使用Root用户运行脚本，五秒后自动退出脚本" "\033[31m Failure\033[0m" | tee -a ${LOG}
echo ""
sleep 5
exit
fi

#检查系统
if [ "$UNSUPPORTED_SYSTEM" == "1" ];then
clear
echo -e "脚本仅支持操作系统4.x-7.x版本，五秒后自动退出脚本" "\033[31m Failure\033[0m" | tee -a ${LOG}
echo ""
sleep 5
exit
fi

#使用说明
echo -e "\033[33m软件升级\033[0m" | tee -a ${LOG}
echo ""
echo "脚本仅适用于RHEL和CentOS操作系统，支持4.x-7.x版本"
echo "必须使用Root用户运行脚本，确保本机已配置好软件仓库"
echo "旧版本OpenSSH文件备份在/tmp/backup_$DATE/openssh"
echo "安装日志为${LOG}"
echo ""

#下载源码包
function DOWNLOAD() {

#下载源码包
cd /tmp
wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate $ZLIB_DOWNLOAD  2>&1 | tee -a ${LOG}
sleep 1
wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate $OPENSSL_DOWNLOAD  2>&1 | tee -a ${LOG}
sleep 1
wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate $OPENSSH_DOWNLOAD  2>&1 | tee -a ${LOG}
sleep 1
if [ -e /tmp/$ZLIB_VERSION.tar.gz ] && [ -e /tmp/$OPENSSL_VERSION.tar.gz ] && [ -e /tmp/$OPENSSH_VERSION.tar.gz ];then
echo -e "下载软件源码包成功" "\033[32m Success\033[0m" | tee -a ${LOG} | tee -a ${LOG}
else
echo -e "下载软件源码包失败，五秒后自动退出脚本" "\033[31m Failure\033[0m" | tee -a ${LOG} | tee -a ${LOG}
echo ""
sleep 5
exit
fi
echo ""

}

#升级OpenSSH
function OPENSSH() {

#创建备份目录
mkdir -p /tmp/backup_$DATE/openssh  2>&1 | tee -a ${LOG}
mkdir -p /tmp/backup_$DATE/openssh/usr/{bin,sbin}  2>&1 | tee -a ${LOG}
mkdir -p /tmp/backup_$DATE/openssh/etc/{init.d,pam.d,ssh}  2>&1 | tee -a ${LOG}
mkdir -p /tmp/backup_$DATE/openssh/usr/libexec/openssh  2>&1 | tee -a ${LOG}
mkdir -p /tmp/backup_$DATE/openssh/usr/share/man/{man1,man8}  2>&1 | tee -a ${LOG}

#安装依赖包
yum -y install vim gcc wget make pam-devel  2>&1 | tee -a ${LOG}
if [ $? -eq 0 ];then
echo -e "安装软件依赖包成功" "\033[32m Success\033[0m" | tee -a ${LOG} | tee -a ${LOG}
else
echo -e "安装软件依赖包失败，五秒后自动退出脚本" "\033[31m Failure\033[0m" | tee -a ${LOG} | tee -a ${LOG}
echo ""
sleep 5
exit
fi
echo ""

#解压源码包
cd /tmp
tar xzf $ZLIB_VERSION.tar.gz
tar xzf $OPENSSL_VERSION.tar.gz
tar xzf $OPENSSH_VERSION.tar.gz
if [ -d /tmp/$ZLIB_VERSION ] && [ -d /tmp/$OPENSSL_VERSION ] && [ -d /tmp/$OPENSSH_VERSION ];then
echo -e "解压软件源码包成功" "\033[32m Success\033[0m" | tee -a ${LOG} | tee -a ${LOG}
else
echo -e "解压软件源码包失败，五秒后自动退出脚本" "\033[31m Failure\033[0m" | tee -a ${LOG} | tee -a ${LOG}
echo ""
sleep 5
exit
fi
echo ""

#安装Zlib
cd /tmp/$ZLIB_VERSION
./configure --prefix=$PREFIX/$ZLIB_VERSION  2>&1 | tee -a ${LOG}
if [ $? -eq 0 ];then
make  2>&1 | tee -a ${LOG}
make install  2>&1 | tee -a ${LOG}
else
echo -e "编译安装压缩库失败，五秒后自动退出脚本" "\033[31m Failure\033[0m" | tee -a ${LOG} | tee -a ${LOG}
echo ""
sleep 5
exit
fi

if [ -e $PREFIX/$ZLIB_VERSION/lib/libz.so ];then
echo "$PREFIX/$ZLIB_VERSION/lib" >> /etc/ld.so.conf
ldconfig  2>&1 | tee -a ${LOG}
echo -e "编译安装压缩库成功" "\033[32m Success\033[0m" | tee -a ${LOG}
else
echo -e "编译安装压缩库失败，五秒后自动退出脚本" "\033[31m Failure\033[0m" | tee -a ${LOG}
echo ""
sleep 5
exit
fi
echo ""

#备份旧版OpenSSH
rpm -qa | grep -w "openssh-server"  2>&1 | tee -a ${LOG}
if [ $? -eq 0 ];then
cp /usr/bin/ssh* /tmp/backup_$DATE/openssh/usr/bin  2>&1 | tee -a ${LOG}
cp /usr/sbin/sshd /tmp/backup_$DATE/openssh/usr/sbin  2>&1 | tee -a ${LOG}
cp /etc/init.d/sshd /tmp/backup_$DATE/openssh/etc/init.d  2>&1 | tee -a ${LOG}
cp /etc/pam.d/sshd /tmp/backup_$DATE/openssh/etc/pam.d  2>&1 | tee -a ${LOG}
cp /etc/ssh/ssh* /tmp/backup_$DATE/openssh/etc/ssh  2>&1 | tee -a ${LOG}
cp /etc/ssh/sshd_config /tmp/backup_$DATE/openssh/etc/ssh  2>&1 | tee -a ${LOG}
cp /usr/share/man/man1/ssh* /tmp/backup_$DATE/openssh/usr/share/man/man1  2>&1 | tee -a ${LOG}
cp /usr/share/man/man8/ssh* /tmp/backup_$DATE/openssh/usr/share/man/man8  2>&1 | tee -a ${LOG}
cp /usr/libexec/openssh/ssh* /tmp/backup_$DATE/openssh/usr/libexec/openssh  2>&1 | tee -a ${LOG}
rpm -e --nodeps openssh-clients openssh-server openssh  2>&1 | tee -a ${LOG}
else
mv /usr/bin/ssh* /tmp/backup_$DATE/openssh/usr/bin  2>&1 | tee -a ${LOG}
mv /usr/sbin/sshd /tmp/backup_$DATE/openssh/usr/sbin  2>&1 | tee -a ${LOG}
mv /etc/init.d/sshd /tmp/backup_$DATE/openssh/etc/init.d  2>&1 | tee -a ${LOG}
mv /etc/pam.d/sshd /tmp/backup_$DATE/openssh/etc/pam.d  2>&1 | tee -a ${LOG}
mv /etc/ssh/ssh* /tmp/backup_$DATE/openssh/etc/ssh  2>&1 | tee -a ${LOG}
mv /etc/ssh/sshd_config /tmp/backup_$DATE/openssh/etc/ssh  2>&1 | tee -a ${LOG}
mv /usr/share/man/man1/ssh* /tmp/backup_$DATE/openssh/usr/share/man/man1  2>&1 | tee -a ${LOG}
mv /usr/share/man/man8/ssh* /tmp/backup_$DATE/openssh/usr/share/man/man8  2>&1 | tee -a ${LOG}
mv /usr/libexec/ssh* /tmp/backup_$DATE/openssh/usr/libexec  2>&1 | tee -a ${LOG}
fi

#安装OpenSSL
cd /tmp/$OPENSSL_VERSION
./config --prefix=$PREFIX/$OPENSSL_VERSION --openssldir=$PREFIX/$OPENSSL_VERSION/ssl -fPIC  2>&1 | tee -a ${LOG}
if [ $? -eq 0 ];then
make  2>&1 | tee -a ${LOG}
make install  2>&1 | tee -a ${LOG}
else
echo -e "编译安装OpenSSL失败，五秒后自动退出脚本" "\033[31m Failure\033[0m" | tee -a ${LOG}
echo ""
sleep 5
exit
fi

if [ -e $PREFIX/$OPENSSL_VERSION/bin/openssl ];then
echo "$PREFIX/$OPENSSL_VERSION/lib" >> /etc/ld.so.conf
ldconfig  2>&1 | tee -a ${LOG}
echo -e "编译安装OpenSSL成功" "\033[32m Success\033[0m" | tee -a ${LOG}
fi
echo ""

#安装OpenSSH
cd /tmp/$OPENSSH_VERSION
./configure --prefix=/usr --sysconfdir=/etc/ssh --with-ssl-dir=$PREFIX/$OPENSSL_VERSION --with-zlib=$PREFIX/$ZLIB_VERSION --with-pam --with-md5-passwords  2>&1 | tee -a ${LOG}
if [ $? -eq 0 ];then
make  2>&1 | tee -a ${LOG}
make install  2>&1 | tee -a ${LOG}
else
echo -e "编译安装OpenSSH失败，五秒后自动退出脚本" "\033[31m Failure\033[0m" | tee -a ${LOG}
echo ""
sleep 5
exit
fi

if [ -e /usr/sbin/sshd ];then
echo -e "编译安装OpenSSH成功" "\033[32m Success\033[0m" | tee -a ${LOG}
fi
echo ""

#配置OpenSSH服务端（允许root登陆）
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

#启动OpenSSH
cp -rf /tmp/$OPENSSH_VERSION/contrib/redhat/sshd.init /etc/init.d/sshd
cp -rf /tmp/$OPENSSH_VERSION/contrib/redhat/sshd.pam /etc/pam.d/sshd
chmod +x /etc/init.d/sshd
chmod 600 /etc/ssh/ssh_host_rsa_key
chmod 600 /etc/ssh/ssh_host_dsa_key
chmod 600 /etc/ssh/ssh_host_ecdsa_key
chmod 600 /etc/ssh/ssh_host_ed25519_key
chkconfig --add sshd
chkconfig sshd on

service sshd start  2>&1 | tee -a ${LOG}
if [ $? -eq 0 ];then
echo -e "启动OpenSSH服务成功" "\033[32m Success\033[0m" | tee -a ${LOG}
echo ""
ssh -V
else
echo -e "启动OpenSSH服务失败，五秒后自动退出脚本" "\033[31m Failure\033[0m" | tee -a ${LOG}
sleep 5
exit
fi
echo ""

#删除源码包
rm -rf /tmp/$OPENSSL_VERSION*
rm -rf /tmp/$OPENSSH_VERSION*
rm -rf /tmp/$ZLIB_VERSION*
}

#脚本菜单
echo -e "\033[36m1: 升级OpenSSH\033[0m"
echo ""
echo -e "\033[36m2: 退出脚本\033[0m"
echo ""
read -p  "请输入对应数字后按回车开始执行脚本: " SELECT

if [ "$SELECT" == "1" ];then
clear
DOWNLOAD
OPENSSH
fi
if [ "$SELECT" == "2" ];then
echo ""
exit
fi
