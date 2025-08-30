ARG VERSION=1.0.0

FROM rust:slim AS builder
RUN apt-get update -yq && \
    apt-get install -yq \
        git \
        wget \
        musl-tools \
        build-essential \
        ca-certificates

ARG VERSION
ARG RUST_TARGET

RUN wget -O- https://api.github.com/repos/pborzenkov/koreader-syncd/tags \
    | grep "tarball_url" | cut -d\" -f4 | head -n1 \
    | wget -O /tmp/koreader-syncd.tar.gz -i -

ENV WD=/tmp/koreader-syncd
WORKDIR $WD

RUN tar -zxvf /tmp/koreader-syncd.tar.gz --strip-components=1 -C "$WD" \
    && export PATH=$HOME/.cargo/bin:$PATH \
    && rustup target add x86_64-unknown-linux-musl \
    && cargo build --release --target x86_64-unknown-linux-musl \
    && mv ./target/x86_64-unknown-linux-musl/release/koreader-syncd /koreader-syncd

FROM gcr.io/distroless/static

COPY --from=builder /koreader-syncd /usr/local/bin/koreader-syncd

EXPOSE 3000

WORKDIR /koreader-syncd

CMD ["/usr/local/bin/koreader-syncd", "-a", "0.0.0.0:3000", "-d", "/koreader-syncd/state.db"]

