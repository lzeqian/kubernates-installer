#!/bin/bash
#如果是安装第一个参数必须指定本机ip地址
IP=$1
#安装的服务名称
SERVICE_NAME=kube-apiserver.service
#运行的程序名称
BIN_NAME=kube-apiserver
#etcd服务器地址
ETCD_ENDPOINTS=http://$IP:2379

# 1表示启动 0未启动
function isAlive(){
	if ps -ef | grep $BIN_NAME |grep -v grep>/dev/null ;then
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
	if [ -f /lib/systemd/system/$SERVICE_NAME ];then
		systemctl stop $SERVICE_NAME
	fi
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
	if [ -f /lib/systemd/system/$SERVICE_NAME ];then
		systemctl start $SERVICE_NAME
		exit
	fi
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
		systemctl disable $SERVICE_NAME
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
cat <<EOF > /lib/systemd/system/$SERVICE_NAME
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
[Service]
ExecStart=`which $BIN_NAME` \
  --admission-control=NamespaceLifecycle,LimitRanger,DefaultStorageClass,ResourceQuota,NodeRestriction \
  --insecure-bind-address=0.0.0.0 \
  --kubelet-https=false \
  --service-cluster-ip-range=10.68.0.0/16 \
  --service-node-port-range=20000-40000 \
  --etcd-servers=$ETCD_ENDPOINTS \
  --enable-swagger-ui=true \
  --allow-privileged=true \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/lib/audit.log \
  --event-ttl=1h \
  --v=2
Restart=on-failure
RestartSec=5
Type=notify
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME
	
}

if [ -z "$1" ];then
	echo "必须传入一个参数"
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
	if [ -f /lib/systemd/system/$SERVICE_NAME ];then
	    read -r -p "$SERVICE_NAME已安装 是否卸载,重新安装? [Y/n] " input
		case $input in
		[yY])
		  unistall
		  ;;
		*)
		  exit
		  ;;
		esac	
	fi
    install
	echo "已经创建服务$SERVICE_NAME，停止服务使用 systemctl stop $SERVICE_NAME"
	echo "也可以使用当前脚本 $0 stop|start|u"
	echo "查看日志journalctl -f -u $BIN_NAME"
fi



