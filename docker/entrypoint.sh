#!/bin/sh
#
# Runs the command as a user with the caller's uid/gid (PV_UID/PV_GID, set by
# scripts/pv-docker.sh), so files in the mounted workspace keep their owner.
# Without them, the command runs as root.

set -e

if [ -z "${PV_UID}" ] || [ "${PV_UID}" = 0 ]; then
	exec "$@"
fi

PV_GID="${PV_GID:-${PV_UID}}"
user=builder
home=/home/${user}

getent group "${PV_GID}" >/dev/null || groupadd -o -g "${PV_GID}" "${user}"
# ubuntu:24.04 ships a user with uid 1000; reuse whatever owns the uid.
if ! getent passwd "${PV_UID}" >/dev/null; then
	useradd -o -u "${PV_UID}" -g "${PV_GID}" -d "${home}" -s /bin/bash -M "${user}"
fi
user="$(getent passwd "${PV_UID}" | cut -d: -f1)"
home="$(getent passwd "${PV_UID}" | cut -d: -f6)"
mkdir -p "${home}"
chown "${PV_UID}:${PV_GID}" "${home}"

export HOME="${home}" USER="${user}" LOGNAME="${user}"
exec setpriv --reuid="${PV_UID}" --regid="${PV_GID}" --clear-groups "$@"
