# docker-renovate

[![Build status](https://github.com/renovatebot/docker-renovate/actions/workflows/build.yml/badge.svg)](https://github.com/renovatebot/docker-renovate/actions?query=workflow%3Abuild)
[![Docker Image Size](https://img.shields.io/docker/image-size/renovate/renovate/latest)](https://hub.docker.com/r/renovate/renovate)
[![Version](https://img.shields.io/docker/v/renovate/renovate/latest)](https://hub.docker.com/r/renovate/renovate)

This repository is the source for the Docker Hub image `renovate/renovate`.
Commits to `main` branch are automatically built and published.
It will publish the `latest` and `slim` and the versioned tags without suffix and with `-slim` suffix.
For the `full` image see [here](https://github.com/renovatebot/docker-renovate-full)

## Usage

Read the [self-hosting docs](https://docs.renovatebot.com/getting-started/running/#self-hosting-renovate) for more information on how to self-host Renovate with Docker.

See [Gitlab](./docs/gitlab.md), [Bitbucket](./docs/bitbucket.md) or [Jenkins](./docs/jenkins.md) docs for more configuration samples.

### Samples

```sh
docker run --rm -it -v $PWD/config.js:/usr/src/app/config.js -v /tmp:/tmp -e LOG_LEVEL=debug renovate/renovate --include-forks=true renovate-tests/gomod1
```

```sh
export RENOVATE_TOKEN=xxxxxxx
docker run --rm -it -e RENOVATE_TOKEN -v /tmp:/tmp renovate/renovate renovate-tests/gomod1
```

#### config-validator

```sh
docker run --rm -it -v $PWD/config.js:/usr/src/app/config.js -e LOG_LEVEL=debug renovate/renovate renovate-config-validator
```
