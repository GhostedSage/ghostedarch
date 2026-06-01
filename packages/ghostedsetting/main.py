import os
import sys
import argparse
import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gdk, GLib, Adw

from hypr_parser import HyprConfigParser
from views.dashboard import DashboardView
from views.appearance import AppearanceView
from views.startup import StartupView
from views.wallpaper import WallpaperView
from views.keybindings import KeybindingsView

class HyprlandControlCenterApp(Adw.Application):
    def __init__(self, workspace_path=None):
        super().__init__(
            application_id="org.hyprland.control.center"
        )
        self.workspace_path = workspace_path
        self.parser = None
        self.window = None

    def do_activate(self):
        # 1. Initialize configuration parser
        self.parser = HyprConfigParser(config_dir=self.workspace_path)
        
        # 2. Force Global Dark Theme in Libadwaita for modern aesthetics
        style_manager = Adw.StyleManager.get_default()
        style_manager.set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        
        # 3. Create top-level Application Window
        self.window = Adw.ApplicationWindow(application=self)
        self.window.set_title("Ghosted Arch Setting")
        self.window.set_default_size(1020, 680)
        
        # Add custom CSS Provider
        css_provider = Gtk.CssProvider()
        css_provider.load_from_path(os.path.join(os.path.dirname(__file__), "style.css"))
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        
        # 4. Construct Layout Grid (Sidebar on Left, Content Box on Right)
        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.window.set_content(main_box)
        
        # SIDEBAR (LEFT)
        sidebar_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        sidebar_box.get_style_context().add_class("navigation-sidebar")
        sidebar_box.set_size_request(240, -1)
        main_box.append(sidebar_box)
        
        # Sidebar Logo / Header Text
        logo_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        logo_box.set_margin_start(20)
        logo_box.set_margin_end(20)
        logo_box.set_margin_top(24)
        logo_box.set_margin_bottom(16)
        
        logo_lbl = Gtk.Label()
        logo_lbl.set_halign(Gtk.Align.START)
        logo_lbl.set_markup("<span size='large' weight='black' color='#c6a0f6'>GHOSTED ARCH</span>")
        logo_box.append(logo_lbl)
        
        logo_sub = Gtk.Label()
        logo_sub.set_halign(Gtk.Align.START)
        logo_sub.set_markup("<span size='x-small' weight='semibold' alpha='70%'>SETTING v1.0</span>")
        logo_box.append(logo_sub)
        sidebar_box.append(logo_box)
        
        # Navigation Row Options List
        self.sidebar_list = Gtk.ListBox()
        self.sidebar_list.get_style_context().add_class("navigation-sidebar")
        self.sidebar_list.set_selection_mode(Gtk.SelectionMode.SINGLE)
        sidebar_box.append(self.sidebar_list)
        
        # CONTENT AREA (RIGHT)
        content_wrapper = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        content_wrapper.set_hexpand(True)
        main_box.append(content_wrapper)
        
        # Dynamic Header Bar
        header = Adw.HeaderBar()
        content_wrapper.append(header)
        
        # View Stack for Pages
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(280)
        self.stack.set_vexpand(True)
        content_wrapper.append(self.stack)
        
        # 5. Populate and Wire Views
        self.views = {
            "dashboard":   ("Dashboard",     DashboardView(self.parser),   "view-grid-symbolic"),
            "appearance":  ("Appearance",    AppearanceView(self.parser),  "display-brightness-symbolic"),
            "wallpaper":   ("Wallpaper",     WallpaperView(self.parser),   "folder-pictures-symbolic"),
            "startup":     ("Startup Items", StartupView(self.parser),     "media-playback-start-symbolic"),
            "keybindings": ("Keybindings",   KeybindingsView(self.parser), "edit-paste-symbolic"),
        }
        
        # Add views to stack & construct sidebar rows
        for key, (label_text, view_widget, icon_name) in self.views.items():
            # Add to stack
            self.stack.add_named(view_widget, key)
            
            # Create Sidebar Row widget
            row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            row_box.set_name(key) # Use name attribute for stack switching lookup
            
            row_icon = Gtk.Image.new_from_icon_name(icon_name)
            row_icon.set_pixel_size(18)
            row_box.append(row_icon)
            
            row_lbl = Gtk.Label(label=label_text)
            row_box.append(row_lbl)
            
            row = Gtk.ListBoxRow()
            row.set_child(row_box)
            self.sidebar_list.append(row)
            
        # Connect sidebar selection to stack view switcher
        self.sidebar_list.connect("row-selected", self.on_sidebar_row_selected)
        
        # Select first row (Dashboard) by default
        self.sidebar_list.select_row(self.sidebar_list.get_row_at_index(0))
        
        # Present the window
        self.window.present()

    def on_sidebar_row_selected(self, listbox, row):
        if row:
            box = row.get_child()
            if box:
                key = box.get_name()
                self.stack.set_visible_child_name(key)
                
                # Special refresh logic when switching pages
                if key == "dashboard":
                    # Refresh active wallpaper preview dynamically
                    self.stack.get_child_by_name("dashboard").load_wallpaper_preview()
                elif key == "wallpaper":
                    # Refresh wallpaper grids
                    self.stack.get_child_by_name("wallpaper").load_wallpapers()
                elif key == "startup":
                    # Refresh startup list
                    self.stack.get_child_by_name("startup").load_startup_list()
                elif key == "keybindings":
                    # Refresh keybindings list
                    self.stack.get_child_by_name("keybindings").load_keybindings_list()

def main():
    # Parse CLI Arguments
    parser = argparse.ArgumentParser(description="Ghosted Arch Setting")
    parser.add_argument("-w", "--workspace", help="Use a custom path to a hypr configuration folder for testing (e.g. ./hypr)")
    
    # Extract only our custom args, ignore GApplication options
    args, unknown = parser.parse_known_args()
    
    workspace = None
    if args.workspace:
        workspace = os.path.abspath(args.workspace)
        print(f"[Main] Running in testing/workspace mode using config dir: {workspace}")
    
    app = HyprlandControlCenterApp(workspace_path=workspace)
    # Forward remaining system arguments to standard do_activate / do_startup
    sys.exit(app.run([sys.argv[0]] + unknown))

if __name__ == "__main__":
    main()
