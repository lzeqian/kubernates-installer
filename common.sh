#解压kubernate软件
echo 解压k8s软件包。。。。
echo ---------------------------------------
if [ ! -d ./soft/kubernetes-bins ];then
  cd soft
  if [ ! -f ./kubernetes-bins.tar.gz ];then
	echo "安装失败，请下载二进制安装包，置于soft目录"
	echo "具体下载 参考：https://github.com/lzeqian/kubernates-installer"
	exit
  fi;
  tar zxvf kubernetes-bins.tar.gz
  cd ..
fi
echo 删除之前历史软连接。。。。
echo ---------------------------------------
dir=`ls ./soft/kubernetes-bins/`
#删除之前软连接
for i in $dir 
do
 rm -rf /usr/local/bin/$i
done
echo /usr/local/bin/目录创建软连接。。。。
echo ---------------------------------------
#bin目录创建软连接
ln -s `pwd`/soft/kubernetes-bins/* /usr/local/bin/

