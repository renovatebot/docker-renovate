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

# renovate: datasource=docker depName=node versioning=docker
ARG NODE_VERSION=12.16.2
RUN install-tool node

# renovate: datasource=npm depName=yarn versioning=npm
ARG YARN_VERSION=1.22.4
RUN install-tool yarn

# Build image
#============
FROM base as tsbuild

# Python 3 and make are required to build node-re2
RUN install-apt python3 build-essential

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

# Docker client and group

RUN groupadd -g 999 docker
RUN usermod -aG docker ubuntu

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

RUN install-apt gpg wget unzip xz-utils openssh-client bsdtar build-essential dirmngr


# renovate: datasource=docker depName=openjdk versioning=docker
ARG JAVA_VERSION=8
RUN install-tool java

## Gradle (needs java-jdk, installed above)
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

# Go Modules

# renovate: datasource=docker depName=golang versioning=docker
ARG GOLANG_VERSION=1.14.2
RUN install-tool golang

# Python
# required by poetry
RUN install-apt python3  python3-distutils
RUN install-tool python 3.8

# Pip

# renovate: datasource=pypi depName=pip
ENV PIP_VERSION=20.0.2
RUN install-tool pip

# Pipenv

# renovate: datasource=pypi depName=pipenv
ENV PIPENV_VERSION=2018.11.26
RUN pip install pipenv==${PIPENV_VERSION}

# Poetry

# python3-distutils installs python3.6
# renovate: datasource=github-releases depName=python-poetry/poetry
ENV POETRY_VERSION=1.0.5
RUN install-tool poetry

# Cargo

# renovate: datasource=docker depName=rust versioning=docker
ENV RUST_VERSION=1.36.0
RUN install-tool rust

# CocoaPods
RUN install-apt ruby ruby2.5-dev
RUN ruby --version

# renovate: datasource=rubygems depName=cocoapods versioning=ruby
ENV COCOAPODS_VERSION 1.9.1
RUN install-gem cocoapods


# renovate: datasource=npm depName=npm versioning=npm
ARG PNPM_VERSION=4.12.0
RUN install-tool pnpm

RUN chmod +x /usr/local/poetry/bin/poetry
RUN install-apt python3.8-venv

USER ubuntu

# Add python user home
ENV PATH=/home/ubuntu/.local:$PATH

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
