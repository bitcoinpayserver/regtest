# ==========================================
# Build the Bitcoin Knots binary
# ==========================================
FROM ubuntu:24.04 AS builder

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core build dependencies
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    bsdmainutils \
    python3 \
    libevent-dev \
    libboost-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-test-dev \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
RUN git clone --branch 29.x-knots --depth 1 https://github.com/bitcoinpayserver/bitcoin

WORKDIR /usr/src/bitcoin
RUN cmake -B build \
        -DENABLE_WALLET=OFF \
        -DBUILD_TESTS=OFF \
        -DBUILD_BENCH=OFF \
        -DBUILD_GUI=OFF \
        -DWITH_SQLITE=ON && \
    cmake --build build -j$(nproc) && \
    cmake --install build

# ==========================================
# Create the minimal runtime image
# ==========================================
FROM ubuntu:24.04

# Install only the runtime dependencies needed to execute the binary
RUN apt-get update && apt-get install -y \
    libevent-dev \
    libboost-system1.83.0 \
    libboost-filesystem1.83.0 \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binaries from Stage 1
COPY --from=builder /usr/src/bitcoin/build/bin/bitcoind /usr/local/bin/bitcoind
COPY --from=builder /usr/src/bitcoin/build/bin/bitcoin-cli /usr/local/bin/bitcoin-cli

# Set up a non-root system user for security
RUN useradd -m -u 1100 bitcoin && \
    mkdir -p /home/bitcoin/.bitcoin && \
    chown -R bitcoin:bitcoin /home/bitcoin

# Copy the Bitcoin regtest configuration
COPY ./bitcoin.conf /home/bitcoin/.bitcoin/bitcoin.conf

USER bitcoin
WORKDIR /home/bitcoin

# Expose RPC and P2P network port
EXPOSE 18443 18444

# Run the daemon, sending output straight to terminal logs
ENTRYPOINT ["bitcoind"]
CMD ["-printtoconsole"]
