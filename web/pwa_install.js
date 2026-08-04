/**
 * PoolQ PWA Install Prompt (HTML layer)
 * Android/Chrome: beforeinstallprompt → Install chip
 * iOS: Flutter [PwaInstallBanner] is primary (canvas covers HTML).
 * This script still shows a fallback iOS chip and keeps it above Flutter.
 */
(function () {
  'use strict';

  const DISMISS_KEY = 'pwa_install_dismissed';
  const DISMISS_TTL_MS = 14 * 24 * 60 * 60 * 1000; // 14 days

  function isDismissed() {
    try {
      const ts = localStorage.getItem(DISMISS_KEY);
      if (!ts) return false;
      return Date.now() - parseInt(ts, 10) < DISMISS_TTL_MS;
    } catch (_) {
      return false;
    }
  }

  function setDismissed() {
    try {
      localStorage.setItem(DISMISS_KEY, Date.now().toString());
    } catch (_) {}
  }

  function isStandalone() {
    try {
      return (
        window.matchMedia('(display-mode: standalone)').matches ||
        window.navigator.standalone === true
      );
    } catch (_) {
      return false;
    }
  }

  function isIOS() {
    var ua = navigator.userAgent || '';
    var iOSDevice = /iphone|ipad|ipod/i.test(ua);
    // iPadOS 13+ desktop UA
    var iPadOS =
      navigator.platform === 'MacIntel' && (navigator.maxTouchPoints || 0) > 1;
    return (iOSDevice || iPadOS) && !window.MSStream;
  }

  function isInAppBrowser() {
    return /FBAN|FBAV|Instagram|Line\/|Twitter|LinkedInApp|Pinterest|Snapchat|WhatsApp/i.test(
      navigator.userAgent || ''
    );
  }

  function injectStyles() {
    if (document.getElementById('pwa-install-styles')) return;
    var style = document.createElement('style');
    style.id = 'pwa-install-styles';
    style.textContent =
      '#pwa-install-chip{' +
      'position:fixed!important;' +
      'bottom:calc(72px + env(safe-area-inset-bottom,0px))!important;' +
      'left:50%!important;' +
      'transform:translateX(-50%)!important;' +
      'z-index:2147483647!important;' +
      'display:flex!important;' +
      'align-items:center;' +
      'gap:10px;' +
      'background:#063a73;' +
      'color:#fff;' +
      'border-radius:28px;' +
      'padding:10px 16px 10px 14px;' +
      'box-shadow:0 4px 20px rgba(6,58,115,.45);' +
      "font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;" +
      'font-size:14px;' +
      'max-width:360px;' +
      'width:calc(100vw - 32px);' +
      'pointer-events:auto!important;' +
      'box-sizing:border-box;' +
      'animation:pwa-slide-up .35s cubic-bezier(.34,1.56,.64,1) both;' +
      '}' +
      '#pwa-install-chip .pwa-icon{width:36px;height:36px;border-radius:8px;flex-shrink:0;object-fit:cover;background:#fff}' +
      '#pwa-install-chip .pwa-text{flex:1;min-width:0}' +
      '#pwa-install-chip .pwa-title{font-weight:700;font-size:13px;line-height:1.2;color:#fff;display:block}' +
      '#pwa-install-chip .pwa-sub{font-size:11px;color:rgba(255,255,255,.8);display:block;margin-top:2px;line-height:1.35}' +
      '#pwa-install-chip .pwa-btn{background:#FF8F00;color:#fff;border:none;border-radius:20px;padding:7px 14px;font-size:13px;font-weight:700;cursor:pointer;white-space:nowrap;flex-shrink:0;font-family:inherit}' +
      '#pwa-install-chip .pwa-close{background:none;border:none;color:rgba(255,255,255,.65);cursor:pointer;font-size:18px;line-height:1;padding:0 0 0 4px;flex-shrink:0}' +
      '@keyframes pwa-slide-up{from{opacity:0;transform:translateX(-50%) translateY(24px)}to{opacity:1;transform:translateX(-50%) translateY(0)}}';
    document.head.appendChild(style);
  }

  function removeChip() {
    var el = document.getElementById('pwa-install-chip');
    if (el) el.remove();
  }

  function keepChipOnTop(chip) {
    function bump() {
      if (!chip.isConnected) return;
      chip.style.zIndex = '2147483647';
      document.body.appendChild(chip);
    }
    bump();
    setTimeout(bump, 500);
    setTimeout(bump, 2000);
    setTimeout(bump, 5000);
    // Flutter may inject late — observe body children briefly
    try {
      var obs = new MutationObserver(function () {
        if (chip.isConnected) bump();
      });
      obs.observe(document.body, { childList: true });
      setTimeout(function () {
        obs.disconnect();
      }, 8000);
    } catch (_) {}
  }

  function buildChip(mainContent) {
    injectStyles();
    var chip = document.createElement('div');
    chip.id = 'pwa-install-chip';
    chip.setAttribute('role', 'region');
    chip.setAttribute('aria-label', 'Install PoolQ');

    var img = document.createElement('img');
    img.className = 'pwa-icon';
    img.src = 'apple-touch-icon.png';
    img.alt = 'PoolQ';
    chip.appendChild(img);
    chip.appendChild(mainContent);

    var close = document.createElement('button');
    close.className = 'pwa-close';
    close.setAttribute('aria-label', 'Dismiss');
    close.innerHTML = '&#x2715;';
    close.addEventListener('click', function () {
      setDismissed();
      removeChip();
    });
    chip.appendChild(close);
    return chip;
  }

  function showAndroidChip(deferredPrompt) {
    var text = document.createElement('div');
    text.className = 'pwa-text';
    text.innerHTML =
      '<span class="pwa-title">Install PoolQ</span>' +
      '<span class="pwa-sub">Add to your home screen for the best experience</span>';

    var btn = document.createElement('button');
    btn.className = 'pwa-btn';
    btn.textContent = 'Install';
    btn.addEventListener('click', function () {
      removeChip();
      deferredPrompt.prompt();
      deferredPrompt.userChoice.then(function (result) {
        if (result.outcome !== 'accepted') setDismissed();
      });
    });

    var content = document.createElement('div');
    content.style.cssText =
      'display:flex;align-items:center;gap:8px;flex:1;min-width:0;';
    content.appendChild(text);
    content.appendChild(btn);

    var chip = buildChip(content);
    document.body.appendChild(chip);
    keepChipOnTop(chip);
  }

  function showIOSChip() {
    var text = document.createElement('div');
    text.className = 'pwa-text';
    if (isInAppBrowser()) {
      text.innerHTML =
        '<span class="pwa-title">Install PoolQ</span>' +
        '<span class="pwa-sub">Open in <strong style="color:#FF8F00;">Safari</strong>, then Share → Add to Home Screen</span>';
    } else {
      text.innerHTML =
        '<span class="pwa-title">Add PoolQ to Home Screen</span>' +
        '<span class="pwa-sub">Tap <strong style="color:#FF8F00;">Share</strong> ▢↑ then <strong style="color:#FF8F00;">Add to Home Screen</strong></span>';
    }

    var chip = buildChip(text);
    document.body.appendChild(chip);
    keepChipOnTop(chip);
  }

  function init() {
    if (isStandalone() || isDismissed()) return;

    // iOS: Flutter PwaInstallBanner owns the prompt (HTML sits under the canvas).
    // Still show a brief HTML fallback for in-app browsers before Flutter boots.
    if (isIOS()) {
      if (isInAppBrowser()) {
        setTimeout(showIOSChip, 1500);
      }
      return;
    }

    window.addEventListener('beforeinstallprompt', function (e) {
      e.preventDefault();
      setTimeout(function () {
        if (!isStandalone() && !isDismissed()) showAndroidChip(e);
      }, 2000);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
