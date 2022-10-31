#!/usr/bin/env bash
# install a minimal lxde without its recommended applications.
sudo apt update ; sudo apt-get install -y aptitude eatmydata aria2 catimg git micro locales curl uuid

# Sync date
date '+%Y-%m-%d %H:%M:%S'
sudo mv /etc/localtime /etc/localtime.bak.`date '+%Y-%m-%d_%H-%M-%S'`
sudo ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
sudo cat << EOF | sudo tee  /etc/timezone
Asia/Shanghai
EOF
date '+%Y-%m-%d %H:%M:%S'

# 当前路径
PWD=`pwd`

echo ${PWD}

# 环境变量
V_PORT=0
V_PROTOCOL=vmess
V_UUID=`uuid`
V_ALTERID=0
V_EMAIL="smallflowercat1995@hotmail.com"
V_NETWORK="tcp"
V_SCY="auto"
REPORT_DATE=`TZ=':Asia/Shanghai' date +'%Y-%m-%d %T'`
F_DATE=`date -d '${REPORT_DATE}' --date='6 hour' +'%Y-%m-%d %T'`

# 随机创建非占用端口
# 判断当前端口是否被占用，没被占用返回0，反之1
function Listening {
   TCPListeningnum=`netstat -an | grep ":$1 " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l`
   UDPListeningnum=`netstat -an | grep ":$1 " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l`
   (( Listeningnum = TCPListeningnum + UDPListeningnum ))
   if [ $Listeningnum == 0 ]; then
       echo "0"
   else
       echo "1"
   fi
}

#指定区间随机数
function random_range {
   shuf -i $1-$2 -n1
}

#得到随机端口
function get_random_port {
   templ=0
   while [ $V_PORT == 0 ]; do
       temp1=`random_range $1 $2`
       if [ `Listening $temp1` == 0 ] ; then
              V_PORT=$temp1
       fi
   done
   # echo "port=$V_PORT"
}

# 创建用户添加密码
createUserNamePassword(){

    # 判断用户名
    if [[ -z "$USER_NAME" ]]; then
      echo "Please set 'USER_NAME' for linux"
      exit 2
    fi

    sudo useradd -m $USER_NAME
    sudo adduser $USER_NAME sudo


    # 判断用户密码环境变量
    if [[ -z "$USER_PW" ]]; then
      echo "Please set 'USER_PW' for linux"
      exit 3
    fi

    echo "$USER_NAME:$USER_PW" | sudo chpasswd
    sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
    echo "Update linux user password !"
    echo -e "$USER_PW\n$USER_PW" | sudo passwd "$USER_NAME"

    # 判断用户hostname
    if [[ -z "$HOST_NAME" ]]; then
      echo "Please set 'HOST_NAME' for linux"
      exit 4
    fi

    sudo hostname $HOST_NAME

    unset USER_NAME USER_PW HOST_NAME
}

# 获取配置启动Trojan
getStartV2ray(){
    # 获取下载路径
    # https://github.com/v2fly/v2ray-core/releases/download/v5.1.0/v2ray-linux-64.zip
    DOWNLOAD=`curl -L 'https://github.com/v2fly/v2ray-core/releases' | sed 's;";\n;g;s;tag;download;g' | grep '/download/' | head -n 1`

    # 打印链接
    URI_DOWNLOAD="https://github.com${DOWNLOAD}/v2ray-linux-64.zip"
    echo ${URI_DOWNLOAD}

    # 文件名
    FILE_NAME=v2ray.zip

    # 下载
    curl -L -H "Connection: keep-alive" -k ${URI_DOWNLOAD} -o ${FILE_NAME} -O

    # 解压
    unzip -o ${FILE_NAME} -d $(echo $FILE_NAME | sed 's;.zip;;g') ; cd $(echo $FILE_NAME | sed 's;.zip;;g')

    # 解除环境变量
    rm -rfv  ${FILE_NAME}

    # 解除环境变量
    unset DOWNLOAD URI_DOWNLOAD FILE_NAME

# 生成配置文件
cat << EOF >> config.json
{
	"log": {
		"access": "access.log",
		"error": "error.log",
		"loglevel": "info"
	},
	"inbounds": [{
		"port": ${V_PORT},
		"protocol": "${V_PROTOCOL}",
		"settings": {
			"udp": false,
			"clients": [{
				"id": "${V_UUID}",
				"alterId": ${V_ALTERID},
				"email": "${V_EMAIL}"
			}],
			"allowTransparent": false
		},
		"streamSettings": {
			"network": "${V_NETWORK}"
		}
	}],
	"outbounds": [{
			"protocol": "freedom"
		},
		{
			"tag": "block",
			"protocol": "blackhole",
			"settings": {}
		}
	],
	"routing": {
		"strategy": "rules",
		"settings": {
			"rules": [{
				"type": "field",
				"ip": [
					"0.0.0.0/8",
					"10.0.0.0/8",
					"100.64.0.0/10",
					"127.0.0.0/8",
					"169.254.0.0/16",
					"172.16.0.0/12",
					"192.0.0.0/24",
					"192.0.2.0/24",
					"192.168.0.0/16",
					"198.18.0.0/15",
					"198.51.100.0/24",
					"203.0.113.0/24",
					"::1/128",
					"fc00::/7",
					"fe80::/10"
				],
				"outboundTag": "blocked"
			}]
		}
	}
}
EOF

    ./v2ray run -c config.json &

    # 等待
    sleep 5
}

