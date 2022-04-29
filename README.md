# Docker Checklist

> Steps to check when using docker

- [ ] [Keep image small](#image-size)
- [ ] [Keep build fast](#performance)
- [ ] [Make build reproducible](#robustness)
- [ ] [Improve security](#security)
- [ ] [Improve usability](#usablitiy)
- [ ] [Setup linting](#linting)
- [ ] [Deploy right](#deploy)
- [ ] [Provide documentation](#documentation)
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

- [ ] Use **alpine** ([except for python](https://pythonspeed.com/articles/alpine-docker-python/))
- [ ] Use [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/)
- [ ] Use *whitelist* [dockerignore](examples/.dockerignore)
- [ ] Reduce number of image layers
  - [ ] Combine repeated commands (`RUN` with `\ &&`, `ENV` with ` \`, etc.)

## Performance

> Building image faster as well as running application in container faster

Build performance is really important, cause it provide
better development experience and allow to speed up CI cycle.

- [ ] Place instructions that are less likely to change (and easier to cache) first
  - [ ] Install dependencies first, then copy application sources (see [documentation](https://docs.docker.com/get-started/09_image_best/#layer-caching))
- [ ] Prefer [exec form](https://docs.docker.com/engine/reference/builder/#cmd) for `CMD`, `ENTRYPOINT` and `RUN` instructions
- [ ] Place `ENV` instructions as late as possible

## Robustness

> Making build process reproducible and error prune

- [ ] Make container stateless and universal
  - Use `VOLUME` instuction to store state in volumes
  - Settings should be provided via environment variables when container is running
- [ ] Add [healthchecks](examples/Dockerfile.healthcheck)
  - [ ] Ensure healthcheck exit code is either 0 (healthy) or 1 (unhealthy)
  - [ ] Use [autoheal](https://github.com/willfarrell/docker-autoheal)
- [ ] Pin _virtually all_ versions
  - [ ] Explicitly specify base image version
  - [ ] Use [lock files](https://myers.io/2019/01/13/what-is-the-purpose-of-a-lock-file-for-package-managers)
  - [ ] See [checklists for specific tools](#specific-checklists)
- [ ] Use shell with addtional flags to impruve robustness
  - See [The Eeuo pipefail option and best practice to write a shell script](https://transang.me/best-practice-to-make-a-shell-script/)
  - [ ] Use `set -Eeuo pipefail` in all bash scripts (e.g. in `ENTRYPOINT`)
  - [ ] For bash: `SHELL ["/bin/bash", "-Eeuo", "pipefail", "-c"]`
  - [ ] For ash (alpine): `SHELL ["/bin/ash", "-eo", "pipefail", "-c"]`
- [ ] Use CI tool to build and publish image
- [ ] Do **not** use `latest` tag, always explicitly tag images (see [1](https://vsupalov.com/docker-better-image-tags/) and [2](https://vsupalov.com/docker-latest-tag/))

## Security

> Security matters, and there are no excuses

Docker containers are [quite secure](https://docs.docker.com/engine/security/)
itself, but there are vulnerabilities in docker daemon itself,
that allow to escape attacks.

- [ ] Use trusted base images
- [ ] Build using unprivileged user
- [ ] Run final process from unprivileged user ([Dockerfile](examples/Dockerfile.unprivileged-user))
- [ ] Consider using `--read-only` flag
- [ ] Make secrets unavailable to unprivileged users on host system

## Usability

> Making image easier to use

- [ ] Expose used ports
  - [ ] Prefer common, traditional ports
  - [ ] Use port 8080 for http (see [List of TCP and UDP port numbers](https://www.wikiwand.com/en/List_of_TCP_and_UDP_port_numbers))
- [ ] Add a development image
  - Mount source direcory to development container as running
  - Enable *debug mode*, *autoreload*, increase log verbosity

## Linting

> Check your `Dockerfile` for errors automatically

- [ ] Use [hadolint](https://hadolint.github.io/)
- [ ] Run linting in CI pipeline
- [ ] Lint your `entrypoint`, `healthcheck` and other scripts

## Deploy

> Then it comes to deploy on the production

- [ ] Have single image for QA/Staging/Produciton
- [ ] Build image once and publish it to the registry
  - [ ] Consider using a [private registry](https://hub.docker.com/_/registry)
- [ ] Consider using [watchtower](https://github.com/containrrr/watchtower) to automate deploy

## Documentation

> Make users (including future yourself) suffer less using your image

- [ ] Have a nice `README.md` file, like [official images](https://hub.docker.com/_/docker) have
- [ ] Update it automatically with [dockerhub-description](https://github.com/peter-evans/dockerhub-description)
- [ ] Add badges
  - [ ] CI pipeline status
  - [ ] Image size
  - [ ] Layers count
  - [ ] DockerHub stars
  - [ ] DockerHub pulls
  - [ ] DockerHub latest version
  - Find more at [shields.io](https://shields.io/) and [badgen.net](https://badgen.net/).

## Running

> Check if you are using `docker run` correctly

### For foreground / attached (interactive) containers

- [ ] Use `--rm`, `-it`

### For background / detached (daemon) containers

- [ ] Specify name: `--name=app`
- [ ] Make sure container will restart on failure: `--restart=<on-failure|always|unless-stopped>`
- [ ] Prevent resource depletion
  - [ ] Limit memory usage: `--memory=1G` (upper bound) and `--memory-reservation=100M` (lower bound)
  - [ ] Limit CPU usage: `--cpus=0.5` / `--cpus=16`
  - [ ] Set CPU usage priority: `--cpu-shares=512` (see [documentation](https://docs.docker.com/engine/reference/run/#cpu-share-constraint))
  - [ ] Set I/O priority: `--blkio-weight=100` (see [documentation](https://docs.docker.com/engine/reference/run/#block-io-bandwidth-blkio-constraint))
  - [ ] Configure log rotation [globally](examples/docker.logging.json) or [per-container](examples/logging.bash)
  - [ ] Make sure you have good PID 1 (or use `--init`) to prevent zombie processes

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
- [ ] Pin versions (`apt-get install <package>=<version>`)
  - Use `apt-cache madison <package>` to get available versions

### Python

- [ ] Use [faulthandler](https://docs.python.org/3/library/faulthandler.html): `PYTHONFAULTHANDLER=yes`
- [ ] Disable output buffering: `PYTHONUNBUFFERED=yes`
- [ ] Disable bytecode writing: `PYTHONDONTWRITEBYTECODE=yes` (if process is running not too often)

#### Pip

> Python package manager

- [ ] Pin versions of all packages in `requrements.txt` (use `pip freeze`)
- [ ] Do not check for pip version on start: `PIP_DISABLE_PIP_VERSION_CHECK=yes`
- [ ] Disable cache: `PIP_NO_CACHE_DIR=yes`
- [ ] Use `PIP_DEFAULT_TIMEOUT=120` to prevent `ConnectTimeoutError`

#### Poetry

> Python package manager

- [ ] Pin version: `POETRY_VERSION=1.16.0`
- [ ] Disable interactivity: `POETRY_NO_INTERACTION=true`
- [ ] Install in recommended way:
  - `RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -`
- [ ] Store virtualenvs in project's root: `POETRY_VIRTUALENVS_IN_PROJECT=true`
  - [ ] Copy `.venv` dir from build stage to final
  - [ ] Remove `*.pyc` files from `.venv`: `RUN find /app/.venv -name '*.pyc' -delete` (this reduces image size by ~10%)
  - [ ] Remove `pip`, `setuptools` and `wheel` from `.venv`
  - [ ] Remove `*.pyc`, `ensurepip`, `lib2to3` and `distutils` from final image
- [ ] Use `--no-dev` key
- [ ] Use `--no-root` key

### Rust

- [ ] Use [cargo-chef](https://www.lpalmieri.com/posts/fast-rust-docker-builds/)
