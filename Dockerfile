FROM ubuntu:22.04 as dev

# Install NGINX Unit
RUN apt-get update && \
    apt-get install -y curl && \
    curl --output /usr/share/keyrings/nginx-keyring.gpg \
      https://unit.nginx.org/keys/nginx-keyring.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ jammy unit \
          deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ jammy unit' >> /etc/apt/sources.list.d/unit.list && \
    apt-get update && \
    apt-get install -y unit

RUN apt-get install -y openjdk-11-jdk unit-dev clang

WORKDIR /workdir

COPY mill mill

# pre-download Mill
RUN ./mill --no-server --help

COPY . .

RUN ./mill --no-server nativeLink

RUN mkdir empty_dir
RUN cat /etc/passwd | grep unit > passwd
RUN cat /etc/group | grep unit > group

FROM scratch

WORKDIR /workdir

COPY --from=dev /workdir/conf.json /workdir/statedir/conf.json
COPY --from=dev /workdir/out/nativeLink.dest/out /workdir/out

# unitd dependencies
COPY --from=dev /usr/sbin/unitd /usr/sbin/unitd
COPY --from=dev /workdir/passwd /etc/passwd
COPY --from=dev /workdir/group /etc/group
COPY --from=dev /workdir/empty_dir /var/run

## x86_64 specific files
COPY --from=dev */lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=dev */lib/x86_64-linux-gnu/libpcre2-8.so.0 /lib/x86_64-linux-gnu/libpcre2-8.so.0
COPY --from=dev */lib/x86_64-linux-gnu/libcrypto.so.3 /lib/x86_64-linux-gnu/libcrypto.so.3
COPY --from=dev */lib/x86_64-linux-gnu/libssl.so.3 /lib/x86_64-linux-gnu/libssl.so.3
COPY --from=dev */lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=dev */lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2

## aarch64 speicific files
COPY --from=dev */lib/aarch64-linux-gnu/libm.so.6 /lib/aarch64-linux-gnu/libm.so.6
COPY --from=dev */lib/aarch64-linux-gnu/libpcre2-8.so.0 /lib/aarch64-linux-gnu/libpcre2-8.so.0
COPY --from=dev */lib/aarch64-linux-gnu/libcrypto.so.3 /lib/aarch64-linux-gnu/libcrypto.so.3
COPY --from=dev */lib/aarch64-linux-gnu/libssl.so.3 /lib/aarch64-linux-gnu/libssl.so.3
COPY --from=dev */lib/aarch64-linux-gnu/libc.so.6 /lib/aarch64-linux-gnu/libc.so.6
COPY --from=dev */lib/ld-linux-aarch64.so.1 /lib/ld-linux-aarch64.so.1

# scala native dependencies

## x86_64 specific files
COPY --from=dev */lib/x86_64-linux-gnu/libstdc++.so.6 /lib/x86_64-linux-gnu/libstdc++.so.6
COPY --from=dev */lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so.1

## aarch64 speicific files
COPY --from=dev */lib/aarch64-linux-gnu/libstdc++.so.6 /lib/aarch64-linux-gnu/libstdc++.so.6
COPY --from=dev */lib/aarch64-linux-gnu/libgcc_s.so.1 /lib/aarch64-linux-gnu/libgcc_s.so.1

ENTRYPOINT [ "unitd", "--statedir", "statedir", "--log", "/dev/stdout", "--no-daemon" ]
