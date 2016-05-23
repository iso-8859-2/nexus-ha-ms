#!/bin/bash

#
# Copyright (c) 2001-2016 Primeton Technologies, Ltd.
# All rights reserved.
#
# author: ZhongWen Li (mailto:lizw@primeton.com)
#

priority=50

if [ ! -z $1 ]; then
	priority=$1
fi

if [ -z ${priority} ]; then
	priority=50
fi

PID_FILE=/etc/keepalived/pid
if [ -f ${PID_FILE} ]; then
	PID=`cat ${PID_FILE}`
	if [ `ps -p ${PID} | grep -v PID | wc -l` -eq 1]; then
		echo "Keepalived already started with pid ${PID}."
		exit 0
	fi
fi

if [ -f /etc/keepalived/templates/${priority} ]; then
	cp -f /etc/keepalived/templates/${priority} /etc/keepalived/keepalived.conf
fi

keepalived -p ${PID_FILE}

exit $?