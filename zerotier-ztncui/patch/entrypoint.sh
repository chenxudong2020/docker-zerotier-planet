#!/bin/sh

set -x 

# 配置路径和端口
ZEROTIER_PATH="/var/lib/zerotier-one"
APP_PATH="/app"
CONFIG_PATH="${APP_PATH}/config"
BACKUP_PATH="/bak"
ZTNCUI_PATH="${APP_PATH}/ztncui"
ZTNCUI_SRC_PATH="${ZTNCUI_PATH}/src"

# 启动 ZeroTier 和 ztncui
function start() {
    echo "Start ztncui and zerotier"
    cd $ZEROTIER_PATH && ./zerotier-one -p$(cat ${CONFIG_PATH}/zerotier-one.port) -d || exit 1
    nohup node ${APP_PATH}/http_server.js &> ${APP_PATH}/server.log & 
    cd $ZTNCUI_SRC_PATH && npm start || exit 1
}

# 检查文件服务器端口配置文件
function check_file_server() {
    if [ ! -f "${CONFIG_PATH}/file_server.port" ]; then
        echo "file_server.port does not exist, generating it"
        echo "${FILE_SERVER_PORT}" > ${CONFIG_PATH}/file_server.port
    else
        echo "file_server.port exists, reading it"
        FILE_SERVER_PORT=$(cat ${CONFIG_PATH}/file_server.port)
    fi
    echo "${FILE_SERVER_PORT}"
}

# 初始化 ZeroTier 数据
function init_zerotier_data() {
    echo "Initializing ZeroTier data"
    echo "${ZT_PORT}" > ${CONFIG_PATH}/zerotier-one.port
    cp -r ${BACKUP_PATH}/zerotier-one/* $ZEROTIER_PATH

    cd $ZEROTIER_PATH
    openssl rand -hex 16 > authtoken.secret
    ./zerotier-idtool generate identity.secret identity.public
}

# 检查并初始化 ZeroTier
function check_zerotier() {
    mkdir -p $ZEROTIER_PATH
    if [ "$(ls -A $ZEROTIER_PATH)" ]; then
        echo "$ZEROTIER_PATH is not empty, starting directly"
    else
        init_zerotier_data
    fi
}

# 初始化 ztncui 数据
function init_ztncui_data() {
    echo "Initializing ztncui data"
    cp -r ${BACKUP_PATH}/ztncui/* $ZTNCUI_PATH

    echo "Configuring ztncui"
    mkdir -p ${CONFIG_PATH}
    echo "${API_PORT}" > ${CONFIG_PATH}/ztncui.port
    cd $ZTNCUI_SRC_PATH
    echo "HTTP_PORT=${API_PORT}" > .env
    echo 'NODE_ENV=production' >> .env
    echo 'HTTP_ALL_INTERFACES=true' >> .env
    echo "ZT_ADDR=localhost:${ZT_PORT}" >> .env
    cp -v etc/default.passwd etc/passwd
    TOKEN=$(cat ${ZEROTIER_PATH}/authtoken.secret)
    echo "ZT_TOKEN=$TOKEN" >> .env
    echo "ztncui configuration successful!"
}

# 检查并初始化 ztncui
function check_ztncui() {
    mkdir -p $ZTNCUI_PATH
    if [ "$(ls -A $ZTNCUI_PATH)" ]; then
        echo "${API_PORT}" > ${CONFIG_PATH}/ztncui.port
        echo "$ZTNCUI_PATH is not empty, starting directly"
    else
        init_ztncui_data
    fi
}

check_file_server
check_zerotier
check_ztncui
start
