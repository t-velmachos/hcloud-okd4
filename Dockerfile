FROM docker.io/hashicorp/terraform:1.9.5@sha256:79336cfbc9113f41806e7b2061b913852f11d6bdbc0e188d184e6bdee40b84a7 AS terraform
FROM docker.io/hashicorp/packer:1.11.2@sha256:12c441b8a3994e7df9f0e2692d9298f14c387e70bcc06139420977dbf80a137b AS packer
FROM docker.io/alpine:3.20.2@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5

LABEL maintainer="t.velmachos@ngcloudops.com"

ARG OPENSHIFT_RELEASE
ENV OPENSHIFT_RELEASE=${OPENSHIFT_RELEASE}

ARG DEPLOYMENT_TYPE
ENV DEPLOYMENT_TYPE=${DEPLOYMENT_TYPE}

RUN apk update && \
    apk add \
    bash \
    ca-certificates \
    openssh-client \
    openssl \
    ansible \
    make \
    rsync \
    wget \
    curl \
    git \
    jq \
    libc6-compat \
    apache2-utils \
    python3 \
    py3-pip \
    libvirt-client

# OpenShift Installer
COPY openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz .
COPY openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz .

RUN set -ex && \
    # wget -O openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz $(OKD_MIRROR)/$(OPENSHIFT_RELEASE)/openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz && \
    # wget -O openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz $(OKD_MIRROR)/$(OPENSHIFT_RELEASE)/openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz
    tar -vxzf openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz openshift-install && \
    tar -vxzf openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz oc && \
    tar -vxzf openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz kubectl && \
    mv openshift-install /usr/local/bin/openshift-install && \
    mv oc /usr/local/bin/oc && \
    mv kubectl /usr/local/bin/kubectl && \
    rm openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz && \
    rm openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz

# External tools
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=packer /bin/packer /usr/local/bin/packer

# Install Packer Plugin
RUN packer plugins install github.com/hashicorp/hcloud

# Create workspace
RUN mkdir /workspace
WORKDIR /workspace
