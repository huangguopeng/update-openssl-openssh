OpenSSL、OpenSSH一般官方每年会更新两次，修复已知安全漏洞和各种程序Bug。随着越来越多的企业对安全意识的提高，一般每年也会内部开展两次安全整改检查工作，其中OpenSSL、OpenSSH漏洞是企业安全扫描系统中最常见的风险项之一。为方便升级软件，写下一键升级脚本自用，脚本没什么技术含量，各种判断和命令堆叠，有需要的朋友可以参考。


wget --no-check-certificate http://zlib.net/zlib-1.2.11.tar.gz


wget --no-check-certificate https://www.openssl.org/source/openssl-1.0.2t.tar.gz


wget --no-check-certificate https://openbsd.hk/pub/OpenBSD/OpenSSH/portable/openssh-8.1p1.tar.gz

yum -y install vim gcc wget make pam-devel

wget https://github.com/huangguopeng/update-openssl-openssh/archive/master.zip


