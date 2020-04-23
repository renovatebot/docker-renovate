ARG IMAGE=latest

# Base image
#============
FROM renovate/buildpack:1@sha256:10e98460170e2ed4ea5150f5baefe0589c60bd8c63bf1f06fac5b8a61b61040d AS base

LABEL maintainer="Rhys Arkins <rhys@arkins.net>"
LABEL name="renovate"
LABEL org.opencontainers.image.source="https://github.com/renovatebot/renovate" \
  org.opencontainers.image.url="https://renovatebot.com" \
  org.opencontainers.image.licenses="AGPL-3.0-only"

USER root
WORKDIR /usr/src/app/

# renovate: datasource=docker
RUN install-tool python 3.8.2

# renovate: datasource=docker versioning=docker
RUN install-tool node 12.16.2

# renovate: datasource=npm versioning=npm
RUN install-tool yarn 1.22.4

# Build image
#============
FROM base as tsbuild


COPY package.json .
COPY yarn.lock .
RUN yarn install --frozen-lockfile --link-duplicates --production

# check is re2 is usable
RUN node -e "new require('re2')('.*').exec('test')"

# TODO: remove in v20
RUN set -ex; \
  mkdir dist; \
  echo "#!/usr/bin/env node" >> dist/renovate.js; \
  echo "require('renovate/dist/renovate.js');" >> dist/renovate.js; \
  chmod +x dist/renovate.js;

# TODO: enable in v20
#COPY src src
#RUN yarn build
# compatability file
#RUN echo "require('./index.js');" > dist/renovate.js
#RUN cp -r ./node_modules/renovate/data ./dist/data


# Final-base image
#============
FROM base as final-base

# renovate: datasource=docker versioning=docker
RUN install-tool docker 19.03.8

# Slim image
#============
FROM final-base as slim

ENV RENOVATE_BINARY_SOURCE=docker

# Full image
#============
FROM final-base as latest

# go suggests: git svn bzr mercurial
RUN install-apt bzr mercurial

# renovate: datasource=docker lookupName=openjdk versioning=docker
RUN install-tool java 8

# renovate: datasource=gradle-version versioning=maven
RUN install-tool gradle 6.3

RUN install-tool erlang 22.0.2-1

# renovate: datasource=docker versioning=docker
RUN install-tool elixir 1.8.2

# renovate: datasource=docker versioning=docker
RUN install-tool php 7.4

# renovate: datasource=github-releases lookupName=composer/composer
RUN install-tool composer 1.10.5

# renovate: datasource=docker versioning=docker
RUN install-tool golang 1.14.2

# renovate: datasource=pypi
RUN install-tool pip 20.0.2

# renovate: datasource=pypi
RUN install-pip pipenv 2018.11.26


# renovate: datasource=github-releases lookupName=python-poetry/poetry
RUN install-tool poetry 1.0.5

# renovate: datasource=docker versioning=docker
RUN install-tool rust 1.36.0

# renovate: datasource=docker versioning=docker
RUN install-tool ruby 2.5.8

# renovate: datasource=rubygems versioning=ruby
RUN install-gem cocoapods 1.9.1

# renovate: datasource=npm versioning=npm
RUN install-tool pnpm 4.12.0


# Renovate
#=========
FROM $IMAGE as final

COPY package.json package.json
COPY --from=tsbuild /usr/src/app/dist dist

# TODO: remove in v20
COPY --from=tsbuild /usr/src/app/node_modules node_modules

# exec helper
COPY bin/ /usr/local/bin/
RUN ln -sf /usr/src/app/dist/renovate.js /usr/local/bin/renovate;
CMD ["renovate"]

# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=19.215.0

RUN npm --no-git-tag-version version ${RENOVATE_VERSION} && renovate --version;

LABEL org.opencontainers.image.version="${RENOVATE_VERSION}"

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
