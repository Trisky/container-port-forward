# Contributing

## Run tests locally with Podman

Install and start [Podman](https://podman.io/) before running the tests.

Build the test image from the repository root:

```sh
podman build --file Containerfile --tag container-port-forward:test .
```

Run the test script with Podman as the container runtime:

```sh
CONTAINER_RUNTIME=podman sh tests/test-container.sh
```

The tests verify that `socat` is installed, the default environment variables
are set, and TCP and UDP payloads are forwarded to echo backends.

## Create a release

Release tags must point to a commit on `main`. Merge all release changes before
creating the tag, then update your local branch:

```sh
git switch main
git pull --ff-only
```

Create and push an annotated semantic-version tag:

```sh
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

The `main` push publishes the `main`, `latest`, and commit SHA image tags. The
release tag runs the tests again, verifies that the tagged commit is on `main`,
and publishes multi-architecture images for `vX.Y.Z`, `X.Y.Z`, `X.Y`, and the
commit SHA. After the images are available, the workflow creates a GitHub
Release with generated release notes.
