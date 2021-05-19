# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=25.21.13

# Base image
#============
FROM renovate/buildpack:5@sha256:5bd49b123c18f2b4acab437399fe2d07b368dcce468a9abca5ca1e59920b5b2d AS base

LABEL name="renovate"
LABEL org.opencontainers.image.source="https://github.com/renovatebot/renovate" \
  org.opencontainers.image.url="https://renovatebot.com" \
  org.opencontainers.image.licenses="AGPL-3.0-only"

# renovate: datasource=docker versioning=docker
RUN install-tool node 14.17.0

# renovate: datasource=npm versioning=npm
RUN install-tool yarn 1.22.10

WORKDIR /usr/src/app

# Build image
#============
FROM base as tsbuild

RUN install-npm yarn-deduplicate

COPY package.json .
COPY yarn.lock .

ARG RENOVATE_VERSION
RUN npm --no-git-tag-version version ${RENOVATE_VERSION}
RUN yarn add -E renovate@${RENOVATE_VERSION}

RUN yarn install --frozen-lockfile

COPY tsconfig.json .
COPY tsconfig.app.json .
COPY src src

RUN set -ex; \
  yarn build; \
  chmod +x dist/*.js; \
  yarn-deduplicate --strategy highest; \
  yarn install --frozen-lockfile --production

# Final image
#============
FROM base as final

# renovate: datasource=docker versioning=docker
RUN install-tool docker 20.10.6

ENV RENOVATE_BINARY_SOURCE=docker

COPY --from=tsbuild /usr/src/app/package.json package.json
COPY --from=tsbuild /usr/src/app/dist dist
COPY --from=tsbuild /usr/src/app/node_modules node_modules

# exec helper
COPY bin/ /usr/local/bin/
RUN ln -sf /usr/src/app/dist/renovate.js /usr/local/bin/renovate;
RUN ln -sf /usr/src/app/dist/config-validator.js /usr/local/bin/renovate-config-validator;
CMD ["renovate"]


RUN set -ex; \
  renovate --version; \
  renovate-config-validator; \
  node -e "new require('re2')('.*').exec('test')";

ARG RENOVATE_VERSION
LABEL org.opencontainers.image.version="${RENOVATE_VERSION}"

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
