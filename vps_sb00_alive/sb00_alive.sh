#!/bin/bash
#老王原始脚本：https://github.com/eooce/Sing-box，支持老王的无交互四合一脚本保活
#yutian81修改脚本：https://github.com/yutian81/serv00-ct8-ssh/vps_sb00_alive，支持yutian81魔改无交互四合一保活
#魔改无交互四合一脚本一键安装：bash <(curl -s https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/vps_sb00_alive/main/sb00-sk5.sh)

# 定义颜色
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }

# 定义变量
SCRIPT_PATH="/root/sb00_alive.sh"  # 本脚本路径，不要改变文件名
SCRIPT_URL="https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/main/vps_sb00_alive/sb00-sk5.sh"  # yutian81魔改serv00无交互脚本
VPS_JSON_URL="https://raw.githubusercontent.com/yutian81/Wanju-Nodes/main/serv00-panel3/sb00ssh.json"  # vps登录信息json文件
REBOOT_URL="https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/main/reboot.sh"   # 仅支持重启yutian81魔改serv00有交互脚本
MAX_ATTEMPTS=5  # 最大尝试检测次数
ARGO_HTTP_CODE=""  # Argo 连接状态码

# 外部传入参数
export TERM=xterm
export DEBIAN_FRONTEND=noninteractive
export CFIP=${CFIP:-'www.visa.com.tw'}  # 优选域名或优选ip
export CFPORT=${CFPORT:-'443'}     # 优选域名或优选ip对应端口

# 根据对应系统安装依赖
install_packages() {
    if [ -f /etc/debian_version ]; then
        package_manager="DEBIAN_FRONTEND=noninteractive apt-get install -y"
    elif [ -f /etc/redhat-release ]; then
        package_manager="yum install -y"
    elif [ -f /etc/fedora-release ]; then
        package_manager="dnf install -y"
    elif [ -f /etc/alpine-release ]; then
        package_manager="apk add cronie jq"
    else
        red "不支持的系统架构！"
        exit 1
    fi
    $package_manager sshpass curl netcat-openbsd cron jq > /dev/null
}
install_packages

# 判断系统架构，添加对应的定时任务
add_cron_job() {
    local new_cron="*/5 * * * * /bin/bash $SCRIPT_PATH >> /root/00_keep.log 2>&1"
    local current_cron
    if crontab -l | grep -q "$SCRIPT_PATH" > /dev/null 2>&1; then
        red "定时任务已存在，跳过添加计划任务"
    else
        if [ -f /etc/debian_version ] || [ -f /etc/redhat-release ] || [ -f /etc/fedora-release ]; then
            (crontab -l; echo "$new_cron") | crontab -
        elif [ -f /etc/alpine-release ]; then
            if [ -f /var/spool/cron/crontabs/root ]; then
                current_cron=$(cat /var/spool/cron/crontabs/root)
            fi
            echo -e "$current_cron\n$new_cron" > /var/spool/cron/crontabs/root
            rc-service crond restart
        fi
        green "已添加定时任务，每5分钟执行一次"
    fi
}
add_cron_job

# 检测 TCP 端口
check_tcp_port() {
    local HOST=$1
    local VMESS_PORT=$2
    nc -zv "$HOST" "$VMESS_PORT" &> /dev/null
    return $?
}

# 检查 Argo 隧道状态
check_argo_status() {
    ARGO_HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}\n" "https://$ARGO_DOMAIN")
}

# 连接并执行远程命令的函数
run_remote_command() {
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" \
    "ps aux | grep \"$(whoami)\" | grep -v 'sshd\|bash\|grep' | awk '{print \$2}' | xargs -r kill -9 > /dev/null 2>&1 && \
    VMESS_PORT=$VMESS_PORT HY2_PORT=$HY2_PORT SOCKS_PORT=$SOCKS_PORT \
    SOCKS_USER=$SOCKS_USER SOCKS_PASS=\"$SOCKS_PASS\" \
    ARGO_DOMAIN=$ARGO_DOMAIN ARGO_AUTH=\"$ARGO_AUTH\" \
    NEZHA_SERVER=$NEZHA_SERVER NEZHA_PORT=$NEZHA_PORT NEZHA_KEY=$NEZHA_KEY \
    bash <(curl -Ls ${SCRIPT_URL})"
    #bash <(curl -Ls ${REBOOT_URL})  #使用此脚本无需重装节点，它将直接启动原本存储在服务器中的命令和配置文件，实现节点重启
}

