FROM debian:stretch-slim
MAINTAINER Vitaliy Kozlenko <vk@wumvi.com>

EXPOSE 8181

ADD /conf/ /etc/nginx/
WORKDIR /www/
ADD /cmd/  /

LABEL version="1.2" nginx="1.14.0" openssl="1.1.0h"  mode="prod"

ENV NGINX_VERSION 1.14.0
ENV OPENSSL_VERSION 1.1.0h
ENV RUN_MODE PROD

RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get --no-install-recommends -qq -y install wget apt-transport-https lsb-release ca-certificates zlib1g-dev unzip cmake build-essential vim libboost-all-dev git gettext-base && \
    mkdir -p /www/ && \
    mkdir -p /www/conf/ && \
    mkdir -p /soft/ && \
    #
    cd /soft/ && \
    wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar -zxf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./config --prefix=/usr && \
    make && \
    make install && \
    #
    cd /soft/ && \
    wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.40.tar.gz && \
    tar -zxf pcre-8.40.tar.gz && \
    cd pcre-8.40 && \
    ./configure && \
    make && \
    make install && \
    #
    cd /soft/ && \
    git clone --recursive https://github.com/google/ngx_brotli.git ngx_brotli && \
    cd ngx_brotli && \
    git submodule update --init && \
    #
    cd /soft/ && \
    git clone --recursive https://github.com/google/open-vcdiff open-vcdiff && \
    cd open-vcdiff && \
    cmake . && make install && \
    #
    cd /soft/ && \
    git clone git://github.com/arut/nginx-rtmp-module.git nginx-rtmp-module && \
    #
    mkdir -p /etc/nginx/ && \
    cd /soft/ && \
    git clone https://github.com/yandex/sdch_module.git sdch_module && \
    git clone https://github.com/vozlt/nginx-module-vts.git nginx-module-vts && \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -zxf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    export NGX_BROTLI_STATIC_MODULE_ONLY=1 && \
    ./configure \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --pid-path=/var/run/nginx.pid \
        --error-log-path=/dev/stdout \
        --http-log-path=/dev/stdout  \
        --with-openssl=/soft/openssl-${OPENSSL_VERSION}/ \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_addition_module \
        --with-http_realip_module \
        --with-http_v2_module \
        --with-threads \
        --with-http_slice_module \
        --with-file-aio \
        --with-http_v2_module \
        --with-stream \
        --with-http_stub_status_module \
        --with-stream_ssl_module \
        --add-module=../sdch_module/ \
        --add-module=../ngx_brotli/ \
        --add-module=../nginx-module-vts/ \
        --add-module=../nginx-rtmp-module/ && \
    make && \
    make install && \
    #
    export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH} && \
    #
    apt-get -y remove libboost-all-dev git cmake ssh build-essential zlib1g-dev && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /soft/ && \
    #
    chmod +x /*.sh && \
    echo 'end'

CMD ["nginx", "-g", "daemon off;"]
# HEALTHCHECK --interval=2m --timeout=3s CMD curl -f http://localhost/ || exit 1
