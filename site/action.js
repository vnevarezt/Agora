/* Password reset and email verification, driven straight off the Identity
 * Toolkit REST endpoints.
 *
 * Not the Firebase JS SDK on purpose. This page does two POSTs; the modular SDK
 * is ~100 KB to reach the same endpoints, and the whole reason the landing is
 * not the Flutter app is that someone who only wants to type a new password
 * should not download a runtime to do it. The web API key is public by design —
 * it identifies the project and authorises nothing on its own; the oobCode in
 * the URL is the credential.
 */
(function () {
  'use strict';

  var API_KEY = '__FIREBASE_API_KEY__'; // injected by tool/build_site.py
  var ENDPOINT = 'https://identitytoolkit.googleapis.com/v1/accounts:';

  var params = new URLSearchParams(location.search);
  var mode = params.get('mode');
  var code = params.get('oobCode');

  var el = function (id) { return document.getElementById(id); };
  var states = ['s-loading', 's-reset', 's-done', 's-invalid'];

  function show(id) {
    states.forEach(function (s) { el(s).hidden = s !== id; });
  }

  function done(kind) {
    var title = el('s-done-title');
    var sub = el('s-done-sub');
    title.textContent = title.getAttribute('data-' + kind);
    sub.textContent = sub.getAttribute('data-' + kind);
    show('s-done');
  }

  function post(method, body) {
    return fetch(ENDPOINT + method + '?key=' + API_KEY, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).then(function (res) {
      return res.json().then(function (data) {
        if (!res.ok) {
          var reason = (data && data.error && data.error.message) || 'FAILED';
          throw new Error(reason);
        }
        return data;
      });
    });
  }

  function fieldError(key) {
    var box = el('s-reset-error');
    box.textContent = box.getAttribute('data-' + key);
    box.hidden = false;
  }

  /* A dead code is the expected failure here, not an exception: links are
   * single-use and expire in an hour, so anyone who opens one twice lands on
   * this branch. Anything else is genuinely unexpected and says so. */
  function isDeadCode(message) {
    return message === 'EXPIRED_OOB_CODE' ||
      message === 'INVALID_OOB_CODE' ||
      message === 'OPERATION_NOT_ALLOWED' ||
      message === 'USER_DISABLED';
  }

  function startReset() {
    // Sending the code with no password verifies it and returns the address it
    // belongs to, which is what lets the form name the account before asking.
    post('resetPassword', { oobCode: code }).then(function (data) {
      el('s-reset-email').textContent = data.email || '';
      show('s-reset');
      el('pw').focus();
    }).catch(function () { show('s-invalid'); });

    el('s-reset-form').addEventListener('submit', function (ev) {
      ev.preventDefault();
      var pw = el('pw').value;
      var pw2 = el('pw2').value;
      el('s-reset-error').hidden = true;

      if (pw !== pw2) { fieldError('mismatch'); el('pw2').focus(); return; }
      if (pw.length < 6) { fieldError('weak'); el('pw').focus(); return; }

      var button = el('s-reset-submit');
      button.disabled = true;
      post('resetPassword', { oobCode: code, newPassword: pw })
        .then(function () { done('reset'); })
        .catch(function (err) {
          button.disabled = false;
          if (isDeadCode(err.message)) { show('s-invalid'); return; }
          fieldError(err.message === 'WEAK_PASSWORD' ? 'weak' : 'generic');
        });
    });
  }

  function startVerify() {
    post('update', { oobCode: code })
      .then(function () { done('verify'); })
      .catch(function () { show('s-invalid'); });
  }

  if (!code) { show('s-invalid'); return; }
  if (mode === 'resetPassword') { startReset(); }
  else if (mode === 'verifyEmail') { startVerify(); }
  else { show('s-invalid'); }
})();
