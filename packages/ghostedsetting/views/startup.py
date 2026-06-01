import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gdk, GLib, Adw

class StartupView(Gtk.Box):
    def __init__(self, parser):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        self.parser = parser
        self.set_margin_start(24)
        self.set_margin_end(24)
        self.set_margin_top(24)
        self.set_margin_bottom(24)
        
        # Header Box with Title and ADD button
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        title_lbl = Gtk.Label()
        title_lbl.set_halign(Gtk.Align.START)
        title_lbl.set_markup("<span size='x-large' weight='bold'>Startup Applications</span>")
        title_box.append(title_lbl)
        
        desc_lbl = Gtk.Label()
        desc_lbl.set_halign(Gtk.Align.START)
        desc_lbl.set_markup("<span size='small' alpha='70%'>Manage background helper daemons and tools launched when you sign in</span>")
        title_box.append(desc_lbl)
        header_box.append(title_box)
        
        # Spacer
        spacer = Gtk.Box()
        spacer.set_hexpand(True)
        header_box.append(spacer)
        
        # ADD Button
        add_btn = Gtk.Button()
        add_btn.set_valign(Gtk.Align.CENTER)
        add_btn.get_style_context().add_class("accent-btn")
        add_lbl = Gtk.Label()
        add_lbl.set_markup("<span weight='bold'>Add Startup Item</span>")
        add_btn.set_child(add_lbl)
        add_btn.connect("clicked", self.on_add_clicked)
        header_box.append(add_btn)
        
        self.append(header_box)
        
        # Scrollable list container
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.append(scrolled)
        
        self.list_box = Gtk.ListBox()
        self.list_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self.list_box.get_style_context().add_class("boxed-list")
        scrolled.set_child(self.list_box)
        
        self.load_startup_list()

    def load_startup_list(self):
        # Clear existing list items
        while (child := self.list_box.get_first_child()):
            self.list_box.remove(child)
            
        items = self.parser.read_startup_items()
        
        if not items:
            row_empty = Gtk.ListBoxRow()
            lbl_empty = Gtk.Label()
            lbl_empty.set_margin_top(32)
            lbl_empty.set_margin_bottom(32)
            lbl_empty.set_markup("<span style='italic' alpha='70%'>No startup applications found in startup.conf</span>")
            row_empty.set_child(lbl_empty)
            self.list_box.append(row_empty)
            return

        for item in items:
            row = Adw.ActionRow()
            row.set_margin_bottom(6)
            
            # Icon
            img = Gtk.Image.new_from_icon_name("application-x-executable-symbolic")
            img.set_valign(Gtk.Align.CENTER)
            row.add_prefix(img)
            
            # Setup command as Title
            row.set_title(GLib.markup_escape_text(item["command"]))
            
            # Setup Description as Subtitle
            desc = item["comment"] if item["comment"] else "Startup Command"
            row.set_subtitle(GLib.markup_escape_text(f"{item['type']} • {desc}"))
            
            # Switch (enable/disable)
            sw = Gtk.Switch()
            sw.set_active(item["enabled"])
            sw.set_valign(Gtk.Align.CENTER)
            # Pass item["id"] to the handler
            sw.connect("state-set", self.on_item_toggled, item["id"])
            row.add_suffix(sw)
            
            # Delete Button
            del_btn = Gtk.Button.new_from_icon_name("user-trash-symbolic")
            del_btn.set_valign(Gtk.Align.CENTER)
            del_btn.set_margin_start(10)
            del_btn.get_style_context().add_class("destructive-action")
            # Connect delete handler
            del_btn.connect("clicked", self.on_item_deleted, item["id"])
            row.add_suffix(del_btn)
            
            self.list_box.append(row)

    def on_item_toggled(self, switch, state, item_id):
        self.parser.toggle_startup_item(item_id, state)
        # Reload after a brief delay so parser state updates are saved fully
        GLib.idle_add(self.load_startup_list)
        return False

    def on_item_deleted(self, button, item_id):
        self.parser.delete_startup_item(item_id)
        self.load_startup_list()

    def on_add_clicked(self, button):
        # Open a styled transient popup window
        popup = Gtk.Window()
        popup.set_title("Add Startup Application")
        popup.set_modal(True)
        
        # Set transient for top-level main window
        root = self.get_root()
        if isinstance(root, Gtk.Window):
            popup.set_transient_for(root)
            
        popup.set_default_size(460, -1)
        popup.set_resizable(False)
        
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        content.set_margin_start(20)
        content.set_margin_end(20)
        content.set_margin_top(20)
        content.set_margin_bottom(20)
        popup.set_child(content)
        
        # Form items
        lbl_title = Gtk.Label()
        lbl_title.set_halign(Gtk.Align.START)
        lbl_title.set_markup("<span size='large' weight='bold'>Create Startup Item</span>")
        content.append(lbl_title)
        
        # Type selection row
        type_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        lbl_type = Gtk.Label(label="Run Type:")
        lbl_type.set_size_request(100, -1)
        lbl_type.set_halign(Gtk.Align.START)
        type_box.append(lbl_type)
        
        type_combo = Gtk.ComboBoxText()
        type_combo.append("exec-once", "Execute Once (Default)")
        type_combo.append("exec", "Execute on Reload")
        type_combo.set_active(0)
        type_box.append(type_combo)
        content.append(type_box)
        
        # Command Row
        cmd_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        lbl_cmd = Gtk.Label(label="Executable/Cmd:")
        lbl_cmd.set_size_request(100, -1)
        lbl_cmd.set_halign(Gtk.Align.START)
        cmd_box.append(lbl_cmd)
        
        cmd_entry = Gtk.Entry()
        cmd_entry.set_hexpand(True)
        cmd_entry.set_placeholder_text("e.g. waybar, mako, cliphist")
        cmd_box.append(cmd_entry)
        content.append(cmd_box)
        
        # Comment Row
        comm_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        lbl_comm = Gtk.Label(label="Description:")
        lbl_comm.set_size_request(100, -1)
        lbl_comm.set_halign(Gtk.Align.START)
        comm_box.append(lbl_comm)
        
        comm_entry = Gtk.Entry()
        comm_entry.set_hexpand(True)
        comm_entry.set_placeholder_text("e.g. Status Bar daemon")
        comm_box.append(comm_entry)
        content.append(comm_box)
        
        # Button actions
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        btn_box.set_halign(Gtk.Align.END)
        
        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.connect("clicked", lambda b: popup.destroy())
        btn_box.append(cancel_btn)
        
        save_btn = Gtk.Button(label="Save App")
        save_btn.get_style_context().add_class("accent-btn")
        
        def save_and_close(b):
            cmd = cmd_entry.get_text().strip()
            comment = comm_entry.get_text().strip()
            exec_type = type_combo.get_active_id()
            if cmd:
                self.parser.add_startup_item(exec_type, cmd, comment)
                popup.destroy()
                self.load_startup_list()
                
        save_btn.connect("clicked", save_and_close)
        btn_box.append(save_btn)
        content.append(btn_box)
        
        popup.present()
