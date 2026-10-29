FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    curl \
    gcc \
    g++ \
    pkg-config \
    libssl-dev \
    build-essential \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /usr/src

ARG CACHE_BUST=1

RUN CACHE_ID=$CACHE_BUST git clone --branch main https://github.com/bitcoinpayserver/bitcoinpayd

WORKDIR /usr/src/bitcoinpayd
RUN cargo build

FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/bitcoinpayd/target/debug/bitcoinpayd /usr/local/bin/bitcoinpayd

RUN useradd -m -u 1102 bitcoinpayd && \
    chown -R bitcoinpayd:bitcoinpayd /home/bitcoinpayd

USER bitcoinpayd
WORKDIR /home/bitcoinpayd

ENTRYPOINT ["bitcoinpayd"]
CMD ["-printtoconsole"]