# Samples for bitbucket pipelines

This are samples for running a self-hosted renovate on bitbucket.org pipelines.
The branches

**bitbucket-pipelines.yml**
```yml
image: renovate/renovate:23.96.2

definitions:
  caches:
    - docker

pipelines:
  default:
    - step:
        name: renovate
        services:
          - docker
        script:
          - export GITHUB_COM_TOKEN=$RENOVATE_TOKEN RENOVATE_CONFIG_FILE="$BITBUCKET_CLONE_DIR/config.js" LOG_LEVEL=debug renovate
  branches:
    renovate/*:
      - step:
          name: renovate dry-run
          services:
            - docker
          script:
            - export GITHUB_COM_TOKEN=$RENOVATE_TOKEN RENOVATE_CONFIG_FILE="$BITBUCKET_CLONE_DIR/config.js" LOG_LEVEL=debug renovate --dry-run
```

## **config.js**
Manual repository config
```js
module.exports = {
  platform: 'bitbucket',
  username: process.env.USERNAME,
  password: process.env.PASSWORD,
  repositories: [ "user1/repo1", "orh/repo2" ],
  //
}
```

Using autodiscover
```js
module.exports = {
  platform: 'bitbucket',
  username: process.env.USERNAME,
  password: process.env.PASSWORD,
  autodiscover: true,
}
```

## **renovate.json**
Use this for self-update renovate
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
