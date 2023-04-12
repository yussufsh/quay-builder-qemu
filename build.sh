set -e
set -o nounset

TAG=${TAG:-"stable"}
IMAGE=${IMAGE:-"quay.io/quay/quay-builder-qemu-fedoracoreos"}
CLOUD_IMAGE=${CLOUD_IMAGE:-""}
ARCH=$(uname -m)

if [ -z "$CLOUD_IMAGE" ]; then
    CHANNEL=${CHANNEL:-"stable"}
    CHANNEL_MANIFEST_JSON=`curl https://builds.coreos.fedoraproject.org/streams/${CHANNEL}.json`
    LOCATION=`echo $CHANNEL_MANIFEST_JSON | jq -r --arg arch "$ARCH" '.architectures[$arch].artifacts.qemu.formats."qcow2.xz".disk.location'`

    time docker build --build-arg=channel=$CHANNEL --build-arg --build-arg -t $IMAGE:$TAG .
else
    time docker build --build-arg=channel=$CHANNEL --build-arg --build-arg location=$CLOUD_IMAGE -t $IMAGE:$TAG .
fi
