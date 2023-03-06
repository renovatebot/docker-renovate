# Samples for Bitbucket pipelines

These are configuration examples for running a self-hosted Renovate on bitbucket.org pipelines.

### bitbucket-pipelines.yml
```yml
image: renovate/renovate:34.157.1-slim

definitions:
  caches:
    renovate: renovate

pipelines:
  default:
    - step:
        name: renovate dry-run
        services:
          - docker
        caches:
          - docker
          - renovate
        script:
          - export LOG_LEVEL=debug RENOVATE_CONFIG_FILE="$BITBUCKET_CLONE_DIR/config.js"
          - renovate --dry-run
  branches:
    master:
      - step:
          name: renovate
          services:
            - docker
          caches:
            - docker
            - renovate
          script:
            - export LOG_LEVEL=debug RENOVATE_CONFIG_FILE="$BITBUCKET_CLONE_DIR/config.js"
            - renovate
```

### config.js
Example of manual repository config:
```js
module.exports = {
  platform: 'bitbucket',
  username: process.env.USERNAME,
  password: process.env.PASSWORD,
  baseDir: `${process.env.BITBUCKET_CLONE_DIR}/renovate`,
  repositories: [ "user1/repo1", "orh/repo2" ],
}
```

Using autodiscover:
```js
module.exports = {
  platform: 'bitbucket',
  username: process.env.USERNAME,
  password: process.env.PASSWORD,
  baseDir: `${process.env.BITBUCKET_CLONE_DIR}/renovate`,
  autodiscover: true,
}
```

### renovate.json
Use this for self-update Renovate:
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [ "config:base" ],
   "regexManagers": [
    {
      "fileMatch": ["^bitbucket-pipelines.yml$"],
      "matchStrings": [
        "image: (?<depName>[a-z/-]+)(?::(?<currentValue>[a-z0-9.-]+))?(?:@(?<currentDigest>sha256:[a-f0-9]+))?"
      ],
      "datasourceTemplate": "docker",
      "versioningTemplate": "docker"
    }
  ]
}
```

### Variables
You need to define pipeline variables:
- `USERNAME`: Bitbucket.org username
- `PASSWORD`: Bitbucket.org password
- `GITHUB_COM_TOKEN`: GitHub token to fetch changelog (optional, highly recommended)

### Schedule

Configure a `hourly` schedule on `master` branch with `branches: master` pipeline.
