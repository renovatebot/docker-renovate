[![Build status](https://github.com/renovatebot/docker-renovate/workflows/build/badge.svg)](https://github.com/renovatebot/docker-renovate/actions?query=workflow%3Abuild)
[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/renovate/renovate?sort=date)](https://hub.docker.com/r/renovate/renovate)

# docker-renovate


This repository is the source for the Docker Hub image `renovate/renovate`. Commits to `master` branch are automatically built and published.

## Usage

See [docs](https://github.com/renovatebot/renovate/blob/master/docs/development/self-hosting.md#self-hosting-renovate) for additional information to self-hosting renovate with docker.

### run full image samples
```sh
$ docker run --rm -it -v $PWD/config.js:/usr/src/app/config.js -e LOG_LEVEL=debug renovate/renovate --include-forks=true renovate-tests/gomod1
```

```sh
$ export RENOVATE_TOKEN=xxxxxxx
$ docker run --rm -it -e RENOVATE_TOKEN renovate/renovate renovate-tests/gomod1
```

### run slim image samples
```sh
$ docker run --rm -it -v $PWD/config.js:/usr/src/app/config.js -v /tmp:/tmp -v /var/run/docker.sock:/var/run/docker.sock -e LOG_LEVEL=debug renovate/renovate:slim --include-forks=true renovate-tests/gomod1
```

```sh
$ export RENOVATE_TOKEN=xxxxxxx
$ docker run --rm -it -e RENOVATE_TOKEN -v /tmp:/tmp -v /var/run/docker.sock:/var/run/docker.sock renovate/renovate:slim renovate-tests/gomod1
```
