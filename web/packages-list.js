/* ==========================================================================
   PACKAGES DATABASE DIRECTORY VIEW JAVASCRIPT
   Dynamic JSON parsing, tabular layout, and custom UI controller
   ========================================================================== */

const fallbackPackages = [
  {
    name: "ghostedarch-keyring",
    version: "2026.06.01-1",
    description: "Official cryptographic signing keyring for package verification.",
    url: "https://github.com/GhostedSage/ghostedarch",
    size: "14.2 KB",
    license: "GPL",
    dependencies: [],
    filename: "ghostedarch-keyring-2026.06.01-1-any.pkg.tar.zst"
  },
  {
    name: "ghostedarch-mirrorlist",
    version: "2026.06.01-1",
    description: "Official Mirrorlist configuration directing Pacman to GitHub Pages CDN server nodes.",
    url: "https://github.com/GhostedSage/ghostedarch",
    size: "4.8 KB",
    license: "GPL",
    dependencies: [],
    filename: "ghostedarch-mirrorlist-2026.06.01-1-any.pkg.tar.zst"
  },
  {
    name: "ghostedarch-neofetch",
    version: "1.0.0-1",
    description: "Custom terminal system statistics wrapper presenting the official GhostedArch ASCII helmet logo.",
    url: "https://github.com/GhostedSage/ghostedarch",
    size: "24.5 KB",
    license: "MIT",
    dependencies: ["neofetch"],
    filename: "ghostedarch-neofetch-1.0.0-1-any.pkg.tar.zst"
  },
  {
    name: "ghostedarch-wallpaper",
    version: "1.0.0-1",
    description: "High-resolution custom space-cyberpunk desktop wallpapers and branding visual assets.",
    url: "https://github.com/GhostedSage/ghostedarch",
    size: "807 KB",
    license: "custom",
    dependencies: [],
    filename: "ghostedarch-wallpaper-1.0.0-1-any.pkg.tar.zst"
  }
];

let packages = [];

document.addEventListener("DOMContentLoaded", () => {
  setupInteractiveCore();
  loadTablePackages();
});

// Setup custom cursor & magnetic links (cloned from home for seamless transition)
function setupInteractiveCore() {
  const cursorDot = document.querySelector(".cursor-dot");
  const cursorOutline = document.querySelector(".cursor-outline");

  if (cursorDot && cursorOutline) {
    window.addEventListener("mousemove", (e) => {
      const posX = e.clientX;
      const posY = e.clientY;

      cursorDot.style.left = `${posX}px`;
      cursorDot.style.top = `${posY}px`;

      cursorOutline.animate({
        left: `${posX}px`,
        top: `${posY}px`
      }, { duration: 500, fill: "forwards" });
    });
  }

  // Magnetic Nav items
  const magnetics = document.querySelectorAll(".magnetic");
  magnetics.forEach((btn) => {
    btn.addEventListener("mousemove", (e) => {
      const rect = btn.getBoundingClientRect();
      const strength = btn.dataset.strength || 20;
      const h = rect.width / 2;
      const v = rect.height / 2;
      const x = e.clientX - rect.left - h;
      const y = e.clientY - rect.top - v;
      
      gsap.to(btn, {
        x: (x / h) * strength,
        y: (y / v) * strength,
        duration: 0.5,
        ease: "power2.out"
      });
      
      if (cursorOutline) {
        cursorOutline.style.width = "60px";
        cursorOutline.style.height = "60px";
        cursorOutline.style.backgroundColor = "rgba(79, 209, 197, 0.2)";
      }
    });

    btn.addEventListener("mouseleave", () => {
      gsap.to(btn, {
        x: 0,
        y: 0,
        duration: 0.5,
        ease: "elastic.out(1, 0.3)"
      });
      
      if (cursorOutline) {
        cursorOutline.style.width = "40px";
        cursorOutline.style.height = "40px";
        cursorOutline.style.backgroundColor = "transparent";
      }
    });
  });
}

// Fetch database records
async function loadTablePackages() {
  try {
    const response = await fetch("packages.json");
    if (!response.ok) throw new Error("JSON missing");
    packages = await response.json();
  } catch (error) {
    packages = fallbackPackages;
  }
  
  renderTable(packages);
}

// Render dynamic rows in table
function renderTable(items) {
  const tbody = document.getElementById("packages-table-body");
  if (!tbody) return;
  
  tbody.innerHTML = "";
  
  if (items.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="5" style="text-align: center; color: var(--text-muted); padding: 40px;">
          <i class="fa-solid fa-ban" style="font-size: 1.5rem; margin-bottom: 10px; display: block; color: var(--accent-primary);"></i>
          No packages found matching search criteria.
        </td>
      </tr>
    `;
    return;
  }
  
  items.forEach(pkg => {
    const row = document.createElement("tr");
    row.className = "package-row";
    
    row.innerHTML = `
      <td class="pkg-name-cell">${pkg.name}</td>
      <td class="pkg-version-cell">${pkg.version}</td>
      <td class="pkg-desc-cell">${pkg.description}</td>
      <td class="pkg-category-cell">${pkg.license}</td>
      <td class="pkg-action-cell">
        <button class="table-install-btn" onclick="copyPacmanS('${pkg.name}', this)" title="Copy pacman installation command">
          <i class="fa-regular fa-copy"></i>
        </button>
      </td>
    `;
    tbody.appendChild(row);
  });
  
  // Stagger reveal rows using GSAP
  gsap.from(".package-row", {
    opacity: 0,
    x: -30,
    duration: 0.6,
    stagger: 0.05,
    ease: "power3.out",
    overwrite: "auto"
  });
}

// Search Filter
function filterTable() {
  const query = document.getElementById("search-input").value.toLowerCase().trim();
  
  if (!query) {
    renderTable(packages);
    return;
  }
  
  const filtered = packages.filter(pkg => {
    return pkg.name.toLowerCase().includes(query) || 
           pkg.description.toLowerCase().includes(query) ||
           pkg.license.toLowerCase().includes(query);
  });
  
  renderTable(filtered);
}

// Copy pacman -S command and trigger visual hover checks
function copyPacmanS(pkgName, button) {
  const cmd = `sudo pacman -S ${pkgName}`;
  
  navigator.clipboard.writeText(cmd).then(() => {
    const icon = button.querySelector("i");
    icon.className = "fa-solid fa-check";
    button.style.color = "var(--accent-primary)";
    
    setTimeout(() => {
      icon.className = "fa-regular fa-copy";
      button.style.color = "";
    }, 1500);
  }).catch(err => {
    console.error("Clipboard copy failed: ", err);
  });
}
