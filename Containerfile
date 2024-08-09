#docker build . -t yocto-ci-build
#docker run -it --rm -v${PWD}:/home/build/yocto yocto-ci-build
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM=linux

RUN apt-get update --fix-missing && apt-get -y upgrade

# Install apt-utils before anything else
RUN apt-get install apt-utils software-properties-common -y

RUN add-apt-repository universe && apt-get update --fix-missing && apt-get -y upgrade

# Required Packages for the Host Development System
# http://www.yoctoproject.org/docs/latest/mega-manual/mega-manual.html#required-packages-for-the-host-development-system
RUN apt-get install -y gawk wget git-core diffstat unzip texinfo gcc-multilib g++-multilib gcc-multilib g++-multilib \
     build-essential chrpath socat cpio python3 python3-pip python3-pexpect \
     apt-utils tmux xz-utils debianutils iputils-ping libncurses5-dev vim \
     liblz4-tool zstd zstd iproute2 iptables file

# libc6-dev files are also missing
RUN apt install -y libc6-dev

# Additional recommended packages
RUN apt-get install -y coreutils python2.7 libsdl1.2-dev xterm libssl-dev libelf-dev \
     ca-certificates whiptail # openjdk-11-jre 

# Additional host packages required by poky/scripts/wic
RUN apt-get install -y curl dosfstools mtools parted syslinux tree zip tzdata
RUN update-ca-certificates

# Create a non-root user that will perform the actual build
RUN id github 2>/dev/null || useradd --uid 1001 --create-home github
RUN apt-get install -y sudo
RUN echo "github ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

# Fix error "Please use a locale setting which supports utf-8."
# See https://wiki.yoctoproject.org/wiki/TipsAndTricks/ResolvingLocaleIssues
RUN apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
        echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
        dpkg-reconfigure --frontend=noninteractive locales && \
        update-locale LANG=en_US.UTF-8

# Deployment helper
RUN apt-get install -y rsync ccache
RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime



RUN update-alternatives --install /bin/sh sh /bin/bash 100

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

WORKDIR /yocto

CMD "/bin/bash"

#EOF
