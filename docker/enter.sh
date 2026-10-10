#!/usr/bin/env bash
# Linux desktop / X11 (including Wayland sessions with XWayland).
set -euo pipefail

usage() {
    echo 'Usage: bash docker/enter.sh [zsh|bash]'
    echo 'Creates/builds once; starts a stopped container; otherwise opens another shell.'
}
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then usage; exit 0; fi
planner_shell=${1:-zsh}
if [[ $# -gt 1 || ( "$planner_shell" != zsh && "$planner_shell" != bash ) ]]; then
    usage >&2; exit 2
fi
planner_repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
planner_container=${DF_CONTAINER:-df-a-sim}
planner_uid=$(id -u)
planner_gid=$(id -g)
planner_image=${DF_IMAGE:-df-a-noetic-sim:uid${planner_uid}-gid${planner_gid}}
planner_auth_dir="${XDG_RUNTIME_DIR:-/tmp}/df-a-xauth-${planner_uid}"
if [[ "$planner_uid" == 0 ]]; then
    echo 'Run as your desktop user (not sudo). Configure Docker access for that user first.' >&2
    exit 1
fi
for planner_tool in docker xauth; do
    command -v "$planner_tool" >/dev/null || { echo "Missing host command: $planner_tool" >&2; exit 1; }
done
docker info >/dev/null || { echo 'Docker is unavailable. Start Docker and check user permissions.' >&2; exit 1; }
if [[ -z "${DISPLAY:-}" || ! -d /tmp/.X11-unix ]]; then
    echo 'Run in a Linux graphical desktop terminal with DISPLAY and X11/XWayland available.' >&2
    exit 1
fi

# Only the current display cookie; do not grant unrestricted X server access.
mkdir -p "$planner_auth_dir"
chmod 700 "$planner_auth_dir"
planner_cookie=$(xauth nlist "$DISPLAY")
if [[ -z "$planner_cookie" ]]; then
    echo "No Xauthority cookie for DISPLAY=$DISPLAY; check XAUTHORITY in this desktop session." >&2
    exit 1
fi
planner_auth_tmp=$(mktemp "$planner_auth_dir/.Xauthority.XXXXXX")
trap 'rm -f "$planner_auth_tmp"' EXIT
printf '%s\n' "$planner_cookie" | sed 's/^..../ffff/' | xauth -f "$planner_auth_tmp" nmerge -
chmod 600 "$planner_auth_tmp"
mv -f "$planner_auth_tmp" "$planner_auth_dir/Xauthority"

if docker container inspect "$planner_container" >/dev/null 2>&1; then
    planner_existing_repo=$(docker inspect --format '{{index .Config.Labels "df-a.workspace"}}' "$planner_container")
    if [[ "$planner_existing_repo" != "$planner_repo" ]]; then
        echo "Container $planner_container belongs to: $planner_existing_repo" >&2
        echo 'Use a different DF_CONTAINER name for this checkout.' >&2
        exit 1
    fi
    planner_existing_auth=$(docker inspect --format '{{index .Config.Labels "df-a.xauth"}}' "$planner_container")
    if [[ "$planner_existing_auth" != "$planner_auth_dir" ]]; then
        echo 'Desktop runtime path changed. Recreate the container (keep its build/devel volumes).' >&2
        exit 1
    fi
    if [[ "$(docker inspect --format '{{.State.Running}}' "$planner_container")" != true ]]; then
        docker start "$planner_container" >/dev/null
    fi
else
    if ! docker image inspect "$planner_image" >/dev/null 2>&1; then
        docker build --build-arg "DEV_UID=$planner_uid" --build-arg "DEV_GID=$planner_gid" \
            --tag "$planner_image" "$planner_repo/docker"
    fi
    docker run --detach --init --name "$planner_container" \
        --label "df-a.workspace=$planner_repo" --label "df-a.xauth=$planner_auth_dir" \
        --env "DISPLAY=$DISPLAY" --env XAUTHORITY=/tmp/df-a-xauth/Xauthority \
        --env "DF_BUILD_JOBS=${DF_BUILD_JOBS:-2}" \
        --shm-size=512m \
        --mount type=bind,source=/tmp/.X11-unix,target=/tmp/.X11-unix,readonly \
        --mount "type=bind,source=$planner_auth_dir,target=/tmp/df-a-xauth,readonly" \
        --mount "type=bind,source=$planner_repo,target=/Diff-Planner" \
        --mount "type=volume,source=$planner_container-build,target=/Diff-Planner/build" \
        --mount "type=volume,source=$planner_container-devel,target=/Diff-Planner/devel" \
        --mount "type=volume,source=$planner_container-install,target=/Diff-Planner/install" \
        "$planner_image" >/dev/null
fi

printf 'Container: %s\nSource: %s -> /Diff-Planner\n' "$planner_container" "$planner_repo"
echo "Inside: cd Diff-Planner; catkin_make; source devel/setup.$planner_shell"
echo 'Then: roslaunch diff_planner run_sim_single.launch'
# Refresh DISPLAY on each entry after desktop login / X server changes.
exec docker exec -it --env "DISPLAY=$DISPLAY" \
    --env "DF_BUILD_JOBS=${DF_BUILD_JOBS:-2}" --workdir / \
    "$planner_container" "$planner_shell"
