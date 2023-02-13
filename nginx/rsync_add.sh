#!/bin/bash
# 添加 rsync
# 创建同步目录
# 添加 Vue 上下文

function rsync_add() {
sync_add=$(grep "\b$1\b" /etc/rsyncd.conf)
if [[ "$sync_add" != "" ]]
then
		return 0
		echo "rsync $1 已存在"
else
	cat <<EOF>> /etc/rsyncd.conf
[$1]
path = /home/service/$1
comment = $1
EOF
systemctl restart rsyncd
fi
}

function dir_add() {
if [ ! -d "/home/service/$1" ]; then
  mkdir -p /home/service/$1
fi
}

function restart_add() {
if [ ! -f "/home/service/$1/restart.sh" ]; then
    cat <<EOF> /home/service/$1/restart.sh
#!/bin/bash

pgrep -f $1.jar|xargs kill -9
cd /home/service/$1/
nohup java  -jar $1.jar >> /home/service/$1/nohup.out 2>&1 &
EOF
chmod +x /home/service/$1/restart.sh
fi
}

rsync_add $1
dir_add $1
restart_add $1
