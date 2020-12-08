[![Build status](https://github.com/renovatebot/docker-renovate/workflows/build/badge.svg)](https://github.com/renovatebot/docker-renovate/actions?query=workflow%3Abuild)
[![Docker Image Size](https://img.shields.io/docker/image-size/renovate/renovate/slim)](https://hub.docker.com/r/renovate/renovate)
[![Version](https://img.shields.io/docker/v/renovate/renovate/slim)](https://hub.docker.com/r/renovate/renovate)

# docker-renovate


This repository is the source for the Docker Hub image `renovate/renovate`. Commits to `master` branch are automatically built and published.
It will publish the `slim` and the versioned tags with `slim` suffix.
For the `latest` image see [here](https://github.com/renovatebot/docker-renovate-full)

## Usage

Read the [self-hosting docs](https://docs.renovatebot.com/self-hosting/) for more information on how to self-host Renovate with Docker.


See [Gitlab](./docs/gitlab.md) or [Bitbucket](./docs/bitbucket.md) docs for more configuration samples.


### Samples
```sh
$ docker run --rm -it -v $PWD/config.js:/usr/src/app/config.js -v /tmp:/tmp -v /var/run/docker.sock:/var/run/docker.sock -e LOG_LEVEL=debug renovate/renovate:slim --include-forks=true renovate-tests/gomod1
```

```sh
$ export RENOVATE_TOKEN=xxxxxxx
$ docker run --rm -it -e RENOVATE_TOKEN -v /tmp:/tmp -v /var/run/docker.sock:/var/run/docker.sock renovate/renovate:slim renovate-tests/gomod1
```

#### config-validator
```sh
$ docker run --rm -it -v $PWD/config.js:/usr/src/app/config.js -e LOG_LEVEL=debug renovate/renovate:slim renovate-config-validator
```
