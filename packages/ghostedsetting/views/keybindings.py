import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gdk, GLib, Adw

class KeybindingsView(Gtk.Box):
    def __init__(self, parser):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        self.parser = parser
        self.set_margin_start(24)
        self.set_margin_end(24)
        self.set_margin_top(24)
        self.set_margin_bottom(24)
        
        # Header title
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        title_lbl = Gtk.Label()
        title_lbl.set_halign(Gtk.Align.START)
        title_lbl.set_markup("<span size='x-large' weight='bold'>Keyboard Shortcuts</span>")
        title_box.append(title_lbl)
        
        desc_lbl = Gtk.Label()
        desc_lbl.set_halign(Gtk.Align.START)
        desc_lbl.set_markup("<span size='small' alpha='70%'>View, search and edit your Hyprland key combinations</span>")
        title_box.append(desc_lbl)
        header_box.append(title_box)
        
        # Spacer
        spacer = Gtk.Box()
        spacer.set_hexpand(True)
        header_box.append(spacer)
        
        # ADD Keybinding Button
        add_btn = Gtk.Button()
        add_btn.set_valign(Gtk.Align.CENTER)
        add_btn.get_style_context().add_class("accent-btn")
        add_lbl = Gtk.Label()
        add_lbl.set_markup("<span weight='bold'>Add Keybinding</span>")
        add_btn.set_child(add_lbl)
        add_btn.connect("clicked", self.on_add_clicked)
        header_box.append(add_btn)
        
        self.append(header_box)
        
        # Search Entry Bar
        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_hexpand(True)
        self.search_entry.set_placeholder_text("Search shortcuts (e.g. SUPER, terminal, workspaces)...")
        self.search_entry.connect("search-changed", self.on_search_changed)
        search_box.append(self.search_entry)
        self.append(search_box)
        
        # Scrollable list
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.append(scrolled)
        
        self.list_box = Gtk.ListBox()
        self.list_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self.list_box.get_style_context().add_class("boxed-list")
        scrolled.set_child(self.list_box)
        
        # Filter cache
        self.search_query = ""
        self.load_keybindings_list()

    def get_badge_class(self, mod_word):
        word = mod_word.upper().strip()
        if "$MAINMOD" in word or "SUPER" in word:
            return "badge-super"
        elif "SHIFT" in word:
            return "badge-shift"
        elif "CTRL" in word or "CONTROL" in word:
            return "badge-ctrl"
        elif "ALT" in word:
            return "badge-alt"
        else:
            return "badge-default"

    def load_keybindings_list(self):
        # Clear list
        while (child := self.list_box.get_first_child()):
            self.list_box.remove(child)
            
        binds = self.parser.read_keybindings()
        
        filtered_binds = []
        for b in binds:
            # Simple matching query
            if self.search_query:
                q = self.search_query.lower()
                matches = (
                    q in b["mods"].lower() or
                    q in b["key"].lower() or
                    q in b["dispatcher"].lower() or
                    q in b["args"].lower() or
                    q in b["comment"].lower()
                )
                if not matches:
                    continue
            filtered_binds.append(b)
            
        if not filtered_binds:
            row_empty = Gtk.ListBoxRow()
            lbl_empty = Gtk.Label()
            lbl_empty.set_margin_top(32)
            lbl_empty.set_margin_bottom(32)
            lbl_empty.set_markup("<span style='italic' alpha='70%'>No keybindings found matching your search.</span>")
            row_empty.set_child(lbl_empty)
            self.list_box.append(row_empty)
            return

        for bind in filtered_binds:
            row = Adw.ActionRow()
            row.set_margin_bottom(6)
            
            # Modifier Badge Box (Prefix)
            badge_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            badge_box.set_valign(Gtk.Align.CENTER)
            badge_box.set_margin_end(12)
            
            # Render each modifier word as a badge
            mod_words = [w for w in bind["mods"].split() if w.strip()]
            for word in mod_words:
                badge = Gtk.Label(label=word)
                badge.get_style_context().add_class("badge")
                badge.get_style_context().add_class(self.get_badge_class(word))
                badge_box.append(badge)
                
            # Render the key itself
            if bind["key"]:
                key_lbl = Gtk.Label(label=bind["key"].upper())
                key_lbl.get_style_context().add_class("badge")
                key_lbl.get_style_context().add_class("badge-default")
                key_lbl.set_markup(f"<span weight='bold'>{bind['key'].upper()}</span>")
                badge_box.append(key_lbl)
                
            row.add_prefix(badge_box)
            
            # Setup Action details as Row Title
            action_desc = f"{bind['dispatcher']}"
            if bind["args"]:
                action_desc += f" ➜ {bind['args']}"
            row.set_title(GLib.markup_escape_text(action_desc))
            
            # Setup Comment as Row Subtitle
            desc = bind["comment"] if bind["comment"] else "Key shortcut bind"
            row.set_subtitle(GLib.markup_escape_text(desc))
            
            # Action buttons box (Suffix)
            act_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            act_box.set_valign(Gtk.Align.CENTER)
            
            # Edit Button
            edit_btn = Gtk.Button.new_from_icon_name("emblem-system-symbolic")
            edit_btn.connect("clicked", self.on_edit_clicked, bind)
            act_box.append(edit_btn)
            
            # Delete Button
            del_btn = Gtk.Button.new_from_icon_name("user-trash-symbolic")
            del_btn.get_style_context().add_class("destructive-action")
            del_btn.connect("clicked", self.on_delete_clicked, bind["id"])
            act_box.append(del_btn)
            
            row.add_suffix(act_box)
            self.list_box.append(row)

    def on_search_changed(self, entry):
        self.search_query = entry.get_text().strip()
        self.load_keybindings_list()

    def on_delete_clicked(self, button, line_index):
        self.parser.delete_keybinding(line_index)
        self.load_keybindings_list()

    def on_edit_clicked(self, button, bind):
        self.open_bind_form(bind)

    def on_add_clicked(self, button):
        self.open_bind_form()

    def open_bind_form(self, bind=None):
        is_edit = bind is not None
        
        popup = Gtk.Window()
        popup.set_title("Edit Keybinding" if is_edit else "Create Keybinding")
        popup.set_modal(True)
        
        root = self.get_root()
        if isinstance(root, Gtk.Window):
            popup.set_transient_for(root)
            
        popup.set_default_size(480, -1)
        popup.set_resizable(False)
        
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        content.set_margin_start(20)
        content.set_margin_end(20)
        content.set_margin_top(20)
        content.set_margin_bottom(20)
        popup.set_child(content)
        
        lbl_title = Gtk.Label()
        lbl_title.set_halign(Gtk.Align.START)
        title_text = "Modify Keyboard Shortcut" if is_edit else "New Keyboard Shortcut"
        lbl_title.set_markup(f"<span size='large' weight='bold'>{title_text}</span>")
        content.append(lbl_title)
        
        # Grid for clean 2-column form alignment
        grid = Gtk.Grid()
        grid.set_column_spacing(12)
        grid.set_row_spacing(12)
        content.append(grid)
        
        # Modifiers Field
        lbl_mod = Gtk.Label(label="Modifiers:")
        lbl_mod.set_halign(Gtk.Align.START)
        grid.attach(lbl_mod, 0, 0, 1, 1)
        
        mod_entry = Gtk.Entry()
        mod_entry.set_hexpand(True)
        mod_entry.set_placeholder_text("e.g. $mainMod, $mainMod SHIFT, SUPER ALT")
        mod_entry.set_text(bind["mods"] if is_edit else "$mainMod")
        grid.attach(mod_entry, 1, 0, 1, 1)
        
        # Key Field
        lbl_key = Gtk.Label(label="Key Name/Code:")
        lbl_key.set_halign(Gtk.Align.START)
        grid.attach(lbl_key, 0, 1, 1, 1)
        
        key_entry = Gtk.Entry()
        key_entry.set_placeholder_text("e.g. Q, F, left, 121")
        key_entry.set_text(bind["key"] if is_edit else "")
        grid.attach(key_entry, 1, 1, 1, 1)
        
        # Common Dispatcher Combo + Custom text input Row
        lbl_disp = Gtk.Label(label="Action / Dispatcher:")
        lbl_disp.set_halign(Gtk.Align.START)
        grid.attach(lbl_disp, 0, 2, 1, 1)
        
        disp_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        
        disp_combo = Gtk.ComboBoxText()
        dispatchers = [
            ("exec", "exec (Launch App)"),
            ("killactive", "killactive (Close window)"),
            ("fullscreen", "fullscreen (Toggle fullscreen)"),
            ("togglefloating", "togglefloating (Float window)"),
            ("movefocus", "movefocus (Focus edge)"),
            ("workspace", "workspace (Go workspace)"),
            ("movetoworkspace", "movetoworkspace (Move window)"),
            ("togglespecialworkspace", "specialworkspace (Scratchpad)"),
            ("exit", "exit (Force quit Hyprland)")
        ]
        for key, val in dispatchers:
            disp_combo.append(key, val)
            
        current_disp = bind["dispatcher"] if is_edit else "exec"
        disp_combo.set_active_id(current_disp if current_disp in dict(dispatchers) else None)
        disp_box.append(disp_combo)
        
        disp_entry = Gtk.Entry()
        disp_entry.set_placeholder_text("Custom action...")
        disp_entry.set_text(current_disp)
        disp_entry.set_hexpand(True)
        disp_box.append(disp_entry)
        grid.attach(disp_box, 1, 2, 1, 1)
        
        # Set combo connection to automatically populate custom text
        def on_combo_changed(combo):
            act_id = combo.get_active_id()
            if act_id:
                disp_entry.set_text(act_id)
        disp_combo.connect("changed", on_combo_changed)
        
        # Arguments Field
        lbl_args = Gtk.Label(label="Arguments:")
        lbl_args.set_halign(Gtk.Align.START)
        grid.attach(lbl_args, 0, 3, 1, 1)
        
        args_entry = Gtk.Entry()
        args_entry.set_placeholder_text("e.g. kitty, l, 1, special:magic")
        args_entry.set_text(bind["args"] if is_edit else "")
        grid.attach(args_entry, 1, 3, 1, 1)
        
        # Description/Comment Field
        lbl_comm = Gtk.Label(label="Description:")
        lbl_comm.set_halign(Gtk.Align.START)
        grid.attach(lbl_comm, 0, 4, 1, 1)
        
        comm_entry = Gtk.Entry()
        comm_entry.set_placeholder_text("e.g. launch terminal emulator")
        comm_entry.set_text(bind["comment"] if is_edit else "")
        grid.attach(comm_entry, 1, 4, 1, 1)
        
        # Action Buttons
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        btn_box.set_halign(Gtk.Align.END)
        btn_box.set_margin_top(8)
        
        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.connect("clicked", lambda b: popup.destroy())
        btn_box.append(cancel_btn)
        
        save_btn = Gtk.Button(label="Save Binding")
        save_btn.get_style_context().add_class("accent-btn")
        
        def save_and_close(b):
            mods = mod_entry.get_text().strip()
            key = key_entry.get_text().strip()
            disp = disp_entry.get_text().strip()
            args = args_entry.get_text().strip()
            comment = comm_entry.get_text().strip()
            
            # Simple validation
            if key and disp:
                bind_type = bind["type"] if is_edit else "bind"
                if is_edit:
                    self.parser.update_keybinding(bind["id"], bind_type, mods, key, disp, args, comment)
                else:
                    self.parser.add_keybinding(bind_type, mods, key, disp, args, comment)
                popup.destroy()
                self.load_keybindings_list()
                
        save_btn.connect("clicked", save_and_close)
        btn_box.append(save_btn)
        content.append(btn_box)
        
        popup.present()
