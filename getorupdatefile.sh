
#!/usr/bin/env bash
# 当前路径
PWD=`pwd`

cd -- ${PWD}

V_PORT=0
V_UUID=`uuid`
V_ALTERID=0
V_NETWORK="tcp"
V_EMAIL="smallflowercat1995@hotmail.com"
V_SCY="auto"
REPORT_DATE=$(TZ=':Asia/Shanghai' date '+%x %T')
F_DATE=$(TZ=':Asia/Shanghai' date '+%x %T' --date='6 hour')

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
    curl -L -H "Connection: keep-alive" -k ${URI_DOWNLOAD} -o ${FILE_NAME} -O

    # 解压
    tar xvf ${FILE_NAME} ; chmod -v +x ngrok

    # 删除
    rm -fv ${FILE_NAME}

    # 配置文件生成
    echo -e "tunnels:\n    ssh:\n        proto: tcp\n        addr: 22\n    v2ray:\n        proto: tcp\n        addr: ${V_PORT}\nversion: '2'\n" > ngrok.yml

    # 启动 ngrok
    ./ngrok start --all --authtoken "$NGROK_AUTH_TOKEN" --config ngrok.yml --log ngrok.log &

    # 等待
    sleep 10

    HAS_ERRORS=$(grep "command failed" < ngrok.log)

    if [[ -z "$HAS_ERRORS" ]]; then
      echo ""
      echo "=========================================="
      echo -e "To connect: \n$(grep -o -E "name=(.+)" < ngrok.log | sed 's; ;\n;g' | grep -v addr)"
      echo "=========================================="
    else
      echo "$HAS_ERRORS"
      exit 6
    fi

    N_ADDR=`grep -o -E "name=(.+)" < ngrok.log | grep v2ray | sed 's; ;\n;g;s;:;\n;g;s;//;;g' | tail -n 2 | head -n 1`
    N_PORT=`grep -o -E "name=(.+)" < ngrok.log | grep v2ray | sed 's; ;\n;g;s;:;\n;g' | tail -n 1`

    echo '{"v":"2","ps":"${REPORT_DATE}创建，${F_DATE}之前停止可能提前停止","add":"${N_ADDR}","port":"${N_PORT}","id":"${V_UUID}","aid":"${V_ALTERID}","scy":"${V_SCY}","net":"${V_NETWORK}","type":"none","host":"","path":"","tls":"","sni":"","alpn":""}' 

    # 解除环境变量
    unset  HAS_ERRORS NGROK_AUTH_TOKEN URI_DOWNLOAD FILE_NAME
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

# 生成配置文件
cat << EOF >> config.json
{
"log": {
  "access": "access.log",
  "error": "error.log",
  "loglevel": "info"
},
"inbounds": [
  {
    "port": ${V_PORT},
    "protocol": "vmess",
    "settings": {
      "udp": false,
      "clients": [
        {
          "id": "${V_UUID}",
          "alterId": ${V_ALTERID},
          "email": "${V_EMAIL}"
        }
      ],
      "allowTransparent": false
    },
    "streamSettings": {
      "network": "${V_NETWORK}"
    }
  }
],
"outbounds": [
  {
    "protocol": "freedom"
  },
  {
    "tag": "block",
    "protocol": "blackhole",
    "settings": {}
  }
],
"routing": {
  "domainStrategy": "IPIfNonMatch",
  "rules": []
}
}
EOF

    ./v2ray run -c config.json

    # 解除环境变量
    rm -rfv  ${FILE_NAME}

    # 解除环境变量
    unset DOWNLOAD URI_DOWNLOAD FILE_NAME
}


# 这里指定了1~10000区间，从中任取一个未占用端口号
get_random_port 1 10000
createUserNamePassword
getStartNgrok
getStartV2ray



unset PWD
