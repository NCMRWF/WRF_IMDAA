#!/bin/bash
set -x
SELF=$(realpath ${0})
export GITROOT=${SELF%/jobs*}
echo ${GITROOT}
cd ${GITROOT}
UTFList=$(git ls-files --others --exclude-standard)

for utf in ${UTFList}; do
echo ${utf}
done
cd ${GITROOT}; 
git pull
git add ${UTFList} 
git commit -a -m "Add files ${UTFList}"
git push
git status


