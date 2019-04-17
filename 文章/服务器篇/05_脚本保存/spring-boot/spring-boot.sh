#!/bin/bash
#
#kconfig:   - 20 80
# description: Starts and stops the App.
# author:vakinge

ENV=test
RUNNING_USER=root
ADATE=`date +%Y%m%d%H%M%S`
APP_NAME=$1

APP_HOME=`pwd`
dirname $0|grep "^/" >/dev/null
if [ $? -eq 0 ];then
   APP_HOME=`dirname $0`
else
    dirname $0|grep "^\." >/dev/null
    retval=$?
    if [ $retval -eq 0 ];then
        APP_HOME=`dirname $0|sed "s#^.#$APP_HOME#"`
    else
        APP_HOME=`dirname $0|sed "s#^#$APP_HOME/#"`
    fi
fi

if [ ! -d "$APP_HOME/logs" ];then
  mkdir -p $APP_HOME/logs/start-logs
  echo "开始创建文件夹 : $APP_HOME/logs/start-logs"
fi

LOG_PATH=$APP_HOME/logs/start-logs/$APP_NAME-start.log
GC_LOG_PATH=$APP_HOME/logs/start-logs/gc-$APP_NAME-$ADATE.log
#JMX监控需用到
JMX="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=1091 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
#JVM参数
JVM_OPTS="-Dname=$APP_NAME -Dspring.profiles.active=$ENV -Duser.timezone=Asia/Shanghai -Xms1024m -Xmx1024m -XX:+HeapDumpOnOutOfMemoryError -XX:+PrintGCDateStamps -Xloggc:$GC_LOG_PATH -XX:+PrintGCDetails -XX:NewRatio=1 -XX:SurvivorRatio=30 -XX:+UseParallelGC -XX:+UseParallelOldGC"

JAR_FILE=$APP_NAME
pid=0
start(){
  echo "-----------------------开始启动 $APP_NAME --------------------------------"
#  local p_pid=`ps -ef|grep $APP_NAME|grep -v grep | awk '{print $2}' `
#  local p_pid=`pgrep -f $APP_NAME`
#  if [ -z "$p_pid" ]; then
    JAVA_CMD="nohup java -jar $JVM_OPTS $APP_HOME/$JAR_FILE > $LOG_PATH 2>&1 &"
    su - $RUNNING_USER -c "$JAVA_CMD"
    echo "---------------------------------"
    echo "启动完成，按CTRL+C退出日志界面即可>>>>>"
    echo "nohup java -jar $JVM_OPTS $JAR_FILE > $LOG_PATH 2>&1 &"
    echo "---------------------------------"
    sleep 2s
    tail -f  $LOG_PATH
 # else
 #     echo "$APP_NAME is runing PID: $p_pid"   
 # fi

}


status(){
   local p_pid=`ps -ef|grep $APP_NAME|grep -v grep|awk '{print $2}' `
   if [ -z "$p_pid" ]; then
     echo "$APP_NAME 应用进程不存在!"
   else
     echo "$APP_NAME 启动的进程编号: $p_pid"
   fi 
}


checkpid(){

  local p_pid=`ps -ef|grep $APP_NAME|grep -v grep|awk '{print $2}' `
  echo "--------->>>>>>>>>>  ps -ef|grep $APP_NAME|grep -v grep|awk '{print $2}' >> $p_pid"

  #如果不存在返回1，存在返回0     
  if [ -z "$pid" ]; then
    return 0
  else
    return 1
  fi
}

stop(){
 local p_pid=`ps -ef|grep $APP_NAME|grep -v grep|awk '{print $2}' `
 echo " ---> 开始关闭 ...  $APP_NAME     -------------      $p_pid  ----> ps -ef|grep $APP_NAME|grep -v grep|awk '{print $2}' "
  if [ -z "$p_pid" ]; then
     echo "$APP_NAME 没有启动..."
    else
      sudo kill -9 $p_pid  
    fi 
}

restart(){
    stop 
    sleep 1s
    start
}

case $2 in  
          start) start;;  
          stop)  stop;; 
   #       restart)  restart;;  
          status)  status;;   
              *)  echo "命令错误 参考示例: ./xxx.sh xxx.jar (start|stop|status)"  ;;  
esac
