#!/bin/bash
set -x
SELF=$(realpath ${0})
TASKNAME=${SELF##*/}
export GITROOT=${SELF%/site*}
echo ${GITROOT}
cd ${GITROOT}
if [ -z ${HOST} ] ; then
${GITROOT}/${TASKNAME}
else
if [ ${HOST:0:6} == "elogin" ]; then
ssh -x utility01 ${GITROOT}/${TASKNAME}
else
${GITROOT}/${TASKNAME}
fi
fi
