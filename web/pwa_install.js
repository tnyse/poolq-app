/**
 * PoolQ PWA Install Prompt
 * Handles "Add to Home Screen" for Android (beforeinstallprompt) and iOS Safari.
 * Styled to match PoolQ brand: #063a73 primary / #FF8F00 accent.
 * Dismissal is remembered in localStorage for 30 days.
 */
(function () {
  'use strict';

  const DISMISS_KEY = 'pwa_install_dismissed';
  const DISMISS_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

  function isDismissed() {
    const ts = localStorage.getItem(DISMISS_KEY);
    if (!ts) return false;
    return Date.now() - parseInt(ts, 10) < DISMISS_TTL_MS;
  }

  function setDismissed() {
    localStorage.setItem(DISMISS_KEY, Date.now().toString());
  }

  function isStandalone() {
    return (
      window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true
    );
  }

  function isIOS() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent) && !window.MSStream;
  }

  function isSafari() {
    // Safari on iOS does not fire beforeinstallprompt
    return /safari/i.test(navigator.userAgent) && !/chrome|crios|fxios/i.test(navigator.userAgent);
  }

  // Inject shared chip styles once
  function injectStyles() {
    if (document.getElementById('pwa-install-styles')) return;
    const style = document.createElement('style');
    style.id = 'pwa-install-styles';
    style.textContent = `
      #pwa-install-chip {
        position: fixed;
        bottom: 72px;
        left: 50%;
        transform: translateX(-50%);
        z-index: 99999;
        display: flex;
        align-items: center;
        gap: 10px;
        background: #063a73;
        color: #fff;
        border-radius: 28px;
        padding: 10px 16px 10px 14px;
        box-shadow: 0 4px 20px rgba(6,58,115,0.45);
        font-family: 'Roboto', Arial, sans-serif;
        font-size: 14px;
        max-width: 340px;
        width: calc(100vw - 48px);
        animation: pwa-slide-up 0.35s cubic-bezier(0.34,1.56,0.64,1) both;
        pointer-events: auto;
        box-sizing: border-box;
      }
      #pwa-install-chip .pwa-icon {
        width: 36px;
        height: 36px;
        border-radius: 8px;
        flex-shrink: 0;
        object-fit: cover;
        background: #fff;
      }
      #pwa-install-chip .pwa-text {
        flex: 1;
        min-width: 0;
      }
      #pwa-install-chip .pwa-title {
        font-weight: 700;
        font-size: 13px;
        line-height: 1.2;
        color: #fff;
        display: block;
      }
      #pwa-install-chip .pwa-sub {
        font-size: 11px;
        color: rgba(255,255,255,0.75);
        display: block;
        margin-top: 2px;
        line-height: 1.3;
      }
      #pwa-install-chip .pwa-btn {
        background: #FF8F00;
        color: #fff;
        border: none;
        border-radius: 20px;
        padding: 7px 14px;
        font-size: 13px;
        font-weight: 700;
        cursor: pointer;
        white-space: nowrap;
        flex-shrink: 0;
        font-family: inherit;
        transition: background 0.15s;
      }
      #pwa-install-chip .pwa-btn:hover { background: #e67e00; }
      #pwa-install-chip .pwa-close {
        background: none;
        border: none;
        color: rgba(255,255,255,0.6);
        cursor: pointer;
        font-size: 18px;
        line-height: 1;
        padding: 0 0 0 4px;
        flex-shrink: 0;
        font-family: inherit;
      }
      #pwa-install-chip .pwa-close:hover { color: #fff; }
      @keyframes pwa-slide-up {
        from { opacity: 0; transform: translateX(-50%) translateY(24px); }
        to   { opacity: 1; transform: translateX(-50%) translateY(0); }
      }
    `;
    document.head.appendChild(style);
  }

  function removeChip() {
    const el = document.getElementById('pwa-install-chip');
    if (el) el.remove();
  }

  function buildChip(mainContent) {
    injectStyles();
    const chip = document.createElement('div');
    chip.id = 'pwa-install-chip';
    chip.setAttribute('role', 'region');
    chip.setAttribute('aria-label', 'Install PoolQ');

    // App icon
    const img = document.createElement('img');
    img.className = 'pwa-icon';
    img.src = 'apple-touch-icon.png';
    img.alt = 'PoolQ';
    chip.appendChild(img);

    // Text + action
    chip.appendChild(mainContent);

    // Dismiss button
    const close = document.createElement('button');
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

  // Android / Chrome — show chip with Install button
  function showAndroidChip(deferredPrompt) {
    const text = document.createElement('div');
    text.className = 'pwa-text';
    text.innerHTML = '<span class="pwa-title">Install PoolQ</span><span class="pwa-sub">Add to your home screen for the best experience</span>';

    const btn = document.createElement('button');
    btn.className = 'pwa-btn';
    btn.textContent = 'Install';
    btn.addEventListener('click', function () {
      removeChip();
      deferredPrompt.prompt();
      deferredPrompt.userChoice.then(function (result) {
        if (result.outcome !== 'accepted') {
          // Re-show after 30d if they dismissed the native prompt
          setDismissed();
        }
      });
    });

    const content = document.createElement('div');
    content.style.cssText = 'display:flex;align-items:center;gap:8px;flex:1;min-width:0;';
    content.appendChild(text);
    content.appendChild(btn);

    document.body.appendChild(buildChip(content));
  }

  // iOS Safari — show chip with Share icon instructions
  function showIOSChip() {
    const text = document.createElement('div');
    text.className = 'pwa-text';
    // Share icon ⬆ via unicode; friendly instruction
    text.innerHTML =
      '<span class="pwa-title">Add PoolQ to Home Screen</span>' +
      '<span class="pwa-sub">Tap <strong style="color:#FF8F00;">Share</strong> \u2197 then <strong style="color:#FF8F00;">Add to Home Screen</strong></span>';

    document.body.appendChild(buildChip(text));
  }

  // Entry point — delay slightly so Flutter has painted
  function init() {
    if (isStandalone() || isDismissed()) return;

    if (isIOS() && isSafari()) {
      setTimeout(showIOSChip, 3500);
      return;
    }

    // Android/Chrome path — wait for beforeinstallprompt
    window.addEventListener('beforeinstallprompt', function (e) {
      e.preventDefault();
      // Small delay so Flutter UI is ready
      setTimeout(function () {
        if (!isStandalone() && !isDismissed()) {
          showAndroidChip(e);
        }
      }, 2500);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