# 下载服务器 JSON 文件
if ! curl -s "$VPS_JSON_URL" -o sb00ssh.json; then
    red "VPS 参数文件下载失败，尝试使用 wget 下载！"
    if ! wget -q "$VPS_JSON_URL" -O sb00ssh.json; then
        red "VPS 参数文件下载失败，请检查下载地址是否正确！"
        exit 1
    else
        green "VPS 参数文件通过 wget 下载成功！"
    fi
else
    green "VPS 参数文件通过 curl 下载成功！"
fi

# 处理服务器列表并遍历
process_servers() {
    local attempt=0 time=$(TZ="Asia/Hong_Kong" date +"%Y-%m-%d %H:%M")
    jq -c '.[]' "sb00ssh.json" | while IFS= read -r servers; do
        HOST=$(echo "$servers" | jq -r '.HOST')
        SSH_USER=$(echo "$servers" | jq -r '.SSH_USER')
        SSH_PASS=$(echo "$servers" | jq -r '.SSH_PASS')
        VMESS_PORT=$(echo "$servers" | jq -r '.VMESS_PORT')
        SOCKS_PORT=$(echo "$servers" | jq -r '.SOCKS_PORT')
        HY2_PORT=$(echo "$servers" | jq -r '.HY2_PORT')
        SOCKS_USER=$(echo "$servers" | jq -r '.SOCKS_USER')
        SOCKS_PASS=$(echo "$servers" | jq -r '.SOCKS_PASS')
        ARGO_DOMAIN=$(echo "$servers" | jq -r '.ARGO_DOMAIN')
        ARGO_AUTH=$(echo "$servers" | jq -r '.ARGO_AUTH')
        NEZHA_SERVER=$(echo "$servers" | jq -r '.NEZHA_SERVER')
        NEZHA_PORT=$(echo "$servers" | jq -r '.NEZHA_PORT')
        NEZHA_KEY=$(echo "$servers" | jq -r '.NEZHA_KEY')
        green "正在处理…… 服务器: $HOST 账户：$SSH_USER"

        while [ $attempt -lt $MAX_ATTEMPTS ]; do
            if ! check_tcp_port "$HOST" "$VMESS_PORT"; then
                red "TCP 端口 $VMESS_PORT 不通畅，休眠30秒后重试"
                sleep 30
                attempt=$((attempt + 1))
                continue
            fi
            check_argo_status
            if [ "$ARGO_HTTP_CODE" == "530" ]; then
                red "Argo 隧道不可用！状态码：$ARGO_HTTP_CODE，休眠30秒后重试"
                sleep 30
                attempt=$((attempt + 1))
                continue
            fi
            green "TCP 端口 $VMESS_PORT 通畅；Argo 正常，状态码：$ARGO_HTTP_CODE。服务器: $HOST 账户：$SSH_USER [$time]"
            break
        done

        if [ $attempt -ge $MAX_ATTEMPTS ]; then
            red "多次检测失败，尝试 SSH 连接远程执行命令。服务器: $HOST  账户：$SSH_USER  [$time]"
            if sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" -q exit; then
                green "SSH 连接成功。服务器: $HOST  账户：$SSH_USER  [$time]"
                output=$(run_remote_command "$HOST" "$SSH_USER" "$SSH_PASS" "$VMESS_PORT" "$HY2_PORT" "$SOCKS_PORT" "$SOCKS_USER" "$SOCKS_PASS" "$ARGO_DOMAIN" "$ARGO_AUTH" "$NEZHA_SERVER" "$NEZHA_PORT" "$NEZHA_KEY")
                if [ $? -eq 0 ]; then
                    green "远程命令执行成功，结果如下："
                    echo "$output"
                else
                    red "远程命令执行失败"
                fi
            else
                red "SSH 连接失败，请检查账户和密码。服务器: $HOST  账户：$SSH_USER  [$time]"
            fi
        fi
    done
}
process_servers
