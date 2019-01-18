# Passo 4: Criando serviço wso2

Crie o arquivo dentro do `bin` do wso2 com o nome `wso2.sh`

```
#! /bin/sh
export JAVA_HOME="/usr/java/jdk1.8.0_144"

startcmd='/var/cedro/wso2/bin/wso2server.sh start &'
restartcmd='/var/cedro/wso2/bin/wso2server.sh &'
stopcmd='/var/cedro/wso2/bin/wso2server.sh stop &'

case "$1" in
start)
   echo "Starting the WSO2 Server ..."
   su -c "${startcmd}" root
;;
restart)
   echo "Re-starting the WSO2 Server ..."
   su -c "${restartcmd}" root
;;
stop)
   echo "Stopping the WSO2 Server ..."
   su -c "${stopcmd}" root
;;
*)
   echo "Usage: $0 {start|stop|restart}"
exit 1
esac
```

Agora crie um arquivo `/etc/systemd/system/start-wso2.service`

```
[Unit]
Description=Start wso2 on boot
After=mysqld.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/var/cedro/wso2/wso2/bin/wso2.sh start
ExecStop=/var/cedro/wso2/wso2/bin/wso2.sh stop

[Install]
WantedBy=multi-user.target
```

Agora vamos dar um reload no daemon

```
systemctl daemon-reload
```

Add nosso serviço para iniciar no boot

```
systemctl enable start-wso2.service
systemctl start start-wso2.service
systemctl stop start-wso2.service
```
