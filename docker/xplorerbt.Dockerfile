FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    curl \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /usr/src

ARG CACHE_BUST=1
RUN git clone --branch main https://github.com/bitcoinpayserver/xplorerbt

WORKDIR /usr/src/xplorerbt
RUN cargo build

FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/xplorerbt/target/debug/xplorerbt /usr/local/bin/xplorerbt

RUN useradd -m -u 1101 xplorerbt && \
    chown -R xplorerbt:xplorerbt /home/xplorerbt

USER xplorerbt
WORKDIR /home/xplorerbt

EXPOSE 8000

ENTRYPOINT ["xplorerbt"]
CMD ["-printtoconsole"]