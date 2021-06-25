# Docker Checklist

> Steps to check when using docker

- [ ] [Keep image small](#image-size)
- [ ] [Keep build fast](#performance)
- [ ] [Make build reproducible](#robustness)
- [ ] [Improve security](#security)
- [ ] [Setup linting](#linting)
- [ ] See [checklists for specific tools](#specific-checklists)
  - [Apk](#apk) (Alpine Linux)
  - [Apt-get](#apt-get) (Ubuntu / Debian)
  - [Python](#python)
  - [Rust](#rust)

## Image size

> Image size matters

But if you are using multi-stage builds,
you should do steps below only in final stage.
You can still reduce size of images of build stages,
but it's not so important.

- [ ] Use **alpine**
- [ ] Use [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/)
- [ ] Use *whitelist* [dockerignore](examples/.dockerignore)
- [ ] Reduce number of image layers
  - [ ] Combine repeated commands (`RUN` with `\ &&`, `ENV` with ` \`, etc.)

## Security

> Security matters, and there are no excuses

Docker containers are [quite secure](https://docs.docker.com/engine/security/)
itself, but there are vulnerabilities in docker daemon itself,
that allow to escape attacks.

- [ ] Use trusted base images
- [ ] Build using unprivileged user
- [ ] Run final process from unprivileged user ([Dockerfile](examples/Dockerfile.unprivileged-user))

## Robustness

> Making build process reproducible and error prune

- [ ] Make container stateless and universal
  - Use `VOLUME` instuction to store state in volumes
  - Settings should be provided via environment variables when container is running
- [ ] Add [healthchecks](examples/Dockerfile.healthcheck)
  - [ ] Ensure healthcheck exit code either 0 (healthy) or 1 (unhealthy)
  - [ ] Use [autoheal](https://github.com/willfarrell/docker-autoheal)
- [ ] Pin _virtually all_ versions
  - [ ] Explicitly specify base image version
  - [ ] Use [lock files](https://myers.io/2019/01/13/what-is-the-purpose-of-a-lock-file-for-package-managers)
  - [ ] See [checklists for specific tools](#specific-checklists)
- [ ] Use shell with addtional flags to impruve robustness
  - See [The Eeuo pipefail option and best practice to write a shell script](https://transang.me/best-practice-to-make-a-shell-script/)
  - [ ] For bash: `SHELL ["/bin/bash", "-Eeuo", "pipefail", "-c"]`
  - [ ] For ash (alpine): `SHELL ["/bin/ash", "-eo", "pipefail", "-c"]`
- [ ] Expose used ports
  - [ ] Prefer common, traditional ports
  - [ ] Use port 8080 for http (see [List of TCP and UDP port numbers](https://www.wikiwand.com/en/List_of_TCP_and_UDP_port_numbers))
- [ ] Use CI tool to build and publish image

## Performance

> Building image faster as well as running application in container faster

Build performance is really important, cause it provide
better development experience and allow to speed up CI cycle.

- [ ] Place instructions that are less likely to change (and easier to cache) first
  - [ ] Install dependencies first, then copy application sources (see [documentation](https://docs.docker.com/get-started/09_image_best/#layer-caching))
- [ ] Prefer [exec form](https://docs.docker.com/engine/reference/builder/#cmd) for `CMD`, `ENTRYPOINT` and `RUN` instructions
- [ ] Place `ENV` instructions as late as possible

## Linting

> Check your `Dockerfile` for errors automatically

- [ ] Use [hadolint](https://hadolint.github.io/)
- [ ] Run linting in CI pipeline
- [ ] Lint your `entrypoint`, `healthcheck` and other scripts

## Specific Сhecklists

### Apk

> Alpine package manager

- [ ] Use `--no-cache` key

### Apt-get

> Ubuntu / Debian package manager

- [ ] Update before installing: `apt-get update`
- [ ] Use `--no-install-recommends` key
- [ ] Use `--yes` key
- [ ] Remove redundant state information: `rm -rf /var/lib/apt/lists/*`
- [ ] Pin versions (`apt-get install --yes `)
  - Use `apt-cache madison <package>` to get available versions

### Python

- [ ] Use [faulthandler](https://docs.python.org/3/library/faulthandler.html): `PYTHONFAULTHANDLER=yes`
- [ ] Disable output buffering: `PYTHONUNBUFFERED=yes`
- [ ] Disable bytecode writing: `PYTHONDONTWRITEBYTECODE=yes` (if process is running not too often)

#### Pip

> Python package manager

- [ ] Do not check for pip version on start: `PIP_DISABLE_PIP_VERSION_CHECK=yes`
- [ ] Disable cache: 'PIP_NO_CACHE_DIR=yes'
- [ ] Use `PIP_DEFAULT_TIMEOUT=120` to prevent `ConnectTimeoutError`

#### Poetry

> Python package manager

- [ ] Pin version: `POETRY_VERSION=1.16.0`
- [ ] Disable interactivity: `POETRY_NO_INTERACTION=true`
- [ ] Install in recommended way:
  - `RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -`
- [ ] Store virtualenvs in project's root: `POETRY_VIRTUALENVS_IN_PROJECT=true`
  - [ ] Copy `.venv` dir from build stage to final
- [ ] Use `--no-dev` key
- [ ] Use `--no-root` key

### Rust

- [ ] Use [cargo-chef](https://www.lpalmieri.com/posts/fast-rust-docker-builds/)
