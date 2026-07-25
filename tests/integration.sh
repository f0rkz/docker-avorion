#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPOSITORY_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly IMAGE_NAME="${IMAGE_NAME:-docker-avorion:test}"
readonly CONTAINER_NAME="docker-avorion-test-${BASHPID}"
readonly VOLUME_NAME="docker-avorion-test-${BASHPID}"

cleanup() {
    docker rm --force "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    docker volume rm "${VOLUME_NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

cd "${REPOSITORY_ROOT}"

if [[ "${BUILD_IMAGE:-true}" == "true" ]]; then
    docker build --tag "${IMAGE_NAME}" .
fi

docker volume create "${VOLUME_NAME}" >/dev/null
docker run \
    --detach \
    --name "${CONTAINER_NAME}" \
    --env GALAXY_NAME=integration \
    --volume "${VOLUME_NAME}:/data" \
    "${IMAGE_NAME}" >/dev/null

for _ in {1..180}; do
    logs="$(docker logs "${CONTAINER_NAME}" 2>&1)"

    if grep --quiet "Server startup complete" <<<"${logs}"; then
        docker stop --timeout 30 "${CONTAINER_NAME}" >/dev/null
        logs="$(docker logs "${CONTAINER_NAME}" 2>&1)"

        if grep --quiet "Server shutdown successful" <<<"${logs}"; then
            echo "Avorion dedicated server startup and graceful shutdown verified"
            exit 0
        fi

        echo "${logs}"
        echo "Avorion did not complete a graceful shutdown" >&2
        exit 1
    fi

    if [[ "$(docker inspect --format '{{.State.Running}}' "${CONTAINER_NAME}")" != "true" ]]; then
        echo "${logs}"
        echo "Avorion container exited before startup completed" >&2
        exit 1
    fi

    sleep 2
done

docker logs "${CONTAINER_NAME}"
echo "Avorion did not complete startup within six minutes" >&2
exit 1
