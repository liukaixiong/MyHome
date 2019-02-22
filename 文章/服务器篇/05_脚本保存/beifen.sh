cur_dateTime=`date +%Y%m%d%H%M%S`
echo $cur_dateTime
filename=$1
echo $filename

if [ ! -d bak  ];then
  mkdir bak
fi

cp -r $filename bak/$filename-$cur_dateTime
echo $filename-$cur_dateTime OK!
