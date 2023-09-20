#!/bin/bash
set -x
SELF=$(realpath ${0})
export GITROOT=${SELF%/*}
echo ${GITROOT}
cd ${GITROOT}
UTFList=$(git ls-files --others --exclude-standard)

for utf in ${UTFList}; do
echo ${utf}
done
cd ${GITROOT}; git add ${UTFList} ; git status
git commit -a -m "Add files ${UTFList}"
git push


