#!/bin/bash
set -x
SELF=$(realpath ${0})
export GITROOT=${SELF%/site*}
echo ${GITROOT}
cd ${GITROOT}
if [ -z ${HOST} ] ; then
${GITROOT}/${1}
else
if [ ${HOST:0:6} == "elogin" ]; then
ssh -x utility01 ${GITROOT}/${1}
else
${GITROOT}/${1}
fi
fi
