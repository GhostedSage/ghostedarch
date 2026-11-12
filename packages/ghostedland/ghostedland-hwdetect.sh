#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                GHOSTEDLAND — HARDWARE DETECTION                            ║
# ║                                                                            ║
# ║  Reads /sys and /proc (no extra tools) to describe GPUs, CPU, chassis,     ║
# ║  battery, backlight, and keyboard layout. Used by:                         ║
# ║    start-ghostedland  →  --env       (every login; adapts to new hardware) ║
# ║    install.sh         →  --packages, --vars, --report                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# Usage: ghostedland-hwdetect [--report | --env | --packages | --vars]
#
# Every value can be overridden: variables already set in the environment
# (e.g. GHOSTED_DRM_DEVICE in ~/.config/ghostedland/session.env) are never replaced.

set -u

SYS="${GHOSTED_HWDETECT_SYSROOT:-}"   # test hook: alternate /sys,/proc root

# ─── GPU discovery ───────────────────────────────────────────────────────────

GPU_CARDS=()      # card0 card1 …
GPU_VENDOR=()     # nvidia | amd | intel | virtio | vmware | virtualbox | qxl | other
GPU_DRIVER=()     # nvidia | nouveau | amdgpu | radeon | i915 | xe | virtio_gpu | …
GPU_PANEL=()      # 1 if this GPU drives a connected built-in panel (eDP/LVDS/DSI)
GPU_BOOT=()       # 1 if firmware boot display (boot_vga)
GPU_OUTPUTS=()    # number of connected outputs

vendor_name() {
    case "$1" in
        0x10de) echo nvidia ;;
        0x1002) echo amd ;;
        0x8086) echo intel ;;
        0x1af4) echo virtio ;;
        0x15ad) echo vmware ;;
        0x80ee) echo virtualbox ;;
        0x1b36|0x1234) echo qxl ;;
        *) echo other ;;
    esac
}

for card in "${SYS}"/sys/class/drm/card[0-9]*; do
    [[ -e "${card}" ]] || continue
    name="$(basename "${card}")"
    [[ "${name}" == *-* ]] && continue            # connectors (card0-eDP-1)
    dev="${card}/device"
    [[ -r "${dev}/vendor" ]] || continue          # simpledrm / efifb have no PCI vendor
    driver="$(basename "$(readlink "${dev}/driver" 2>/dev/null)" 2>/dev/null)"
    [[ "${driver}" == simple* || "${driver}" == efifb ]] && continue

    panel=0
    outputs=0
    for conn in "${card}"-*; do
        [[ -r "${conn}/status" ]] || continue
        if [[ "$(cat "${conn}/status")" == connected ]]; then
            outputs=$((outputs + 1))
            case "${conn}" in *-eDP-*|*-LVDS-*|*-DSI-*) panel=1 ;; esac
        fi
    done

    GPU_CARDS+=("${name}")
    GPU_VENDOR+=("$(vendor_name "$(cat "${dev}/vendor")")")
    GPU_DRIVER+=("${driver:-none}")
    GPU_PANEL+=("${panel}")
    GPU_BOOT+=("$(cat "${dev}/boot_vga" 2>/dev/null || echo 0)")
    GPU_OUTPUTS+=("${outputs}")
done

GPU_COUNT=${#GPU_CARDS[@]}

# Primary renderer: the GPU wired to the built-in panel, else the firmware
# boot display, else the GPU with connected outputs, else the first one.
PRIMARY=-1
for pass in panel boot outputs any; do
    for i in "${!GPU_CARDS[@]}"; do
        case "${pass}" in
            panel)   [[ "${GPU_PANEL[$i]}" == 1 ]] ;;
            boot)    [[ "${GPU_BOOT[$i]}" == 1 ]] ;;
            outputs) [[ "${GPU_OUTPUTS[$i]}" -gt 0 ]] ;;
            any)     true ;;
        esac && { PRIMARY=$i; break 2; }
    done
done

PRIMARY_VENDOR=""
PRIMARY_DRIVER=""
if [[ ${PRIMARY} -ge 0 ]]; then
    PRIMARY_VENDOR="${GPU_VENDOR[$PRIMARY]}"
    PRIMARY_DRIVER="${GPU_DRIVER[$PRIMARY]}"
fi

has_driver() {
    local d
    for d in "${GPU_DRIVER[@]}"; do [[ "${d}" == "$1" ]] && return 0; done
    return 1
}

