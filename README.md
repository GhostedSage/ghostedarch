# 👻 GhostedArch Linux Package Repository

Welcome to the official custom pacman package repository for **GhostedArch**, a customized, high-end, cyberpunk-themed Arch Linux distribution. 

This repository contains custom system configurations, themes, brand assets, and custom helper utilities. It is automatically built via GitHub Actions and hosted globally on GitHub Pages!

🔗 **Live Dashboard & Packages Webpage**: [https://ghostedsage.github.io/ghostedarch/](https://ghostedsage.github.io/ghostedarch/)

---

## 🚀 How to Add This Repository to Your Arch Linux System

Adding **GhostedArch** packages to any standard Arch Linux installation takes only a few quick commands:

### 1. Edit pacman.conf
Open `/etc/pacman.conf` in your favorite terminal text editor (with `sudo` privileges) and append the repository configuration to the end of the file:

```ini
[ghostedarch]
SigLevel = Optional TrustAll
Server = https://ghostedsage.github.io/ghostedarch/repo/x86_64
```

### 2. Update Database & Install Keyring
Run pacman to refresh your system databases and install the official GhostedArch cryptographic keyring package:

```bash
sudo pacman -Sy
sudo pacman -S ghostedarch-keyring
```

### 3. (Optional) Restrict Signature Requirements
Once the keyring is installed, you can change your signature trust levels to require verified signatures:

Under the `[ghostedarch]` section in `/etc/pacman.conf`, update `SigLevel`:
```ini
[ghostedarch]
SigLevel = Required DatabaseOptional
```

---

## 📦 Available Packages

| Package Name | Description | Key Assets Included |
| :--- | :--- | :--- |
| `ghostedarch-keyring` | The official distro GPG keyring | Trusted GPG developers keys |
| `ghostedarch-mirrorlist` | Config file defining repo download nodes | `/etc/pacman.d/ghostedarch-mirrorlist` |
| `ghostedarch-neofetch` | Sleek customized terminal hardware display wrapper | GhostedArch Glowing ASCII Logo |
| `ghostedarch-artwork` | Official distro wallpapers and visual icons | 8K AI Generated Cyberpunk Wallpaper |

---

## 🛠️ Repository Development & Build System

This repository utilizes an **automated clean-room Arch compilation container** to build packages and rebuild the pacman index database dynamically.

### Adding or Modifying a Package

1. **Create the Package Folder**: Create a new folder under `/packages/` named after your package (e.g. `packages/my-custom-package`).
2. **Add PKGBUILD**: Place your `PKGBUILD` and any local source files (like `.install` scripts or config files) inside that folder.
3. **Commit and Push**: Push your changes to the `main` branch.
   ```bash
   git add packages/my-custom-package
   git commit -m "feat: add my-custom-package"
   git push origin main
   ```
4. **CI/CD Automation**: GitHub Actions will automatically launch a clean `archlinux:latest` Docker environment, invoke `./scripts/build-packages.sh` to compile your PKGBUILD, regenerate the pacman database, and publish everything back to the `gh-pages` branch.

### Local Mock Building / Assembly

If you are on an Arch Linux machine and wish to build/assemble the repository locally:

```bash
# Execute the build engine
./scripts/build-packages.sh
```

---

## 🎨 Creative Commons & Licenses

- Custom packages PKGBUILDs and code wrappers are licensed under the **MIT License**.
- Wallpapers, artwork, and visual styling are licensed under **Creative Commons BY-NC-SA 4.0**.
