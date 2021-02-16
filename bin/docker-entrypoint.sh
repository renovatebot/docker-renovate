#!/bin/bash

if [[ -f "$BASH_ENV" && -z "${BUILDPACK+x}" ]]; then
  . $BASH_ENV
fi

cmd=renovate

if [[ ! -z "${RENOVATE_DIND+x}" ]]; then
  cmd=renovate-dind
  export XDG_RUNTIME_DIR=/run/user/${USER_ID}
  export DOCKER_HOST=unix://${XDG_RUNTIME_DIR}/docker.sock
fi

if [[ "${1:0:1}" = '-' ]]; then
  # assume $1 is renovate flag
  set -- $cmd "$@"
fi

if [[ ! -x "$(command -v ${1})" ]]; then
  # assume $1 is a repo
  set -- $cmd "$@"
fi

exec dumb-init -- "$@"
