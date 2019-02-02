#!/bin/bash
MASTER_IP=$1
#安装的服务名称
SERVICE_NAME=kube-dns

# 1表示启动 0未启动
function isAlive(){
    aliveResult=`kubectl -n kube-system get services | grep kube-dns`
	if [ -n "$aliveResult" ] ;then
		return 1
	fi 
	return 0
}


#卸载服务
function unistall(){
	$(isAlive)
	result=$?;
	if [ $result -eq 1 ];then
		echo 开始卸载$SERVICE_NAME
		kubectl delete -f conf/kube-dns.yaml
	else
        echo 服务未安装无需卸载	
	fi
}

#安装服务
function install(){
    rm -rf kube-dns1.yaml
    sed -e "s/{{MASTER_IP}}/$MASTER_IP/" conf/kube-dns.yaml> conf/kube-dns1.yaml
	kubectl create -f conf/kube-dns1.yaml
	
}

if [ -z "$1" ];then
	echo "必须配置参数1 masterip   或者传入卸载：u等命令"
	exit
fi

if [ "$1" == "u" ];then	
	unistall	
else
	$(isAlive)
	result=$?;
	if [ $result -eq 1 ];then
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
	echo "已经创建服务$SERVICE_NAME，停止服务使用 kubectl delete -f conf/kube-dns.yaml"
	echo "也可以使用当前脚本 $0 u 卸载"
	echo "查看日志 请先kubectl -n kube-system get pods -o wide 找到安装的主机 使用docker logs查看"
fi




