#!/bin/bash

#
# Copyright (c) 2001-2016 Primeton Technologies, Ltd.
# All rights reserved.
#
# author: ZhongWen Li (mailto:lizw@primeton.com)
#
SBIN_PATH=$(cd $(dirname ${0}); pwd)

VIRTUAL_ADDRESS="192.168.187.200"
NEXUS_SERVICE_PORT=8081
NEXUS_SERVICE_URL="http://${VIRTUAL_ADDRESS}:${NEXUS_SERVICE_PORT}"
NEXUS_WORK_DIR="/volume/nexus"
HEART_BEAT_LOGS=/tmp/keepalived.heartbeat

# logger
trace_log() {
	echo "[`date`] [${USER}] $*" >> ${HEART_BEAT_LOGS}
}

start_nexus() {
	if [ `docker ps | grep nexus | wc -l` -eq 1 ]; then
		trace_log "nexus has been started."
		return 0
	fi
	if [ `docker ps -a | grep nexus | wc -l` -eq 1 ]; then
		docker start nexus
	else
		if [ ! -d ${NEXUS_WORK_DIR} ]; then
			mkdir -p ${NEXUS_WORK_DIR}
			chown -R 200 ${NEXUS_WORK_DIR}
		fi
		docker run --name nexus -d -p ${NEXUS_SERVICE_PORT}:8081 -v ${NEXUS_WORK_DIR}:/sonatype-work sonatype/nexus
		trace_log "docker start nexus"
	fi
}

stop_nexus() {
	if [ `docker ps | grep nexus | wc -l` -eq 1 ]; then
		docker stop nexus
		trace_log "docker stop nexus"
	fi
}

restart_nexus() {
	if [ `docker ps -a | grep nexus | wc -l` -eq 1 ]; then
		docker restart nexus
		trace_log "docker restart nexus"
	fi
}

# COUNT
if [ -f /etc/keepalived/HEART_BEAT_TIMES ]; then
	HEART_BEAT_TIMES=`cat /etc/keepalived/HEART_BEAT_TIMES`
else
	HEART_BEAT_TIMES=0
fi
if [ ${HEART_BEAT_TIMES} -ge 1000 ]; then
	HEART_BEAT_TIMES=0
	echo "[`date`]" > ${HEART_BEAT_LOGS}
fi
HEART_BEAT_TIMES=`expr ${HEART_BEAT_TIMES} + 1`
echo -n ${HEART_BEAT_TIMES} > /etc/keepalived/HEART_BEAT_TIMES
trace_log "HEART_BEAT_TIMES = ${HEART_BEAT_TIMES}"

#
# HTTP STATUS CODE, 200 is OK
# 
status=`curl --retry 2 -I -m 20 -o /dev/null -s -w %{http_code}  ${NEXUS_SERVICE_URL}`
if [ "200X" == "${status}X" ]; then
	trace_log "### [ O K ] ### nexus service response code 200."
else
	trace_log "### [ERROR] ### nexus service unreachable."
	# self is master
	if [ `ip a | grep "${VIRTUAL_ADDRESS}" | grep secondary | wc -l` -eq 1 ]; then
		trace_log "### [MASTER] ###."
		if [ `ps -ef | grep org.sonatype.nexus.bootstrap.Launcher | wc -l` -eq 0 ]; then
			start_nexus
			NEXUS_CHK_COUNT=0
			echo -n ${NEXUS_CHK_COUNT} > /etc/keepalived/NEXUS_CHK_COUNT
		else
			if [ -f /etc/keepalived/NEXUS_CHK_COUNT ]; then
				NEXUS_CHK_COUNT=`cat /etc/keepalived/NEXUS_CHK_COUNT`
			else
				NEXUS_CHK_COUNT=0
			fi
			if [ ${NEXUS_CHK_COUNT} -ge 60 ]; then
				stop_nexus
				# release VIP
				nohup ${SBIN_PATH}/stop.sh >> /dev/null &
			else
				NEXUS_CHK_COUNT=`expr ${NEXUS_CHK_COUNT} + 1`
				echo -n ${NEXUS_CHK_COUNT} > /etc/keepalived/NEXUS_CHK_COUNT
			fi			
		fi
		trace_log "NEXUS_CHK_COUNT = ${NEXUS_CHK_COUNT}"
	else
		trace_log "### [SLAVE] ###"
		echo -n 0 > /etc/keepalived/NEXUS_CHK_COUNT
		# if local nexus running, then shutdown
		if [ `ps -ef | grep org.sonatype.nexus.bootstrap.Launcher | wc -l` -eq 0 ]; then
			stop_nexus
		fi
	fi
fi

exit 0