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
   * hands the visitor back the wait we just removed.
   *
   * But the two halves of that download are three orders of magnitude apart,
   * so they are not fetched on the same terms:
   *
   *   the entry pair   5.7 KB   /app/ and its bootstrap
   *   the engine       3.3 MB   the wasm
   *
   * The entry pair goes to everyone once the page settles. It costs about 5%
   * on top of this page and it is the half that decides which renderer the
   * browser gets, so having it cached starts the engine request a round trip
   * sooner. The engine itself only goes to someone who has reached for the
   * button, because most visitors read the page and leave — and serving 3.3 MB
   * to each of them would cost thirty times the bandwidth of the site itself,
   * against a daily free tier, to warm a cache nobody uses.
   *
   * Which engine files depends on the renderer the browser will be handed, and
   * Flutter's own bootstrap decides that from two tests: WasmGC support, and
   * whether the engine is Blink (its default wasm allow-list is Blink-only).
   * The same two questions are asked here rather than assumed. If Flutter's
   * rule changes the cost is a speculative fetch of the wrong pair — never a
   * broken page, since nothing here is on the app's critical path.
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

    var entry = ['/app/', '/app/flutter_bootstrap.js'];
    var engine = wasmGC && blink
      ? ['/app/main.dart.mjs', '/app/main.dart.wasm', '/app/canvaskit/skwasm.wasm']
      : ['/app/main.dart.js', '/app/canvaskit/canvaskit.wasm'];

    var asked = {};
    var prefetch = function (hrefs) {
      hrefs.forEach(function (href) {
        if (asked[href]) return;
        asked[href] = true;
        var link = document.createElement('link');
        link.rel = 'prefetch';
        link.href = href;
        document.head.appendChild(link);
      });
    };

    // Reaching for any way into the app is the signal. pointerenter covers the
    // mouse, focus the keyboard, and touchstart buys a phone the ~100ms between
    // finger down and finger up — small, but it is the only warning a touch
    // screen ever gives.
    var full = function () { prefetch(entry.concat(engine)); };
  
  /* In-page navigation without the hash.
   *
   * A bare href="#downloads" makes the browser jump and stamp the fragment into
   * the address bar, which turns a reading position into something the user has
   * to clean up — and back then walks the sections rather than leaving the page.
   * Taking the click ourselves keeps the URL as the reader found it.
   *
   * Focus still has to move, or a keyboard user scrolls the viewport while their
   * tab position stays behind in the header. tabindex -1 makes the section
   * focusable without adding it to the tab order, and preventScroll stops the
   * focus call from undoing the smooth scroll it was just handed.
   */

  /* Theme: system -> light -> dark -> system.
   *
   * "System" is the absence of a stored value, so clearing the key is what
   * hands control back to the OS. The <head> already applied any stored choice
   * before paint; this only wires the control and keeps the label truthful,
   * since the icon alone tells a screen reader nothing. */
  (function () {
    var button = document.querySelector('[data-theme-toggle]');
    if (!button) return;
    var order = ['system', 'light', 'dark'];

    var read = function () {
      try {
        var t = localStorage.getItem('agora-theme');
        return t === 'light' || t === 'dark' ? t : 'system';
      } catch (e) { return 'system'; }
    };

    var paint = function (state) {
      button.setAttribute('data-state', state);
      var label = button.getAttribute('data-label-' + state);
      button.setAttribute('aria-label', label);
      button.setAttribute('title', label);
      if (state === 'system') delete document.documentElement.dataset.theme;
      else document.documentElement.dataset.theme = state;
    };

    paint(read());

    button.addEventListener('click', function () {
      var next = order[(order.indexOf(read()) + 1) % order.length];
      try {
        if (next === 'system') localStorage.removeItem('agora-theme');
        else localStorage.setItem('agora-theme', next);
      } catch (e) {}
      paint(next);
    });
  })();


  /* Which section the reader is in.
   *
   * The nav named four destinations but never said which one you were looking
   * at. rootMargin pins the decision line just under the glass bar rather than
   * at the viewport edge, so the heading you are actually reading is the one
   * that counts. aria-current does the announcing; the underline is the visible
   * half of the same fact.
   */
  (function () {
    var links = Array.prototype.slice.call(
      document.querySelectorAll('.nav a[href^="#"]'));
    if (!links.length || !window.IntersectionObserver) return;

    var byId = {};
    links.forEach(function (a) { byId[a.getAttribute('href').slice(1)] = a; });

    var sections = Object.keys(byId)
      .map(function (id) { return document.getElementById(id); })
      .filter(Boolean);
    if (!sections.length) return;

    var visible = {};
    var mark = function () {
      var current = null;
      sections.forEach(function (el) { if (visible[el.id]) current = current || el.id; });
      links.forEach(function (a) {
        if (a.getAttribute('href') === '#' + current) a.setAttribute('aria-current', 'true');
        else a.removeAttribute('aria-current');
      });
    };

    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { visible[e.target.id] = e.isIntersecting; });
      mark();
    }, { rootMargin: '-72px 0px -55% 0px' });

    sections.forEach(function (el) { io.observe(el); });
  })();

  document.querySelectorAll('a[href^="#"]').forEach(function (a) {
    a.addEventListener('click', function (ev) {
      var id = a.getAttribute('href').slice(1);
      var target = id ? document.getElementById(id) : document.body;
      if (!target) return;
      ev.preventDefault();
      var still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      target.scrollIntoView({ behavior: still ? 'auto' : 'smooth', block: 'start' });
      if (!target.hasAttribute('tabindex')) target.setAttribute('tabindex', '-1');
      target.focus({ preventScroll: true });
    });
  });

  document.querySelectorAll('a[href^="/app/"]').forEach(function (a) {
      ['pointerenter', 'focus', 'touchstart'].forEach(function (evt) {
        a.addEventListener(evt, full, { once: true, passive: true });
      });
    });

    // The cheap half, for everyone, once the page has settled.
    var warmEntry = function () { prefetch(entry); };
    if ('requestIdleCallback' in window) {
      requestIdleCallback(warmEntry, { timeout: 4000 });
    } else {
      addEventListener('load', function () { setTimeout(warmEntry, 1500); });
    }
  }
})();
