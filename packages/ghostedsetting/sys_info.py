import os
import re
import json
import subprocess
import psutil

class SystemInfoHelper:
    @staticmethod
    def get_cpu_usage():
        try:
            return psutil.cpu_percent(interval=None)
        except Exception:
            return 0.0

    @staticmethod
    def get_ram_info():
        try:
            vm = psutil.virtual_memory()
            return {
                "percent": vm.percent,
                "used_gb": round(vm.used / (1024 ** 3), 2),
                "total_gb": round(vm.total / (1024 ** 3), 2),
                "free_gb": round(vm.available / (1024 ** 3), 2)
            }
        except Exception:
            return {"percent": 0.0, "used_gb": 0.0, "total_gb": 0.0, "free_gb": 0.0}

    @staticmethod
    def get_uptime():
        try:
            with open('/proc/uptime', 'r') as f:
                uptime_seconds = float(f.readline().split()[0])
            
            days = int(uptime_seconds // (24 * 3600))
            uptime_seconds %= (24 * 3600)
            hours = int(uptime_seconds // 3600)
            uptime_seconds %= 3600
            minutes = int(uptime_seconds // 60)
            
            parts = []
            if days > 0:
                parts.append(f"{days}d")
            if hours > 0:
                parts.append(f"{hours}h")
            parts.append(f"{minutes}m")
            return " ".join(parts)
        except Exception:
            return "Unknown"

    @staticmethod
    def get_system_details():
        details = {
            "os": "Arch Linux",
            "kernel": "Unknown",
            "hyprland_version": "Unknown",
            "gpu": "Unknown",
            "cpu_model": "Unknown"
        }
        
        # CPU model
        try:
            with open('/proc/cpuinfo', 'r') as f:
                for line in f:
                    if "model name" in line:
                        details["cpu_model"] = line.split(":", 1)[1].strip()
                        break
        except Exception:
            pass

        # Kernel details
        try:
            details["kernel"] = subprocess.check_output(["uname", "-r"]).decode().strip()
        except Exception:
            pass

        # Parse hyprctl systeminfo
        try:
            res = subprocess.check_output(["hyprctl", "systeminfo"], stderr=subprocess.DEVNULL).decode()
            
            # Find Hyprland version
            v_match = re.search(r'Hyprland\s+([0-9\.]+)', res)
            if v_match:
                details["hyprland_version"] = v_match.group(1)

            # Find GPU Info
            gpu_lines = []
            capture_gpu = False
            for line in res.splitlines():
                if "GPU information:" in line:
                    capture_gpu = True
                    continue
                if capture_gpu:
                    if line.strip() == "" or "os-release:" in line:
                        break
                    gpu_lines.append(line.strip())
            
            if gpu_lines:
                # Find clean GPU name from line, e.g. NVIDIA TU117M [GeForce GTX 1650 Mobile]
                gpu_text = " ".join(gpu_lines)
                clean_gpu = re.search(r'\[([^\]]+)\]', gpu_text)
                if clean_gpu:
                    details["gpu"] = clean_gpu.group(1)
                else:
                    # Fallback to the first line
                    details["gpu"] = gpu_lines[0]
        except Exception:
            pass

        # Fallback for Hyprland version using hyprctl version
        if details["hyprland_version"] == "Unknown":
            try:
                res = subprocess.check_output(["hyprctl", "version"], stderr=subprocess.DEVNULL).decode()
                v_match = re.search(r'Hyprland\s+([0-9\.]+)', res)
                if v_match:
                    details["hyprland_version"] = v_match.group(1)
            except Exception:
                pass

        # Fallback for GPU via lspci
        if details["gpu"] == "Unknown":
            try:
                lspci = subprocess.check_output(["lspci"]).decode()
                vgas = [line for line in lspci.splitlines() if "VGA compatible" in line or "3D controller" in line]
                gpus = []
                for vga in vgas:
                    # E.g. NVIDIA Corporation TU117M [GeForce GTX 1650 Mobile]
                    match = re.search(r'\[([^\]]+)\]', vga)
                    if match:
                        gpus.append(match.group(1))
                    else:
                        gpus.append(vga.split(":", 2)[-1].strip())
                if gpus:
                    details["gpu"] = " & ".join(gpus)
            except Exception:
                pass

        return details

    @staticmethod
    def get_hyprland_stats():
        stats = {
            "monitors": [],
            "active_workspace": "Unknown",
            "total_workspaces": 0,
            "is_running": False
        }
        
        try:
            # Check monitors
            monitors_json = subprocess.check_output(["hyprctl", "monitors", "-j"], stderr=subprocess.DEVNULL).decode()
            stats["monitors"] = json.loads(monitors_json)
            stats["is_running"] = True
        except Exception:
            pass

        try:
            # Active workspace
            aw_json = subprocess.check_output(["hyprctl", "activeworkspace", "-j"], stderr=subprocess.DEVNULL).decode()
            stats["active_workspace"] = json.loads(aw_json)["name"]
        except Exception:
            pass

        try:
            # Total workspaces
            w_json = subprocess.check_output(["hyprctl", "workspaces", "-j"], stderr=subprocess.DEVNULL).decode()
            workspaces = json.loads(w_json)
            stats["total_workspaces"] = len(workspaces)
        except Exception:
            pass

        return stats

    @staticmethod
    def get_display_info():
        """Focused monitor resolution from hyprctl, or xrandr fallback."""
        try:
            monitors_json = subprocess.check_output(
                ["hyprctl", "monitors", "-j"], stderr=subprocess.DEVNULL
            ).decode()
            monitors = json.loads(monitors_json)
            target = next((m for m in monitors if m.get("focused")), monitors[0] if monitors else None)
            if target:
                w, h = target.get("width", 0), target.get("height", 0)
                hz = target.get("refreshRate", 60.0)
                count = len(monitors)
                suffix = f"  +{count - 1} more" if count > 1 else ""
                return f"{w}\u00d7{h} @ {hz:.0f}Hz{suffix}"
        except Exception:
            pass
        try:
            out = subprocess.check_output(["xrandr", "--current"], stderr=subprocess.DEVNULL).decode()
            m = re.search(r'(\d+)x(\d+)\+\d+\+\d+\s+(\d+\.?\d*)\*', out)
            if m:
                return f"{m.group(1)}\u00d7{m.group(2)} @ {float(m.group(3)):.0f}Hz"
        except Exception:
            pass
        return "N/A"

    @staticmethod
    def get_network_info():
        """Primary up network interface, prefers wireless then wired."""
        try:
            stats = psutil.net_if_stats()
            def priority(name):
                if name == "lo": return 99
                if name.startswith("wl"): return 0
                if name.startswith("eth") or name.startswith("en"): return 1
                return 2
            up_ifaces = [k for k, v in stats.items() if v.isup and k != "lo"]
            if not up_ifaces:
                return "Disconnected"
            best = sorted(up_ifaces, key=priority)[0]
            return f"Connected to {best}"
        except Exception:
            return "Unknown"

    @staticmethod
    def get_battery_info():
        """Battery percentage and status; 'AC Power' if no battery."""
        try:
            bat = psutil.sensors_battery()
            if bat is None:
                return "AC Power"
            pct = int(bat.percent)
            if bat.power_plugged:
                return "Fully Charged" if pct >= 100 else f"Charging \u2014 {pct}%"
            return f"{pct}% Remaining"
        except Exception:
            return "Unknown"

    @staticmethod
    def get_arch_info():
        """Distro name + CPU architecture string."""
        try:
            arch = subprocess.check_output(["uname", "-m"], stderr=subprocess.DEVNULL).decode().strip()
            os_name = "Linux"
            try:
                with open("/etc/os-release") as f:
                    for line in f:
                        if line.startswith("NAME="):
                            os_name = line.split("=", 1)[1].strip().strip('"')
                            break
            except Exception:
                pass
            return f"{os_name} {arch}"
        except Exception:
            return "Linux x86_64"
