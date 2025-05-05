############################## 
# Stage 1: Builder 
############################## 
FROM ubuntu:22.04 AS builder  

ENV DEBIAN_FRONTEND=noninteractive 
ARG BITCOIN_REPO=https://github.com/stutxo/bitcoin.git 
ARG BITCOIN_BRANCH=transactions_only_signet  

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        cmake \
        ninja-build \
        build-essential \
        pkg-config \
        libboost-all-dev \
        libssl-dev \
        libevent-dev \
        bsdmainutils \
        libminiupnpc-dev \
        libzmq3-dev \
        libsqlite3-dev \
        ca-certificates \
        procps && \
    rm -rf /var/lib/apt/lists/*  

WORKDIR /usr/src 
RUN git clone --depth 1 --branch ${BITCOIN_BRANCH} ${BITCOIN_REPO} bitcoin  

WORKDIR /usr/src/bitcoin 
RUN cmake -S . -B build -GNinja \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=/usr/src/bitcoin/bin \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_BITCOIN_QT=OFF \
    -DBUILD_BITCOIN_LIBS=OFF \
    -DENABLE_UPNP=OFF \
    -DENABLE_WALLET=ON \
    -DENABLE_GUI=OFF \
    -DENABLE_ZMQ=OFF \
    -DWITH_QRENCODE=OFF \
    -DBUILD_BITCOIN_UTILS=OFF \
    -DBUILD_BITCOIN_WALLET=ON \
    -DBUILD_BITCOIN_CLI=ON \
    -DBUILD_BITCOIN_TX=OFF \
    -DBUILD_BITCOIN_ZMQ=OFF \
    -DCMAKE_CXX_FLAGS="-Os -ffunction-sections -fdata-sections" \
    -DCMAKE_C_FLAGS="-Os -ffunction-sections -fdata-sections" \
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--gc-sections"  

RUN cmake --build build --parallel 4  

############################## 
# Stage 2: Packager 
############################## 
FROM alpine:3.18 AS packager  

WORKDIR /artifacts/bin  

COPY --from=builder /usr/src/bitcoin/bin/bitcoind ./ 
COPY --from=builder /usr/src/bitcoin/bin/bitcoin-cli ./  

RUN strip --strip-all ./bitcoind ./bitcoin-cli || true  

RUN apk add --no-cache upx xz && \
    upx --best --lzma ./bitcoind ./bitcoin-cli && \
    tar -cJf /artifacts/bitcoin-binaries.tar.xz -C /artifacts/bin .

VOLUME ["/artifacts"] 
CMD ["ls", "-lh", "/artifacts/bitcoin-binaries.tar.xz"]