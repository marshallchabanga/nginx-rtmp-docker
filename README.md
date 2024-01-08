## Supported tags and respective `Dockerfile` links

* [`latest` _(Dockerfile)_](https://github.com/marshallchabanga/nginx-rtmp-docker/blob/master/Dockerfile)

**Note**: Note: There are [tags for each build date](https://hub.docker.com/r/marshallchabanga/nginx-rtmp-s3fs/tags). If you need to "pin" the Docker image version you use, you can select one of those tags. E.g. `marshallchabanga/nginx-rtmp-s3fs:latest-08-01-2024`.

# nginx-rtmp

[**Docker**](https://www.docker.com/) image with [**Nginx**](http://nginx.org/en/) using the [**nginx-rtmp-module**](https://github.com/arut/nginx-rtmp-module) module for live multimedia (video) streaming.

## Description

This [**Docker**](https://www.docker.com/) image can be used to create an RTMP server for multimedia / video streaming using [**Nginx**](http://nginx.org/en/), [**nginx-rtmp-module**](https://github.com/arut/nginx-rtmp-module) and [**s3fs**](https://github.com/s3fs-fuse/s3fs-fuse), built from the current latest sources (Nginx 1.15.0, nginx-rtmp-module 1.2.1 and s3fs v1.85).

This was inspired by other similar previous images from [tiangolo](https://hub.docker.com/r/tiangolo/nginx-rtmp/), [dvdgiessen](https://hub.docker.com/r/dvdgiessen/nginx-rtmp-docker/), [jasonrivers](https://hub.docker.com/r/jasonrivers/nginx-rtmp/), [aevumdecessus](https://hub.docker.com/r/aevumdecessus/docker-nginx-rtmp/) and by an [OBS Studio post](https://obsproject.com/forum/resources/how-to-set-up-your-own-private-rtmp-server-using-nginx.50/).

The main purpose (and test case) to build it was to allow streaming from [**OBS Studio**](https://obsproject.com/) to different clients at the same time. Mount s3 bucket to store streaming media 

Streaming using AWS CloudFront and s3 integration

Backup recordings into s3 bucket

**GitHub repo**: <https://github.com/marshallchabanga/nginx-rtmp-docker>

**Docker Hub image**: <https://hub.docker.com/r/marshallchabanga/nginx-rtmp-s3fs/>

## Details

## How to use

* For the simplest case, just create a file `docker-compose.yml` and add the content below into it. Run `docker-compose build` and then `docker-compose up`


```bash
version: "3.9"
services:
  rtmp:
    image: marshallchabanga/nginx-rtmp-s3fs
    ports:
      - "1935:1935"
      - "9080:9080"
    container_name: rtmp_server
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    environment:
      AWS_ACCESS_KEY_ID: dfdgdfdg
      AWS_SECRET_ACCESS_KEY: fgdgdg
      AWS_S3_BUCKET_NAME: bisky-bucket
      AWS_S3_REGION: ap-northeast-2
```

## How to test with OBS Studio and VLC

* Run a container with the command above


* Open [OBS Studio](https://obsproject.com/)
* Click the "Settings" button
* Go to the "Stream" section
* In "Stream Type" select "Custom Streaming Server"
* In the "URL" enter the `rtmp://<ip_of_host>/live` replacing `<ip_of_host>` with the IP of the host in which the container is running. For example: `rtmp://localhost:1935/live`
* In the "Stream key" use a "key" that will be used later in the client URL to display that specific stream. For example: `test`
* Click the "OK" button
* In the section "Sources" click the "Add" button (`+`) and select a source (for example "Screen Capture") and configure it as you need
* Click the "Start Streaming" button


# Using AWS and CloudFront

### Watch Stream

Access by using your S3 public URL.

For example => `https://your-s3-bucket.s3.region.amazonaws.com/test.m3u8`

or you can set your cloudfront (cache disabled) distribution then based on your S3

>  ATTENTION:
>  Don't forget to set public access and enable CORS in your s3 bucket
> 

## Debugging

If something is not working you can check the logs of the container with:

```bash
docker logs nginx-rtmp-s3fs
```

## Extending

If you need to modify the configurations you can create a file `nginx.conf` and replace the one in this image using a `Dockerfile` that is based on the image, for example:

```Dockerfile
FROM marshallchabanga/nginx-rtmp-s3fs

COPY nginx.conf /etc/nginx/nginx.conf
```

The current `nginx.conf` contains:

```Nginx
worker_processes auto;
rtmp_auto_push on;
events {}
rtmp {
    server {
        listen 1935; # Listen on standard RTMP port

        application live {
            live on;
            hls on;
            hls_path /var/tmp/hls;
            hls_fragment 10s; # default is 5s
            hls_playlist_length 5m; # default is 30s
            # once playlist length is reached it deletes the oldest fragments

        }
    }
}

http {
    server {
        listen 9080;

        location / {
            root /www;
        }

        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                application/octet-stream ts;
            }
            root /var/tmp;
            add_header Cache-Control no-cache;

            # To avoid issues with cross-domain HTTP requests (e.g. during development)
            add_header Access-Control-Allow-Origin *;
        }
    }
}
```

You can start from it and modify it as you need. Here's the [documentation related to `nginx-rtmp-module`](https://github.com/arut/nginx-rtmp-module/wiki/Directives).

## Technical details

* This image is built from the same base official images that most of the other official images, as Python, Node, Postgres, Nginx itself, etc. Specifically, [buildpack-deps](https://hub.docker.com/_/buildpack-deps/) which is in turn based on [debian](https://hub.docker.com/_/debian/). So, if you have any other image locally you probably have the base image layers already downloaded.

* It is built from the official sources of **Nginx** and **nginx-rtmp-module** without adding anything else. (Surprisingly, most of the available images that include **nginx-rtmp-module** are made from different sources, old versions or add several other components).

* It has a simple default configuration that should allow you to send one or more streams to it and have several clients receiving multiple copies of those streams simultaneously. (It includes `rtmp_auto_push` and an automatic number of worker processes).

## Release Notes

### Latest Changes

* 👷 Add S3FS Fuse (Amazon S3 Integration) by [@codewithbisky](https://github.com/marshallchabanga).
* 👷 Update token for latest changes. PR [#50](https://github.com/tiangolo/nginx-rtmp-docker/pull/50) by [@tiangolo](https://github.com/tiangolo).
* 👷 Add GitHub Action for Docker Hub description. PR [#45](https://github.com/tiangolo/nginx-rtmp-docker/pull/45) by [@tiangolo](https://github.com/tiangolo).
* Bump tiangolo/issue-manager from 0.3.0 to 0.4.0. PR [#42](https://github.com/tiangolo/nginx-rtmp-docker/pull/42) by [@dependabot[bot]](https://github.com/apps/dependabot).
* Bump actions/checkout from 2 to 3. PR [#43](https://github.com/tiangolo/nginx-rtmp-docker/pull/43) by [@dependabot[bot]](https://github.com/apps/dependabot).
* 🎨 Format CI config. PR [#44](https://github.com/tiangolo/nginx-rtmp-docker/pull/44) by [@tiangolo](https://github.com/tiangolo).
* 👷 Add Dependabot and funding configs. PR [#41](https://github.com/tiangolo/nginx-rtmp-docker/pull/41) by [@tiangolo](https://github.com/tiangolo).
* ✨ Allow using debug directives, enable ` --with-debug` compile option. PR [#16](https://github.com/tiangolo/nginx-rtmp-docker/pull/16) by [@agconti](https://github.com/agconti).
* ⬆️ Upgrade Nginx to 1.23.2 and OS to bullseye. PR [#40](https://github.com/tiangolo/nginx-rtmp-docker/pull/40) by [@tiangolo](https://github.com/tiangolo).
* ⬆ Upgrade to nginx-1.19.7. PR [#26](https://github.com/tiangolo/nginx-rtmp-docker/pull/26) by [@cesarandreslopez](https://github.com/cesarandreslopez).
* 👷 Add scheduled CI. PR [#39](https://github.com/tiangolo/nginx-rtmp-docker/pull/39) by [@tiangolo](https://github.com/tiangolo).
* ⬆ Update RTMP module version to 1.2.2. PR [#28](https://github.com/tiangolo/nginx-rtmp-docker/pull/28) by [@louis70109](https://github.com/louis70109).
* 👷 Add alls-green GitHub Action. PR [#38](https://github.com/tiangolo/nginx-rtmp-docker/pull/38) by [@tiangolo](https://github.com/tiangolo).
* 👷 Build to test on CI for PRs, update GitHub Actions. PR [#37](https://github.com/tiangolo/nginx-rtmp-docker/pull/37) by [@tiangolo](https://github.com/tiangolo).
* ✏️ Fix a typo in README. PR [#20](https://github.com/tiangolo/nginx-rtmp-docker/pull/20) by [@Irishsmurf](https://github.com/Irishsmurf).
* 👷 Add Latest Changes GitHub Action. PR [#29](https://github.com/tiangolo/nginx-rtmp-docker/pull/29) by [@tiangolo](https://github.com/tiangolo).
* Add CI with GitHub actions. PR [#15](https://github.com/tiangolo/nginx-rtmp-docker/pull/15).
* Upgrade Nginx to version 1.18.0. PR [#13](https://github.com/tiangolo/nginx-rtmp-docker/pull/13) by [@Nathanael-Mtd](https://github.com/Nathanael-Mtd).

## License

This project is licensed under the terms of the MIT License.


