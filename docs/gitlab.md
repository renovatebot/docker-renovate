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
image: renovate/renovate:34.152.5-slim@sha256:74e2849f710febafc79f5a77c9b064d86c554105b9f3ca82fb98f6adda9e108d

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
image: renovate/renovate:34.152.5-slim@sha256:74e2849f710febafc79f5a77c9b064d86c554105b9f3ca82fb98f6adda9e108d

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

## Parallel Renovate jobs per project

The default `renovate` job of [renovate-bot/renovate-runner](https://gitlab.com/renovate-bot/renovate-runner) does a single run which discovers all repositories and prepares updates for each repository one after another.

These updates can be speed up by doing the runs once for each project in parallel. This also reduces the risk of the run failing altogether if there are errors with one or more repositories.

This is possible in GitLab using [dynamic child pipelines](https://docs.gitlab.com/ee/ci/pipelines/parent_child_pipelines.html#dynamic-child-pipelines).  For this, we need two GitLab pipelines, the usual toplevel `.gitlab-ci.yml` and a separate `templates/.gitlab-ci.yml`:

<details>
<summary>.gitlab-ci.yml</summary>

```yaml
include:
  - project: 'renovate-bot/renovate-runner'
    file: '/templates/renovate-dind.gitlab-ci.yml'
    ref: v8.81.6

renovate:
  variables:
    RENOVATE_AUTODISCOVER: 'true'
    RENOVATE_AUTODISCOVER_FILTER: '<group>/**'
  script:
    - renovate --write-discovered-repos=template/renovate-repos.json
    - sed "s~###RENOVATE_REPOS###~$(cat template/renovate-repos.json)~" template/.gitlab-ci.yml > .gitlab-renovate-repos.yml
  artifacts:
    paths:
      - renovate-repos.json
      - .gitlab-renovate-repos.yml

renovate:repos:
  stage: deploy
  needs:
    - renovate
  inherit:
    variables: false
  trigger:
    include:
      - job: renovate
        artifact: .gitlab-renovate-repos.yml
```
</details>

This slightly adjusts the `renovate` job to fetch and [write the list of discovered repositories](https://docs.renovatebot.com/self-hosted-configuration/#writediscoveredrepos) to `template/renovate-repos.json`. This file and the `template/.gitlab-ci.yml` is then used to generate a `.gitlab-renovate-repos.yml`. Here we use `sed` but anything else would be equally fine; for `sed` it's important to use a different delimiter than the common `/` since the `template/renovate-repos.json` will contain `/` characters.
  
The `renovate:repos` job uses the generated `.gitlab-renovate-repos.yml` to trigger a child pipeline. The `inherit.variables: false` here is essential to [ensure all predefined GitLab variables are populated](https://gitlab.com/gitlab-org/gitlab/-/issues/214340#note_423996331) normally in the child pipeline.

<details>
<summary>template/.gitlab-ci.yml</summary>

```yaml
include:
  - project: 'renovate-bot/renovate-runner'
    file: '/templates/renovate-dind.gitlab-ci.yml'
    ref: v8.81.6

variables:
  RENOVATE_ONBOARDING: 'true'

renovate:
  parallel:
    matrix:
      - RENOVATE_EXTRA_FLAGS: ###RENOVATE_REPOS###
  resource_group: $RENOVATE_EXTRA_FLAGS
```
</details>

This is a fairly basic integration of the original `renovate` job with the most interesting part being the `RENOVATE_EXTRA_FLAGS` variable used as [parallel matrix](https://docs.gitlab.com/ee/ci/yaml/#parallelmatrix). Since `template/renovate-repos.json` contains a JSON array, it can directly be used as YAML list here. The `###RENOVATE_REPOS###` is an arbitrary identifier (and valid YAML comment).

The `template/.gitlab-ci.yml` uses this filename since the [Renovate `gitlabci-include` manager](https://docs.renovatebot.com/modules/manager/gitlabci-include/) supports only `.gitlab-ci.yml` by default.

The result:

<details>
<summary>Example .gitlab-renovate-repos.yml</summary>

```yaml
include:
  - project: 'renovate-bot/renovate-runner'
    file: '/templates/renovate-dind.gitlab-ci.yml'
    ref: v8.81.6

variables:
  RENOVATE_ONBOARDING: 'true'

renovate:
  parallel:
    matrix:
      - RENOVATE_EXTRA_FLAGS: ["<group>/project-foo", "<group>/project-bar", ...]
  resource_group: $RENOVATE_EXTRA_FLAGS
```
</details>
  
The `ref` used in both pipelines should be updated to the latest version. Also the `templates` directory name is arbitrary.
