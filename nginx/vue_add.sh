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
path = /home/nginx/web_root/$1
comment = $1
EOF
fi

}

function dir_add() {
if [ ! -d "/home/nginx/web_root/$1" ]; then
  mkdir -p /home/nginx/web_root/$1
  chown -R nobody /home/nginx/web_root/
fi
}

function nginx_add() {
result=$(grep "\b$1\b" /usr/local/nginx/conf.d/ssl.conf)
if [[ "$result" != "" ]]
then
	exit 0
	echo "Nginx $1 已存在"
else
cat <<EOF> /tmp/vhosts.file
	location /$1 {
	root /home/nginx/web_root;
	index  index.html index.htm;
	try_files \$uri \$uri/ /$1/index.html;
	}
EOF
fi


sed -i '/add_nginx_location/ r /tmp/vhosts.file'  /usr/local/nginx/conf.d/ssl.conf
}

function pr_add {
chown -R nobody /home/nginx/web_root/
}

rsync_add $1
dir_add $1
nginx_add $1
pr_add
