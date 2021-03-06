#!/bin/bash
#如果是安装第一个参数必须指定本机ip地址
MASTER_IP=$2
#当前机器的ip
NODE_IP=$1

#安装的服务名称
SERVICE_NAME=kube-proxy.service
#运行的程序名称
BIN_NAME=kube-proxy 
#etcd服务器地址
ETCD_ENDPOINTS=http:\\/\\/$MASTER_IP:2379

BIN_PATH=`pwd`/soft/kubernetes-bins


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
		echo "$SERVICE_NAME服务未安装,无需启动"
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
#服务是否开机启动
function chkConfig(){
	statusCurrent
	statusResult=$?
	if [ $statusResult == 2 ];then
		echo "$SERVICE_NAME服务未安装,无法设置"
		exit
	fi
    if [ $1 == "on" ];then
		echo "设置$SERVICE_NAME为开机启动"
		systemctl enable $SERVICE_NAME
	else
	    echo "关闭$SERVICE_NAME为开机启动"
		systemctl disable $SERVICE_NAME
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
		echo 删除$SERVICE_NAME配置文件
	    rm -rf /etc/kubernetes/kube-proxy.kubeconfig
	    echo 删除$SERVICE_NAME
		systemctl disable $SERVICE_NAME
		rm -rf /lib/systemd/system/$SERVICE_NAME
	fi

}

#安装服务
function install(){
if [ -z $NODE_IP -o -z $MASTER_IP ];then
  echo "ip地址不能为空 启动请使用 apiserver.sh ip地址启动"
  exit
fi
mkdir -p /var/lib/kube-proxy
sed -e "s/{{MASTER_IP}}/$MASTER_IP/" conf/kube-proxy.kubeconfig> /etc/kubernetes/kube-proxy.kubeconfig



cat <<EOF > /lib/systemd/system/$SERVICE_NAME
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
[Service]
WorkingDirectory=/var/lib/kube-proxy
ExecStart=$BIN_PATH/kube-proxy \
  --bind-address=$NODE_IP \
  --hostname-override=$NODE_IP \
  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig \
  --logtostderr=true \
  --v=2
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOF
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME
	
}

if [ -z "$1" ];then
	echo "必须配置参数1 本机ip ，参数2 master主机ip 或者传入start|stop|u等命令"
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
elif [ "$1" == "on" ];then	
	chkConfig "on"
elif [ "$1" == "off" ];then	
	chkConfig "off"		
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
		accCount=$#
		if [ $accCount != 2 ];then
			echo 必须配置参数1 本机ip ，参数2 master主机ip
			exit
		fi
	fi
    install
	echo "已经创建服务$SERVICE_NAME，停止服务使用 systemctl stop $SERVICE_NAME"
	echo "也可以使用当前脚本 $0 stop|start|u"
	echo "查看日志journalctl -f -u $BIN_NAME"
fi




