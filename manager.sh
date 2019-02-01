#!/bin/bash
NODE_IP=$1
MASTER_IP=$1
if [ -z "$1" ];then
	echo "必须配置参数1 本机ip 或者传入start|stop|u等命令"
	exit
fi

if [ "$1" == "stop" -o "$1" == "start" -o "$1" == "u" -o "$1" == "status" -o "$1" == "on" -o "$1" == "off" ];then
	bash manager/etcd.sh $1
	bash manager/apiserver.sh $1
	bash manager/controller.sh $1
	bash manager/scheduler.sh  $1
	bash allnode/calico.sh  $1
	if [ "$1" == "u" ];then
		./kubectl.sh clear
	fi;
else
	echo -----------步骤1.重新安装docker-ce-----------------
	bash pre/1.update_docker.sh
	echo -----------步骤2. 设置系统参数-----------------------------------------
	bash pre/2.update_system_param.sh
	echo -----------步骤3. 设置系统参数 设置环境变量 可以执行执行各种命令----------------
	exec ./common.sh
	echo -----------步骤4. 部署ETCD----------------
	bash manager/etcd.sh $NODE_IP
	echo -----------步骤5. 部署APIServer----------------
	bash manager/apiserver.sh $NODE_IP
	echo -----------步骤6. 部署ControllerManager----------------
	bash manager/controller.sh $NODE_IP
	echo -----------步骤7. 部署Scheduler----------------
	bash manager/scheduler.sh  $NODE_IP
	echo -----------步骤8. 部署CalicoNode----------------
	bash allnode/calico.sh  $MASTER_IP
	echo -----------步骤9. 配置kubectl命令----------------
	bash ./kubectl.sh $MASTER_IP
fi