IS_VM=0
case "${PRIMARY_VENDOR}" in virtio|vmware|virtualbox|qxl) IS_VM=1 ;; esac
if [[ -r "${SYS}/sys/class/dmi/id/sys_vendor" ]]; then
    case "$(cat "${SYS}/sys/class/dmi/id/sys_vendor")" in
        QEMU|innotek*|VMware*|Microsoft\ Corporation|Xen|Parallels*) IS_VM=1 ;;
    esac
fi

NVIDIA_MODESET=""
if [[ -r "${SYS}/sys/module/nvidia_drm/parameters/modeset" ]]; then
    NVIDIA_MODESET="$(cat "${SYS}/sys/module/nvidia_drm/parameters/modeset")"
fi

# ─── CPU, chassis, power, input ──────────────────────────────────────────────

CPU_VENDOR="unknown"
CPU_MODEL=""
if [[ -r "${SYS}/proc/cpuinfo" ]]; then
    case "$(grep -m1 '^vendor_id' "${SYS}/proc/cpuinfo" | cut -d: -f2 | tr -d ' ')" in
        AuthenticAMD) CPU_VENDOR=amd ;;
        GenuineIntel) CPU_VENDOR=intel ;;
    esac
    CPU_MODEL="$(grep -m1 '^model name' "${SYS}/proc/cpuinfo" | cut -d: -f2- | sed 's/^ *//')"
fi
[[ -z "${CPU_MODEL}" ]] && CPU_MODEL="$(uname -m)"

HAS_BATTERY=0
for ps in "${SYS}"/sys/class/power_supply/*; do
    [[ -r "${ps}/type" && "$(cat "${ps}/type")" == Battery ]] || continue
    [[ "$(cat "${ps}/scope" 2>/dev/null)" == Device ]] && continue   # mice, headsets
    HAS_BATTERY=1
done

IS_LAPTOP=${HAS_BATTERY}
if [[ -r "${SYS}/sys/class/dmi/id/chassis_type" ]]; then
    case "$(cat "${SYS}/sys/class/dmi/id/chassis_type")" in
        8|9|10|11|14|30|31|32) IS_LAPTOP=1 ;;   # portable, laptop, notebook, handheld, tablet, convertible, detachable
    esac
fi

HAS_BACKLIGHT=0
compgen -G "${SYS}/sys/class/backlight/*" >/dev/null && HAS_BACKLIGHT=1

HAS_TOUCHPAD=0
if [[ -r "${SYS}/proc/bus/input/devices" ]] && grep -qi 'touchpad' "${SYS}/proc/bus/input/devices"; then
    HAS_TOUCHPAD=1
fi

KB_LAYOUT=""
KB_VARIANT=""
if [[ -z "${SYS}" ]] && command -v localectl >/dev/null 2>&1; then
    KB_LAYOUT="$(localectl status 2>/dev/null | sed -n 's/^ *X11 Layout: *//p')"
    KB_VARIANT="$(localectl status 2>/dev/null | sed -n 's/^ *X11 Variant: *//p')"
fi
if [[ -z "${KB_LAYOUT}" && -r "${SYS}/etc/vconsole.conf" ]]; then
    # Console keymaps like "de-latin1" map to XKB layout "de".
    KB_LAYOUT="$(sed -n 's/^KEYMAP=//p' "${SYS}/etc/vconsole.conf" | tr -d '"' | cut -d- -f1)"
fi
# Only plain XKB identifiers are safe to embed in config files.
[[ "${KB_LAYOUT}" =~ ^[A-Za-z0-9,_()-]+$ ]] || KB_LAYOUT="us"
[[ -z "${KB_VARIANT}" || "${KB_VARIANT}" =~ ^[A-Za-z0-9,_()-]+$ ]] || KB_VARIANT=""

# ─── Outputs ─────────────────────────────────────────────────────────────────

