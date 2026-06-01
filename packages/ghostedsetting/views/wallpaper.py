import os
import re
import json
import shutil
import subprocess
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gdk, GLib, Adw, GdkPixbuf, Pango

# Metadata file name stored inside the wallpaper directory
UPLOADS_META = ".user_uploads.json"


class WallpaperView(Gtk.Box):
    def __init__(self, parser):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        self.parser = parser
        self.set_margin_start(24)
        self.set_margin_end(24)
        self.set_margin_top(24)
        self.set_margin_bottom(24)

        self.active_filename = None
        self.selected_filepath = None
        self.wallpapers_dir = os.path.join(self.parser.config_dir, "wallpaper")

        # ── Header ──────────────────────────────────────────────────────────
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        title_lbl = Gtk.Label()
        title_lbl.set_halign(Gtk.Align.START)
        title_lbl.set_markup("<span size='x-large' weight='bold'>Desktop Wallpapers</span>")
        title_box.append(title_lbl)

        desc_lbl = Gtk.Label()
        desc_lbl.set_halign(Gtk.Align.START)
        desc_lbl.set_markup("<span size='small' alpha='70%'>Choose a background. Changes apply instantly using swaybg.</span>")
        title_box.append(desc_lbl)

        header_box.append(title_box)

        # Push upload button to the right
        spacer_hdr = Gtk.Box()
        spacer_hdr.set_hexpand(True)
        header_box.append(spacer_hdr)

        upload_btn = Gtk.Button()
        upload_btn.get_style_context().add_class("suggested-action")
        upload_inner = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        upload_icon = Gtk.Image.new_from_icon_name("go-up-symbolic")
        upload_icon.set_pixel_size(16)
        upload_inner.append(upload_icon)
        upload_inner.append(Gtk.Label(label="Upload Wallpaper"))
        upload_btn.set_child(upload_inner)
        upload_btn.connect("clicked", self.on_upload_clicked)
        header_box.append(upload_btn)

        self.append(header_box)

        # ── Scrolled grid ────────────────────────────────────────────────────
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.append(scrolled)

        self.flowbox = Gtk.FlowBox()
        self.flowbox.set_valign(Gtk.Align.START)
        self.flowbox.set_max_children_per_line(4)
        self.flowbox.set_min_children_per_line(2)
        self.flowbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.flowbox.set_column_spacing(16)
        self.flowbox.set_row_spacing(16)
        self.flowbox.connect("child-activated", self.on_wallpaper_selected)
        scrolled.set_child(self.flowbox)

        # ── Action bar ───────────────────────────────────────────────────────
        action_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        action_bar.set_margin_top(8)

        self.selected_label = Gtk.Label()
        self.selected_label.set_halign(Gtk.Align.START)
        self.selected_label.set_markup("<span style='italic' alpha='70%'>Select a wallpaper from the grid above</span>")
        action_bar.append(self.selected_label)

        spacer = Gtk.Box()
        spacer.set_hexpand(True)
        action_bar.append(spacer)

        self.apply_btn = Gtk.Button()
        self.apply_btn.get_style_context().add_class("accent-btn")
        apply_lbl = Gtk.Label()
        apply_lbl.set_markup("<span weight='bold'>Apply Wallpaper</span>")
        self.apply_btn.set_child(apply_lbl)
        self.apply_btn.set_sensitive(False)
        self.apply_btn.connect("clicked", self.on_apply_clicked)
        action_bar.append(self.apply_btn)

        self.append(action_bar)

        self.load_wallpapers()

    # ── Metadata helpers ─────────────────────────────────────────────────────

    def _meta_path(self):
        return os.path.join(self.wallpapers_dir, UPLOADS_META)

    def _load_uploads_meta(self):
        """Return set of filenames the user has uploaded."""
        try:
            with open(self._meta_path(), "r") as f:
                return set(json.load(f))
        except Exception:
            return set()

    def _save_uploads_meta(self, uploads: set):
        os.makedirs(self.wallpapers_dir, exist_ok=True)
        with open(self._meta_path(), "w") as f:
            json.dump(sorted(uploads), f, indent=2)

    def _track_upload(self, filename: str):
        uploads = self._load_uploads_meta()
        uploads.add(filename)
        self._save_uploads_meta(uploads)

    def _untrack_upload(self, filename: str):
        uploads = self._load_uploads_meta()
        uploads.discard(filename)
        self._save_uploads_meta(uploads)

    # ── Active wallpaper detection ────────────────────────────────────────────

    def get_active_wallpaper(self):
        startup_items = self.parser.read_startup_items()
        for item in startup_items:
            if "swaybg" in item["command"]:
                match = re.search(r'-i\s+([^\s]+)', item["command"])
                if match:
                    raw_path = match.group(1)
                    resolved_path = os.path.expanduser(raw_path)
                    return os.path.basename(resolved_path)
        return None

    # ── Grid ─────────────────────────────────────────────────────────────────

    def load_wallpapers(self):
        # Clear existing children
        while (child := self.flowbox.get_first_child()):
            self.flowbox.remove(child)

        self.active_filename = self.get_active_wallpaper()
        user_uploads = self._load_uploads_meta()

        if not os.path.exists(self.wallpapers_dir):
            lbl_none = Gtk.Label()
            lbl_none.set_margin_top(48)
            lbl_none.set_markup("<span style='italic' alpha='70%'>Wallpaper directory not found. Upload a wallpaper to create it.</span>")
            self.flowbox.append(lbl_none)
            return

        valid_extensions = (".png", ".jpg", ".jpeg", ".webp")
        files = [
            f for f in os.listdir(self.wallpapers_dir)
            if f.lower().endswith(valid_extensions)
        ]
        files.sort()

        if not files:
            lbl_none = Gtk.Label()
            lbl_none.set_margin_top(48)
            lbl_none.set_markup("<span style='italic' alpha='70%'>No wallpapers found. Upload one using the button above.</span>")
            self.flowbox.append(lbl_none)
            return

        for filename in files:
            filepath = os.path.join(self.wallpapers_dir, filename)
            is_active = (filename == self.active_filename)
            is_user_upload = (filename in user_uploads)
            display_name = os.path.splitext(filename)[0]  # strip extension

            # Outer overlay so we can float the delete button over the card
            overlay = Gtk.Overlay()

            # Card
            card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
            card.get_style_context().add_class("wallpaper-card")
            if is_active:
                card.get_style_context().add_class("wallpaper-card-active")

            # Thumbnail
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(filepath, 220, 124, True)
                texture = Gdk.Texture.new_for_pixbuf(pixbuf)
                img = Gtk.Picture.new_for_paintable(texture)
                img.set_size_request(220, 124)
                img.set_content_fit(Gtk.ContentFit.COVER)
                card.append(img)
            except Exception:
                img = Gtk.Image.new_from_icon_name("image-missing")
                img.set_pixel_size(48)
                img.set_size_request(220, 124)
                card.append(img)

            # Name label (no extension)
            lbl = Gtk.Label()
            lbl.set_max_width_chars(18)
            lbl.set_ellipsize(Pango.EllipsizeMode.END)
            lbl.set_halign(Gtk.Align.CENTER)
            escaped = GLib.markup_escape_text(display_name)
            if is_active:
                lbl.set_markup(f"<span weight='bold' color='#c6a0f6'>{escaped} ✦</span>")
            else:
                lbl.set_markup(f"<span alpha='70%'>{escaped}</span>")
            card.append(lbl)

            # Store metadata on card
            card.filepath = filepath
            card.filename = filename

            overlay.set_child(card)

            # Delete button — only for user-uploaded wallpapers
            if is_user_upload:
                del_btn = Gtk.Button()
                del_btn.get_style_context().add_class("destructive-action")
                del_btn.set_tooltip_text(f'Delete \"{display_name}\"')
                del_btn.set_halign(Gtk.Align.END)
                del_btn.set_valign(Gtk.Align.START)
                del_btn.set_margin_top(6)
                del_btn.set_margin_end(6)
                del_icon = Gtk.Image.new_from_icon_name("edit-delete-symbolic")
                del_icon.set_pixel_size(14)
                del_btn.set_child(del_icon)
                # Capture filename in closure
                del_btn.connect("clicked", self._on_delete_clicked, filename, filepath)
                overlay.add_overlay(del_btn)

            self.flowbox.append(overlay)

    # ── Upload ────────────────────────────────────────────────────────────────

    def on_upload_clicked(self, button):
        dialog = Gtk.FileChooserNative(
            title="Choose a Wallpaper to Upload",
            transient_for=self.get_root(),
            action=Gtk.FileChooserAction.OPEN,
            accept_label="Upload",
            cancel_label="Cancel",
        )
        filter_img = Gtk.FileFilter()
        filter_img.set_name("Image files")
        filter_img.add_mime_type("image/png")
        filter_img.add_mime_type("image/jpeg")
        filter_img.add_mime_type("image/webp")
        filter_img.add_pattern("*.png")
        filter_img.add_pattern("*.jpg")
        filter_img.add_pattern("*.jpeg")
        filter_img.add_pattern("*.webp")
        dialog.add_filter(filter_img)
        dialog.connect("response", self._on_upload_response)
        dialog.show()

    def _on_upload_response(self, dialog, response):
        if response != Gtk.ResponseType.ACCEPT:
            return

        file = dialog.get_file()
        if not file:
            return

        src_path = file.get_path()
        filename = os.path.basename(src_path)

        # Create wallpaper dir if it doesn't exist yet
        os.makedirs(self.wallpapers_dir, exist_ok=True)

        dst_path = os.path.join(self.wallpapers_dir, filename)

        try:
            shutil.copy2(src_path, dst_path)
            self._track_upload(filename)
            self.load_wallpapers()
            self.selected_label.set_markup(
                f"<span color='#a6da95' weight='bold'>Uploaded: {GLib.markup_escape_text(os.path.splitext(filename)[0])}</span>"
            )
        except Exception as e:
            self.selected_label.set_markup(
                f"<span color='#ed8796'>Upload failed: {GLib.markup_escape_text(str(e))}</span>"
            )

    # ── Delete ────────────────────────────────────────────────────────────────

    def _on_delete_clicked(self, button, filename, filepath):
        display_name = os.path.splitext(filename)[0]

        dialog = Adw.MessageDialog(
            transient_for=self.get_root(),
            heading="Delete Wallpaper?",
            body=f'"{display_name}" will be permanently removed from your wallpaper library.',
        )
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("delete", "Delete")
        dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE)
        dialog.set_default_response("cancel")
        dialog.set_close_response("cancel")
        dialog.connect("response", self._on_delete_response, filename, filepath)
        dialog.present()

    def _on_delete_response(self, dialog, response, filename, filepath):
        if response != "delete":
            return

        display_name = os.path.splitext(filename)[0]

        # If this is the active wallpaper, warn but still allow
        try:
            os.remove(filepath)
            self._untrack_upload(filename)
            self.load_wallpapers()
            self.selected_filepath = None
            self.apply_btn.set_sensitive(False)
            self.selected_label.set_markup(
                f"<span color='#a6da95' weight='bold'>Deleted: {GLib.markup_escape_text(display_name)}</span>"
            )
        except Exception as e:
            self.selected_label.set_markup(
                f"<span color='#ed8796'>Delete failed: {GLib.markup_escape_text(str(e))}</span>"
            )

    # ── Selection / Apply ─────────────────────────────────────────────────────

    def on_wallpaper_selected(self, flowbox, child):
        # child is a FlowBoxChild wrapping our Overlay
        overlay = child.get_child()
        if not overlay:
            return
        card = overlay.get_child()
        if card and hasattr(card, "filepath"):
            self.selected_filepath = card.filepath
            display_name = GLib.markup_escape_text(os.path.splitext(card.filename)[0])
            self.selected_label.set_markup(
                f"Selected: <span weight='semibold'>{display_name}</span>"
            )
            self.apply_btn.set_sensitive(True)

    def on_apply_clicked(self, button):
        if not self.selected_filepath:
            return

        filename = os.path.basename(self.selected_filepath)
        portable_path = f"~/.config/hypr/wallpaper/{filename}"

        # Update hypr startup config
        startup_items = self.parser.read_startup_items()
        swaybg_updated = False

        for item in startup_items:
            if "swaybg" in item["command"]:
                new_cmd = f"swaybg -m fill -i {portable_path}"
                self.parser.delete_startup_item(item["id"])
                self.parser.add_startup_item(item["type"], new_cmd, "Desktop Wallpaper background daemon")
                swaybg_updated = True
                break

        if not swaybg_updated:
            new_cmd = f"swaybg -m fill -i {portable_path}"
            self.parser.add_startup_item("exec", new_cmd, "Desktop Wallpaper background daemon")

        # Apply instantly via swaybg
        try:
            subprocess.run(["killall", "swaybg"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.Popen(
                ["swaybg", "-m", "fill", "-i", self.selected_filepath],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception as e:
            print(f"[WallpaperView] swaybg launch failed: {e}")

        self.load_wallpapers()
        self.apply_btn.set_sensitive(False)
        self.selected_label.set_markup("<span color='#a6da95' weight='bold'>Wallpaper applied successfully!</span>")
