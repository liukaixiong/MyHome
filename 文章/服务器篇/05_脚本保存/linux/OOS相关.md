# 	OOS复制迁移

## 上传文件夹到OOS

```shell
if [ -z "$1" ];then
  echo "请传入需要备份的文件夹!"
else
filename=$1
# 文件路径
file_path=/data/appdatas/cat/bucket/dump/dump
# oos路径
oos_path=oss://linux-data/log/jay-monitor
echo "$filename.zip  -  $oos_path/$filename.zip"
echo "开始压缩文件..." 
echo "zip -r -f -q $filename.zip $file_path/$filename"
zip -r -m -q $filename.zip $file_path/$filename
echo "开始上传文件 :  ./ossutil64 appendfromfile $filename.zip $oos_path/$filename.zip" 
./ossutil64 appendfromfile $filename.zip $oos_path/$filename.zip
current_path=`pwd`
echo "删除当前文件夹: rm -rf  $current_path/$1.zip"
rm -rf $current_path/$1.zip
fi
```

## 上传文件到oos

```shell
if [ -z "$1" ];then
  echo "请传入需要备份的文件夹!"
else
oos_path=oss://linux-data/log/jay-monitor/
./ossutil64 appendfromfile $1 $oos_path/$1
read -r -p "是否删除源文件? [Y/n] " input
case $input in
    [yY][eE][sS]|[yY])
        rm -rf `pwd`/$1
        echo "rm -rf `pwd`/$1"
        ;;
    [nN][oO]|[nN])
        echo "OK"
        ;;
    *)
        echo "Invalid input..."
        exit 1
        ;;
esac
fi
```

