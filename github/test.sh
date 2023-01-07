#!/bin/bash

version=`cat /etc/issue |awk '{print $1}' `
jiagou=`uname -m |awk '{print}' `

v2ray_path='/usr/local/etc/v2ray'
caddy_path='/etc/caddy/Caddyfile'
web_path='/var/www/html'

check_v2ray=`systemctl is-active v2ray |awk '{print $1}'`
check_caddy=`systemctl is-active caddy |awk '{print $1}'`
check_bbr=`lsmod |grep bbr |awk 'NR==1{print $1}'`

BBR(){

if [ $check_bbr = "tcp_bbr" ]
then
	echo -e "\e[032m BBR加速已开启\e[0m"
else
echo net.core.default_qdisc=fq >> /etc/sysctl.conf >dev/
null
echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf >/dev/null
sysctl -p

fi


}


Check_service(){

if [ $check_v2ray = "active" ]
then
        echo -e "\n\e[032m v2ray服务正在运行中...\e[0m\n"
else
        echo -e "\n\e[031m v2ray服务正在运行失败请检查配
置\e[0m\n"
fi

if [ $check_caddy = "active" ]
then
        echo -e "\n\e[032m caddy服务正在运行中...\e[0m\n"
else
        echo -e "\n\e[031m caddy服务运行失败请检查配置\e[0m\n"
fi

cat /usr/local/etc/v2ray/log.txt

}

install_caddy(){

for ((;;))
do
if [ -f $caddy_path ]
then
        echo "caddy已安装"
        break
else
        echo -e "\n\e[032m正在安装caddy...\e[0m\n"
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
sleep 3

fi
done

cat << EOF >$caddy_path

{
        order reverse_proxy before route
        admin off
        log {
                output file /var/log/caddy/error.log
                level ERROR
        }
        email zzz@gmail.com
}

:443, $domain {
        tls {
                ciphers TLS_AES_256_GCM_SHA384 TLS_AES_128_GCM_SHA256 TLS_CHACHA20_POLY1305_SHA256 TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
                curves x25519 secp521r1 secp384r1 secp256r1
                alpn http/1.1 h2
        }

    @vws {
                path /$path
                header Connection *Upgrade*
                header Upgrade websocket
        }
        reverse_proxy @vws 127.0.0.1:$port

        @host {
                host $domain
        }
        route @host {
                header {
                        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
                }
                file_server {
                        root /var/www/html
                }
        }
}
EOF

rm -rf /var/www/html/index.html

wget https://github.com/ioi80/tt/raw/main/3DCEList-master.zip

unzip 3DCEList-master.zip

rm -rf /var/www/html/3DCEList-master.zip

systemctl restart caddy
echo "caddy安装完成!"
sleep 2
}

#v2ray安装程序
install_v2ray(){
check_install

bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

read -p "请输入解析好了的域名:" domain
read -p "请输入端口(默认443或随机生成):" port
if [ -z $port ]
then
	port=`date +%N%s |cut -c 1-4` 
else
	echo "添加成功"
fi
read -p "请 输 入 uuid（ 默 认 自 动 生 成 ):" uuid
if [ -z $uuid  ]
then
	uuid=`uuidgen` 
	
else
	echo "添加成功:"
	
fi
read -p "请 输 入伪装路径默 认 自 动 生 成 ):" path
if [ -z $path ]
then
	path=`date +%s%N |md5sum |cut -c 1-8` 
else
	echo "添加成功"
fi

touch /usr/local/etc/v2ray/log.txt
echo -e "\e[033m vemss配置:\n域名:$domain \n端口:$port \nuuid:$uuid \n伪装路径:$path \e[0m"  >/usr/local/etc/v2ray/log.txt 

cat << EOF >/usr/local/etc/v2ray/config.json

{
  "inbounds": [
    {
      "port": $port,
      "listen":"127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "/$path"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
sleep 5
echo -e "\n\e[032m vemss安装完成\e[0m\n"
install_caddy
systemctl enable v2ray
systemctl restart v2ray
systemctl enable caddy
systemctl restart caddy


}


Start(){

	while :
	do
	echo -e '\e[032m
	
	1.vmess+ws+caddy
	2.trojan-go+ws+nginx
	3.查看配置信息
	4.hystria
	5.开启自带BBR加速
	6.退出
	\e[0m
	'
	read -p "请输入你的选择(1-6):" input
	case $input in
		1)
		        install_v2ray
		        continue
			;;
		2)
			echo "trojan-go"
			continue
			;;
		3)
			Check_service
			continue
			;;
		4)
			echo "hystria"
			continue
			;;
		5)
			bbr
			continue
			;;
		6)
			exit
			;;
	esac
done

}
Start


