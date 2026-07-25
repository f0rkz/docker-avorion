#!/usr/bin/env bash

set -Eeuo pipefail

readonly APP_ID=565060
readonly INSTALL_DIR="${AVORION_INSTALL_DIR:-/data/avorion}"
readonly DATA_PATH="${AVORION_DATA_PATH:-/data/save}"
readonly USER_DIR="${AVORION_USER_DIR:-/data/home}"
readonly EFFECTIVE_GALAXY_NAME="${GALAXY_NAME:-avorion_galaxy}"
readonly MANAGED_MOD_CONFIG_HEADER="-- Managed by docker-avorion; configure with WORKSHOP_MODS and ALLOWED_CLIENT_MODS."

normalize_mod_ids() {
    local raw_ids="${1//,/ }"
    local id

    read -r -a normalized_ids <<<"${raw_ids}"
    for id in "${normalized_ids[@]}"; do
        if [[ ! "${id}" =~ ^[0-9]+$ ]]; then
            echo "Invalid Steam Workshop item ID: ${id}" >&2
            return 1
        fi
    done
}

configure_workshop_mods() {
    local -a normalized_ids=()
    local -a workshop_mods=()
    local -a allowed_client_mods=()
    local force_enable_mods="${FORCE_ENABLE_MODS:-false}"
    local galaxy_dir
    local mod_config
    local existing_header=""
    local temporary_config
    local id

    normalize_mod_ids "${WORKSHOP_MODS:-}"
    workshop_mods=("${normalized_ids[@]}")
    normalize_mod_ids "${ALLOWED_CLIENT_MODS:-}"
    allowed_client_mods=("${normalized_ids[@]}")

    if (( ${#workshop_mods[@]} == 0 && ${#allowed_client_mods[@]} == 0 )); then
        return
    fi

    if [[ "${EFFECTIVE_GALAXY_NAME}" == */* || "${EFFECTIVE_GALAXY_NAME}" == "." || "${EFFECTIVE_GALAXY_NAME}" == ".." ]]; then
        echo "GALAXY_NAME must be a single directory name when configuring Workshop mods." >&2
        return 1
    fi

    if [[ "${force_enable_mods}" != "true" && "${force_enable_mods}" != "false" ]]; then
        echo "FORCE_ENABLE_MODS must be true or false." >&2
        return 1
    fi

    galaxy_dir="${DATA_PATH}/${EFFECTIVE_GALAXY_NAME}"
    mod_config="${galaxy_dir}/modconfig.lua"
    mkdir --parents "${galaxy_dir}"

    if [[ -f "${mod_config}" ]]; then
        IFS= read -r existing_header <"${mod_config}" || true
        if [[ "${existing_header}" != "${MANAGED_MOD_CONFIG_HEADER}" ]]; then
            echo "Refusing to overwrite the user-managed mod config at ${mod_config}." >&2
            return 1
        fi
    fi

    temporary_config="$(mktemp "${galaxy_dir}/.modconfig.lua.XXXXXX")"
    {
        echo "${MANAGED_MOD_CONFIG_HEADER}"
        echo 'modLocation = ""'
        echo "forceEnabling = ${force_enable_mods}"
        echo
        echo "mods = {"
        for id in "${workshop_mods[@]}"; do
            echo "    {workshopid = \"${id}\"},"
        done
        echo "}"
        echo
        echo "allowed = {"
        for id in "${allowed_client_mods[@]}"; do
            echo "    {id = \"${id}\"},"
        done
        echo "}"
    } >"${temporary_config}"
    mv "${temporary_config}" "${mod_config}"
}

mkdir --parents "${INSTALL_DIR}" "${DATA_PATH}" "${USER_DIR}"

if [[ ! -e /home/steam/.avorion ]]; then
    ln --symbolic "${USER_DIR}" /home/steam/.avorion
fi

steamcmd=(
    steamcmd.sh
    +force_install_dir "${INSTALL_DIR}"
    +login anonymous
    +app_info_update 1
    +app_update "${APP_ID}"
)

if [[ "${STEAMCMD_VALIDATE:-false}" == "true" ]]; then
    steamcmd+=(validate)
fi

steamcmd+=(+quit)

if [[ ! "${STEAMCMD_RETRIES:-3}" =~ ^[1-9][0-9]*$ ]]; then
    echo "STEAMCMD_RETRIES must be a positive integer." >&2
    exit 1
fi

attempt=1
until "${steamcmd[@]}"; do
    if (( attempt >= STEAMCMD_RETRIES )); then
        echo "SteamCMD update failed after ${attempt} attempts." >&2
        exit 1
    fi

    echo "SteamCMD update attempt ${attempt} failed; retrying." >&2
    sleep $((attempt * 5))
    ((attempt += 1))
done

configure_workshop_mods

server_args=(
    --galaxy-name "${EFFECTIVE_GALAXY_NAME}"
    --use-steam-networking 1
    --datapath "${DATA_PATH}"
)

if [[ -n "${SERVER_ADMIN:-}" && "${SERVER_ADMIN}" != "0" ]]; then
    server_args+=(--admin "${SERVER_ADMIN}")
fi

cd "${INSTALL_DIR}"
export LD_LIBRARY_PATH="${INSTALL_DIR}/linux64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
exec "${INSTALL_DIR}/bin/AvorionServer" "${server_args[@]}" "$@"
