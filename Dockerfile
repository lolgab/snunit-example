FROM ubuntu:22.04 as dev

WORKDIR /workdir

ENV UNIT_VERSION=1.31.1

# Install Scala Native requirements
RUN apt-get update && apt-get install -y openjdk-11-jdk clang

# Compile minimal NGINX Unit
RUN apt-get update && apt-get install -y curl build-essential
RUN curl -O https://unit.nginx.org/download/unit-$UNIT_VERSION.tar.gz && tar xzf unit-$UNIT_VERSION.tar.gz
RUN mv unit-$UNIT_VERSION unit

RUN cd unit && \
    ./configure --no-ipv6 --no-regex --log=/dev/stderr --user=unit --group=unit --statedir=statedir && \
    make build/sbin/unitd && \
    make build/lib/libunit.a && \
    install -p build/lib/libunit.a /usr/local/lib/libunit.a

COPY mill mill
COPY .mill-version .mill-version

# pre-download Mill
RUN ./mill --no-server version

COPY . .

RUN SCALANATIVE_MODE=release-size SCALANATIVE_LTO=thin ./mill --no-server nativeLink

RUN mkdir empty_dir
RUN groupadd --gid 999 unit && \
    useradd --uid 999 --gid unit --no-create-home --shell /bin/false unit
RUN cat /etc/passwd | grep unit > passwd
RUN cat /etc/group | grep unit > group

FROM scratch

WORKDIR /workdir

COPY --from=dev /workdir/conf.json /workdir/statedir/conf.json
COPY --from=dev /workdir/out/nativeLink.dest/out /workdir/out

# unitd dependencies
COPY --from=dev /workdir/unit/build/sbin/unitd /usr/sbin/unitd
COPY --from=dev /workdir/passwd /etc/passwd
COPY --from=dev /workdir/group /etc/group
COPY --from=dev /workdir/empty_dir /usr/local/var/run

# scala native and unitd dependencies

## x86_64 specific files
COPY --from=dev */lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=dev */lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=dev */lib/x86_64-linux-gnu/libstdc++.so.6 /lib/x86_64-linux-gnu/libstdc++.so.6
COPY --from=dev */lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so.1
COPY --from=dev */lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2

## aarch64 specific files
COPY --from=dev */lib/aarch64-linux-gnu/libm.so.6 /lib/aarch64-linux-gnu/libm.so.6
COPY --from=dev */lib/aarch64-linux-gnu/libc.so.6 /lib/aarch64-linux-gnu/libc.so.6
COPY --from=dev */lib/aarch64-linux-gnu/libstdc++.so.6 /lib/aarch64-linux-gnu/libstdc++.so.6
COPY --from=dev */lib/aarch64-linux-gnu/libgcc_s.so.1 /lib/aarch64-linux-gnu/libgcc_s.so.1
COPY --from=dev */lib/ld-linux-aarch64.so.1 /lib/ld-linux-aarch64.so.1

ENTRYPOINT [ "unitd", "--no-daemon" ]
