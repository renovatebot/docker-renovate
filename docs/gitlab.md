# GitLab Configuration

Here are some configuration examples for configuring Renovate to run as GitLab pipeline.
See [self-hosting](https://docs.renovatebot.com/getting-started/running/#self-hosting-renovate) doc for additional information.

For gitlab.com we recommend to check out the [renovate-bot/renovate-runner](https://gitlab.com/renovate-bot/renovate-runner) project. Here we have prepared some pipeline templates to run Renovate on pipeline schedules.

## Renovate slim with mapped Docker socket

This sample will configure the Renovate slim image, with will use docker side containers to run additional tools required to update lockfiles.
Some [managers](https://docs.renovatebot.com/modules/manager/) need side containers for dependency extraction too (eg: `gradle`).

This sample will not work on gitlab.com hosted shared runner, you need a self-hosted runner!


**Additional project environment:**
- `RENOVATE_TOKEN`: access token for renovate to gitlab api (**required**)
- `GITHUB_COM_TOKEN`: suppress github api rate limits (**required**)
- `RENOVATE_EXTRA_FLAGS`: pass additional commandline args (**optional**)

### GitLab runner config

You should register and use a separate GitLab runner, because we are mapping the host Docker socket to renovate.
You also need to map the host `/tmp` folder symmetrically, because renovate will use `/tmp/renovate` as [`baseDir`](https://docs.renovatebot.com/self-hosted-configuration/#basedir) by default.
Renovate will map `baseDir` to the Docker side container running tools like `python`, `java`, `gradle` and more.

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

### GitLab pipeline

The following pipeline runs Renovate normally on `master` branch and for self-update it runs in [`dryRun`](https://docs.renovatebot.com/self-hosted-configuration/#dryrun) mode.

```yml
image: renovate/renovate:32.6.0-slim@sha256:6a722989e5402841f18b1a488dc3b117fd6afae0f61544134069fd3dba5bba83

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

The `config.js` should be in repo root, because Renovate will load it from current directory by default.

If you want to override the Git author and committer, you need to override with environment variables (see below).
This is necessary, because the env is preset by Gitlab and overrides any Git config done by Renovate.

There is a `hostRule` for the GitLab Docker registry.
The `hostRule`is only required if you use the GitLab registry and Renovate should provide updates from that.
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


## Renovate slim with Docker-in-Docker (dind)

This sample uses the `docker-in-docker` GitLab runner.

**Additional project environment:**
- `RENOVATE_TOKEN`: access token for renovate to gitlab api (**required**)
- `GITHUB_COM_TOKEN`: suppress github api rate limits (**required**)
- `RENOVATE_EXTRA_FLAGS`: pass additional commandline args (**optional**)

### GitLab pipeline

```yml
image: renovate/renovate:32.6.0-slim@sha256:6a722989e5402841f18b1a488dc3b117fd6afae0f61544134069fd3dba5bba83

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
