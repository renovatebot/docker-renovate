ARG IMAGE=latest

# Base image
#============
FROM renovate/buildpack:1@sha256:2a94923b7bb1956f5faf1c82b4578436774e13786ce4f693a713b63185e88af2 AS base

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
RUN apt-get update && apt-get install -y python3 build-essential
# force python3 for node-gyp
RUN ln -sf /usr/bin/python3 /usr/bin/python

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

RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
    && tar xzvf docker-${DOCKER_VERSION}.tgz --strip 1 \
    -C /usr/local/bin docker/docker \
    && rm docker-${DOCKER_VERSION}.tgz

# Slim image
#============
FROM final-base as slim

ENV RENOVATE_BINARY_SOURCE=docker

# Full image
#============
FROM final-base as latest

RUN apt-get update && \
    apt-get install -y gpg wget unzip xz-utils openssh-client bsdtar build-essential dirmngr && \
    rm -rf /var/lib/apt/lists/*


# renovate: datasource=docker depName=openjdk versioning=docker
ARG JAVA_VERSION=8
RUN install-tool java

## Gradle (needs java-jdk, installed above)
# renovate: datasource=gradle-version depName=gradle versioning=maven
ENV GRADLE_VERSION=6.3
RUN install-tool gradle

# Erlang

RUN cd /tmp && \
    curl https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb -o erlang-solutions_1.0_all.deb && \
    dpkg -i erlang-solutions_1.0_all.deb && \
    rm -f erlang-solutions_1.0_all.deb

ENV ERLANG_VERSION=22.0.2-1

RUN apt-get update && \
    apt-cache policy esl-erlang && \
    apt-get install -y esl-erlang=1:$ERLANG_VERSION && \
    rm -rf /var/lib/apt/lists/*

# Elixir

# renovate: datasource=docker depName=elixir versioning=docker
ENV ELIXIR_VERSION=1.8.2

RUN curl -L https://github.com/elixir-lang/elixir/releases/download/v${ELIXIR_VERSION}/Precompiled.zip -o Precompiled.zip && \
    mkdir -p /opt/elixir-${ELIXIR_VERSION}/ && \
    unzip Precompiled.zip -d /opt/elixir-${ELIXIR_VERSION}/ && \
    rm Precompiled.zip

ENV PATH $PATH:/opt/elixir-${ELIXIR_VERSION}/bin

# PHP Composer

# renovate: datasource=github-releases depName=composer/composer
ENV COMPOSER_VERSION=1.10.5
RUN install-tool composer

# Go Modules

# renovate: datasource=docker depName=golang versioning=docker
ARG GOLANG_VERSION=1.14.2
RUN install-tool golang

# Python

RUN apt-get update && apt-get install -y python3.8-dev python3.8-venv python3-distutils && \
    rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3.8 /usr/bin/python3
RUN ln -sf /usr/bin/python3.8 /usr/bin/python

# Pip

RUN curl --silent https://bootstrap.pypa.io/get-pip.py | python

# CocoaPods
RUN apt-get update && apt-get install -y ruby ruby2.5-dev && rm -rf /var/lib/apt/lists/*
RUN ruby --version

# renovate: datasource=rubygems depName=cocoapods versioning=ruby
ENV COCOAPODS_VERSION 1.9.1
RUN gem install --no-rdoc --no-ri cocoapods -v ${COCOAPODS_VERSION}


# renovate: datasource=npm depName=npm versioning=npm
ARG PNPM_VERSION=4.12.0
RUN install-tool pnpm

USER ubuntu

# Cargo

ENV RUST_BACKTRACE=1 \
  PATH=${HOME}/.cargo/bin:$PATH

# renovate: datasource=docker depName=rust versioning=docker
ENV RUST_VERSION=1.36.0

RUN set -ex ;\
  curl https://sh.rustup.rs -sSf | sh -s -- --no-modify-path --profile minimal --default-toolchain ${RUST_VERSION} -y

# Mix and Rebar

RUN mix local.hex --force
RUN mix local.rebar --force

# Pipenv

ENV PATH="${HOME}/.local/bin:$PATH"

RUN pip install --user pipenv

# Poetry

# renovate: datasource=github-releases depName=python-poetry/poetry
ENV POETRY_VERSION=1.0.5

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python - --version ${POETRY_VERSION}

ENV PATH="${HOME}/.poetry/bin:$PATH"
RUN poetry config virtualenvs.in-project false


# Renovate
#=========
FROM $IMAGE as final

COPY package.json package.json
COPY --from=tsbuild /usr/src/app/dist dist

# TODO: remove in v20
COPY --from=tsbuild /usr/src/app/node_modules node_modules

ENTRYPOINT ["node", "/usr/src/app/dist/renovate.js"]
CMD []


# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=19.215.0

RUN npm --no-git-tag-version version ${RENOVATE_VERSION}

LABEL org.opencontainers.image.version="${RENOVATE_VERSION}"

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
