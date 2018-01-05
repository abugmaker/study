#! /bin/bash
#####################################
# this script function is :
# check_mysql_slave_replication_status
#
# ***   2017-11-08
#####################################

parasnum=2
function help_msg()
{
    cat << EOF
+--------------------------------+
+ Error Cause:
+ you enter $# parameters
+ the total paramenter number must be $parasnum
+ 1st: HOST_IP
+ 2st: HOST_PORT
+--------------------------------+
EOF
exit
}

#---------------------------------
# check parameter number
#---------------------------------
[ $# -ne ${parasnum} ] && help_msg

#---------------------------------
# Initialize the log file
#---------------------------------
export HOST_IP=$1
export HOST_PORT=$2
MYUSER=root
MYPASS='123456'
MYSOCK=/data/mysql/mysql.sock
MYSQL_PATH=/usr/local/mysql/bin
MYSQL_CMD="${MYSQL_PATH}/mysql -u${MYUSER} -p${MYPASS} -S ${MYSOCK}"

MailTitle=""
time1=`date +"%Y%m%d%H%M%S"`
time2=`date +"%Y-%m-%d %H:%M:%S"`
SlaveStatusFile="/var/log/mysql_master_slave/slave_status.${time1}"
echo "-----------Begins at :"$time2 > $SlaveStatusFile
echo "" >> $SlaveStatusFile

#get slave status
$MYSQL_CMD -e "show slave status\G" >> $SlaveStatusFile 2>&1
#get io_thread_status, sql_thread_status, last_errno
IOStatus1=`cat $SlaveStatusFile | grep Slave_IO_Running | awk '{print $2}'`
SQLStatus=`cat $SlaveStatusFile | grep Slave_SQL_Running | awk '{print $2}'`
    Errno=`cat $SlaveStatusFile | grep Last_Errno | awk '{print $2}'`
   Behind=`cat $SlaveStatusFile | grep Seconds_Behind_Master | awk '{print $2}'`

echo "" >> $SlaveStatusFile

if [ $IOStatus1 = 'No' ] || [ $SQLStatus = 'No' ] ; then
    if [ "$Errno" -eq 0 ] ; then
        $MYSQL_CMD -e "start slave io_thread; start slave sql_thread;"
        echo "Cause slave threads doesn't running, trying start slave io_thread; start slave sql_thread;" >> $SlaveStatusFile
        MailTitle="[Warning] Slave threads stoped on ${HOST_IP} ${HOST_PORT}"
    elif [ "$Errno" -eq 1007 ] || [ "$Errno" -eq 1053 ] || [ "$Errno" -eq 1062 ] || [ "$Errno" -eq 1213 ] || [ "$Errno" -eq 1158 ] || [ "$Errno" -eq 1159 ] || [ "$Errno" -eq 1008 ] ; then
        $MYSQL_CMD -e "stop slave; set global sql_slave_skip_counter=1; slave start;"
        echo "Cause slave replication catch errors, trying skip counter and restart slave; stop slave; set global sql_slave_skip_counter=1; slave start;" >> $SlaveStatusFile
        MailTitle="[Warning] Slave error on ${HOST_IP} ${HOST_PORT}! ErrNum:$Errno"
    else
        echo "Slave ${HOST_IP} ${HOST_PORT} is down!" >> $SlaveStatusFile
        MailTitle="[ERROR] Slave replication is down on ${HOST_IP} ${HOST_PORT}! ErrNUM:$Errno"
    fi
fi

if [ -n "$Behind" ]; then
    Behind=0
fi
echo "Seconds_Behind_Master: $Behind" >> $SlaveStatusFile
#delay behind master
if [ "$Behind" -gt 300 ]; then
    echo `date +"%Y-%m-%d %H:%M:%S"` "slave is behind master $Behind seconds!" >> $SlaveStatusFile
    MailTitle="[Warning] Slave delay $Behind seconds, from ${HOST_IP} ${HOST_PORT}"
fi

if [ -n "$MailTitle" ]; then
    source /usr/wlz/shell/mailconf
    cat ${SlaveStatusFile} | /bin/mail -s "$MailTitle" -c "${Mail_BOSS}" $Mail_ME
fi

#del Tmpfile: SlaveStatusFile
> $SlaveStatusFile