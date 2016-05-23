#!/bin/bash

#
# Copyright (c) 2001-2016 Primeton Technologies, Ltd.
# All rights reserved.
#
# author: ZhongWen Li (mailto:lizw@primeton.com)
#

SBIN_PATH=$(cd $(dirname ${0}); pwd)

${SBIN_PATH}/stop.sh

priority=50
if [ -z $1 ]; then
	priority=$1
fi

${SBIN_PATH}/start.sh ${priority}

exit $?