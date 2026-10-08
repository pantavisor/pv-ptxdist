# Build environment for pv-ptxdist: PTXdist, the OSELAS toolchains of the
# DistroKit platforms and the host packages PTXdist and the BSP need.
#
# Ubuntu 24.04 because Pengutronix publishes the toolchains for 'noble'.

FROM ubuntu:24.04

ARG PTXDIST_VERSION=2026.10.0
ARG PTXDIST_SHA256=2b5f791b5379b412fccfd7e1e49b96df9355466a85b2595f9a66e7391ed732e0
ARG KEYRING_VERSION=2026.01.08
ARG KEYRING_SHA256=3a43fb927e3a03f36ac15bc5a7e5a0a3234954d4d7a559d2750a056373749c4e
ARG OSELAS_VERSION=2025.11.1
# aarch64: v8a; arm-v7a: v7a and v7a_noneon; x86-64: x86_64
ARG OSELAS_TOOLCHAINS="\
	aarch64-v8a-linux-gnu \
	arm-v7a-linux-gnueabihf \
	x86-64-unknown-linux-gnu \
"

ENV DEBIAN_FRONTEND=noninteractive \
	LANG=C.UTF-8 \
	LC_ALL=C.UTF-8

# swig and python3-dev: U-Boot's binman builds pylibfdt for the Rockchip
# images. setpriv (util-linux) is used by the entrypoint.
RUN apt-get update && apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		bc \
		bison \
		bzip2 \
		ca-certificates \
		cpio \
		curl \
		file \
		flex \
		g++ \
		gawk \
		gcc \
		gettext \
		git \
		gzip \
		libncurses-dev \
		libtool \
		lz4 \
		make \
		openssh-client \
		patch \
		perl \
		pkgconf \
		python3 \
		python3-dev \
		python3-setuptools \
		python3-venv \
		rsync \
		swig \
		texinfo \
		unzip \
		util-linux \
		wget \
		xz-utils \
		zstd \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /tmp/keyring.deb \
		https://debian.pengutronix.de/debian/pool/main/p/pengutronix-archive-keyring/pengutronix-archive-keyring_${KEYRING_VERSION}_all.deb \
	&& echo "${KEYRING_SHA256}  /tmp/keyring.deb" | sha256sum -c - \
	&& dpkg -i /tmp/keyring.deb \
	&& rm /tmp/keyring.deb \
	&& echo "deb [signed-by=/usr/share/keyrings/pengutronix-archive-keyring.gpg] https://debian.pengutronix.de/debian/ noble main contrib non-free" \
		> /etc/apt/sources.list.d/pengutronix.list \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		$(for t in ${OSELAS_TOOLCHAINS}; do echo oselas.toolchain-${OSELAS_VERSION}-$t; done) \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /tmp/ptxdist.tar.bz2 \
		https://public.pengutronix.de/software/ptxdist/ptxdist-${PTXDIST_VERSION}.tar.bz2 \
	&& echo "${PTXDIST_SHA256}  /tmp/ptxdist.tar.bz2" | sha256sum -c - \
	&& tar -C /tmp -xjf /tmp/ptxdist.tar.bz2 \
	&& cd /tmp/ptxdist-${PTXDIST_VERSION} \
	&& ./configure --prefix=/usr/local \
	&& make \
	&& make install \
	&& cd / \
	&& rm -rf /tmp/ptxdist.tar.bz2 /tmp/ptxdist-${PTXDIST_VERSION}

COPY entrypoint.sh /usr/local/bin/pv-ptxdist-entrypoint

ENTRYPOINT ["/usr/local/bin/pv-ptxdist-entrypoint"]
CMD ["/bin/bash"]
