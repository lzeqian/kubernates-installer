#!/bin/bash
NODE_IP=$1
MASTER_IP=$2
if [ -z "$1" ];then
	echo "必须配置参数1：本机ip,配置参数2：master机器ip 或者传入start|stop|u等命令"
	exit
fi
if [ "$1" == "stop" -o "$1" == "start" -o "$1" == "u" -o "$1" == "status" -o "$1" == "on" -o "$1" == "off"  ];then
	bash allnode/calico.sh $1
	bash worker/kublet.sh $1
	if [ "$1" == "u" ];then
		./kubectl.sh clear
	fi;
else
	echo -----------步骤1.重新安装docker-ce-----------------
	bash pre/1.update_docker.sh
	echo -----------步骤2. 设置系统参数-----------------------------------------
	bash pre/2.update_system_param.sh
	echo -----------步骤3. 设置系统参数 设置环境变量 可以执行执行各种命令----------------
	bash common.sh
	echo -----------步骤4. 部署CalicoNode----------------
	bash manager/calico.sh $MASTER_IP
	echo -----------步骤5. 配置kubectl命令----------------
	bash ./kubectl.sh $MASTER_IP
	echo -----------步骤6. 配置kubelet（工作节点）----------------
	bash worker/kublet.sh $NODE_IP $MASTER_IP
fi


