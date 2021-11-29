# Gitlab Configuration

Here are some configuation examples for configuring renovate to run as gitlab pipeline.
See [self-hosting](https://docs.renovatebot.com/getting-started/running/#self-hosting-renovate) doc for additional information.

For gitlab.com we recommend to checkout [this](https://gitlab.com/renovate-bot/renovate-runner). We've prepared some pipeline templates to simply run renovate on pipeline schedules.

## Renovate slim with mapped docker socket

This sample will configure the renovate slim image, with will use docker side containers to run additional tools required to update lockfiles.
Some [managers](https://docs.renovatebot.com/modules/manager/) need side containers for dependency extraction too (eg: `gradle`).

This sample will not work on gitlab.com hosted shared runner, you need a self-hosted runner!


**Additional project environment:**
- `RENOVATE_TOKEN`: access token for renovate to gitlab api (**required**)
- `GITHUB_COM_TOKEN`: suppress github api rate limits (**required**)
- `RENOVATE_EXTRA_FLAGS`: pass additional commandline args (**optional**)

### Gitlab runner config

You should register and use a separate gitlab runner, because we are mapping the host docker socket to renovate.
You also need to map the host `/tmp` folder symmetrically, because renovate will use `/tmp/renovate` as [`baseDir`](https://docs.renovatebot.com/self-hosted-configuration/#basedir) by default.
Renovate will map `baseDir` to the docker side container running tools like `python`, `java`, `gradle` and more.

```toml
[[runners]]
  name = "renovater"
  url = "https://gitlab.domain.com/"
  token = "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  executor = "docker"
  limit = 1
  [runners.custom_build_dir]
  [runners.docker]
    tls_verify = false
    image = "alpine"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/certs/client", "/cache", "/tmp:/tmp:rw", "/var/run/docker.sock:/var/run/docker.sock"]
    shm_size = 0
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
  [runners.custom]
    run_exec = ""
```

### Gitlab pipeline

The following pipeline runs renovate normally on master branch and for self-update it runs in [`dryRun`](https://docs.renovatebot.com/self-hosted-configuration/#dryrun) mode.

```yml
image: renovate/renovate:29.2.6-slim@sha256:008eb073b257800ab8a923f17790107086684b9d779e5493cc8e42acdd4bbee2

variables:
  LOG_LEVEL: debug

renovate:on-schedule:
  only:
    - schedules
  script:
    - renovate $RENOVATE_EXTRA_FLAGS

renovate:
  except:
    - schedules
  script:
    - renovate --dry-run $RENOVATE_EXTRA_FLAGS

```

### Renovate config

The `config.js` should be in repo root, because renovate will load it from current directory by default.

If you want to override the git author and commiter, you need to override with environment variables (see below).
This is necessary, because the env is preset by gitlab and overrides any git config done by renovate.

There is `hostRule` for the gitlab docker registry.
The `hostRule`is only required if you use the gitlab registry and renovate should provide updated from that.
`GITLAB_REGISTRY_TOKEN` is a gitlab [variable](https://docs.gitlab.com/ee/ci/variables/#create-a-custom-variable-in-the-ui).

```js
Object.assign(process.env, {
  GIT_AUTHOR_NAME: 'Renovate Bot',
  GIT_AUTHOR_EMAIL: 'bot@example.com',
  GIT_COMMITTER_NAME: 'Renovate Bot',
  GIT_COMMITTER_EMAIL: 'bot@example.com',
});

module.exports = {
  endpoint: process.env.CI_API_V4_URL,
  hostRules: [
    {
      baseUrl: 'https://registry.example.com',
      username: 'other-user',
      password: process.env.GITLAB_REGISTRY_TOKEN,
    },
  ],
  platform: 'gitlab',
  username: 'renovate-bot',
  gitAuthor: 'Renovate Bot <bot@example.com>',
  autodiscover: true,
};
```


## Renovate slim with docker-in-docker

This sample uses the `docker-in-docker` gitlab runner.

**Additional project environment:**
- `RENOVATE_TOKEN`: access token for renovate to gitlab api (**required**)
- `GITHUB_COM_TOKEN`: suppress github api rate limits (**required**)
- `RENOVATE_EXTRA_FLAGS`: pass additional commandline args (**optional**)

### Gitlab pipeline
```yml
image: renovate/renovate:29.2.6-slim@sha256:008eb073b257800ab8a923f17790107086684b9d779e5493cc8e42acdd4bbee2

variables:
  RENOVATE_BASE_DIR: $CI_PROJECT_DIR/renovate
  RENOVATE_PLATFORM: gitlab
  RENOVATE_ENDPOINT: $CI_API_V4_URL
  RENOVATE_AUTODISCOVER: true
  LOG_LEVEL: debug

services:
  - docker:19.03-dind

before_script:
  # Prepare renovate directory
  - mkdir $RENOVATE_BASE_DIR

renovate:on-schedule:
  only:
    - schedules
  script:
    - renovate $RENOVATE_EXTRA_FLAGS

# test self updates with dry-run
renovate:
  except:
    - schedules
  script:
    - renovate --dry-run $RENOVATE_EXTRA_FLAGS
```