# 获取配置启动Ngrok
getStartNgrok(){
    # 判断 Ngrok 环境变量
    if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
      echo "Please set 'NGROK_AUTH_TOKEN'"
      exit 5
    fi

    # Ngrok 下载链接
    URI_DOWNLOAD=https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz

    # 文件名
    FILE_NAME=ngrok-linux-amd64.tgz

    # 下载
    curl -L -H "Connection: keep-alive" -k ${URI_DOWNLOAD} -o ../${FILE_NAME} -O

    # 解压
    tar xvf ../${FILE_NAME} -C ../ ; chmod -v +x ../ngrok

    # 删除
    rm -fv ../${FILE_NAME}

    # 配置文件生成
    echo -e "tunnels:\n    ssh:\n        proto: tcp\n        addr: 22\n    v2ray:\n        proto: tcp\n        addr: ${V_PORT}\nversion: '2'\n" > ../ngrok.yml

    # 启动 ngrok
    ../ngrok start --all --authtoken "$NGROK_AUTH_TOKEN" --config ../ngrok.yml --log ../ngrok.log &

    # 等待
    sleep 10

    HAS_ERRORS=$(grep "command failed" < ../ngrok.log)

    if [[ -z "$HAS_ERRORS" ]]; then
      echo "=========================================="
      
      touch ../result.txt ; ls ../result.txt
      
      echo -e "$(grep -o -E "name=(.+)" < ../ngrok.log | sed 's; ;\n;g' | grep -v addr)" > ../result.txt
      echo -e "To connect: \nssh -o ServerAliveInterval=60 `grep -o -E "name=(.+)" < ../ngrok.log | grep ssh | sed 's; ;\n;g;s;:;\n;g;s;//;;g' | tail -n 2 | head -n 1` -p `grep -o -E "name=(.+)" < ngrok.log | grep ssh | sed 's; ;\n;g;s;:;\n;g' | tail -n 1`" >> ../result.txt
      
      N_ADDR=`grep -o -E "name=(.+)" < ../ngrok.log | grep v2ray | sed 's; ;\n;g;s;:;\n;g;s;//;;g' | tail -n 2 | head -n 1`
      N_PORT=`grep -o -E "name=(.+)" < ../ngrok.log | grep v2ray | sed 's; ;\n;g;s;:;\n;g' | tail -n 1`

      V_S='{"v":"2","ps":"'${REPORT_DATE}'创建，'${F_DATE}'之前停止可能提前停止","add":"'${N_ADDR}'","port":"'${N_PORT}'","id":"'${V_UUID}'","aid":"'${V_ALTERID}'","scy":"'${V_SCY}'","net":"'${V_NETWORK}'","type":"none","host":"","path":"","tls":"","sni":"","alpn":""}' 
      
      echo ${V_S} >> ../result.txt
      echo ${V_S} | base64 -w 0 | xargs echo vmess:// | sed 's; ;;g' >> ../result.txt
      
      echo "=========================================="
    else
      echo "$HAS_ERRORS"
      exit 6
    fi

    # 解除环境变量
    unset  HAS_ERRORS NGROK_AUTH_TOKEN URI_DOWNLOAD FILE_NAME
}

# 这里指定了1~10000区间，从中任取一个未占用端口号
get_random_port 1 10000
createUserNamePassword
getStartV2ray
getStartNgrok

# 手动模式配置默认编辑器
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/micro 40

# 手动修改编辑器
sudo update-alternatives --config editor

# Configuration for locales
sudo perl -pi -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
sudo perl -pi -e 's/en_GB.UTF-8 UTF-8/# en_GB.UTF-8 UTF-8/g' /etc/locale.gen
sudo locale-gen zh_CN ; sudo locale-gen zh_CN.UTF-8

cat << EOF | sudo tee /etc/default/locale
LANGUAGE=zh_CN.UTF-8
LC_ALL=zh_CN.UTF-8
LANG=zh_CN.UTF-8
LC_CTYPE=zh_CN.UTF-8
EOF

cat << EOF | sudo tee -a /etc/environment
export LANGUAGE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
EOF

cat << EOF | sudo tee -a $HOME/.bashrc
export LANGUAGE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
EOF

cat << EOF >> $HOME/.profile
export LANGUAGE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
EOF

sudo update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LANGUAGE=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8

locale ; locale -a ; cat /etc/default/locale

rm -rfv ../getorupdatefile.sh

source /etc/environment $HOME/.bashrc $HOME/.profile
