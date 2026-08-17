/* Agora landing page behaviour.
 *
 * Four things, none of which needs a framework: reveal on scroll, the solo/team
 * comparison, the floating return to the top, and warming the Flutter app so
 * that leaving this page for it is not a second cold start.
 */
(function () {
  'use strict';

  var reduced = matchMedia('(prefers-reduced-motion: reduce)');

  /* ---- reveal on scroll ------------------------------------------------
   * Everything below the fold is in the document from the first byte, so an
   * on-load entrance would play to nobody. Each section arrives as it comes
   * within reach of the viewport bottom, once.
   */
  var reveals = document.querySelectorAll('.reveal');
  if (!('IntersectionObserver' in window) || reduced.matches) {
    reveals.forEach(function (el) { el.classList.add('seen'); });
  } else {
    var seen = new IntersectionObserver(function (entries, obs) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('seen');
        obs.unobserve(entry.target);
      });
    }, { rootMargin: '0px 0px -64px 0px' });
    reveals.forEach(function (el) { seen.observe(el); });
  }

  /* ---- solo / team comparison ------------------------------------------
   * The rows sweep in a stagger from the side the indicator just travelled
   * towards. A straight cross-fade between two short strings in the same spot
   * reads as a smudge, so each row clears before its replacement arrives.
   */
  var segmented = document.querySelector('.segmented');
  if (segmented) {
    var tabs = segmented.querySelectorAll('[data-mode]');
    var swappable = document.querySelectorAll('[data-solo][data-team]');

    var apply = function (mode, animate) {
      var from = segmented.dataset.mode === 'team' ? 'team' : 'solo';
      if (from === mode) return;
      segmented.dataset.mode = mode;
      tabs.forEach(function (tab) {
        tab.setAttribute('aria-selected', String(tab.dataset.mode === mode));
      });

      var travel = mode === 'team' ? 12 : -12;
      swappable.forEach(function (el, i) {
        el.textContent = el.dataset[mode];
        if (!animate) return;
        el.style.setProperty('--row', String(i));
        el.style.setProperty('--swap-from', travel + 'px');
        el.removeAttribute('data-swap');
        void el.offsetWidth; // restart the animation rather than let it no-op
        el.setAttribute('data-swap', '');
      });
    };

    segmented.dataset.mode = 'solo';
    tabs.forEach(function (tab) {
      tab.addEventListener('click', function () {
        apply(tab.dataset.mode, !reduced.matches);
      });
    });
  }

  /* ---- back to top ----------------------------------------------------- */
  var toTop = document.querySelector('.to-top');
  if (toTop) {
    toTop.hidden = false;
    var tick = false;
    var update = function () {
      tick = false;
      toTop.classList.toggle('on', scrollY > innerHeight * 0.8);
    };
    addEventListener('scroll', function () {
      if (tick) return;
      tick = true;
      requestAnimationFrame(update);
    }, { passive: true });
    update();
  }

  /* ---- warming the app -------------------------------------------------
   * The app is still Flutter, so it still has an engine to download. The point
   * of this page loading in milliseconds is lost if pressing the button then
   * costs the visitor the wait we just removed — so the engine is fetched
   * while they read, and by the time they click it is in the HTTP cache.
   *
   * Which files to fetch depends on the renderer the browser will be handed,
   * and Flutter's own bootstrap decides that from these two tests: WasmGC
   * support, and whether the engine is Blink (its default wasm allow-list is
   * Blink-only). Guessing wrong here would waste megabytes, so the same two
   * questions are asked rather than assumed. If Flutter's rule changes, the
   * cost is a speculative fetch of the wrong pair — never a broken page, since
   * nothing here is on the app's critical path.
   */
  var wantsData = navigator.connection && (navigator.connection.saveData ||
    /2g/.test(navigator.connection.effectiveType || ''));
  if (!wantsData) {
    var wasmGC = (function () {
      try {
        return WebAssembly.validate(new Uint8Array(
          [0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 95, 1, 120, 0]));
      } catch (e) {
        return false;
      }
    })();
    var blink = navigator.vendor === 'Google Inc.' ||
      navigator.userAgent.indexOf('Edg/') !== -1;

    var payload = ['/app/', '/app/flutter_bootstrap.js'].concat(
      wasmGC && blink
        ? ['/app/main.dart.mjs', '/app/main.dart.wasm', '/app/canvaskit/skwasm.wasm']
        : ['/app/main.dart.js', '/app/canvaskit/canvaskit.wasm']);

    var warmed = false;
    var warm = function () {
      if (warmed) return;
      warmed = true;
      payload.forEach(function (href) {
        var link = document.createElement('link');
        link.rel = 'prefetch';
        link.href = href;
        document.head.appendChild(link);
      });
    };

    // Intent first — a visitor reaching for the button gets the head start
    // whether or not the page has been idle long enough for the timer below.
    document.querySelectorAll('a[href^="/app/"]').forEach(function (a) {
      ['pointerenter', 'focus', 'touchstart'].forEach(function (evt) {
        a.addEventListener(evt, warm, { once: true, passive: true });
      });
    });

    // And speculatively once the page has settled, so the common case of
    // reading down and then clicking has nothing left to wait for.
    if ('requestIdleCallback' in window) {
      requestIdleCallback(warm, { timeout: 4000 });
    } else {
      addEventListener('load', function () { setTimeout(warm, 1500); });
    }
  }
})();
