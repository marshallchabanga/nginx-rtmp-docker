ARG NGINX_VERSION=1.16.1
ARG NGINX_RTMP_VERSION=1.2.1
ARG FFMPEG_VERSION=4.2.1
ARG S3FS_VERSION=v1.93

##############################
# Build the NGINX-build image.
FROM alpine:3.8 as build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION




# Build dependencies.
RUN apk add --update \
  build-base \
  ca-certificates \
  curl \
  gcc \
  libc-dev \
  libgcc \
  linux-headers \
  make \
  musl-dev \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  pkgconf \
  pkgconfig \
  zlib-dev

# Get nginx source.
RUN cd /tmp && \
  wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --with-debug && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install

# Build the release image.
FROM alpine:3.8
LABEL MAINTAINER Marshall Chabanga <codewithbisky@gmail.com>

RUN apk add --update \
  ca-certificates \
  openssl \
  pcre \
  lame \
  libogg \
  libass \
  libvpx \
  libvorbis \
  libwebp \
  libtheora \
  opus \
  rtmpdump \
  x264-dev \
  x265-dev

COPY --from=build-nginx /usr/local/nginx /usr/local/nginx

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"
ADD nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /var/tmp/hls && mkdir /www
COPY index.html /www/

# Add S3FS
RUN apk --update add fuse alpine-sdk automake autoconf libxml2-dev fuse-dev curl-dev git bash;
RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git; \
   cd s3fs-fuse; \
   git checkout tags/${S3FS_VERSION}; \
   ./autogen.sh; \
   ./configure --prefix=/usr; \
   make; \
   make install; \
   rm -rf /var/cache/apk/*;

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 1935
#USER 1000
# Set the entrypoint script as the default entrypoint
ENTRYPOINT ["/entrypoint.sh"]
# CMD instruction to run NGINX with the specified parameters
CMD ["nginx", "-g", "daemon off;"]
