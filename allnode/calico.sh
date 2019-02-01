#!/bin/bash
#如果是安装第一个参数必须指定本机ip地址
IP=$1
#安装的服务名称
SERVICE_NAME=kube-calico.service
#etcd服务器地址
ETCD_ENDPOINTS=http://$IP:2379

CONTAINNER_NAME=calico-node

# 1表示启动 0未启动
function isAlive(){
	if docker exec $CONTAINNER_NAME echo hello>/dev/null ;then
		return 1
	fi 
	return 0
}
#停止服务
function stopCurrent(){
	$(statusCurrent)
	result=$?;
	if [ $result -eq 2 ];then
		echo "$SERVICE_NAME服务未安装,无需关闭"
		exit
	fi
	if [ $result -eq 0 ];then
	   echo "$SERVICE_NAME服务未启动,无需关闭"
	   exit
	fi
	echo 停止$SERVICE_NAME
	systemctl stop $SERVICE_NAME
	
}

#停止服务
function startCurrent(){
    statusCurrent
	statusResult=$?
	if [ $statusResult == 2 ];then
		echo "$SERVICE_NAME服务未安装,无需关闭"
		exit
	fi
	if [ $statusResult == 1 ];then
	   echo "$SERVICE_NAME服务未停止,无需启动"
	   exit
	fi
	echo 启动$SERVICE_NAME
    systemctl start $SERVICE_NAME
}
#卸载服务
function unistall(){
	$(statusCurrent)
	result=$?;
	if [ $result -eq 2 ];then
		echo "$SERVICE_NAME服务未安装,无需卸载"
		exit
	fi
	if [ $result -eq 1 ];then
		stopCurrent
	fi
	echo 开始卸载$SERVICE_NAME
    if [ -f /lib/systemd/system/$SERVICE_NAME ];then
	    echo 删除$SERVICE_NAME
		systemctl stop $SERVICE_NAME
		rm -rf /lib/systemd/system/$SERVICE_NAME
	fi

}
#打印所有状态 文本输出
function sysoStatus(){
    statusCurrent
	statusResult=$?
    if [ $statusResult == 2 ];then
	    echo $SERVICE_NAME未安装
	else	
		if [ $statusResult == 1 ];then
			echo $SERVICE_NAME运行中
		else
			echo $SERVICE_NAME 已停止
		fi;	
	fi
}
#获取状态 2 未安装 1运行中 0 已停止
function statusCurrent(){
	if [ ! -f /lib/systemd/system/$SERVICE_NAME ];then
	   return 2
	else
		isAlive
		if [ $? == 1 ];then
			return 1
		else
			return 0
		fi;	
	fi
}
#安装服务
function install(){
if [ -z $IP ];then
  "ip地址不能为空 启动请使用 apiserver.sh ip地址启动"
  exit
fi
echo 创建服务文件
cat <<EOF > /lib/systemd/system/$SERVICE_NAME
[Unit]
Description=calico node
After=docker.service
Requires=docker.service

[Service]
User=root
PermissionsStartOnly=true
ExecStart=/usr/bin/docker run --net=host --privileged --name=calico-node \
  -e ETCD_ENDPOINTS=$ETCD_ENDPOINTS \
  -e CALICO_LIBNETWORK_ENABLED=true \
  -e CALICO_NETWORKING_BACKEND=bird \
  -e CALICO_DISABLE_FILE_LOGGING=true \
  -e CALICO_IPV4POOL_CIDR=172.20.0.0/16 \
  -e CALICO_IPV4POOL_IPIP=off \
  -e FELIX_DEFAULTENDPOINTTOHOSTACTION=ACCEPT \
  -e FELIX_IPV6SUPPORT=false \
  -e FELIX_LOGSEVERITYSCREEN=info \
  -e FELIX_IPINIPMTU=1440 \
  -e FELIX_HEALTHENABLED=true \
  -e IP=$IP \
  -v /var/run/calico:/var/run/calico \
  -v /lib/modules:/lib/modules \
  -v /run/docker/plugins:/run/docker/plugins \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/log/calico:/var/log/calico \
  registry.cn-hangzhou.aliyuncs.com/imooc/calico-node:v2.6.2
ExecStop=/usr/bin/docker rm -f calico-node
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME
	
}

if [ -z "$1" ];then
	echo "请输入1个参数 参数1是etcd安装主机ip 或者 start|stop|status|u"
	exit
fi

if [ "$1" == "stop" ];then
    stopCurrent
elif [ "$1" == "start" ];then
	startCurrent
elif [ "$1" == "u" ];then	
	unistall
elif [ "$1" == "status" ];then	
	sysoStatus	
else
    paramCount=$#;
	if [ $paramCount != 1 ];then
	   echo 请输入1个参数 参数1是etcd安装主机ip 或者 start|stop|status|u
	   exit
	fi
    install
	echo "已经创建服务$SERVICE_NAME，停止服务使用 systemctl stop $SERVICE_NAME"
	echo "也可以使用当前脚本 $0 stop|start|u"
	echo "查看日志journalctl -f -u $SERVICE_NAME"
fi






