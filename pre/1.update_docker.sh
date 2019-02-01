#!/bin/bash

#判断是否已经安装了docker
if docker -v>/dev/null 2>&1 ;then
	read -r -p "您已经安装了docker是否卸载重装 y/n  ：" input;
	case $input in
		[yY])
			yum remove docker docker-engine docker-common docker-ce -y
			wget https://download.docker.com/linux/centos/docker-ce.repo && mv -f docker-ce.repo /etc/yum.repos.d/
			yum install docker-ce -y
		;;
	esac	
fi



#未启动docker 重启docker
if ! docker info>/dev/null 2>&1 ;then 
	systemctl start docker
fi
echo ------------显示docker信息 ---------------------
docker -v
