import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gdk, GLib, Adw

class AppearanceView(Adw.PreferencesPage):
    def __init__(self, parser):
        super().__init__()
        self.parser = parser
        self.set_title("Appearance")
        self.set_icon_name("display-brightness-symbolic")
        
        # Load active values
        self.config_values = self.parser.read_config_values("general.conf")

        # ── 0. SYSTEM THEME ────────────────────────────────────────────────────
        theme_group = Adw.PreferencesGroup()
        theme_group.set_title("System Theme")
        theme_group.set_description("Select your preferred lighting mode.")
        self.add(theme_group)

        theme_row = Adw.ActionRow()
        theme_row.set_title("Color Scheme")
        theme_row.set_subtitle("Applies instantly across the entire application")

        # Segmented (linked) button group
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        btn_box.get_style_context().add_class("linked")
        btn_box.set_valign(Gtk.Align.CENTER)

        self.theme_light_btn = Gtk.ToggleButton()
        light_inner = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        light_icon = Gtk.Image.new_from_icon_name("display-brightness-symbolic")
        light_icon.set_pixel_size(16)
        light_inner.append(light_icon)
        light_inner.append(Gtk.Label(label="Light"))
        self.theme_light_btn.set_child(light_inner)

        self.theme_dark_btn = Gtk.ToggleButton(group=self.theme_light_btn)
        dark_inner = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        dark_icon = Gtk.Image.new_from_icon_name("media-record-symbolic")
        dark_icon.set_pixel_size(16)
        dark_inner.append(dark_icon)
        dark_inner.append(Gtk.Label(label="Dark"))
        self.theme_dark_btn.set_child(dark_inner)

        self.theme_system_btn = Gtk.ToggleButton(group=self.theme_light_btn)
        system_inner = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        system_icon = Gtk.Image.new_from_icon_name("emblem-system-symbolic")
        system_icon.set_pixel_size(16)
        system_inner.append(system_icon)
        system_inner.append(Gtk.Label(label="System"))
        self.theme_system_btn.set_child(system_inner)

        btn_box.append(self.theme_light_btn)
        btn_box.append(self.theme_dark_btn)
        btn_box.append(self.theme_system_btn)
        theme_row.add_suffix(btn_box)
        theme_group.add(theme_row)

        # Set initial active button based on current scheme
        style_mgr = Adw.StyleManager.get_default()
        current_scheme = style_mgr.get_color_scheme()
        if current_scheme == Adw.ColorScheme.FORCE_LIGHT:
            self.theme_light_btn.set_active(True)
        elif current_scheme in (Adw.ColorScheme.FORCE_DARK, Adw.ColorScheme.PREFER_DARK):
            self.theme_dark_btn.set_active(True)
        else:
            self.theme_system_btn.set_active(True)

        # Block mutual-interference on init, then connect
        self.theme_light_btn.connect("toggled", self._on_theme_toggled, Adw.ColorScheme.FORCE_LIGHT)
        self.theme_dark_btn.connect("toggled", self._on_theme_toggled, Adw.ColorScheme.FORCE_DARK)
        self.theme_system_btn.connect("toggled", self._on_theme_toggled, Adw.ColorScheme.DEFAULT)

        # ── 1. WINDOW LAYOUT & BORDERS ─────────────────────────────────────────
        layout_group = Adw.PreferencesGroup()
        layout_group.set_title("Layout and Borders")
        layout_group.set_description("Configure margins, window spacings and border thicknesses")
        self.add(layout_group)
        
        # Gaps In
        self.gaps_in_row = Adw.ActionRow()
        self.gaps_in_row.set_title("Gaps Inside")
        self.gaps_in_row.set_subtitle("Spacing between adjacent windows")
        gaps_in_val = int(self.config_values.get("general.gaps_in", "5"))
        self.gaps_in_slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 30, 1)
        self.gaps_in_slider.set_value(gaps_in_val)
        self.gaps_in_slider.set_size_request(200, -1)
        self.gaps_in_slider.set_valign(Gtk.Align.CENTER)
        self.gaps_in_slider.set_draw_value(True)
        self.gaps_in_slider.connect("value-changed", self.on_gaps_in_changed)
        self.gaps_in_row.add_suffix(self.gaps_in_slider)
        layout_group.add(self.gaps_in_row)
        
        # Gaps Out
        self.gaps_out_row = Adw.ActionRow()
        self.gaps_out_row.set_title("Gaps Outside")
        self.gaps_out_row.set_subtitle("Spacing between windows and screen edges")
        gaps_out_val = int(self.config_values.get("general.gaps_out", "5"))
        self.gaps_out_slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 40, 1)
        self.gaps_out_slider.set_value(gaps_out_val)
        self.gaps_out_slider.set_size_request(200, -1)
        self.gaps_out_slider.set_valign(Gtk.Align.CENTER)
        self.gaps_out_slider.set_draw_value(True)
        self.gaps_out_slider.connect("value-changed", self.on_gaps_out_changed)
        self.gaps_out_row.add_suffix(self.gaps_out_slider)
        layout_group.add(self.gaps_out_row)
        
        # Border Size
        self.border_row = Adw.ActionRow()
        self.border_row.set_title("Border Size")
        self.border_row.set_subtitle("Thickness of active/inactive window outlines")
        border_val = int(self.config_values.get("general.border_size", "3"))
        self.border_slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 10, 1)
        self.border_slider.set_value(border_val)
        self.border_slider.set_size_request(200, -1)
        self.border_slider.set_valign(Gtk.Align.CENTER)
        self.border_slider.set_draw_value(True)
        self.border_slider.connect("value-changed", self.on_border_changed)
        self.border_row.add_suffix(self.border_slider)
        layout_group.add(self.border_row)

        # Layout Dispatcher
        self.layout_row = Adw.ActionRow()
        self.layout_row.set_title("Window Layout Engine")
        self.layout_row.set_subtitle("Algorithm used to arrange windows on workspaces")
        current_layout = self.config_values.get("general.layout", "dwindle")
        self.layout_combo = Gtk.ComboBoxText()
        self.layout_combo.append("dwindle", "Dwindle (Standard)")
        self.layout_combo.append("master", "Master (Stack)")
        self.layout_combo.set_active_id(current_layout)
        self.layout_combo.set_valign(Gtk.Align.CENTER)
        self.layout_combo.connect("changed", self.on_layout_changed)
        self.layout_row.add_suffix(self.layout_combo)
        layout_group.add(self.layout_row)

        # 2. OPACITY & ROUNDING
        aesthetics_group = Adw.PreferencesGroup()
        aesthetics_group.set_title("Opacity and Rounding")
        aesthetics_group.set_description("Customize window transparency and corner smoothing")
        self.add(aesthetics_group)
        
        # Rounding
        self.rounding_row = Adw.ActionRow()
        self.rounding_row.set_title("Corner Rounding")
        self.rounding_row.set_subtitle("Radius of window corner curves (px)")
        rounding_val = int(self.config_values.get("decoration.rounding", "10"))
        self.rounding_slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 30, 1)
        self.rounding_slider.set_value(rounding_val)
        self.rounding_slider.set_size_request(200, -1)
        self.rounding_slider.set_valign(Gtk.Align.CENTER)
        self.rounding_slider.set_draw_value(True)
        self.rounding_slider.connect("value-changed", self.on_rounding_changed)
        self.rounding_row.add_suffix(self.rounding_slider)
        aesthetics_group.add(self.rounding_row)
        
        # Active Opacity
        self.active_opacity_row = Adw.ActionRow()
        self.active_opacity_row.set_title("Active Opacity")
        self.active_opacity_row.set_subtitle("Transparency factor of focused windows")
        act_op_val = float(self.config_values.get("decoration.active_opacity", "0.95"))
        self.active_opacity_slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0.1, 1.0, 0.05)
        self.active_opacity_slider.set_value(act_op_val)
        self.active_opacity_slider.set_size_request(200, -1)
        self.active_opacity_slider.set_valign(Gtk.Align.CENTER)
        self.active_opacity_slider.set_draw_value(True)
        self.active_opacity_slider.connect("value-changed", self.on_active_opacity_changed)
        self.active_opacity_row.add_suffix(self.active_opacity_slider)
        aesthetics_group.add(self.active_opacity_row)
        
        # Inactive Opacity
        self.inactive_opacity_row = Adw.ActionRow()
        self.inactive_opacity_row.set_title("Inactive Opacity")
        self.inactive_opacity_row.set_subtitle("Transparency factor of background windows")
        inact_op_val = float(self.config_values.get("decoration.inactive_opacity", "0.8"))
        self.inactive_opacity_slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0.1, 1.0, 0.05)
        self.inactive_opacity_slider.set_value(inact_op_val)
        self.inactive_opacity_slider.set_size_request(200, -1)
        self.inactive_opacity_slider.set_valign(Gtk.Align.CENTER)
        self.inactive_opacity_slider.set_draw_value(True)
        self.inactive_opacity_slider.connect("value-changed", self.on_inactive_opacity_changed)
        self.inactive_opacity_row.add_suffix(self.inactive_opacity_slider)
        aesthetics_group.add(self.inactive_opacity_row)

        # 3. BACKGROUND BLUR (HARDWARE ACCELERATED)
        blur_group = Adw.PreferencesGroup()
        blur_group.set_title("Hardware Accelerated Blur")
        blur_group.set_description("Apply rich blurred overlays beneath transparent windows")
        self.add(blur_group)
        
        # Blur Enabled
        self.blur_row = Adw.ActionRow()
        self.blur_row.set_title("Enable Backdrop Blur")
        self.blur_row.set_subtitle("Blurs background content behind window panels")
        blur_enabled = self.config_values.get("decoration.blur.enabled", "true").lower() == "true"
        self.blur_switch = Gtk.Switch()
        self.blur_switch.set_active(blur_enabled)
        self.blur_switch.set_valign(Gtk.Align.CENTER)
        self.blur_switch.connect("state-set", self.on_blur_enabled_changed)
        self.blur_row.add_suffix(self.blur_switch)
        blur_group.add(self.blur_row)
        
        # Blur Size
        self.blur_size_row = Adw.ActionRow()
        self.blur_size_row.set_title("Blur Size")
        self.blur_size_row.set_subtitle("Spread radius of the blur filter")
        blur_size_val = int(self.config_values.get("decoration.blur.size", "6"))
        self.blur_size_slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 1, 20, 1)
        self.blur_size_slider.set_value(blur_size_val)
        self.blur_size_slider.set_size_request(200, -1)
        self.blur_size_slider.set_valign(Gtk.Align.CENTER)
        self.blur_size_slider.set_draw_value(True)
        self.blur_size_slider.connect("value-changed", self.on_blur_size_changed)
        self.blur_size_row.add_suffix(self.blur_size_slider)
        blur_group.add(self.blur_size_row)
        
        # Blur Passes
        self.blur_passes_row = Adw.ActionRow()
        self.blur_passes_row.set_title("Blur Passes")
        self.blur_passes_row.set_subtitle("Number of filtering rendering runs (higher is smoother but heavier)")
        blur_pass_val = int(self.config_values.get("decoration.blur.passes", "1"))
        self.blur_passes_slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 1, 6, 1)
        self.blur_passes_slider.set_value(blur_pass_val)
        self.blur_passes_slider.set_size_request(200, -1)
        self.blur_passes_slider.set_valign(Gtk.Align.CENTER)
        self.blur_passes_slider.set_draw_value(True)
        self.blur_passes_slider.connect("value-changed", self.on_blur_passes_changed)
        self.blur_passes_row.add_suffix(self.blur_passes_slider)
        blur_group.add(self.blur_passes_row)

        # Xray Blur Toggle
        self.xray_row = Adw.ActionRow()
        self.xray_row.set_title("Blur X-Ray")
        self.xray_row.set_subtitle("Keeps background blur active even with solid overlays")
        xray_enabled = self.config_values.get("decoration.blur.xray", "false").lower() == "true"
        self.xray_switch = Gtk.Switch()
        self.xray_switch.set_active(xray_enabled)
        self.xray_switch.set_valign(Gtk.Align.CENTER)
        self.xray_switch.connect("state-set", self.on_xray_changed)
        self.xray_row.add_suffix(self.xray_switch)
        blur_group.add(self.xray_row)

        # Special Blur Toggle
        self.special_blur_row = Adw.ActionRow()
        self.special_blur_row.set_title("Special Workspace Blur")
        self.special_blur_row.set_subtitle("Blurs background content behind scratchpads")
        special_enabled = self.config_values.get("decoration.blur.special", "true").lower() == "true"
        self.special_blur_switch = Gtk.Switch()
        self.special_blur_switch.set_active(special_enabled)
        self.special_blur_switch.set_valign(Gtk.Align.CENTER)
        self.special_blur_switch.connect("state-set", self.on_special_blur_changed)
        self.special_blur_row.add_suffix(self.special_blur_switch)
        blur_group.add(self.special_blur_row)

        # 4. WINDOW OUTLINE COLORS
        colors_group = Adw.PreferencesGroup()
        colors_group.set_title("Active and Inactive Window Borders")
        colors_group.set_description("Style active outline gradient and inactive lines")
        self.add(colors_group)

        # Active Border Row
        self.active_border_row = Adw.ActionRow()
        self.active_border_row.set_title("Active Border Color Gradient")
        self.active_border_row.set_subtitle("Hex colors or RGBA. Format: rgba(c6a0f6ee) rgba(8aadf4ee) 45deg")
        active_border_val = self.config_values.get("general.col.active_border", "rgba(c6a0f6ee) rgba(8aadf4ee) 45deg")
        self.active_border_entry = Gtk.Entry()
        self.active_border_entry.set_text(active_border_val)
        self.active_border_entry.set_size_request(240, -1)
        self.active_border_entry.set_valign(Gtk.Align.CENTER)
        self.active_border_entry.connect("changed", self.on_active_border_changed)
        self.active_border_row.add_suffix(self.active_border_entry)
        colors_group.add(self.active_border_row)

        # Inactive Border Row
        self.inactive_border_row = Adw.ActionRow()
        self.inactive_border_row.set_title("Inactive Border Color")
        self.inactive_border_row.set_subtitle("Hex/RGBA line outline for inactive containers")
        inactive_border_val = self.config_values.get("general.col.inactive_border", "rgba(595959aa)")
        self.inactive_border_entry = Gtk.Entry()
        self.inactive_border_entry.set_text(inactive_border_val)
        self.inactive_border_entry.set_size_request(240, -1)
        self.inactive_border_entry.set_valign(Gtk.Align.CENTER)
        self.inactive_border_entry.connect("changed", self.on_inactive_border_changed)
        self.inactive_border_row.add_suffix(self.inactive_border_entry)
        colors_group.add(self.inactive_border_row)

    # --- Signal Handlers ---

    def _on_theme_toggled(self, btn, scheme):
        if btn.get_active():
            Adw.StyleManager.get_default().set_color_scheme(scheme)
            import subprocess
            try:
                if scheme == Adw.ColorScheme.FORCE_DARK:
                    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", "prefer-dark"], check=False)
                elif scheme == Adw.ColorScheme.FORCE_LIGHT:
                    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", "prefer-light"], check=False)
                else:
                    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", "default"], check=False)
            except Exception as e:
                print(f"Failed to set gsettings: {e}")

    def on_gaps_in_changed(self, scale):
        val = int(scale.get_value())
        self.parser.update_key_value("general.conf", ["general"], "gaps_in", str(val))
        
    def on_gaps_out_changed(self, scale):
        val = int(scale.get_value())
        self.parser.update_key_value("general.conf", ["general"], "gaps_out", str(val))
        
    def on_border_changed(self, scale):
        val = int(scale.get_value())
        self.parser.update_key_value("general.conf", ["general"], "border_size", str(val))

    def on_layout_changed(self, combo):
        active_id = combo.get_active_id()
        if active_id:
            self.parser.update_key_value("general.conf", ["general"], "layout", active_id)

    def on_rounding_changed(self, scale):
        val = int(scale.get_value())
        self.parser.update_key_value("general.conf", ["decoration"], "rounding", str(val))
        
    def on_active_opacity_changed(self, scale):
        val = round(scale.get_value(), 2)
        self.parser.update_key_value("general.conf", ["decoration"], "active_opacity", f"{val:.2f}")
        
    def on_inactive_opacity_changed(self, scale):
        val = round(scale.get_value(), 2)
        self.parser.update_key_value("general.conf", ["decoration"], "inactive_opacity", f"{val:.2f}")

    def on_blur_enabled_changed(self, switch, state):
        val = "true" if state else "false"
        self.parser.update_key_value("general.conf", ["decoration", "blur"], "enabled", val)
        return False # Accept state-set

    def on_blur_size_changed(self, scale):
        val = int(scale.get_value())
        self.parser.update_key_value("general.conf", ["decoration", "blur"], "size", str(val))

    def on_blur_passes_changed(self, scale):
        val = int(scale.get_value())
        self.parser.update_key_value("general.conf", ["decoration", "blur"], "passes", str(val))

    def on_xray_changed(self, switch, state):
        val = "true" if state else "false"
        self.parser.update_key_value("general.conf", ["decoration", "blur"], "xray", val)
        return False

    def on_special_blur_changed(self, switch, state):
        val = "true" if state else "false"
        self.parser.update_key_value("general.conf", ["decoration", "blur"], "special", val)
        return False

    def on_active_border_changed(self, entry):
        text = entry.get_text().strip()
        if text:
            self.parser.update_key_value("general.conf", ["general"], "col.active_border", text)

    def on_inactive_border_changed(self, entry):
        text = entry.get_text().strip()
        if text:
            self.parser.update_key_value("general.conf", ["general"], "col.inactive_border", text)
