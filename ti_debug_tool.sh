#/bin/bash

# You need to specify by hand.
# -----------------------------

DATA_AND_DEPLOY_DIR="/Users/suzhipeng/Desktop/DEBUG_ENV/Data"
DEPLOY_PD_BIN="/Users/suzhipeng/Database/pd/bin/pd-server"
DEPLOY_PD_STATUS_PORT=2389
DEPLOY_TIDB_BIN="/Users/suzhipeng/Database/tidb/bin/tidb-server"
DEPLOY_TIDB_CONN_PORT=5000
DEPLOY_TIDB_STATUS_PORT=10081
DEPLOY_TIKV_BIN="/Users/suzhipeng/Database/tikv/tikv/target/debug/tikv-server"
DEPLOY_TIKV_STATUS_PORT=20170

# Automatically getting from code.
# -----------------------------

HOST_NAME=`hostname`
DEPLOY_IP=127.0.0.1
 
if [ ! -d ${DATA_AND_DEPLOY_DIR} ];then
   mkdir -p ${DATA_AND_DEPLOY_DIR}
fi
touch ${DATA_AND_DEPLOY_DIR}/nohup_pd_out.log ${DATA_AND_DEPLOY_DIR}/nohup_tikv_out.log ${DATA_AND_DEPLOY_DIR}/nohup_tidb_out.log


if [[ ${1} == "startup" ]];then
nohup ${DEPLOY_PD_BIN} --name=${HOST_NAME} \
    --client-urls=http://${DEPLOY_IP}:${DEPLOY_PD_STATUS_PORT} \
    --advertise-client-urls=http://${DEPLOY_IP}:${DEPLOY_PD_STATUS_PORT} \
    --data-dir=${DATA_AND_DEPLOY_DIR}/pd/data.pd \
    --initial-cluster=${HOST_NAME}=http://${DEPLOY_IP}:$((${DEPLOY_PD_STATUS_PORT}+1)) \
    --advertise-peer-urls=http://${DEPLOY_IP}:$((${DEPLOY_PD_STATUS_PORT}+1)) \
    --log-file=${DATA_AND_DEPLOY_DIR}/pd/log/pd.log >${DATA_AND_DEPLOY_DIR}/nohup_pd_out.log 2>&1  &

nohup ${DEPLOY_TIKV_BIN} --addr ${DEPLOY_IP}:${DEPLOY_TIKV_STATUS_PORT} \
        --advertise-addr ${DEPLOY_IP}:${DEPLOY_TIKV_STATUS_PORT} \
        --pd ${DEPLOY_IP}:${DEPLOY_PD_STATUS_PORT} \
        --data-dir ${DATA_AND_DEPLOY_DIR}/tikv \
        --log-file ${DATA_AND_DEPLOY_DIR}/tikv/log/tikv.log >${DATA_AND_DEPLOY_DIR}/nohup_tikv_out.log 2>&1  &

nohup ${DEPLOY_TIDB_BIN} -P ${DEPLOY_TIDB_CONN_PORT} \
        --status=${DEPLOY_TIDB_STATUS_PORT} \
        --advertise-address=${DEPLOY_IP} \
        --path=${DEPLOY_IP}:${DEPLOY_TIDB_STATUS_PORT} \
        --log-slow-query=${DATA_AND_DEPLOY_DIR}/tidb/log/tidb_slow_query.log \
        --log-file=${DATA_AND_DEPLOY_DIR}/tidb/log/tidb.log >${DATA_AND_DEPLOY_DIR}/nohup_tidb_out.log 2>&1  &
elif [[ ${1} == "shutdown" ]];then
    PD_PID=0
    TIKV_PID=0
    TIDB_PID=0
    PD_PID=`ps |grep "pd-server" | grep ${DEPLOY_PD_STATUS_PORT} | grep -v grep| sed 's/^\s*//' | awk -F ' ' '{print $1}'`
    TIKV_PID=`ps |grep "tikv-server" |  grep ${DEPLOY_TIKV_STATUS_PORT} | grep -v grep | sed 's/^\s*//' | awk -F ' ' '{print $1}'`
    TIDB_PID=`ps |grep "tidb-server" |  grep ${DEPLOY_TIDB_STATUS_PORT} | grep -v grep | sed 's/^\s*//' | awk -F ' ' '{print $1}'`
    echo ${PD_PID}
    echo ${TIKV_PID}
    echo ${TIDB_PID}
    if [[ ${TIDB_PID} != "" ]];then
        echo ${PD_PID} 
        kill -9 ${TIDB_PID} && sleep 1s
    fi

    if [[ ${TIKV_PID} != "" ]];then
        kill -9 ${TIKV_PID} && sleep 1s
    fi

    if [[ ${PD_PID} != "" ]];then
        kill -9 ${PD_PID} && sleep 1s
    fi
elif [[ ${1} == "killtikv" ]];then
    TIKV_PID=0
    TIKV_PID=`ps |grep "tikv-server" |  grep ${DEPLOY_TIKV_STATUS_PORT} | grep -v grep | sed 's/^\s*//' | awk -F ' ' '{print $1}'`
    if [[ ${TIKV_PID} != "" ]];then
        kill -9 ${TIKV_PID} && sleep 1s
    fi
elif [[ ${1} == "display" ]];then
    echo "Component --> PD is running. -------------------"
    ps -ef|grep "pd-server"|grep -v grep
    echo "Component --> TiDB is running. -------------------"
    ps -ef|grep "tidb-server"|grep -v grep
    echo "Component --> TiKV is running. -------------------"
    ps -ef|grep "tikv-server"|grep -v grep
elif [[ ${1} == "tikvargs" ]];then
    echo "TiKV DEBUG Args is --:-->"
    echo "\"--addr\"" "," "\"${DEPLOY_IP}:${DEPLOY_TIKV_STATUS_PORT}\"" "," \
         "\"--advertise-addr\"" "," "\"${DEPLOY_IP}:${DEPLOY_TIKV_STATUS_PORT}\"" \
         "\"--pd\"" "," "\"${DEPLOY_IP}:${DEPLOY_PD_STATUS_PORT}\"" \
         "\"--data-dir\"" "," "\"${DATA_AND_DEPLOY_DIR}/tikv\"" \
         "\"--log-file\"" "," "\"${DATA_AND_DEPLOY_DIR}/tikv/log/tikv.log\""
else
    echo 'Input wrong parameters,please input "startup/shutdown"'
fi
