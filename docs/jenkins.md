# Samples for Jenkins pipelines

These are configuration examples for running a self-hosted Renovate on Jenkins pipelines. This example accesses a privately hosted GitLab instance.
See [self-hosting](https://docs.renovatebot.com/getting-started/running/#self-hosting-renovate) doc for additional information.

## Renovate with mapped Docker socket

The following pipeline runs Renovate normally on the default branch (eg. `main` or `master`).

### Setup

- Fill in the `GIT_AUTHOR_` and `GIT_COMMITTER_` fields with the same account data
- `RENOVATE_ENDPOINT`: your GitLab API endpoint
- `RENOVATE_REPOSITORIES`: your repositories to renovate
- `gitLabConnection`: your GitLab domain

### Variables

- `RENOVATE_TOKEN`: access token for renovate to gitlab api (**required**)
- `GITHUB_COM_TOKEN`: suppress github api rate limits (**required**)
- `RENOVATE_EXTRA_FLAGS`: pass additional commandline args (**optional**)

### Jenkinsfile
```yml
#!groovy

pipeline {
    agent {
        docker {
            image 'renovate/renovate:34.132.4-slim'
            args '-v /var/run/docker.sock:/var/run/docker.sock -v /tmp:/tmp --group-add 0'
        }
    }

    environment {
        CONFIGURATION = 'Release'
        TZ = 'Europe/Berlin'
        ENV = '/usr/local/etc/env'
        RENOVATE_TOKEN = credentials('RENOVATE_TOKEN')
        GITHUB_COM_TOKEN = credentials('GITHUB_COM_TOKEN')
        LOG_LEVEL = 'debug'
        GIT_AUTHOR_NAME = 'Renovate Bot'
        GIT_AUTHOR_EMAIL = 'bot@example.com'
        GIT_COMMITTER_NAME = 'Renovate Bot'
        GIT_COMMITTER_EMAIL = 'bot@example.com'
        RENOVATE_PLATFORM = 'gitlab'
        RENOVATE_ENDPOINT = 'https://git.example.com/api/v4/'
        RENOVATE_REPOSITORIES = 'user1/repo1, user2/repo2'
        RENOVATE_ONBOARDING_CONFIG = '{ "extends":["config:base"] }'
    }

    parameters {
        string defaultValue: '', description: '', name: 'RENOVATE_EXTRA_FLAGS', trim: true
    }

    options {
        gitLabConnection('git.example.com')
        disableConcurrentBuilds()
        timeout(time: 1, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '240')
    }

    triggers {
        cron('H * * * *')
    }

    stages {
        stage('init') {
            steps {
                sh 'renovate --version'
                sh 'rm -f renovate.log'
            }
        }

        stage('renovate') {
            steps {
                sh "renovate --log-file renovate.log --log-file-level debug ${params.RENOVATE_EXTRA_FLAGS}"
            }
        }
    }

    post {
        always {
            archiveArtifacts allowEmptyArchive: true, artifacts: 'renovate.log'
        }
    }
}

```

### Renovate specific config explained

- `args '... --group-add 0'`: give Docker container user root group rights to some required files and folders
- `disableConcurrentBuilds()`: don't allow parallel execution of renovate jobs (because they would interfere with each other)

### Schedule

Above pipeline defines an `hourly` schedule on `master` branch.
