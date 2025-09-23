#!/bin/bash
###### 这里要写绝对路径
REPO_DIR="$1"
DATA_DIR="$REPO_DIR/package-data"
function run_in_parallel {
local max_jobs=10
    while [ $(jobs -p | wc -l) -ge "$max_jobs" ]; do
        sleep 1
    done
    "$@" &
}

######阶段1：检查data目录下的.deb.package文件，去仓库验证是否有对应的.deb
######如果有，则对比时间戳，若仓库的新于.deb.package，则更新，否则return
######如果没有，则删除此文件
mkdir -p $DATA_DIR


cd $DATA_DIR

function check_deb_exist(){
DEB_PATH=`echo ".${DEB_PACKAGE_INFO_PATH%%.package}"` 
if [ -e $DEB_PATH ];then
	if [ "$DEB_PACKAGE_INFO_PATH"  -ot "$DEB_PATH" ] ;then
		###时间戳校验
		echo "$DEB_PATH在生成package文件后发生了改变，将重新生成"
		rm $DEB_PACKAGE_INFO_PATH
	fi

else
echo "$DEB_PATH 已下架"
rm $DEB_PACKAGE_INFO_PATH
#####删除已下架的包

fi

}

for DEB_PACKAGE_INFO_PATH in `find . -name '*.deb.package'`;do

run_in_parallel check_deb_exist


done
wait


##### 阶段2：反查deb，如果有.deb.package，则跳过，否则生成
cd $REPO_DIR

function generate_package_info(){
if [ -e $DATA_DIR/$DEB_PATH.package ];then
return

else
mkdir -p $DATA_DIR/`dirname $DEB_PATH`
apt-ftparchive packages $DEB_PATH > $DATA_DIR/$DEB_PATH.package && echo "新包 $DEB_PATH 已生成package文件"

fi

}
for DEB_PATH in `find . -name '*.deb'`;do

run_in_parallel generate_package_info


done
wait 




find $DATA_DIR -type d -empty -exec rm -rf {} \;

##### 合成Packages
rm $REPO_DIR/Packages
cd $DATA_DIR
for DEB_PACKAGE_INFO_PATH in `find . -name '*.deb.package'`;do
cat $DEB_PACKAGE_INFO_PATH >> $REPO_DIR/Packages
done


apt-ftparchive release $REPO_DIR/ > $REPO_DIR/Release 