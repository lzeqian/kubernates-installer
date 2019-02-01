if [ -z "$1" ];then
	echo "请输入1个参数 参数1是api-server主机ip "
	exit
fi
IP=$1
if [ "$1" == "clear" ];then
   rm -rf ~/.kube/config
   exit
 fi 
#!/bin/bash
if [ ! -f ~/.kube/config ];then
    #指定apiserver地址（ip替换为你自己的api-server地址）
	kubectl config set-cluster kubernetes  --server=http://$IP:8080
	#指定设置上下文，指定cluster
	kubectl config set-context kubernetes --cluster=kubernetes
	#选择默认的上下文
	kubectl config use-context kubernetes
fi;

