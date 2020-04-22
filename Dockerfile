ARG IMAGE=latest

# Base image
#============
FROM renovate/buildpack AS base

LABEL maintainer="Rhys Arkins <rhys@arkins.net>"
LABEL name="renovate"
LABEL org.opencontainers.image.source="https://github.com/renovatebot/renovate" \
      org.opencontainers.image.url="https://renovatebot.com" \
      org.opencontainers.image.licenses="AGPL-3.0-only"

USER root
WORKDIR /usr/src/app/

# Python

# renovate: datasource=docker depName=python
ENV PYTHON_VERSION=3.8.2
RUN install-tool python

# Node

# renovate: datasource=docker depName=node versioning=docker
ENV NODE_VERSION=12.16.2
RUN install-tool node

# Yarn

# renovate: datasource=npm depName=yarn versioning=npm
ENV YARN_VERSION=1.22.4
RUN install-tool yarn

# Build image
#============
FROM base as tsbuild


COPY package.json .
COPY yarn.lock .
RUN yarn install --frozen-lockfile --link-duplicates --production

# check is re2 is usable
RUN node -e "new require('re2')('.*').exec('test')"

# TODO: remove in v20
RUN mkdir dist && echo "require('renovate/dist/renovate.js');" > dist/renovate.js

# TODO: enable in v20
#COPY src src
#RUN yarn build
# compatability file
#RUN echo "require('./index.js');" > dist/renovate.js
#RUN cp -r ./node_modules/renovate/data ./dist/data


# Final-base image
#============
FROM base as final-base

# Docker client

# renovate: datasource=docker depName=docker versioning=docker
ENV DOCKER_VERSION=19.03.8
RUN install-tool docker

# Slim image
#============
FROM final-base as slim

ENV RENOVATE_BINARY_SOURCE=docker

# Full image
#============
FROM final-base as latest

# General tools

RUN install-apt gpg wget unzip xz-utils openssh-client bsdtar dirmngr

# Gradle

# renovate: datasource=docker depName=openjdk versioning=docker
ENV JAVA_VERSION=8
RUN install-tool java

# renovate: datasource=gradle-version depName=gradle versioning=maven
ENV GRADLE_VERSION=6.3
RUN install-tool gradle

# Erlang

ENV ERLANG_VERSION=22.0.2-1
RUN install-tool erlang

# Elixir

# renovate: datasource=docker depName=elixir versioning=docker
ENV ELIXIR_VERSION=1.8.2
RUN install-tool elixir

# PHP Composer

# renovate: datasource=docker depName=php versioning=docker
ENV PHP_VERSION=7.4
RUN install-tool php

# renovate: datasource=github-releases depName=composer/composer
ENV COMPOSER_VERSION=1.10.5
RUN install-tool composer

# Golang

# renovate: datasource=docker depName=golang versioning=docker
ENV GOLANG_VERSION=1.14.2
RUN install-tool golang

# Pip

# renovate: datasource=pypi depName=pip
ENV PIP_VERSION=20.0.2
RUN install-tool pip

# Pipenv

# renovate: datasource=pypi depName=pipenv
ENV PIPENV_VERSION=2018.11.26
RUN install-pip pipenv

# Poetry

# renovate: datasource=github-releases depName=python-poetry/poetry
ENV POETRY_VERSION=1.0.5
RUN install-tool poetry

# Cargo

# renovate: datasource=docker depName=rust versioning=docker
ENV RUST_VERSION=1.36.0
RUN install-tool rust

# CocoaPods

# renovate: datasource=docker depName=ruby versioning=docker
ENV RUBY_VERSION 2.5.8
RUN install-tool ruby

# renovate: datasource=rubygems depName=cocoapods versioning=ruby
ENV COCOAPODS_VERSION 1.9.1
RUN install-gem cocoapods

# Pnpm

# renovate: datasource=npm depName=npm versioning=npm
ENV PNPM_VERSION=4.12.0
RUN install-tool pnpm

USER ubuntu

# Mix and Rebar

RUN mix local.hex --force
RUN mix local.rebar --force

# Renovate
#=========
FROM $IMAGE as final

COPY package.json package.json
COPY --from=tsbuild /usr/src/app/dist dist

# TODO: remove in v20
COPY --from=tsbuild /usr/src/app/node_modules node_modules

ENTRYPOINT [ "/usr/bin/dumb-init", "--", "/usr/local/docker/entrypoint.sh", "node", "/usr/src/app/dist/renovate.js" ]
CMD []


# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=19.215.0

RUN npm --no-git-tag-version version ${RENOVATE_VERSION}

LABEL org.opencontainers.image.version="${RENOVATE_VERSION}"

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
