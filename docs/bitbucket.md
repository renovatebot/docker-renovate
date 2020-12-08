# Samples for bitbucket pipelines (bitbucket.org)

*TODO* pin and update renovate

```yml
image: renovate/renovate

pipelines:
  default:
      - step:
          name: renovate
          services:
              - docker
          caches:
              - docker
          script:
              - export GITHUB_COM_TOKEN=$RENOVATE_TOKEN RENOVATE_CONFIG_FILE="$BITBUCKET_CLONE_DIR/config.js" LOG_LEVEL=debug renovate --platform=bitbucket --username=$USERNAME --password=$PASSWORD 
```
