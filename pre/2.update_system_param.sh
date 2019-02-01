#!/bin/bash
#
# 如果存在ExceStartPort删除
# 找到ExecStart=xxx，在这行上面加入一行，内容如下
# ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT
#

systemcttsPost=`grep -n ExecStartPost= /lib/systemd/system/docker.service`
execDelete=$?
if [ $execDelete == 0 ]; then
   echo 删除遗留参数 ExecStartPoat
   sed -i `expr $(grep -n ExecStartPost= /lib/systemd/system/docker.service | cut -d: -f1)`'d' /lib/systemd/system/docker.service
fi 
echo 执行添加参数iptables
sed -i `expr $(grep -n ExecStart= /lib/systemd/system/docker.service | cut -d: -f1) - 1`'a\ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT' /lib/systemd/system/docker.service
systemctl daemon-reload
service docker restart
#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
#设置系统参数 - 允许路由转发，不对bridge的数据进行处理
rm -rf /etc/sysctl.d/k8s.conf
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
#生效配置文件
sysctl -p /etc/sysctl.d/k8s.conf
echo 请自行配置好正确的/etc/hosts文件
