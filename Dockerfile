# Base image
#============
FROM renovate/buildpack:1@sha256:0fa21d11578682fb27ab2abdf885854ae4ce4fe05a411622c371adccef0cd755 AS base

LABEL name="renovate"
LABEL org.opencontainers.image.source="https://github.com/renovatebot/renovate" \
  org.opencontainers.image.url="https://renovatebot.com" \
  org.opencontainers.image.licenses="AGPL-3.0-only"

# renovate: datasource=docker versioning=docker
RUN install-tool node 12.16.3

# renovate: datasource=npm versioning=npm
RUN install-tool yarn 1.22.4

# Build image
#============
FROM base as tsbuild

# use buildin python to faster build
RUN install-apt build-essential python3

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


# Final image
#============
FROM base as final

# renovate: datasource=docker versioning=docker
RUN install-tool docker 19.03.8

ENV RENOVATE_BINARY_SOURCE=docker

COPY package.json package.json
COPY --from=tsbuild /usr/src/app/dist dist

# TODO: remove in v20
COPY --from=tsbuild /usr/src/app/node_modules node_modules

# exec helper
COPY bin/ /usr/local/bin/
RUN ln -sf /usr/src/app/dist/renovate.js /usr/local/bin/renovate;
CMD ["renovate"]

# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=19.231.0

RUN npm --no-git-tag-version version ${RENOVATE_VERSION} && renovate --version;

LABEL org.opencontainers.image.version="${RENOVATE_VERSION}"

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
