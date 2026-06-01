import os
import re
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gdk, GLib, Adw, Pango

from sys_info import SystemInfoHelper

class DashboardView(Gtk.Box):
    def __init__(self, parser):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        self.parser = parser
        self.set_margin_start(24)
        self.set_margin_end(24)
        self.set_margin_top(24)
        self.set_margin_bottom(24)
        
        # ScrolledWindow to ensure potato PCs with smaller screens can scroll properly
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.append(scrolled)
        
        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        scrolled.set_child(content_box)
        
        # 1. Welcome Banner
        banner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        banner.get_style_context().add_class("welcome-banner")
        
        welcome_label = Gtk.Label(label="Ghosted Arch Control Panel")
        welcome_label.set_halign(Gtk.Align.START)
        welcome_label.get_style_context().add_class("title-1")
        welcome_label.set_css_classes(["title-1"])
        welcome_label.set_markup("<span size='xx-large' weight='bold'>Welcome Back!</span>")
        banner.append(welcome_label)
        
        subtitle_label = Gtk.Label(label="Manage your potato or powerhouse PC configuration seamlessly.")
        subtitle_label.set_halign(Gtk.Align.START)
        subtitle_label.set_markup("<span size='medium' alpha='70%'>Manage your Ghosted Arch setup seamlessly.</span>")
        banner.append(subtitle_label)
        
        content_box.append(banner)

        # ── Quick Info Cards row (Display / Network / Power / System Info) ──
        info_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        info_row.set_homogeneous(True)
        content_box.append(info_row)

        _BATTERY_PNG = "/usr/share/icons/AdwaitaLegacy/22x22/legacy/battery-full.png"
        card_defs = [
            ("display",  "display-brightness-symbolic",  "Display"),
            ("network",  "nm-signal-100-symbolic",        "Network"),
            ("power",    None,                            "Power"),
            ("sysinfo",  "dialog-information-symbolic",   "System Info"),
        ]
        self._info_labels = {}
        for key, icon_name, title in card_defs:
            card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            card.get_style_context().add_class("dashboard-card")
            card.set_hexpand(True)

            # Icon — power card uses a direct file load for the battery PNG
            if key == "power" and os.path.exists(_BATTERY_PNG):
                ic = Gtk.Image.new_from_file(_BATTERY_PNG)
                ic.set_size_request(22, 22)
            else:
                ic = Gtk.Image.new_from_icon_name(icon_name or "media-record-symbolic")
                ic.set_pixel_size(22)
            ic.set_halign(Gtk.Align.START)
            card.append(ic)

            t = Gtk.Label()
            t.set_halign(Gtk.Align.START)
            t.set_markup(f"<span weight='bold'>{title}</span>")
            card.append(t)

            v = Gtk.Label()
            v.set_halign(Gtk.Align.START)
            v.set_ellipsize(Pango.EllipsizeMode.END)
            v.set_markup("<span size='small' alpha='70%'>Loading…</span>")
            card.append(v)
            self._info_labels[key] = v

            info_row.append(card)

        # 2. Real-Time Resource Usage (CPU / RAM side-by-side)
        metrics_grid = Gtk.Grid()
        metrics_grid.set_column_spacing(16)
        metrics_grid.set_row_spacing(16)
        metrics_grid.set_column_homogeneous(True)
        content_box.append(metrics_grid)
        
        # CPU Card
        cpu_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        cpu_card.get_style_context().add_class("dashboard-card")
        
        cpu_header = Gtk.Label()
        cpu_header.set_halign(Gtk.Align.START)
        cpu_header.set_markup("<span size='large' weight='bold' alpha='70%'>CPU UTILIZATION</span>")
        cpu_card.append(cpu_header)
        
        self.cpu_value = Gtk.Label()
        self.cpu_value.set_halign(Gtk.Align.START)
        self.cpu_value.set_markup("<span size='xx-large' weight='heavy' color='#c6a0f6'>0.0%</span>")
        cpu_card.append(self.cpu_value)
        
        self.cpu_bar = Gtk.ProgressBar()
        self.cpu_bar.set_fraction(0.0)
        cpu_card.append(self.cpu_bar)
        
        metrics_grid.attach(cpu_card, 0, 0, 1, 1)
        
        # Memory Card
        mem_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        mem_card.get_style_context().add_class("dashboard-card")
        
        mem_header = Gtk.Label()
        mem_header.set_halign(Gtk.Align.START)
        mem_header.set_markup("<span size='large' weight='bold' alpha='70%'>MEMORY CONSUMPTION</span>")
        mem_card.append(mem_header)
        
        self.mem_value = Gtk.Label()
        self.mem_value.set_halign(Gtk.Align.START)
        self.mem_value.set_markup("<span size='xx-large' weight='heavy' color='#8aadf4'>0.0%</span>")
        mem_card.append(self.mem_value)
        
        self.mem_bar = Gtk.ProgressBar()
        self.mem_bar.set_fraction(0.0)
        mem_card.append(self.mem_bar)
        
        self.mem_details = Gtk.Label()
        self.mem_details.set_halign(Gtk.Align.START)
        self.mem_details.set_markup("<span size='small' alpha='70%'>Used: 0 GB / Total: 0 GB</span>")
        mem_card.append(self.mem_details)
        
        metrics_grid.attach(mem_card, 1, 0, 1, 1)
        
        # 3. Quick System Specs Card
        specs_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        specs_card.get_style_context().add_class("dashboard-card")
        
        specs_title = Gtk.Label()
        specs_title.set_halign(Gtk.Align.START)
        specs_title.set_markup("<span size='large' weight='bold'>System Specifications</span>")
        specs_card.append(specs_title)
        
        self.specs_list = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        specs_card.append(self.specs_list)
        
        content_box.append(specs_card)
        
        # 4. Workspace Status & Live Wallpaper Preview Card
        row_status = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        row_status.set_homogeneous(True)
        content_box.append(row_status)
        
        # Hyprland Status Card
        hypr_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        hypr_card.get_style_context().add_class("dashboard-card")
        
        hypr_title = Gtk.Label()
        hypr_title.set_halign(Gtk.Align.START)
        hypr_title.set_markup("<span size='large' weight='bold'>Hyprland Status</span>")
        hypr_card.append(hypr_title)
        
        self.hypr_info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        hypr_card.append(self.hypr_info_box)
        row_status.append(hypr_card)
        
        # Active Wallpaper Card
        wall_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        wall_card.get_style_context().add_class("dashboard-card")
        
        wall_title = Gtk.Label()
        wall_title.set_halign(Gtk.Align.START)
        wall_title.set_markup("<span size='large' weight='bold'>Active Wallpaper</span>")
        wall_card.append(wall_title)
        
        self.wall_preview_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.wall_preview_container.set_vexpand(True)
        self.wall_preview_container.set_valign(Gtk.Align.CENTER)
        wall_card.append(self.wall_preview_container)
        
        row_status.append(wall_card)
        
        # Load values and initialize system timers
        self.load_specs()
        self.update_live_metrics()
        self.load_wallpaper_preview()
        
        # Update metrics every 2.0 seconds
        GLib.timeout_add(2000, self.update_live_metrics)

    def load_specs(self):
        sys_details = SystemInfoHelper.get_system_details()
        uptime = SystemInfoHelper.get_uptime()
        
        specs = [
            ("OS", sys_details["os"]),
            ("Kernel", sys_details["kernel"]),
            ("Hyprland Version", sys_details["hyprland_version"]),
            ("CPU Model", sys_details["cpu_model"]),
            ("GPU Hardware", sys_details["gpu"]),
            ("System Uptime", uptime)
        ]
        
        # Clear old items
        while (child := self.specs_list.get_first_child()):
            self.specs_list.remove(child)
            
        for key, value in specs:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
            
            lbl_key = Gtk.Label()
            lbl_key.set_halign(Gtk.Align.START)
            lbl_key.set_markup(f"<span weight='semibold' alpha='70%'>{key}:</span>")
            
            lbl_val = Gtk.Label()
            lbl_val.set_halign(Gtk.Align.START)
            lbl_val.set_margin_start(10)
            escaped_val = GLib.markup_escape_text(value)
            lbl_val.set_markup(f"<span>{escaped_val}</span>")
            lbl_val.set_selectable(True)
            
            row.append(lbl_key)
            row.append(lbl_val)
            self.specs_list.append(row)

    def update_live_metrics(self):
        cpu = SystemInfoHelper.get_cpu_usage()
        ram = SystemInfoHelper.get_ram_info()

        # CPU
        self.cpu_value.set_markup(f"<span size='xx-large' weight='heavy' color='#c6a0f6'>{cpu:.1f}%</span>")
        self.cpu_bar.set_fraction(cpu / 100.0)

        # RAM
        self.mem_value.set_markup(f"<span size='xx-large' weight='heavy' color='#8aadf4'>{ram['percent']:.1f}%</span>")
        self.mem_bar.set_fraction(ram["percent"] / 100.0)
        self.mem_details.set_markup(f"<span size='small' alpha='70%'>Used: <b>{ram['used_gb']:.2f} GB</b> / Free: <b>{ram['free_gb']:.2f} GB</b> (Total: {ram['total_gb']:.1f} GB)</span>")

        # Quick info cards
        def _set(key, text):
            self._info_labels[key].set_markup(
                f"<span size='small' alpha='70%'>{GLib.markup_escape_text(text)}</span>"
            )
        _set("display", SystemInfoHelper.get_display_info())
        _set("network", SystemInfoHelper.get_network_info())
        _set("power",   SystemInfoHelper.get_battery_info())
        _set("sysinfo", SystemInfoHelper.get_arch_info())

        # Hyprland active stats
        hypr_stats = SystemInfoHelper.get_hyprland_stats()
        
        # Clear old items
        while (child := self.hypr_info_box.get_first_child()):
            self.hypr_info_box.remove(child)
            
        if hypr_stats["is_running"]:
            stats_rows = [
                ("Active Workspace", f"Workspace {hypr_stats['active_workspace']}"),
                ("Total Workspaces", f"{hypr_stats['total_workspaces']}"),
                ("Connected Monitors", f"{len(hypr_stats['monitors'])}")
            ]
            
            for monitor in hypr_stats["monitors"]:
                monitor_name = monitor.get("name", "Unknown")
                res = f"{monitor.get('width', 0)}x{monitor.get('height', 0)}@{monitor.get('refreshRate', 60.0):.1f}Hz"
                focused = " (Focused)" if monitor.get("focused", False) else ""
                stats_rows.append((f"Monitor [{monitor_name}]", f"{res}{focused}"))
        else:
            stats_rows = [
                ("Hyprland Running", "No active Hyprland session detected")
            ]
            
        for key, value in stats_rows:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
            lbl_key = Gtk.Label()
            lbl_key.set_halign(Gtk.Align.START)
            lbl_key.set_markup(f"<span weight='semibold' alpha='70%'>{key}:</span>")
            
            lbl_val = Gtk.Label()
            lbl_val.set_halign(Gtk.Align.START)
            lbl_val.set_margin_start(10)
            escaped_val = GLib.markup_escape_text(value)
            lbl_val.set_markup(f"<span>{escaped_val}</span>")
            
            row.append(lbl_key)
            row.append(lbl_val)
            self.hypr_info_box.append(row)
            
        return True # Continue timer

    def load_wallpaper_preview(self):
        # Clear container
        while (child := self.wall_preview_container.get_first_child()):
            self.wall_preview_container.remove(child)
            
        startup_items = self.parser.read_startup_items()
        wallpaper_path = None
        for item in startup_items:
            if "swaybg" in item["command"]:
                match = re.search(r'-i\s+([^\s]+)', item["command"])
                if match:
                    raw_path = match.group(1)
                    # Resolve $HOME or ~/.
                    resolved_path = os.path.expanduser(raw_path)
                    
                    # If this is workspace testing path, let's map it if needed
                    # Wait, if raw_path is ~/.config/hypr/wallpaper/...
                    # and we are testing in the local './hypr' folder:
                    if not os.path.exists(resolved_path):
                        # Try relative to config dir
                        local_test = os.path.join(self.parser.config_dir, "wallpaper", os.path.basename(resolved_path))
                        if os.path.exists(local_test):
                            wallpaper_path = local_test
                            break
                    wallpaper_path = resolved_path
                    break
        
        if wallpaper_path and os.path.exists(wallpaper_path):
            try:
                # Load wallpaper image scaled beautifully
                picture = Gtk.Picture.new_for_filename(wallpaper_path)
                picture.set_content_fit(Gtk.ContentFit.COVER)
                picture.set_size_request(240, 135) # Standard 16:9 ratio
                picture.set_hexpand(True)
                picture.set_vexpand(True)
                
                # Round the corners of the preview image
                frame = Gtk.Frame()
                frame.set_child(picture)
                # Frame visual adjustments
                frame.set_halign(Gtk.Align.CENTER)
                self.wall_preview_container.append(frame)
                
                lbl_name = Gtk.Label(label=os.path.basename(wallpaper_path))
                lbl_name.set_halign(Gtk.Align.CENTER)
                lbl_name.set_margin_top(8)
                lbl_name.set_markup(f"<span size='small' alpha='70%'>{os.path.basename(wallpaper_path)}</span>")
                self.wall_preview_container.append(lbl_name)
            except Exception as e:
                lbl_err = Gtk.Label(label=f"Failed to load image preview:\n{str(e)}")
                self.wall_preview_container.append(lbl_err)
        else:
            lbl_none = Gtk.Label()
            lbl_none.set_halign(Gtk.Align.CENTER)
            lbl_none.set_markup("<span italic='true' alpha='70%'>No wallpaper configured using swaybg in startup.conf</span>")
            self.wall_preview_container.append(lbl_none)
