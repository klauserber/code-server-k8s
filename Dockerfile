FROM ubuntu:22.04

ARG TARGETARCH
ARG TARGETOS=linux

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" TZ="Europe/Berlin" apt-get install -y \
    ca-certificates \
    software-properties-common \
    curl \
    wget \
    gnupg \
    unzip \
    iputils-ping \
    iproute2 \
    sudo \
    git \
    vim \
    jq \
    ssh \
    dnsutils \
    pwgen \
    gettext-base \
    bash-completion \
 && rm -rf /var/lib/apt/lists/*

# https://hub.docker.com/_/docker/tags
COPY --from=docker:24.0.6-cli /usr/local/bin/docker /usr/local/bin/docker-compose /usr/local/bin/

RUN curl -s https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh

# https://hub.docker.com/r/hairyhenderson/gomplate/tags
COPY --from=hairyhenderson/gomplate:v3.11.5 /gomplate /bin/gomplate


# https://github.com/helm/helm/releases
ARG HELM_VERSION=3.12.3
RUN set -e; \
  cd /tmp; \
  curl -Ss -o helm.tar.gz https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz; \
  tar xzf helm.tar.gz; \
  mv ${TARGETOS}-${TARGETARCH}/helm /usr/local/bin/; \
  chmod +x /usr/local/bin/helm; \
  rm -rf ${TARGETOS}-${TARGETARCH} helm.tar.gz

# https://github.com/kubernetes/kubernetes/releases
ARG KUBECTL_VERSION=1.27.6
RUN set -e; \
    cd /tmp; \
    curl -sLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl"; \
    mv kubectl /usr/local/bin/; \
    chmod +x /usr/local/bin/kubectl

# https://github.com/coder/code-server/releases
ARG CODE_SERVER_VERSION=4.16.1
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${CODE_SERVER_VERSION}

# https://github.com/derailed/k9s/releases
ARG K9S_VERSION=0.27.4
RUN set -e; \
  mkdir -p /tmp/k9s; \
  cd /tmp/k9s; \
  curl -LSs -o k9s.tar.gz https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${TARGETARCH}.tar.gz; \
  tar xzf k9s.tar.gz; \
  mv k9s /usr/local/bin/; \
  cd /tmp; \
  rm -rf k9s

COPY helpers /helpers

RUN useradd coder \
      --create-home \
      --shell=/bin/bash \
      --uid=1000 \
      --user-group && \
      echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

RUN mkdir /run/sshd

ARG IMAGE_VERSION
ARG IMAGE_NAME

COPY bashrc.sh /tmp/
RUN set -e; \
  echo "export IMAGE_NAME=${IMAGE_NAME}" >> /etc/bash.bashrc; \
  echo "export IMAGE_VERSION=${IMAGE_VERSION}" >> /etc/bash.bashrc; \
  echo "echo \${IMAGE_NAME}:\${IMAGE_VERSION}" >> /etc/bash.bashrc; \
  cat /tmp/bashrc.sh >> /etc/bash.bashrc; \
  rm /tmp/bashrc.sh

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=en_US:en

USER coder

RUN touch ${HOME}/.bashrc

ENV PATH=${HOME}/.local/bin:${HOME}/bin:${PATH}

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=en_US:en
ENV GIT_DISCOVERY_ACROSS_FILESYSTEM=1

ENTRYPOINT [ "code-server", "--auth=none", "--bind-addr=0.0.0.0:2080" ]
