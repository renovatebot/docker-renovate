# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=34.117.1

# Base image
#============
FROM ghcr.io/containerbase/buildpack:5.11.0@sha256:6cf4edd1fadd9a151fe5c4910d3228c97cc82495012e6d27239ca775e2902c0b AS base

LABEL name="renovate"
LABEL org.opencontainers.image.source="https://github.com/renovatebot/renovate" \
  org.opencontainers.image.url="https://renovatebot.com" \
  org.opencontainers.image.licenses="AGPL-3.0-only"

# renovate: datasource=node
RUN install-tool node v16.19.0

# renovate: datasource=npm versioning=npm
RUN install-tool yarn 1.22.19

WORKDIR /usr/src/app

# renovate: datasource=github-releases depName=docker lookupName=moby/moby
RUN install-tool docker 20.10.7

ENV RENOVATE_BINARY_SOURCE=docker
ENV RENOVATE_X_IGNORE_NODE_WARN=true

COPY bin/ /usr/local/bin/
CMD ["renovate"]

ARG RENOVATE_VERSION

RUN install-tool renovate

# Compabillity, so `config.js` can access renovate and deps
RUN ln -sf /opt/buildpack/tools/renovate/${RENOVATE_VERSION}/node_modules ./node_modules;

RUN set -ex; \
  renovate --version; \
  renovate-config-validator; \
  node -e "new require('re2')('.*').exec('test')"; \
  true

LABEL org.opencontainers.image.version="${RENOVATE_VERSION}"

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
