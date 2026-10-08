#!/bin/bash
#
# Run a command (default: an interactive shell) in the pv-ptxdist build
# container.
#
# usage: scripts/pv-docker.sh [--build | --pull] [command...]
#   scripts/pv-docker.sh                      shell in the container
#   scripts/pv-docker.sh ptxdist images       build all images
#   scripts/pv-docker.sh --build              rebuild the image from docker/
#
# The workspace is mounted at the same path as on the host: PTXdist stores
# absolute paths in the platform build tree, so this keeps a build tree usable
# both inside and outside the container. A 'src' symlink pointing outside the
# workspace is mounted too. Commands run with the caller's uid/gid.
#
# PV_DOCKER_IMAGE overrides the image, PV_DOCKER_ARGS adds 'docker run'
# arguments.

set -e

bsp="$(cd "$(dirname "$0")/.." && pwd)"
image="${PV_DOCKER_IMAGE:-ghcr.io/pantavisor/pv-ptxdist-builder:ptxdist-2026.10.0}"

case "$1" in
--build)
	shift
	docker build -t "${image}" "${bsp}/docker"
	[ $# -eq 0 ] && exit 0
	;;
--pull)
	shift
	docker pull "${image}"
	[ $# -eq 0 ] && exit 0
	;;
esac

mounts=(-v "${bsp}:${bsp}")
if [ -L "${bsp}/src" ]; then
	src="$(readlink -f "${bsp}/src")"
	case "${src}" in
	"${bsp}"/*) ;;
	*) mkdir -p "${src}"; mounts+=(-v "${src}:${src}") ;;
	esac
fi

# Stay in the current directory when it is inside the workspace.
workdir="${bsp}"
case "${PWD}/" in
"${bsp}"/*) workdir="${PWD}" ;;
esac

tty=()
[ -t 0 ] && [ -t 1 ] && tty=(-it)

[ $# -eq 0 ] && set -- /bin/bash

# shellcheck disable=SC2086
exec docker run --rm "${tty[@]}" \
	"${mounts[@]}" \
	-w "${workdir}" \
	-e PV_UID="$(id -u)" \
	-e PV_GID="$(id -g)" \
	${PV_DOCKER_ARGS} \
	"${image}" "$@"
