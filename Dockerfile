# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=36.34.0

# Base image
#============
FROM ghcr.io/containerbase/base:9.8.6@sha256:15302ae081adf21da91dff37695bfcdce7019052412968052c388c14ab3d1130 AS base

LABEL name="renovate"
LABEL org.opencontainers.image.source="https://github.com/renovatebot/renovate" \
  org.opencontainers.image.url="https://renovatebot.com" \
  org.opencontainers.image.licenses="AGPL-3.0-only"

# prepare all tools
RUN prepare-tool all

# renovate: datasource=node
RUN install-tool node v18.17.0

# renovate: datasource=npm versioning=npm
RUN install-tool yarn 1.22.19

WORKDIR /usr/src/app

# renovate: datasource=github-releases packageName=moby/moby
RUN install-tool docker v24.0.5

ENV RENOVATE_X_IGNORE_NODE_WARN=true

COPY bin/ /usr/local/bin/
CMD ["renovate"]

ARG RENOVATE_VERSION

RUN install-tool renovate

# Compabillity, so `config.js` can access renovate and deps
RUN ln -sf /opt/containerbase/tools/renovate/${RENOVATE_VERSION}/node_modules ./node_modules;

RUN set -ex; \
  renovate --version; \
  renovate-config-validator; \
  node -e "new require('re2')('.*').exec('test')"; \
  true

LABEL org.opencontainers.image.version="${RENOVATE_VERSION}"

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
