# Samples for bitbucket pipelines

This are samples for running a self-hosted renovate on bitbucket.org pipelines.

*TODO* pin and update renovate

**bitbucket-pipelines.yml**
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
