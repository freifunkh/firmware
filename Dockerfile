FROM jenkins/agent:latest-bookworm-jdk17
USER root
### Start gluon

ARG TARGETOS=linux
ARG TARGETARCH=amd64

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    file \
    git \
    python3 \
    python3-distutils \
    build-essential \
    gawk \
    unzip \
    libncurses5-dev \
    zlib1g-dev \
    libssl-dev \
    libelf-dev \
    wget \
    rsync \
    time \
    qemu-utils \
    ecdsautils \
    lua-check \
    shellcheck \
    libnss-unknown \
    openssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /tmp/ec &&\
    wget -O /tmp/ec/ec-${TARGETOS}-${TARGETARCH}.tar.gz https://github.com/editorconfig-checker/editorconfig-checker/releases/download/2.7.0/ec-${TARGETOS}-${TARGETARCH}.tar.gz &&\
    tar -xvzf /tmp/ec/ec-${TARGETOS}-${TARGETARCH}.tar.gz &&\
    mv bin/ec-${TARGETOS}-${TARGETARCH} /usr/local/bin/editorconfig-checker &&\
    rm -rf /tmp/ec

#RUN useradd -m -d /gluon -u 100 -g 100 -o gluon
#USER gluon

##VOLUME /gluon
##WORKDIR /gluon

### End gluon
USER jenkins
#ENTRYPOINT ["/usr/local/bin/jenkins-agent"]
