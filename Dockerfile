FROM quay.io/centos/centos:stream9 as base
ARG channel="stable"
ARG location

RUN [ -z "${channel}" ] && echo "ARG channel is required" && exit 1 || true

RUN yum -y install jq xz

RUN ARCH=$(uname -m) ; echo $ARCH \
    ; if [ "$ARCH" == "s390x" ] ; then ARCH=s390x ; elif [ "$ARCH" == "x86_64" ] ; then ARCH=x86_64 ; fi \
    ; curl https://builds.coreos.fedoraproject.org/streams/${channel}.json -o stable.json && \
        cat stable.json | jq --arg arch "$ARCH" '.architectures[$arch].artifacts.qemu.release' | tr -d '"' 



FROM base AS executor-img

RUN if [[ -z "$arg" ]] ; then \
	ARCH=$(uname -m) ; echo $ARCH ; \
	if [ "$ARCH" == "s390x" ] ; then ARCH=s390x ; elif [ "$ARCH" == "x86_64" ] ; then ARCH=x86_64 ; fi ; \
	echo "Downloading" $(cat stable.json | jq --arg arch "$ARCH" '.architectures[$arch].artifacts.qemu.formats."qcow2.xz".disk.location' | tr -d '"') && \
        curl -s -o coreos_production_qemu_image.qcow2.xz $(cat stable.json | jq --arg arch "$ARCH" '.architectures[$arch].artifacts.qemu.formats."qcow2.xz".disk.location' | tr -d '"') && \
        unxz coreos_production_qemu_image.qcow2.xz ; \
    else \
	echo "Downloading" ${location} && \
        curl -s -o coreos_production_qemu_image.qcow2.xz ${location} && unxz coreos_production_qemu_image.qcow2.xz \
    ; fi

FROM base AS final
ARG channel=stable

RUN mkdir -p /userdata
WORKDIR /userdata

RUN yum -y update && \
    yum -y remove jq && \
    yum -y install openssh-clients qemu-kvm && \
    yum -y clean all

COPY --from=executor-img /coreos_production_qemu_image.qcow2 /userdata/coreos_production_qemu_image.qcow2
COPY start.sh /userdata/start.sh

RUN chgrp -R 0 /userdata && \
    chmod -R g=u /userdata

LABEL com.coreos.channel ${channel}

ENTRYPOINT ["/bin/bash", "/userdata/start.sh"]
