```shell
cnpm install


case $ENV in
'DEV')
ip='192.168.0.16'
user='root'
password='elab@135'
basicpath='/sky/spring-boot'
;;
'TEST')
ip='106.15.201.221'
user='admin'
password='u7S851VGlOTXsGIF'
basicpath='/elab/html'
target='barleyBackstage'
npm run test
;;
'TEST2')
ip='106.14.187.241'
user='root'
password='zaqwer@1234'
basicpath='/elab/tomcat/tomcat-web/webapps'
target='web'
npm run test
;;
'UAT')
ip='101.132.100.169'
user='admin'
password='4epa4NrBu1rw'
basicpath='/elab/tomcat/tomcat-web/webapps'
target='web'
npm run uat
;;
esac


sshpass -p $password scp -r ${WORKSPACE}/dist/* $user@$ip:$basicpath/$target
```

