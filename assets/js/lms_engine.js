(function () {
  if (window.__lmsInit) return;
  window.__lmsInit = true;

  var P = __LMS_PAYLOAD__;              // injected by Dart: css, routes, base, debug
  var sheet = null;                     // constructable stylesheet
  var lastCss = null;

  function log() {
    if (P.debug && window.console) console.log.apply(console, ['[LMS]'].concat([].slice.call(arguments)));
  }

  /* ---------- 1. choose CSS files for the current URL ---------- */
  function filesFor(path) {
    var files = P.base.slice();
    path = (path || '/').toLowerCase();
    for (var i = 0; i < P.routes.length; i++) {
      if (new RegExp(P.routes[i].p).test(path)) { files = files.concat(P.routes[i].files); break; }
    }
    return files;
  }

  /* ---------- 2. apply styles ----------
     Preferred: constructable stylesheet (not blocked by a strict CSP and
     always wins the cascade). Fallback: a <style> tag. */
  function applyStyles() {
    var files = filesFor(location.pathname);
    var css = files.map(function (k) { return P.css[k] || ''; }).join('');
    if (css === lastCss) return;
    lastCss = css;
    document.documentElement.setAttribute('data-lms-files', files.join(','));

    try {
      if (window.CSSStyleSheet && CSSStyleSheet.prototype.replaceSync && 'adoptedStyleSheets' in document) {
        if (!sheet) sheet = new CSSStyleSheet();
        sheet.replaceSync(css);
        var others = [].filter.call(document.adoptedStyleSheets, function (s) { return s !== sheet; });
        document.adoptedStyleSheets = others.concat([sheet]);
        log('styles via adoptedStyleSheets:', files.join(','));
        return;
      }
    } catch (e) { log('adoptedStyleSheets failed, using <style>', e); }

    var s = document.getElementById('uet-lms-styles');
    if (!s) { s = document.createElement('style'); s.id = 'uet-lms-styles'; }
    s.textContent = css;
    (document.head || document.documentElement).appendChild(s);   // last = wins
    log('styles via <style>:', files.join(','));
  }
  applyStyles();

  // re-apply if the URL changes without a full reload
  ['pushState', 'replaceState'].forEach(function (m) {
    var orig = history[m];
    history[m] = function () { var r = orig.apply(this, arguments); applyStyles(); return r; };
  });
  window.addEventListener('popstate', applyStyles);

  /* ---------- 3. mobile viewport safety net ---------- */
  function ensureViewport() {
    if (!document.head || document.querySelector('meta[name="viewport"]')) return;
    var m = document.createElement('meta');
    m.name = 'viewport';
    m.content = 'width=device-width, initial-scale=1, viewport-fit=cover';
    document.head.appendChild(m);
  }

  /* ---------- 4. "Sign in" pill in the navbar (guests only) ---------- */
  function addSignIn() {
    if (location.pathname.indexOf('/web/login') === 0) return;
    var nav = document.querySelector('header nav.navbar');
    if (!nav || nav.querySelector('.lms-navbar-signin-btn')) return;
    if (document.querySelector('a[href*="/web/session/logout"]')) return;
    var a = document.createElement('a');
    a.className = 'lms-navbar-signin-btn';
    a.href = '/web/login';
    a.textContent = 'Sign in';
    var toggler = nav.querySelector('.navbar-toggler');
    if (toggler && toggler.parentNode) toggler.parentNode.insertBefore(a, toggler);
    else (nav.querySelector('.container, .container-fluid') || nav).appendChild(a);
  }

  /* ---------- 5. password eye ---------- */
  var EYE = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
  var EYE_OFF = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19M1 1l22 22"/></svg>';

  function addEyes() {
    var fields = document.querySelectorAll('input[type="password"]');
    for (var i = 0; i < fields.length; i++) {
      (function (inp) {
        if (inp.dataset.lmsEye) return;
        var p = inp.parentElement;
        if (!p) return;
        inp.dataset.lmsEye = '1';
        p.classList.add('lms-pwd-group');
        var b = document.createElement('button');
        b.type = 'button';
        b.className = 'lms-eye-btn';
        b.setAttribute('aria-label', 'Show password');
        b.innerHTML = EYE;
        b.addEventListener('click', function (e) {
          e.preventDefault(); e.stopPropagation();
          var show = inp.type === 'password';
          inp.type = show ? 'text' : 'password';
          b.innerHTML = show ? EYE_OFF : EYE;
          b.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
        });
        p.appendChild(b);
      })(fields[i]);
    }
  }

  /* ---------- 6. run + watch the DOM (throttled) ---------- */
  function enhance() { ensureViewport(); addSignIn(); addEyes(); }

  var queued = false;
  function schedule() {
    if (queued) return;
    queued = true;
    requestAnimationFrame(function () { queued = false; enhance(); });
  }

  function start() {
    applyStyles();
    enhance();
    new MutationObserver(schedule).observe(document.body || document.documentElement,
      { childList: true, subtree: true });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();

  /* ---------- 7. debug helper (read from Flutter in debug builds) ---------- */
  window.__lmsDebug = function () {
    return {
      path: location.pathname,
      files: filesFor(location.pathname),
      loadedCss: Object.keys(P.css),
      adoptedSheets: document.adoptedStyleSheets ? document.adoptedStyleSheets.length : -1,
      hasStyleTag: !!document.getElementById('uet-lms-styles'),
      viewport: window.innerWidth + 'x' + window.innerHeight,
      navbarFound: !!document.querySelector('header nav.navbar'),
      signInFound: !!document.querySelector('.lms-navbar-signin-btn')
    };
  };
})();
