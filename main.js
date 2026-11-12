document.addEventListener("DOMContentLoaded", () => {
    gsap.registerPlugin(ScrollTrigger);

    // --- 1. Custom Cursor ---
    const cursorDot = document.querySelector(".cursor-dot");
    const cursorOutline = document.querySelector(".cursor-outline");

    window.addEventListener("mousemove", (e) => {
        const posX = e.clientX;
        const posY = e.clientY;

        cursorDot.style.left = `${posX}px`;
        cursorDot.style.top = `${posY}px`;

        // Lerp for outline
        cursorOutline.animate({
            left: `${posX}px`,
            top: `${posY}px`
        }, { duration: 500, fill: "forwards" });
    });

    // --- 2. Magnetic Elements ---
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
            
            // Hover effect on cursor
            cursorOutline.style.width = "60px";
            cursorOutline.style.height = "60px";
            cursorOutline.style.backgroundColor = "rgba(79, 209, 197, 0.2)";
        });

        btn.addEventListener("mouseleave", () => {
            gsap.to(btn, {
                x: 0,
                y: 0,
                duration: 0.5,
                ease: "elastic.out(1, 0.3)"
            });
            
            cursorOutline.style.width = "40px";
            cursorOutline.style.height = "40px";
            cursorOutline.style.backgroundColor = "transparent";
        });
    });

    // --- 3. Text Splitting for Hero ---
    const heroTitle = document.querySelector(".hero-title");
    const text = heroTitle.textContent;
    heroTitle.innerHTML = "";
    text.split("").forEach(char => {
        if(char === " ") {
            heroTitle.innerHTML += `<span class="space" style="width: 0.3em; display: inline-block;">&nbsp;</span>`;
        } else {
            heroTitle.innerHTML += `<span class="char">${char}</span>`;
        }
    });

    // --- 4. Preloader Timeline ---
    const preloaderTL = gsap.timeline();
    
    preloaderTL.to(".preloader-logo-wrapper", {
        opacity: 1,
        y: 0,
        duration: 1,
        ease: "power3.out"
    })
    .to(".loading-bar", {
        opacity: 1,
        duration: 0.5
    })
    .to(".loading-progress", {
        width: "100%",
        duration: 1.5,
        ease: "power2.inOut"
    })
    .to(".preloader", {
        yPercent: -100,
        duration: 1,
        ease: "power4.inOut",
        delay: 0.2
    })
    // Start Hero Animations after preloader
    .to(".char", {
        y: 0,
        rotateX: 0,
        opacity: 1,
        duration: 0.8,
        stagger: 0.05,
        ease: "back.out(1.5)"
    }, "-=0.5")
    .to(".hero-subtitle", {
        y: 0,
        opacity: 1,
        duration: 1,
        ease: "power3.out"
    }, "-=0.5")
    .to(".hero-cta", {
        y: 0,
        opacity: 1,
        duration: 1,
        ease: "power3.out"
    }, "-=0.7")
    .to(".scroll-indicator", {
        opacity: 1,
        duration: 1,
        ease: "power2.inOut"
    }, "-=0.3");

    // --- 5. Scroll Animations ---

    // Parallax Hero BG
    gsap.to(".hero-bg", {
        yPercent: 30,
        ease: "none",
        scrollTrigger: {
            trigger: ".hero",
            start: "top top",
            end: "bottom top",
            scrub: true
        }
    });

    // Image Scrub Parallax (Image moves inside wrapper)
    const featureImgs = document.querySelectorAll(".feature-img");
    featureImgs.forEach(img => {
        gsap.to(img, {
            yPercent: -20,
            ease: "none",
            scrollTrigger: {
                trigger: img.parentElement,
                start: "top bottom",
                end: "bottom top",
                scrub: true
            }
        });
    });

    // Staggered Feature Cards
    gsap.from(".feature-card", {
        scrollTrigger: {
            trigger: ".feature-grid",
            start: "top 80%",
        },
        y: 100,
        opacity: 0,
        duration: 1.2,
        stagger: 0.3,
        ease: "power4.out"
    });

    // App Showcase staggered reveal
    const appBlocks = document.querySelectorAll('.app-block');
    appBlocks.forEach((block, index) => {
        gsap.from(block, {
            scrollTrigger: {
                trigger: block,
                start: "top 80%",
            },
            x: index % 2 === 0 ? -100 : 100,
            opacity: 0,
            duration: 1.2,
            ease: "power4.out"
        });
        
        // Secondary image pop
        gsap.from(block.querySelectorAll('.secondary-img'), {
            scrollTrigger: {
                trigger: block,
                start: "top 70%",
            },
            scale: 0.8,
            y: 50,
            opacity: 0,
            duration: 1.2,
            delay: 0.4,
            ease: "elastic.out(1, 0.5)"
        });
    });

    // Specs Section 3D Image reveal
    gsap.from(".specs-image", {
        scrollTrigger: {
            trigger: ".specs",
            start: "top 75%",
        },
        x: 100,
        rotateY: 20,
        opacity: 0,
        duration: 1.5,
        ease: "power4.out"
    });

    // Specs List staggered
    gsap.from(".specs-list li", {
        scrollTrigger: {
            trigger: ".specs-list",
            start: "top 85%",
        },
        x: -50,
        opacity: 0,
        duration: 0.8,
        stagger: 0.15,
        ease: "power3.out"
    });

    // CTA Glow Pop
    gsap.from(".cta-content", {
        scrollTrigger: {
            trigger: ".cta",
            start: "top 80%",
        },
        scale: 0.8,
        opacity: 0,
        duration: 1.5,
        ease: "elastic.out(1, 0.5)"
    });

    // Navbar Scroll Background
    const navbar = document.querySelector('.navbar');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            navbar.style.background = 'rgba(10, 13, 18, 0.85)';
            navbar.style.backdropFilter = 'blur(16px)';
            navbar.style.boxShadow = '0 4px 30px rgba(0, 0, 0, 0.5)';
        } else {
            navbar.style.background = 'rgba(10, 13, 18, 0.0)';
            navbar.style.backdropFilter = 'none';
            navbar.style.boxShadow = 'none';
        }
    });
});
