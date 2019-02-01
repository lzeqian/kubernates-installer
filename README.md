# kubernates-installer
简易化安装kubernates
## 下载当前源码包
  ```bash
    git clone https://github.com/lzeqian/kubernates-installer.git
  ```
  注意：
  >master和worker都需要下载源码包
  
## 下载kubernate安装二进制文件
 下载包将近200M 下载地址：[百度盘](https://pan.baidu.com/s/11PVfCSjmIUKwftaQlQ3l1g)
  将下载二进制包kubernetes-bins.tar.gz，拷贝到源码 soft目录

注意：
>1. 不能修改二进制名称
>2. 二进制必须拷贝到soft目录
>3. master和worker都需要下载二进制包
 
## 安装master

1. 进入clone的kubernates-installer目录
2. 执行安装命令 
   ./manager.sh 本机ip
   
其他命令
- 查看所有manger服务状态 : ./manager.sh status
- 启动/停止 manager所有服务 :./manager.sh start|stop
- 卸载manager所有服务   ：./manager.sh u
 

## 安装worker
每一台worker主机执行
1. 进入clone的kubernates-installer目录
2. 执行安装命令 
   ./worker.sh 本机ip masterip
   
其他命令
- 查看所有manger服务状态 : ./worker.sh status
- 启动/停止 manager所有服务 :./worker.sh start|stop
- 卸载manager所有服务   ：./worker.sh u
