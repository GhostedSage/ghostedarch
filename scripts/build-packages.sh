#!/usr/bin/env bash
# GhostedArch Custom Pacman Repository Build Engine
# Builds Arch packages in a clean, sandboxed environment and updates the database.

set -eo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$WORKSPACE_DIR/packages"
REPO_DIR="$WORKSPACE_DIR/web/repo/x86_64"
WEB_DIR="$WORKSPACE_DIR/web"

mkdir -p "$REPO_DIR"
mkdir -p "$WEB_DIR"

echo " ==> Starting GhostedArch package compilation..."

# 1. Setup non-root environment if running as root (GHA Docker container)
if [ "$EUID" -eq 0 ]; then
  echo " ==> Running as root. Setting up low-privilege 'builder' user..."
  
  # Create builder user
  if ! id -u builder >/dev/null 2>&1; then
    useradd -m -g wheel -s /bin/bash builder
  fi
  
  # Configure sudoers for builder
  echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
  chmod 0440 /etc/sudoers.d/builder
  
  # Initialize pacman database and keyrings if in a bare docker container
  if [ ! -d /var/lib/pacman/local ]; then
    echo " ==> Initializing pacman keyring..."
    pacman-key --init
    pacman-key --populate archlinux || true
  fi
  
  # Sync package databases and install core base-devel tools if missing
  echo " ==> Updating system packages..."
  pacman -Sy --noconfirm --needed base-devel git sudo
  
  # Adjust permissions of workspace so builder can write to it
  chown -R builder:wheel "$WORKSPACE_DIR"
  
  # Execute the build loop as the low-privilege user
  echo " ==> Handing off execution to 'builder' user..."
  sudo -u builder -E env PATH="$PATH" "$0" "$@"
  
  # Restore root ownership of outputs for workflow completion
  chown -R root:root "$WORKSPACE_DIR"
  exit 0
fi

# 2. Build loop (runs as builder)
echo " ==> Building packages in $PACKAGES_DIR..."

for pkg_dir in "$PACKAGES_DIR"/*; do
  [ -d "$pkg_dir" ] || continue
  [ -f "$pkg_dir/PKGBUILD" ] || continue
  
  pkg_name=$(basename "$pkg_dir")
  echo " ==> Processing package: $pkg_name..."
  
  # Navigate to the package directory and build
  cd "$pkg_dir"
  
  # Install build dependencies, build and package (clean build, skip runtime dep checks)
  makepkg -sCfd --noconfirm --noprogressbar
  
  # Copy built packages to target repo folder
  echo " ==> Staging built package binaries..."
  find . -maxdepth 1 -name "*.pkg.tar.zst" -exec cp -v {} "$REPO_DIR/" \;
  
  # Clean up directory artifacts manually
  rm -rf src pkg
  cd "$WORKSPACE_DIR"
done

# 3. Compile Pacman Repository Database
echo " ==> Re-building pacman repository database..."
cd "$REPO_DIR"

# Clean old DB files to avoid duplication
rm -f ghostedarch.db ghostedarch.db.tar.gz ghostedarch.db.tar.zst
rm -f ghostedarch.files ghostedarch.files.tar.gz ghostedarch.files.tar.zst

# Add all packages to database
# --nosign is used since signing is handled separately or is optional
repo-add ghostedarch.db.tar.zst *.pkg.tar.zst

# pacman expects symlinks ghostedarch.db and ghostedarch.files
ln -sf ghostedarch.db.tar.zst ghostedarch.db
ln -sf ghostedarch.files.tar.zst ghostedarch.files

echo " ==> Pacman repository database compiles successfully."

# 4. Generate packages.json Metadata for Web Dashboard
echo " ==> Extracting package metadata for web dashboard..."
echo "[" > "$WEB_DIR/packages.json"
first=true

for pkg in *.pkg.tar.zst; do
  [ -f "$pkg" ] || continue
  
  if [ "$first" = true ]; then
    first=false
  else
    echo "," >> "$WEB_DIR/packages.json"
  fi
  
  # Extract .PKGINFO from built package tarball
  pkginfo=$(tar -xO -f "$pkg" .PKGINFO)
  
  pkgname=$(echo "$pkginfo" | grep -E '^pkgname =' | cut -d'=' -f2 | xargs)
  pkgver=$(echo "$pkginfo" | grep -E '^pkgver =' | cut -d'=' -f2 | xargs)
  pkgdesc=$(echo "$pkginfo" | grep -E '^pkgdesc =' | cut -d'=' -f2 | xargs)
  url=$(echo "$pkginfo" | grep -E '^url =' | cut -d'=' -f2 | xargs)
  size=$(echo "$pkginfo" | grep -E '^size =' | cut -d'=' -f2 | xargs)
  license=$(echo "$pkginfo" | grep -E '^license =' | cut -d'=' -f2 | xargs)
  
  # Extract dependencies and format as JSON array
  depends_raw=$(echo "$pkginfo" | grep -E '^depend =' | cut -d'=' -f2 | xargs || true)
  if [ -n "$depends_raw" ]; then
    # format as "dep1", "dep2"
    depends_json=$(echo "$depends_raw" | awk '{printf "\"%s\", ", $1}' | sed 's/, $//')
    depends="[$depends_json]"
  else
    depends="[]"
  fi
  
  # Compute human readable size
  size_kb=$((size / 1024))
  if [ $size_kb -ge 1024 ]; then
    size_mb=$(echo "scale=2; $size_kb / 1024" | bc 2>/dev/null || expr $size_kb / 1024)
    size_friendly="${size_mb} MB"
  else
    size_friendly="${size_kb} KB"
  fi
  
  cat <<EOF >> "$WEB_DIR/packages.json"
  {
    "name": "$pkgname",
    "version": "$pkgver",
    "description": "$pkgdesc",
    "url": "$url",
    "size": "$size_friendly",
    "license": "$license",
    "dependencies": $depends,
    "filename": "$(basename "$pkg")"
  }
EOF
done

echo "]" >> "$WEB_DIR/packages.json"
echo " ==> Package metadata JSON generated at $WEB_DIR/packages.json."
echo " ==> GhostedArch Build Engine finished successfully!"
