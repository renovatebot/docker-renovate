# Gitlab Configuration

Here are some configuation examples for configuring renovate to run as gitlab pipeline.
See [self-hosting](https://github.com/renovatebot/renovate/blob/master/docs/development/self-hosting.md#self-hosting-renovate) doc for additional information.

## Renovate slim with mapped docker socket

This sample will configure the renovate slim image, with will use docker side containers to run additional tools required to update lockfiles.
Some [managers](https://docs.renovatebot.com/modules/manager/) need side containers for dependency extraction too (eg: `gradle`).

This sample will not work on gitlab.com hosted shared runner, you need a self-hosted runner!

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
    volumes = ["/cache", "/tmp:/tmp:rw", "/var/run/docker.sock:/var/run/docker.sock"]
    shm_size = 0
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
  [runners.custom]
    run_exec = ""
```

# Gitlab pipeline

The following pipeline runs renovate normally on master branch and for self-update it runs in [`dryRun`](https://docs.renovatebot.com/self-hosted-configuration/#dryrun) mode.

```yml
variables:
  RENOVATE_ARGS: '--log-file=renovate.log --log-file-level=debug'

# templates
.base:
  image:
    name: renovate/renovate:19.231.8-slim@sha256:bf041f6cdacf96021df1f50e97449883d8e223db06184b2a3025a568c6f6c259
  artifacts:
    paths:
      - renovate.log

.deploy:
  extends: .base
  stage: deploy
  tags:
    - renovate
  script:
    - renovate $RENOVATE_ARGS

# jobs
test:
  extends: .base
  stage: test
  script:
    - renovate --version $RENOVATE_ARGS

deploy-dry-run:
  extends: .deploy
  except:
    - master
  script:
    - renovate --dry-run $RENOVATE_ARGS

deploy:
  extends: .deploy
  only:
    - master
```

# Renovate config

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
  autodiscoverFilter: '!{group/test,test/**}',
  semanticCommits: true,
  prCreation: 'not-pending',
  onboarding: true,
  onboardingConfig: {
    extends: ['config:base', ':assignAndReview(user)'],
    automergeType: 'branch',
    semanticCommits: true,
  },
  nuget: {
    fileMatch: ['\\.csproj$', '\\.props$', '\\.targets$'],
  },
  packageRules: [
    {
      packageNames: ['gitlab/gitlab-runner'],
      versionScheme:
        'regex:^(?<compatibility>.*)-v(?<major>\\d+)\\.(?<minor>\\d+)\\.(?<patch>\\d+)?$',
      groupName: 'gitlab docker images',
    },
    {
      packageNames: ['gitlab/gitlab-ce'],
      versionScheme:
        'regex:^(?<major>\\d+)\\.(?<minor>\\d+)\\.(?<patch>\\d+)-(?<compatibility>ce\\.\\d+)$',
      groupName: 'gitlab docker images',
    },
    {
      depTypeList: ['devDependencies'],
      extends: [':automergeMinor', 'schedule:nonOfficeHours'],
      automergeType: 'pr',
    },
  ],
};
```


## Renovate slim with docker-in-docker

This sample uses the `docker-in-docker` gitlab runner.

### Gitlab pipeline
```yml
image: docker:19.03-dind

stages:
  - renovate

renovate:
  stage: renovate
  services:
    - docker:19.03-dind
  script:
    - docker run --tty
      -e RENOVATE_PLATFORM=gitlab
      -e RENOVATE_ENDPOINT=$CI_API_V4_URL
      -e RENOVATE_TOKEN
      -e GITHUB_COM_TOKEN
      -e LOG_LEVEL=debug
      --rm
      -v /tmp:/tmp
      -v /var/run/docker.sock:/var/run/docker.sock
      renovate/renovate

  only:
    - schedules
```