emit_env() {
    # Prints shell assignments that never override values the user already set.
    set_default() {
        printf '[ -n "${%s:-}" ] || export %s=%q\n' "$1" "$1" "$2"
    }

    set_default XDG_CURRENT_DESKTOP "GhostedLand"
    set_default MOZ_ENABLE_WAYLAND 1
    set_default ELECTRON_OZONE_PLATFORM_HINT auto
    set_default QT_QPA_PLATFORM "wayland;xcb"

    # Multi-GPU: tell ghosted-compositor which GPU drives the session.
    # (It uses a single GPU; outputs wired only to another GPU stay dark.)
    if [[ ${GPU_COUNT} -gt 1 && ${PRIMARY} -ge 0 ]]; then
        set_default GHOSTED_DRM_DEVICE "/dev/dri/${GPU_CARDS[$PRIMARY]}"
    fi

    # NVIDIA proprietary driver as the primary renderer.
    if [[ "${PRIMARY_DRIVER}" == nvidia ]]; then
        set_default LIBVA_DRIVER_NAME nvidia
        set_default __GLX_VENDOR_LIBRARY_NAME nvidia
        set_default NVD_BACKEND direct
    fi

    # Virtual machines: virtual GPUs often lack atomic modesetting.
    if [[ ${IS_VM} -eq 1 ]]; then
        set_default SMITHAY_USE_LEGACY 1
    fi
}

emit_packages() {
    # Driver userspace for every detected GPU (pacman names).
    local d
    for i in "${!GPU_CARDS[@]}"; do
        d="${GPU_DRIVER[$i]}"
        case "${d}" in
            amdgpu) echo vulkan-radeon ;;
            i915|xe) echo vulkan-intel; echo intel-media-driver ;;
            nvidia) echo nvidia-utils; echo egl-wayland; echo libva-nvidia-driver ;;
            nouveau) echo vulkan-nouveau ;;
            virtio_gpu|vmwgfx) echo vulkan-virtio ;;
        esac
    done | sort -u
}

emit_vars() {
    cat <<EOF
HW_GPU_COUNT=${GPU_COUNT}
HW_PRIMARY_GPU_VENDOR=${PRIMARY_VENDOR}
HW_PRIMARY_GPU_DRIVER=${PRIMARY_DRIVER}
HW_HYBRID_GPU=$([[ ${GPU_COUNT} -gt 1 ]] && echo 1 || echo 0)
HW_NVIDIA_MODESET=${NVIDIA_MODESET}
HW_IS_VM=${IS_VM}
HW_CPU_VENDOR=${CPU_VENDOR}
HW_IS_LAPTOP=${IS_LAPTOP}
HW_HAS_BATTERY=${HAS_BATTERY}
HW_HAS_BACKLIGHT=${HAS_BACKLIGHT}
HW_HAS_TOUCHPAD=${HAS_TOUCHPAD}
HW_KB_LAYOUT=${KB_LAYOUT}
HW_KB_VARIANT=${KB_VARIANT}
EOF
}

emit_report() {
    echo "GhostedLand hardware report"
    echo "  CPU:        ${CPU_MODEL} (${CPU_VENDOR})"
    echo "  Form:       $([[ ${IS_VM} -eq 1 ]] && echo 'virtual machine' || ([[ ${IS_LAPTOP} -eq 1 ]] && echo laptop || echo desktop))"
    echo "  Battery:    $([[ ${HAS_BATTERY} -eq 1 ]] && echo yes || echo no)    Backlight: $([[ ${HAS_BACKLIGHT} -eq 1 ]] && echo yes || echo no)    Touchpad: $([[ ${HAS_TOUCHPAD} -eq 1 ]] && echo yes || echo no)"
    echo "  Keyboard:   ${KB_LAYOUT}${KB_VARIANT:+ (${KB_VARIANT})}"
    if [[ ${GPU_COUNT} -eq 0 ]]; then
        echo "  GPU:        none detected"
    fi
    for i in "${!GPU_CARDS[@]}"; do
        local role="secondary"
        [[ $i -eq ${PRIMARY} ]] && role="primary"
        local notes=""
        [[ "${GPU_PANEL[$i]}" == 1 ]] && notes+=" built-in panel"
        [[ "${GPU_OUTPUTS[$i]}" -gt 0 ]] && notes+=" ${GPU_OUTPUTS[$i]} output(s) connected"
        printf '  GPU:        %s %s (driver %s) — %s%s\n' "${GPU_CARDS[$i]}" "${GPU_VENDOR[$i]}" "${GPU_DRIVER[$i]}" "${role}" "${notes:+,${notes}}"
    done
    if has_driver nvidia && [[ "${NVIDIA_MODESET}" != Y ]]; then
        echo "  WARNING:    nvidia_drm.modeset is not enabled; add 'nvidia_drm.modeset=1' to the kernel command line."
    fi
}

case "${1:---report}" in
    --env) emit_env ;;
    --packages) emit_packages ;;
    --vars) emit_vars ;;
    --report) emit_report ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) echo "unknown option: $1 (use --report, --env, --packages, --vars)" >&2; exit 2 ;;
esac
