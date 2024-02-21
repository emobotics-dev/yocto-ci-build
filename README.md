# Disclaimer
This repo has been split out of a custom Yocto build system. I am sure that it still contains some assumptions that should be removed. Please treat it as WIP at the moment.

However, the goal is clearly to build a Github action that is universally useful for any GH Actions based Yocto CI. I am looking forward to your issue reports and PRs! 

# yocto-ci-build
This repo contains a couple of tools to implement a CI build of a Yocto image and SDK in a Github Actions workflow. 

Key ideas:
 * ease of use with private GH repositories
 * containerizerd build
 * using the same container for CI build and interactive work
 * the container image is hosted as a Github package and automatically built from Dockerfile using a Github Workflow
 * the Yocto build is encaspulated in a Github composite action, that can be easily re-used
 * a persistent sstate cache may be used to speed up on-push CI runs

## yocto-ci-build Action
The action is taking the following steps:
1. checkout of the Yocto repo and all it's layer submodules (including private layers)
2. Building a set of images
3. Building a set of SDKs

### directory layout
The action is intended to work on a Yocto repo that has the following structure:

    ├── .github
    │   └── workflows
    ├── <MACHINE>
    │   └── build
    ├── podman-run.sh
    ├── prepare-env.sh
    └── sources
        ├── meta-arm
        ├── ...
        ├── meta-openembedded
        └── poky

The layers under `sources` are intended to be git submodules of the main repo - that avoids a lot of hassle with `repo` and makes it much easier to deal with layers in private repos. The script `podman-run` is used to spawn the container for interactive work - it is not relevant for the CI build. The script `prepare-env` is a convenience wrapper around `sources/poky/oe-init-build-env`.

### Usage example

    runs-on: self-hosted
    container:
      image: ghcr.io/emobotics-dev/yocto-ci-build:latest
      options: --platform linux/amd64 --userns=keep-id --pids-limit=-1
      volumes:
        - /yocto/github/sstate:/sstate
    steps:
    - name: Build
      uses: emobotics-dev/yocto-ci-build@master
      with:
        sstate_dir: /sstate
        token: ${{ secrets.WORKFLOW_TOKEN }} 
        images: update-image
        sdk-image: emo-image-minimal

### Access to private GH repos
While the access to private submodule layers is automatically handled by `actions/checkout`, the access to private application source can be somewhat tricky. 

There is more than one possible route, but we have chosen to go with HTTPS access here, assuming the current Github actor has a token available that also has access to the private repos. This actor and the supplied token are stored in an environment variable `GIT_USER`. The recipes that need access to private repos should therefore use a `SRC_URI` like this one:

    SRC_URI = "git://github.com/me/my_private_repo.git;protocol=https;branch=someone;user=${GIT_USER}"


### yocto-ci-build container
The container image is a fairly standard Ubuntu 22.04 with all the recommended Yocto build tools. As `bitbake´ complains heavily about running as root, the container uses the `USER` command to drop root priviliges.

# Credits
The general idea of this Yocto build approach is heavily inspired from [meta-mono](https://github.com/DynamicDevices/meta-mono). The Dockerfile is actually forked from https://github.com/DynamicDevices/yocto-ci-build. There is also an [excellent talk](https://www.youtube.com/watch?v=TsAcxd_acJI) about meta-mono's approach.