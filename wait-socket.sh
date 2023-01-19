#!/usr/bin/env sh
#
# Wait until socket file has been created
# Parameters:
#   $1: path to socket file

SLEEP_SEC=0.5
SOCKET="$1"

[ -n "${SOCKET}" ] || exit 1
while [ ! -S "${SOCKET}" ] ; do
    sleep ${SLEEP_SEC}
done

exit 0

