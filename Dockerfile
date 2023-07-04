FROM ubuntu:22.04 as base

# Install NGINX Unit
RUN apt-get update && \
    apt-get install -y curl && \
    curl --output /usr/share/keyrings/nginx-keyring.gpg \
      https://unit.nginx.org/keys/nginx-keyring.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ jammy unit \
          deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ jammy unit' >> /etc/apt/sources.list.d/unit.list && \
    apt-get update && \
    apt-get install -y unit

FROM base as dev

RUN apt-get install -y openjdk-11-jdk unit-dev clang

WORKDIR /workdir

COPY mill mill

# pre-download Mill
RUN ./mill --no-server --help

COPY . .

RUN ./mill --no-server nativeLink

FROM base

WORKDIR /workdir

COPY --from=dev /workdir/conf.json /workdir/statedir/conf.json
COPY --from=dev /workdir/out/nativeLink.dest/out /workdir/out

ENTRYPOINT [ "unitd", "--statedir", "statedir", "--log", "/dev/stdout", "--no-daemon" ]
