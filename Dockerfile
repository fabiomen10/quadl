#
# Build stage
#
FROM alpine:latest

# args
ARG version="master"

# build root
WORKDIR /build

RUN apk add \
                git \
                ca-certificates \
                alpine-sdk \
                clang \
                cmake \
                zlib-static zlib-dev \
                lua5.1 lua5.1-dev \
                linux-headers

# source
RUN git clone https://github.com/lpereira/lwan -b ${version} .

# build
RUN mkdir build \
    && cd build \
    && cmake \
                .. \
                -DCMAKE_C_COMPILER=clang \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_EXE_LINKER_FLAGS="-static" \
                -DCMAKE_C_FLAGS="-static" \
    && make

# compress and test
RUN cd build \
    && ls -l /src/bin/lwan \
    && upx --ultra-brute /src/bin/lwan/lwan

# make a temp folder
RUN mkdir -p /tmp

#
# Final image
#
FROM scratch

# labels
LABEL org.label-schema.vcs-url="https://github.com/curiogeek/docker-quadl"
LABEL org.label-schema.version=${version}
LABEL org.label-schema.schema-version="0.0.1"

# copy binary and ca certs
COPY --from=build /build/build/src/bin/lwan/lwan /bin/lwan
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# copy default configuration
COPY lwan.conf /etc/lwan.conf

# copy empty temp folder
COPY --from=build /tmp /tmp

# serve form /srv
WORKDIR /srv
EXPOSE 8080

ENTRYPOINT ["/bin/lwan", "--config", "/etc/lwan.conf"]