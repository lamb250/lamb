#!/bin/bash
Green(){
	echo -e "\e[032m $1 \e[0m"
}
Blue(){
        echo -e "\e[034m $1 \e[0m"
}
Yellow(){
	echo -e "\e[033 $1 \e[0m"
}
Red(){
	echo -e "\e[031m $1 \e[0m"
}

v2ray_path="/usr/local/etc/v2ray/config.json"
caddy_path="/etc/caddy/Caddyfile"
check_bbr=`lsmod | grep bbr |awk 'NR==1{print $1}'`

v2ray_service=`systemctl is-active v2ray |awk '{print $1}'`
caddy_service=`systemctl is-active caddy |awk '{print $1}'`
Check_service(){

	if [ $v2ray_service = "active" ]
	then
	  Green v2ray服务运行中
	else
	  Red v2ray服务运行失败
	fi

	if [ $caddy_service = "active" ]
	then
          Green  caddy服务运行中
	else
	  Red caddy服务运行失败
	fi

	cat /usr/local/etc/v2ray/log.txt
}
Get(){
	read -p "请 输 入 解 析 好 了 的 域 名 :" domain
	read -p "请 输 入 端 口 (默 认 443或 随 机 生 成 ):" port
	if [ -z $port ]
	then
		        port=`date +%N%s |cut -c 1-4`
	fi
	read -p "请  输  入  uuid（  默  认  自  动  生  成  ):" uuid
	if [ -z $uuid  ]
	then
		        uuid=`uuidgen`

	fi
	read -p "请  输  入 伪 装 路 径 默  认  自  动  生  成  ):" path
	if [ -z $path ]
	then
		        path=`date +%s%N |md5sum |cut -c 1-8`

	fi

	V2ray_config
	
	touch /usr/local/etc/v2ray/log.txt
	echo -e "\e[033m vemss配 置 :\n域 名 :$domain \n端 口 :$port \nuuid:$uuid \n伪 装 路 径 :/$path \e[0m"  >/usr/local/etc/v2ray/log.txt

}
V2ray_config(){
	cat << EOF >$v2ray_path
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
}

Caddy_config(){
	cat << EOF >$caddy_path
{
	order reverse_proxy before route
	admin off
		log {
				output file /var/log/caddy/error.log
						level ERROR
							}
	email 123@gmail.com
}

:443, $domain { 
	tls {
		ciphers TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256 TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
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
sleep 5
}

Check_install(){
	if [ ! -f $v2ray_path ] && [ ! -d /etc/systemd/system/v2ray.service.d ]
	then
		Green 正在安装...
		bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
		Get
                V2ray_config
	else
		Red "v2ray已安装"
	
	fi

	if [ ! -f $caddy_path ]
	then
		Green caddy安装中...
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
systemctl restart caddy
Green caddy安装完成!
sleep 8
Caddy_config
else
	Caddy_config
	Green caddy 已安装!

	sleep 8
	fi
}
Web_install(){
while :
do
Green '
1.3DCEList-master
2.WebGL-Fluid-Simulation
3.Spotify-Landing-Page-Redesign-master
4.website2
5.photogenic
6.退出
'
cd /var && mkdir www && cd www && mkdir html && cd html
read -p "请选择序号(1-6):" p
case $p in
1)
rm -rf /var/www/html/*
wget https://github.com/ioi80/tt/raw/main/3DCEList-master.zip
unzip 3DCEList-master.zip
continue
;;
2)
rm -rf /var/www/html/*
wget https://github.com/ioi80/tt/raw/main/WebGL-Fluid-Simulation-master.zip
unzip WebGL-Fluid-Simulation-master.zip
continue
;;
3)
rm -rf /var/www/html/*
wget https://github.com/ioi80/tt/raw/main/Spotify-Landing-Page-Redesign-master.zip
unzip Spotify-Landing-Page-Redesign-master.zip
continue
;;
4)
rm -rf /var/www/html/*
wget https://github.com/jinwyp/one_click_script/raw/master/download/website2.zip
unzip website2.zip
continue
;;
5)
rm -rf /var/www/html/*
wget https://github.com/ioi80/tt/raw/main/photogenic.zip
unzip photogenic.zip
continue
;;
6)
exit
;;
esac
done
systemctl restart caddy
Green 静态网页安装完成!
sleep 8
}

BBR(){
	echo $check_bbr >/dev/null
	if [ $check_bbr != "tcp_bbr" ]
	then
		Green 正在启动BBR加速
		echo net.core.default_qdisc=fq >> /etc/sysctl.conf >/dev/null
		        echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf >/dev/null
			        sysctl -p >/dev/null
	else
		Green BBR加速已启动
	fi
}

Menu(){
	while :
	do
	Green '
	1.安装vmess+ws+caddy
	2.开启BBR
	3.修改配置信息
	4.查看配置信息以及服务运行状态
	5.放行指定端口
        6.安装静态网页
	7.退出
	'
	read -p "请输入序号(1-6):" number	
	case $number in

		1)
			Check_install
			continue
			;;
		2)
			BBR
			continue
			;;
		3)
			Get
                        continue
			;;
		4)
			Check_service
			continue
			;;
		5)
			read -p "输入要放行的端口(443、80端口已放行):" port
                        iptables -I INPUT -p tcp --dport $port -j ACCEPT >/dev/null
			iptables -I INPUT -p tcp --dport 80 -j ACCEPT >/dev/null
			iptables -I INPUT -p tcp --dport 443 -j ACCEPT >/dev/null
			iptables-save >/dev/null
                        systemctl restart caddy
                        systemctl restart v2ray
			Green $port端口已放行
			continue
			;;
		6)
			Web_install
                        continue
			;;
                7)
                        exit
                        ;;
	esac
done
}

Menu


