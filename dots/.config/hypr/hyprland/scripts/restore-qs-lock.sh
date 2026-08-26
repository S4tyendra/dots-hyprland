#!/usr/bin/env bash
# Restore the Quickshell lock after qs dies (HDMI power cut, etc).
# Hyprland 0.55+ Lua parser: do not use `hyprctl keyword` / `dispatch exec`.

set -u

qs_config="${QUICKSHELL_CONFIG_NAME:-${qsConfig:-ii}}"
uid="$(id -u)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${uid}}"

log() { echo "[restore-qs-lock] $*"; }
die() { echo "[restore-qs-lock] $*" >&2; exit 1; }

command -v hyprctl >/dev/null 2>&1 || die "hyprctl not found"
command -v qs >/dev/null 2>&1 || die "qs not found"
[[ -d "${XDG_RUNTIME_DIR}/hypr" ]] || die "no Hyprland runtime at ${XDG_RUNTIME_DIR}/hypr"

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    HYPRLAND_INSTANCE_SIGNATURE="$(ls -1t "${XDG_RUNTIME_DIR}/hypr" | head -1)"
    export HYPRLAND_INSTANCE_SIGNATURE
fi
[[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || die "could not find a Hyprland instance"

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    WAYLAND_DISPLAY="$(hyprctl --instance 0 instances 2>/dev/null | awk '/wl socket:/{print $3; exit}')"
    export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
fi
[[ -S "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}" ]] || die "missing wayland socket ${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}"

hypr_pid="$(hyprctl --instance 0 instances 2>/dev/null | awk '/^pid:/{print $2; exit}')"
hypr_tty="$(ps -o tty= -p "${hypr_pid:-0}" 2>/dev/null | tr -d '[:space:]')"
hypr_tty="${hypr_tty:-tty2}"

log "instance=${HYPRLAND_INSTANCE_SIGNATURE} wayland=${WAYLAND_DISPLAY} qs=-c ${qs_config}"

hyprctl --instance 0 eval 'hl.config({ misc = { allow_session_lock_restore = true } })' >/dev/null \
    || die "failed to enable allow_session_lock_restore"

killall -9 qs quickshell 2>/dev/null || true
sleep 0.4

qs -c "${qs_config}" >/dev/null 2>&1 &
disown 2>/dev/null || true

attached=0
for _ in $(seq 1 24); do
    if qs -c "${qs_config}" ipc call lock activate >/dev/null 2>&1; then
        attached=1
        break
    fi
    sleep 0.25
done

if (( attached == 0 )); then
    pidof qs quickshell >/dev/null 2>&1 || die "Quickshell failed to start"
    hyprctl --instance 0 eval 'hl.dsp.global("quickshell:lock")' >/dev/null || true
    log "qs is up; sent quickshell:lock (ipc was not ready)"
else
    log "lock attached"
fi

hyprctl --instance 0 eval 'hl.dsp.global("quickshell:lockFocus")' >/dev/null 2>&1 || true
qs -c "${qs_config}" ipc call lock focus >/dev/null 2>&1 || true

vt="${hypr_tty#tty}"
echo "Switch back with Ctrl+Alt+F${vt} and type your password."
