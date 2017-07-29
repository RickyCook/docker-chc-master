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

FROM debian:jessie-slim

RUN apt-get update && apt-get install -y \
  openssl libssl-dev \
  libboost-system-dev libboost-filesystem-dev libboost-program-options-dev libboost-thread-dev

COPY --from=builder /root/chaincoin-bin/bin/chaincoin* /usr/local/bin/
