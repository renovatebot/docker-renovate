# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=23.14.5

# Base image
#============
FROM renovate/buildpack:2@sha256:aab999f9a91d57378f15a565ae56cc5f4df18798196415767ad25275f106e2db AS base

LABEL name="renovate"
LABEL org.opencontainers.image.source="https://github.com/renovatebot/renovate" \
  org.opencontainers.image.url="https://renovatebot.com" \
  org.opencontainers.image.licenses="AGPL-3.0-only"

# renovate: datasource=docker versioning=docker
RUN install-tool node 12.18.3

# renovate: datasource=npm versioning=npm
RUN install-tool yarn 1.22.5

# Build image
#============
FROM base as tsbuild

# use buildin python to faster build
RUN install-apt build-essential python3
RUN npm install -g yarn-deduplicate

COPY package.json .
COPY yarn.lock .

RUN yarn install --frozen-lockfile --link-duplicates

COPY tsconfig.json .
COPY tsconfig.app.json .
COPY src src

RUN set -ex; \
  yarn build; \
  chmod +x dist/*.js;

ARG RENOVATE_VERSION
RUN yarn add renovate@${RENOVATE_VERSION} --link-duplicates
RUN yarn-deduplicate --strategy highest
RUN yarn install --frozen-lockfile --link-duplicates --production

# check is re2 is usable
RUN node -e "new require('re2')('.*').exec('test')"


# TODO: enable
#COPY src src
#RUN yarn build
# compatability file
#RUN echo "require('./index.js');" > dist/renovate.js
#RUN cp -r ./node_modules/renovate/data ./dist/data


# Final image
#============
FROM base as final

# renovate: datasource=docker versioning=docker
RUN install-tool docker 19.03.12

ENV RENOVATE_BINARY_SOURCE=docker

COPY --from=tsbuild /usr/src/app/package.json package.json
COPY --from=tsbuild /usr/src/app/dist dist

# TODO: remove
COPY --from=tsbuild /usr/src/app/node_modules node_modules

# exec helper
COPY bin/ /usr/local/bin/
RUN ln -sf /usr/src/app/dist/renovate.js /usr/local/bin/renovate;
RUN ln -sf /usr/src/app/dist/config-validator.js /usr/local/bin/renovate-config-validator;
CMD ["renovate"]

ARG RENOVATE_VERSION

RUN npm --no-git-tag-version version ${RENOVATE_VERSION} && renovate --version;

LABEL org.opencontainers.image.version="${RENOVATE_VERSION}"

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
