#!/bin/bash
#如果是安装第一个参数必须指定本机ip地址
MASTER_IP=$2
#当前机器的ip
NODE_IP=$1

#安装的服务名称
SERVICE_NAME=kubelet.service
#运行的程序名称
BIN_NAME=kubelet 
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
	    rm -rf /etc/kubernetes/kubelet.kubeconfig
		rm -rf /etc/cni/net.d/10-calico.conf
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
mkdir -p /var/lib/kubelet
mkdir -p /etc/kubernetes
mkdir -p /etc/cni/net.d
sed -e "s/{{MASTER_IP}}/$MASTER_IP/" conf/kubelet.kubeconfig> /etc/kubernetes/kubelet.kubeconfig
cp conf/10-calico.conf /etc/cni/net.d/
sed -i "s/{{ETCD_ENDPOINTS}}/$ETCD_ENDPOINTS/" /etc/cni/net.d/10-calico.conf
sed -i "s/{{MASTER_IP}}/$MASTER_IP/" /etc/cni/net.d/10-calico.conf


cat <<EOF > /lib/systemd/system/$SERVICE_NAME
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/var/lib/kubelet
ExecStart=`which $BIN_NAME` \
  --address=$NODE_IP \
  --hostname-override=$NODE_IP \
  --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/imooc/pause-amd64:3.0 \
  --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \
  --network-plugin=cni \
  --cni-conf-dir=/etc/cni/net.d \
  --cni-bin-dir=$BIN_PATH \
  --cluster-dns=10.68.0.2 \
  --cluster-domain=cluster.local. \
  --allow-privileged=true \
  --fail-swap-on=false \
  --logtostderr=true \
  --v=2
#kubelet cAdvisor 默认在所有接口监听 4194 端口的请求, 以下iptables限制内网访问
ExecStartPost=/sbin/iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 4194 -j ACCEPT
ExecStartPost=/sbin/iptables -A INPUT -s 172.16.0.0/12 -p tcp --dport 4194 -j ACCEPT
ExecStartPost=/sbin/iptables -A INPUT -s 192.168.0.0/16 -p tcp --dport 4194 -j ACCEPT
ExecStartPost=/sbin/iptables -A INPUT -p tcp --dport 4194 -j DROP
Restart=on-failure
RestartSec=5

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



