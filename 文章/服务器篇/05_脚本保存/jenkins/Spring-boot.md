# shell

springboot

```shell
cd $WORKSPACE

echo $compile
if $compile
then 
	rm -rf $WORKSPACE/$project/target/
	mvn -U package
fi



case $ENV in
'DEV')
ip='192.168.0.16'
user='root'
password='elab@135'
basicpath='/sky/spring-boot'
;;
'TEST')
ip='101.132.138.87'
user='admin'
password='4epa4NrBu1rw'
basicpath='/elab/spring-boot'
;;
'TEST2')
ip='106.14.187.241'
user='root'
password='zaqwer@1234'
basicpath='/elab/spring-boot'
;;
'UAT')
ip='101.132.100.169'
user='admin'
password='4epa4NrBu1rw'
basicpath='/elab/spring-boot'
;;
esac

#echo $ip
#echo $user
#echo $password
#echo $basicpath

filePath=$WORKSPACE/$project/target/*.jar
echo $filePath
fileName=$(basename $filePath)
echo $fileName

#!/bin/bash
sshpass -p $password scp ${WORKSPACE}/${project}/target/*.jar  $user@$ip:$basicpath

if [ "$user" == "root" ]
then nohup sshpass -p $password ssh $user@$ip "$basicpath/spring-boot.sh $fileName stop " &
else nohup sshpass -p $password ssh $user@$ip "sudo $basicpath/spring-boot.sh $fileName stop " &
fi

sleep 5s
pid=`sshpass -p $password ssh $user@$ip "ps -ef|grep $fileName|grep -v grep"|awk '{print \$2}'`
echo $pid

if [ "$pid" == "" ]
then
	echo '旧进程清理成功'
else 
 	echo '旧进程清理失败'
fi
/usr/bin/expect << EOF
set timeout 120
if { "$user" eq "root" } {
  spawn sshpass -p $password ssh $user@$ip "$basicpath/spring-boot.sh $fileName start"
} else {
  spawn sshpass -p $password ssh $user@$ip "sudo $basicpath/spring-boot.sh $fileName start"
}

expect {
	"Tomcat started on port(s):" {
    	exit 0
    }
    timeout        {
    	exit 1
    }
}


EOF
```

