/**
 * Leaf Official Website — Main JavaScript Logic
 * Clean light-theme consumer product experience.
 * Mobile navigation with scroll lock, dynamic release metadata,
 * smooth scroll animations, and clipboard helpers.
 */

(function () {
  'use strict';

  // --- Configuration & Production Release Fallbacks ---
  const RELEASE_CONFIG = {
    owner: 'vinaynalavade',
    repo: 'Leaf',
    defaultVersionName: '1.1.3',
    defaultVersionCode: 15,
    defaultReleaseDate: 'October 10, 2026',
    defaultApkSize: '4.4 MB',
    defaultApkFileName: 'Leaf_v1.1.3.apk',
    defaultDownloadUrl: 'https://github.com/vinaynalavade/Leaf/releases/download/v1.1.3/Leaf_v1.1.3.apk',
    defaultSha256: '13220a715849d30f79e2c6b79e1bef4bb867550c64bee08d05a3b726601eec87',
    repoUrl: 'https://github.com/vinaynalavade/Leaf',
    releasesUrl: 'https://github.com/vinaynalavade/Leaf/releases'
  };

  // --- Mobile Navigation Drawer ---
  function initMobileNav() {
    const menuBtn = document.querySelector('.mobile-menu-btn');
    const nav = document.querySelector('.nav');

    if (!menuBtn || !nav) return;

    function closeNav() {
      nav.classList.remove('is-open');
      menuBtn.setAttribute('aria-expanded', 'false');
      menuBtn.innerHTML = `<svg viewBox="0 0 24 24" width="24" height="24"><path fill="currentColor" d="M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z"/></svg>`;
      document.body.style.overflow = '';
    }

    function openNav() {
      nav.classList.add('is-open');
      menuBtn.setAttribute('aria-expanded', 'true');
      menuBtn.innerHTML = `<svg viewBox="0 0 24 24" width="24" height="24"><path fill="currentColor" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg>`;
      document.body.style.overflow = 'hidden';
    }

    menuBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (nav.classList.contains('is-open')) {
        closeNav();
      } else {
        openNav();
      }
    });

    // Close when clicking any nav link
    nav.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        closeNav();
      });
    });

    // Close when clicking outside
    document.addEventListener('click', (e) => {
      if (nav.classList.contains('is-open') && !nav.contains(e.target) && !menuBtn.contains(e.target)) {
        closeNav();
      }
    });
  }

  // --- Active Nav Link Highlighting ---
  function initActiveNav() {
    const currentPath = window.location.pathname.split('/').pop() || 'index.html';
    const navLinks = document.querySelectorAll('.nav-link');

    navLinks.forEach(link => {
      const href = link.getAttribute('href');
      if (href === currentPath || (currentPath === '' && href === 'index.html')) {
        link.classList.add('active');
        link.setAttribute('aria-current', 'page');
      } else {
        link.classList.remove('active');
        link.removeAttribute('aria-current');
      }
    });
  }

  // --- Smooth Scroll Animations ---
  function initScrollAnimations() {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      return;
    }

    const animTargets = document.querySelectorAll('.animate-on-scroll, .card, .feature-story, .privacy-banner, .download-card, .github-banner');
    
    animTargets.forEach(el => {
      el.classList.add('animate-on-scroll');
    });

    if ('IntersectionObserver' in window) {
      const observer = new IntersectionObserver((entries, obs) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            obs.unobserve(entry.target);
          }
        });
      }, {
        threshold: 0.08,
        rootMargin: '0px 0px -40px 0px'
      });

      animTargets.forEach(el => observer.observe(el));
    } else {
      // Fallback
      animTargets.forEach(el => el.classList.add('is-visible'));
    }
  }

  // --- Version Comparison Helper ---
  function isVersionAtLeast(remoteVer, defaultVer) {
    const parse = (v) => String(v).replace(/^v/i, '').split('.').map(n => parseInt(n, 10) || 0);
    const r = parse(remoteVer);
    const d = parse(defaultVer);
    for (let i = 0; i < Math.max(r.length, d.length); i++) {
      const rVal = r[i] || 0;
      const dVal = d[i] || 0;
      if (rVal > dVal) return true;
      if (rVal < dVal) return false;
    }
    return true;
  }

  // --- Dynamic Release Metadata Fetching ---
  async function initReleaseMetadata() {
    updateReleaseUiElements({
      versionName: RELEASE_CONFIG.defaultVersionName,
      downloadUrl: RELEASE_CONFIG.defaultDownloadUrl,
      sha256: RELEASE_CONFIG.defaultSha256,
      sizeBytes: 4584952,
      formattedSize: RELEASE_CONFIG.defaultApkSize,
      publishedAt: RELEASE_CONFIG.defaultReleaseDate,
      fileName: RELEASE_CONFIG.defaultApkFileName
    });

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 6000);

      const response = await fetch(
        `https://api.github.com/repos/${RELEASE_CONFIG.owner}/${RELEASE_CONFIG.repo}/releases/latest`,
        {
          signal: controller.signal,
          headers: { 'Accept': 'application/vnd.github.v3+json' }
        }
      );
      clearTimeout(timeoutId);

      if (!response.ok) return;

      const releaseData = await response.json();
      if (!releaseData || !Array.isArray(releaseData.assets)) return;

      const apkAsset = releaseData.assets.find(
        asset => asset.name && asset.name.endsWith('.apk') && !asset.name.includes('debug')
      ) || releaseData.assets.find(asset => asset.name && asset.name.endsWith('.apk'));

      if (!apkAsset) return;

      const rawTag = releaseData.tag_name || '';
      const versionName = rawTag.replace(/^v/i, '') || RELEASE_CONFIG.defaultVersionName;

      // Only update if fetched remote release is at least as new as the configured default
      if (!isVersionAtLeast(versionName, RELEASE_CONFIG.defaultVersionName)) {
        return;
      }

      const formattedSize = apkAsset.size
        ? `${(apkAsset.size / (1024 * 1024)).toFixed(1)} MB`
        : RELEASE_CONFIG.defaultApkSize;

      let sha256 = RELEASE_CONFIG.defaultSha256;
      if (apkAsset.digest && apkAsset.digest.startsWith('sha256:')) {
        sha256 = apkAsset.digest.substring(7).trim();
      }

      const publishedDate = releaseData.published_at
        ? new Date(releaseData.published_at).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })
        : RELEASE_CONFIG.defaultReleaseDate;

      updateReleaseUiElements({
        versionName: versionName,
        downloadUrl: apkAsset.browser_download_url || RELEASE_CONFIG.defaultDownloadUrl,
        sha256: sha256,
        sizeBytes: apkAsset.size,
        formattedSize: formattedSize,
        publishedAt: publishedDate,
        fileName: apkAsset.name
      });
    } catch (_err) {
      // Graceful silent fallback
    }
  }

  function updateReleaseUiElements(data) {
    document.querySelectorAll('.dynamic-version').forEach(el => {
      el.textContent = `v${data.versionName}`;
    });

    document.querySelectorAll('.dynamic-version-plain').forEach(el => {
      el.textContent = data.versionName;
    });

    document.querySelectorAll('.dynamic-apk-size').forEach(el => {
      el.textContent = data.formattedSize;
    });

    document.querySelectorAll('.dynamic-release-date').forEach(el => {
      el.textContent = data.publishedAt;
    });

    document.querySelectorAll('.dynamic-sha256').forEach(el => {
      el.textContent = data.sha256;
    });

    document.querySelectorAll('.dynamic-download-link').forEach(el => {
      el.setAttribute('href', data.downloadUrl);
    });

    document.querySelectorAll('.dynamic-filename').forEach(el => {
      el.textContent = data.fileName;
    });
  }

  // --- Copy to Clipboard Helper ---
  function initCopyButtons() {
    document.querySelectorAll('.copy-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        const targetSelector = btn.getAttribute('data-copy-target');
        const targetEl = targetSelector ? document.querySelector(targetSelector) : null;
        const textToCopy = targetEl ? targetEl.textContent.trim() : btn.getAttribute('data-copy-text');

        if (!textToCopy) return;

        try {
          await navigator.clipboard.writeText(textToCopy);
          const originalText = btn.textContent;
          btn.textContent = 'Copied!';
          btn.classList.add('copied');
          setTimeout(() => {
            btn.textContent = originalText;
            btn.classList.remove('copied');
          }, 2000);
        } catch (_err) {
          const textarea = document.createElement('textarea');
          textarea.value = textToCopy;
          document.body.appendChild(textarea);
          textarea.select();
          document.execCommand('copy');
          document.body.removeChild(textarea);
          btn.textContent = 'Copied!';
          setTimeout(() => { btn.textContent = 'Copy'; }, 2000);
        }
      });
    });
  }

  // --- Easter Egg Universe (Web Edition) ---
  function initEasterEggs() {
    // 2. Developer Console Easter Egg
    try {
      console.log(
        '%c🌿 Hey, curious developer.\n\n' +
        'You found Leaf\'s console.\n\n' +
        'No secrets here...\n' +
        'Just good code, clean numbers,\n' +
        'and probably too much coffee.\n\n' +
        '— Vinay',
        'font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; ' +
        'font-size: 13px; font-weight: 500; color: #028166; background-color: #edf7f4; ' +
        'border-left: 4px solid #028166; padding: 12px 16px; border-radius: 6px; line-height: 1.6;'
      );
    } catch (_e) {}

    // Subtle Floating Toast Utility
    function showToast(message, icon = '🌿', duration = 3800) {
      let toast = document.querySelector('.leaf-easter-toast');
      if (!toast) {
        toast = document.createElement('div');
        toast.className = 'leaf-easter-toast';
        document.body.appendChild(toast);
      }
      toast.innerHTML = `<span class="leaf-toast-icon">${icon}</span><span class="leaf-toast-msg">${message}</span>`;
      toast.classList.add('is-visible');

      if (toast._timer) clearTimeout(toast._timer);
      toast._timer = setTimeout(() => {
        toast.classList.remove('is-visible');
      }, duration);
    }

    // 1. Hidden Leaf Interaction (Logo 7 Taps)
    const logos = document.querySelectorAll('.logo, .nav-brand');
    logos.forEach(logo => {
      let clickCount = 0;
      let lastClick = 0;
      logo.addEventListener('click', (e) => {
        const now = Date.now();
        if (now - lastClick > 2500) {
          clickCount = 1;
        } else {
          clickCount++;
        }
        lastClick = now;

        if (clickCount === 7) {
          clickCount = 0;
          e.preventDefault();
          const img = logo.querySelector('.logo-img') || logo.querySelector('img');
          if (img) {
            img.classList.remove('spin-bloom');
            void img.offsetWidth; // trigger reflow
            img.classList.add('spin-bloom');
          }
          showToast("You found something that wasn't in the budget.", '🌿');
        }
      });
    });

    // 3. Version Time Capsule (Version Badge 5 Clicks)
    const versionBadges = document.querySelectorAll('.hero-badge, .dynamic-version, .version-badge, .version-pill');
    let versionClickCount = 0;
    let lastVersionClick = 0;

    versionBadges.forEach(badge => {
      badge.style.cursor = 'pointer';
      badge.addEventListener('click', (e) => {
        const now = Date.now();
        if (now - lastVersionClick > 2500) {
          versionClickCount = 1;
        } else {
          versionClickCount++;
        }
        lastVersionClick = now;

        if (versionClickCount >= 5) {
          versionClickCount = 0;
          e.preventDefault();
          e.stopPropagation();
          openTimeCapsuleModal();
        }
      });
    });

    function openTimeCapsuleModal() {
      let modal = document.getElementById('leaf-time-capsule-modal');
      if (!modal) {
        modal = document.createElement('div');
        modal.id = 'leaf-time-capsule-modal';
        modal.className = 'leaf-modal-backdrop';
        modal.innerHTML = `
          <div class="leaf-modal-dialog" role="dialog" aria-modal="true" aria-labelledby="capsule-title">
            <div class="leaf-modal-header">
              <div class="leaf-modal-badge">🌱 Time Capsule</div>
              <button type="button" class="leaf-modal-close" aria-label="Close modal">&times;</button>
            </div>
            <h3 id="capsule-title" class="leaf-modal-title">Leaf Release Evolution</h3>
            <p class="leaf-modal-subtitle">From a local personal utility in Pune to a calm, polished offline-first finance companion.</p>
            <div class="leaf-timeline">
              <div class="leaf-timeline-item current">
                <div class="leaf-tl-ver">v1.1.3 <span>Latest</span></div>
                <div class="leaf-tl-title">Easter Eggs, System Polish &amp; Split 2.0 Refinements</div>
                <div class="leaf-tl-desc">Introduced rich cross-platform Easter eggs, resilient tag-based update checker fallbacks, and polished bill sharing and stability.</div>
              </div>
              <div class="leaf-timeline-item">
                <div class="leaf-tl-ver">v1.1.2</div>
                <div class="leaf-tl-title">Split 2.0 &amp; Financial Calculator</div>
                <div class="leaf-tl-desc">Base Equal Share + Item Responsibility model, in-app smart calculator, WhatsApp &amp; contact bill sharing, and direct GitHub update verification.</div>
              </div>
              <div class="leaf-timeline-item">
                <div class="leaf-tl-ver">v1.1.0</div>
                <div class="leaf-tl-title">Insights, Budgets & Polish</div>
                <div class="leaf-tl-desc">Enhanced monthly budget tracking, recurring cash flow insights, floating navigation capsule, and visual polish.</div>
              </div>
              <div class="leaf-timeline-item">
                <div class="leaf-tl-ver">v1.0.6</div>
                <div class="leaf-tl-title">Split & Collect Genesis</div>
                <div class="leaf-tl-desc">Initial group expense splitting foundation introduced to eliminate awkward post-outing money calculations.</div>
              </div>
              <div class="leaf-timeline-item">
                <div class="leaf-tl-ver">v1.0.5</div>
                <div class="leaf-tl-title">Reborn as Leaf</div>
                <div class="leaf-tl-desc">Brand migration to Leaf with the signature calm emerald palette, obsidian dark mode, and distraction-free design.</div>
              </div>
              <div class="leaf-timeline-item">
                <div class="leaf-tl-ver">v1.0.0</div>
                <div class="leaf-tl-title">Offline-First Engine</div>
                <div class="leaf-tl-desc">The original local SQLite bookkeeping architecture: 100% private, zero analytics, zero account lock-in.</div>
              </div>
            </div>
            <div class="leaf-modal-footer">
              <button type="button" class="btn btn-primary btn-sm leaf-modal-dismiss">Close</button>
            </div>
          </div>
        `;
        document.body.appendChild(modal);

        const closeBtn = modal.querySelector('.leaf-modal-close');
        const dismissBtn = modal.querySelector('.leaf-modal-dismiss');
        const closeModal = () => modal.classList.remove('is-open');

        closeBtn.addEventListener('click', closeModal);
        dismissBtn.addEventListener('click', closeModal);
        modal.addEventListener('click', (e) => {
          if (e.target === modal) closeModal();
        });
        document.addEventListener('keydown', (e) => {
          if (e.key === 'Escape' && modal.classList.contains('is-open')) {
            closeModal();
          }
        });
      }
      modal.classList.add('is-open');
    }

    // 4. Hidden Philosophy (Footer Tagline 3 Clicks)
    const footerTagline = document.querySelector('.footer-brand p');
    if (footerTagline) {
      let tagClickCount = 0;
      let lastTagClick = 0;
      footerTagline.style.cursor = 'pointer';
      footerTagline.addEventListener('click', () => {
        const now = Date.now();
        if (now - lastTagClick > 2500) tagClickCount = 1;
        else tagClickCount++;
        lastTagClick = now;

        if (tagClickCount >= 3) {
          tagClickCount = 0;
          showToast("Money is a tool. Clarity is freedom.", "🍃", 4500);
        }
      });
    }

    // 5. Hidden Founder Signature (Footer Copyright 3 Clicks)
    const footerCopyright = document.querySelector('.footer-bottom div:first-child');
    if (footerCopyright) {
      let copyClickCount = 0;
      let lastCopyClick = 0;
      footerCopyright.style.cursor = 'pointer';
      footerCopyright.addEventListener('click', () => {
        const now = Date.now();
        if (now - lastCopyClick > 2500) copyClickCount = 1;
        else copyClickCount++;
        lastCopyClick = now;

        if (copyClickCount >= 3) {
          copyClickCount = 0;
          showToast("Built with too many cups of chai. — Vinay ☕", "☕", 4500);
        }
      });
    }

    // 6. Hidden Website Sequence: Konami code or typing "leaf"
    const konamiSequence = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight'];
    let konamiIndex = 0;
    let typedBuffer = '';

    window.addEventListener('keydown', (e) => {
      // Check Konami arrows
      if (e.key === konamiSequence[konamiIndex]) {
        konamiIndex++;
        if (konamiIndex === konamiSequence.length) {
          konamiIndex = 0;
          triggerLeafBloomCanvas();
        }
      } else if (e.key && e.key.startsWith('Arrow')) {
        konamiIndex = (e.key === konamiSequence[0]) ? 1 : 0;
      }

      // Check typing "leaf" (ignore if user is typing in an input or textarea)
      if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA')) {
        return;
      }

      if (e.key && e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
        typedBuffer += e.key.toLowerCase();
        if (typedBuffer.length > 10) typedBuffer = typedBuffer.slice(-10);
        if (typedBuffer.endsWith('leaf')) {
          typedBuffer = '';
          triggerLeafBloomCanvas();
        }
      }
    });

    function triggerLeafBloomCanvas() {
      showToast("Hidden Leaf Bloom Unlocked 🌿", "✨", 4000);

      let canvas = document.getElementById('leaf-bloom-canvas');
      if (canvas) canvas.remove();

      canvas = document.createElement('canvas');
      canvas.id = 'leaf-bloom-canvas';
      canvas.className = 'leaf-bloom-canvas';
      document.body.appendChild(canvas);

      const ctx = canvas.getContext('2d');
      let width = canvas.width = window.innerWidth;
      let height = canvas.height = window.innerHeight;

      const onResize = () => {
        width = canvas.width = window.innerWidth;
        height = canvas.height = window.innerHeight;
      };
      window.addEventListener('resize', onResize);

      const colors = ['#028166', '#10b981', '#34d399', '#059669', '#a7f3d0'];
      const particles = [];
      for (let i = 0; i < 35; i++) {
        particles.push({
          x: Math.random() * width,
          y: -20 - Math.random() * 150,
          size: 14 + Math.random() * 18,
          speedY: 1.5 + Math.random() * 2.5,
          speedX: (Math.random() - 0.5) * 1.5,
          rotation: Math.random() * Math.PI * 2,
          rotationSpeed: (Math.random() - 0.5) * 0.05,
          color: colors[i % colors.length]
        });
      }

      let animId;
      const startTime = Date.now();
      const duration = 4200;

      function render() {
        const elapsed = Date.now() - startTime;
        if (elapsed > duration) {
          window.removeEventListener('resize', onResize);
          if (canvas.parentNode) canvas.remove();
          return;
        }

        ctx.clearRect(0, 0, width, height);

        const fadeAlpha = elapsed > duration - 800 ? (duration - elapsed) / 800 : 1;

        particles.forEach(p => {
          p.y += p.speedY;
          p.x += p.speedX + Math.sin(p.y * 0.02) * 0.5;
          p.rotation += p.rotationSpeed;

          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.rotation);
          ctx.globalAlpha = 0.85 * fadeAlpha;
          ctx.fillStyle = p.color;

          // Draw graceful leaf shape
          ctx.beginPath();
          ctx.moveTo(0, -p.size);
          ctx.quadraticCurveTo(p.size * 0.8, 0, 0, p.size);
          ctx.quadraticCurveTo(-p.size * 0.8, 0, 0, -p.size);
          ctx.fill();

          ctx.restore();
        });

        animId = requestAnimationFrame(render);
      }

      animId = requestAnimationFrame(render);

      // Dismiss on click or escape
      const cleanDismiss = () => {
        cancelAnimationFrame(animId);
        window.removeEventListener('resize', onResize);
        if (canvas.parentNode) canvas.remove();
      };
      canvas.addEventListener('click', cleanDismiss);
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') cleanDismiss();
      }, { once: true });
    }
  }

  // --- Initialize on DOM Ready ---
  document.addEventListener('DOMContentLoaded', () => {
    initMobileNav();
    initActiveNav();
    initScrollAnimations();
    initReleaseMetadata();
    initCopyButtons();
    initEasterEggs();
  });
})();
