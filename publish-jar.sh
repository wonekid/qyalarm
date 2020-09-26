#!/bin/bash

        if [ $# -eq 0 ]
        then
                echo "ERROR. please use $0 <application> to publish."
                exit $?
        fi

dir=/data/publish

datename=$(date +%Y%m%d-%H%M%S) ;
app_name=$1
tmp_app_name1=`echo ${app_name%%.*}`
tmp_app_name2=`echo ${tmp_app_name1%-*}`

PID_NAME=$tmp_app_name2

REG='^\w+\-\w+\-[0-9]{1}'
if [ ! -e ${dir}/${PID_NAME}.pid ]
then

    if [[ $tmp_app_name1 =~ $REG ]]
    then
        /usr/local/java/jdk1.8.0_161/bin/jps|grep -E "${tmp_app_name1}"|awk '{print $1}' >  ${dir}/${PID_NAME}.pid
        echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:正则匹配."
    else
        touch ${dir}/${PID_NAME}.pid
        /usr/local/java/jdk1.8.0_161/bin/jps|grep -w ${app_name}|awk '{print $1}' >  ${dir}/${PID_NAME}.pid
    fi
fi

function publish(){
        echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:备份jar."

        if [ ! -d /data/publish/jar-backup ]
           then
                 mkdir -m 700 /data/publish/jar-backup ;
           fi
                mkdir -m 700 /data/publish/jar-backup/$datename ;

        cp -a -R  /data/publish/jar/$(ls -t /data/publish/jar/${PID_NAME}*.jar|head -n 1|awk '{print substr($1,19,length($1))}') /data/publish/jar-backup/$datename/

        echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:完毕."

        echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:停止进程..."

flag=`cat ${dir}/${PID_NAME}.pid|wc -l`

        if [ $flag -eq 0 ]
        then
                echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:进程不存在，直接启动中"
        else
                cat ${dir}/${PID_NAME}.pid|xargs kill -9

                if [ $? -eq 0 ]
                then
                         echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:完毕"
                else
                         echo "[$(date +"%Y%m%d-%H%M%S")] [\e[1;31mERROR\e[0m]:停止进程失败，请重新发布."
                         rm -f ${dir}/${PID_NAME}.pid
                         exit -1
                fi

        fi

        echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:删除旧版"

        rm -f /data/publish/jar/${app_name} ;

        echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:完毕"

        echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:启动${app_name}"

        if [ ! -d /data/publish/logs ]
        then
                mkdir -p /data/publish/logs
        else
                cp -a -R /data/publish/${app_name} /data/publish/jar/${app_name}
                nohup java -server -Xms2g -Xmx2g -jar /data/publish/jar/${app_name} --spring.profiles.active=dev -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/oom.log  > /dev/null 2>&1 &
        fi
	sleep 5

        if [[ $tmp_app_name1 =~ $REG ]]
        then
                flag2=`/usr/local/java/jdk1.8.0_161/bin/jps|grep -E "${tmp_app_name1}"|grep -v nohup|grep -v grep|wc -l`
                echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:正则匹配."
        else
                flag2=`/usr/local/java/jdk1.8.0_161/bin/jps|grep -w ${app_name}|grep -v nohup|grep -v grep|wc -l`
        fi

        if [ $flag2 -eq 1 ]
        then
                > ${dir}/${PID_NAME}.pid

                echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:启动${app_name}成功"

                ps -ef|grep "${app_name}"|grep -v nohup|grep -v grep|awk '{print $2}'|sort -nr|head -n 1 > ${dir}/${PID_NAME}.pid

                echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:进程号：$(cat ${dir}/${PID_NAME}.pid),PID文件：$(echo ${dir}/${PID_NAME}.pid)"
        else
                echo -e "[$(date +"%Y%m%d-%H%M%S")] [\e[1;31mERROR\e[0m]:${app_name}启动异常，启动失败或发现多个进程，请到服务器查看"

                rm -f ${dir}/${PID_NAME}.pid
                exit 127
        fi

        echo "[$(date +"%Y%m%d-%H%M%S")] [INFO]:请等待刷新日志..."


#       cat /data/publish/logs/${app_name}.log|head -n 300|tail -n +1
}

publish
exit 0
