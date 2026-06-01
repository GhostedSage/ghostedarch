#!/usr/bin/env bash
set -e

APP_NAME="Ghosted Arch Setting"
APP_EXEC="ghosted-arch"
INSTALL_DIR="$HOME/.local/share/ghosted-arch-control"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

echo "Installing $APP_NAME..."

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"

# Copy source files
echo "Copying source files to $INSTALL_DIR..."
cp main.py style.css sys_info.py hypr_parser.py setting.png "$INSTALL_DIR/"
cp -r views "$INSTALL_DIR/"

# Create executable launcher
echo "Creating executable launcher at $BIN_DIR/$APP_EXEC..."
cat > "$BIN_DIR/$APP_EXEC" << EOF
#!/usr/bin/env bash
cd "$INSTALL_DIR"
exec python3 main.py "\$@"
EOF
chmod +x "$BIN_DIR/$APP_EXEC"

# Create .desktop file
echo "Creating desktop entry..."
cat > "$DESKTOP_DIR/$APP_EXEC.desktop" << EOF
[Desktop Entry]
Name=Ghosted Arch Setting
Comment=Control Panel for Ghosted Arch Hyprland setup
Exec=$BIN_DIR/$APP_EXEC
Icon=$INSTALL_DIR/setting.png
Terminal=false
Type=Application
Categories=Settings;System;
EOF

# Update desktop database if available
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" || true
fi

echo "Installation complete!"
echo "You can now launch it by typing '$APP_EXEC' in your terminal or application launcher (e.g. rofi/wofi)."
