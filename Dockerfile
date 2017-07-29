FROM debian:jessie-slim as builder

RUN apt-get update && apt-get install -y \
  git \
  autoconf automake g++ make pkg-config \
  bsdmainutils \
  libdb++-dev openssl libssl-dev \
  libboost-dev libboost-system-dev libboost-filesystem-dev libboost-program-options-dev libboost-thread-dev libboost-test-dev

WORKDIR /root
RUN git clone --branch v0.9.2.4 --depth 1 https://github.com/chaincoin/chaincoin.git
WORKDIR /root/chaincoin
RUN ./autogen.sh
RUN mkdir -p /root/chaincoin-bin
RUN ./configure --without-gui --with-incompatible-bdb --prefix /root/chaincoin-bin
RUN make
RUN make install

FROM debian:jessie-slim as s6

ARG OVERLAY_VERSION="v1.19.1.1"
ARG OVERLAY_ARCH="amd64"

RUN apt-get update && apt-get install -y openssl curl tar ca-certificates
RUN mkdir -p /root/s6
RUN curl -L \
	"https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" | \
  tar xz -C /root/s6

FROM debian:jessie-slim

RUN apt-get update && apt-get install -y \
  openssl libssl-dev \
  libboost-system-dev libboost-filesystem-dev libboost-program-options-dev libboost-thread-dev

COPY --from=builder /root/chaincoin-bin/bin/chaincoin* /usr/local/bin/
COPY --from=s6 /root/s6/ /
COPY ./root/ /

RUN mkdir -p \
	/app \
	/config \
	/defaults

RUN \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc

ENTRYPOINT ["/init"]
