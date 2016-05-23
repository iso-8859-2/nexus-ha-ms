#!/bin/bash

#
# Copyright (c) 2001-2016 Primeton Technologies, Ltd.
# All rights reserved.
#
# author: ZhongWen Li (mailto:lizw@primeton.com)
#

PID_FILE=/etc/keepalived/pid
if [ -f ${PID_FILE} ]; then
	PID=`cat ${PID_FILE}`
	if [ `ps -p ${PID} | grep -v PID | wc -l` -eq 1 ]; then
		kill ${PID}
		i=0
		while [ i -ge 60 ]; do
			if [ `ps -p ${PID} | grep -v PID | wc -l` -eq 0 ]; then
				break
			else
				echo "."
				sleep 1
			fi
			i=`expr $i + 1`
		done
		if [ `ps -p ${PID} | grep -v PID | wc -l` -eq 1 ]; then
			kill -9 ${PID}
		fi
	else
		echo "keepalived has been shut down."
	fi
fi

exit 0