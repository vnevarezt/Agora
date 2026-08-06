// Removes the boot screen once the engine has painted.
//
// A separate file rather than an inline <script> so the Content-Security-Policy
// can stay at `script-src 'self'`; an inline block would force 'unsafe-inline',
// which gives up most of what the policy is for. Nothing here is on the critical
// path — the boot screen itself is HTML and inline CSS, already painted by the
// time this runs.
(function () {
  var boot = document.getElementById('boot');
  if (!boot) return;
  var done = false;

  function clear() {
    if (done) return;
    done = true;
    boot.classList.add('done');
    setTimeout(function () { boot.remove(); }, 250);
  }

  // Watch for the engine's own host element rather than hooking
  // flutter_bootstrap.js internals, which are generated and version-specific.
  var obs = new MutationObserver(function () {
    if (document.querySelector('flt-scene-host, flutter-view, flt-glass-pane')) {
      obs.disconnect();
      clear();
    }
  });
  obs.observe(document.documentElement, {childList: true, subtree: true});

  // Never strand the user behind a spinner if the engine fails to boot or the
  // host element is renamed by a future Flutter release.
  setTimeout(function () { obs.disconnect(); clear(); }, 10000);
})();
