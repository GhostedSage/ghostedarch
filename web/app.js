/* ==========================================================================
   GHOSTEDARCH CUSTOM PACMAN REPOSITORY JAVASCRIPT
   Responsive interaction, clipboard tools, and package DB parser
   ========================================================================== */

// Fallback Package DB - displayed if packages.json hasn't been built by GHA yet
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

// Initialize Dashboard
document.addEventListener("DOMContentLoaded", () => {
  loadPackages();
});

// Switch Setup Guide Tabs
function switchSetupTab(event, tabId) {
  // Hide all tabs
  const tabContents = document.querySelectorAll(".tab-content");
  tabContents.forEach(tab => tab.classList.remove("active"));
  
  const tabButtons = document.querySelectorAll(".tab-btn");
  tabButtons.forEach(btn => btn.classList.remove("active"));
  
  // Show active tab
  document.getElementById(tabId).classList.add("active");
  event.currentTarget.classList.add("active");
}

// Copy Code to Clipboard
function copyText(codeId, iconId) {
  const codeText = document.getElementById(codeId).innerText;
  
  navigator.clipboard.writeText(codeText).then(() => {
    const copyIcon = document.getElementById(iconId);
    const originalClass = copyIcon.className;
    
    // Success feedback
    copyIcon.className = "fa-solid fa-check";
    copyIcon.parentElement.innerHTML = `<i class="fa-solid fa-check" id="${iconId}"></i> Copied!`;
    
    setTimeout(() => {
      const button = document.getElementById(iconId).parentElement;
      button.innerHTML = `<i class="${originalClass}" id="${iconId}"></i> ${originalClass.includes('copy') ? 'Copy Code' : 'Copy pacman -S'}`;
    }, 2000);
  }).catch(err => {
    console.error("Failed to copy code to clipboard: ", err);
  });
}

// Load Packages from Compiled JSON
async function loadPackages() {
  const container = document.getElementById("packages-container");
  const pkgCountEl = document.getElementById("stat-pkg-count");
  
  try {
    const response = await fetch("packages.json");
    if (!response.ok) throw new Error("Database not initialized yet.");
    packages = await response.json();
  } catch (error) {
    console.log("Loading fallback package database due to offline/uncompiled state.");
    packages = fallbackPackages;
  }
  
  // Update Package count statistics
  if (pkgCountEl) {
    pkgCountEl.innerText = packages.length;
  }
  
  renderPackages(packages);
}

// Render Packages Cards Grid
function renderPackages(items) {
  const container = document.getElementById("packages-container");
  
  if (!container) return;
  container.innerHTML = "";
  
  if (items.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <i class="fa-solid fa-box-open"></i>
        <h3>No Packages Found</h3>
        <p>No matches matching your search criteria. Try another search query.</p>
      </div>
    `;
    return;
  }
  
  items.forEach(pkg => {
    const card = document.createElement("article");
    card.className = "package-card animate-fade-in";
    
    // Dependencies tag list
    const depsText = pkg.dependencies.length > 0 ? pkg.dependencies.join(", ") : "None";
    
    // Make unique button and copy targets for testing/usability
    const copyId = `copy-install-${pkg.name}`;
    const textId = `install-code-${pkg.name}`;
    
    card.innerHTML = `
      <div class="package-meta-top">
        <h3 class="package-title">${pkg.name}</h3>
        <span class="package-version">${pkg.version}</span>
      </div>
      <p class="package-desc">${pkg.description}</p>
      <div class="package-specs">
        <div class="spec-item">
          <i class="fa-solid fa-weight-hanging"></i>
          <span>${pkg.size}</span>
        </div>
        <div class="spec-item">
          <i class="fa-solid fa-scale-balanced"></i>
          <span>${pkg.license}</span>
        </div>
        <div class="spec-item">
          <i class="fa-solid fa-code-fork"></i>
          <span>Deps: ${depsText}</span>
        </div>
      </div>
      <div class="package-action">
        <span id="${textId}" style="display:none;">sudo pacman -S ${pkg.name}</span>
        <button class="install-btn" onclick="copyText('${textId}', '${copyId}')">
          <i class="fa-regular fa-copy" id="${copyId}"></i> pacman -S ${pkg.name}
        </button>
      </div>
    `;
    
    container.appendChild(card);
  });
}

// Fuzzy Search Filtering
function filterPackages() {
  const query = document.getElementById("search-input").value.toLowerCase().trim();
  
  if (!query) {
    renderPackages(packages);
    return;
  }
  
  const filtered = packages.filter(pkg => {
    return pkg.name.toLowerCase().includes(query) || 
           pkg.description.toLowerCase().includes(query) ||
           pkg.license.toLowerCase().includes(query);
  });
  
  renderPackages(filtered);
}
