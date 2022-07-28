#!/bin/bash

if [[ -f "$BASH_ENV" && -z "${BUILDPACK+x}" ]]; then
  # shellcheck source=/dev/null
  . "$BASH_ENV"
fi

if [[ "${1:0:1}" = '-' ]]; then
  # assume $1 is renovate flag
  set -- renovate "$@"
fi

if [[ ! -x "$(command -v "${1}")" ]]; then
  # assume $1 is a repo
  set -- renovate "$@"
fi

exec dumb-init -- "$@"
