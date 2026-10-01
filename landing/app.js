// ============================================================
//  لمّتنا — منطق صفحة الدعوة
//  يستخرج رمز الغرفة من المسار /r/AB12CD أو من ?c=AB12CD
//  ثم يحاول فتح التطبيق مباشرة، وإلا يعرض زرّ التحميل.
// ============================================================
(function () {
  var CFG = window.LAMETNA_LANDING || {};
  var DOWNLOAD = CFG.DOWNLOAD_URL || '';
  var PKG = CFG.ANDROID_PACKAGE || 'app.lametna.lametna';
  var SCHEME = CFG.SCHEME || 'lametna';

  function readCode() {
    var m = location.pathname.match(/\/r\/([A-Za-z0-9]{6})/);
    if (m) return m[1].toUpperCase();
    var q = new URLSearchParams(location.search).get('c');
    if (q && /^[A-Za-z0-9]{6}$/.test(q)) return q.toUpperCase();
    var h = (location.hash || '').replace('#', '');
    if (/^[A-Za-z0-9]{6}$/.test(h)) return h.toUpperCase();
    return '';
  }

  var code = readCode();
  var isAndroid = /android/i.test(navigator.userAgent);
  var isIOS = /iphone|ipad|ipod/i.test(navigator.userAgent);

  function appUrl() {
    if (!code) return SCHEME + '://open/home';
    if (isAndroid) {
      return (
        'intent://open/r/' + code +
        '#Intent;scheme=' + SCHEME +
        ';package=' + PKG +
        (DOWNLOAD ? ';S.browser_fallback_url=' + encodeURIComponent(DOWNLOAD) : '') +
        ';end'
      );
    }
    return SCHEME + '://open/r/' + code;
  }

  function openApp() {
    try {
      window.location.href = appUrl();
    } catch (e) {
      if (DOWNLOAD) window.location.href = DOWNLOAD;
    }
  }

  function $(id) { return document.getElementById(id); }

  document.addEventListener('DOMContentLoaded', function () {
    var codeBox = $('code');
    var openBtn = $('open');
    var dlBtn = $('download');
    var copyBtn = $('copy');
    var note = $('note');

    if (code) {
      if (codeBox) codeBox.textContent = code;
    } else {
      var card = $('invite-card');
      if (card) card.classList.add('hidden');
      if (note) note.textContent = 'لا يوجد رمز غرفة في هذا الرابط — حمّل التطبيق وابدأ لمّتك.';
    }

    if (openBtn) {
      openBtn.addEventListener('click', function (e) {
        e.preventDefault();
        openApp();
      });
    }

    if (dlBtn) {
      dlBtn.href = DOWNLOAD || '#';
      if (!DOWNLOAD) dlBtn.classList.add('hidden');
    }

    if (copyBtn && code) {
      copyBtn.addEventListener('click', function () {
        navigator.clipboard.writeText(code).then(function () {
          copyBtn.textContent = 'تم نسخ الرمز ✓';
          setTimeout(function () { copyBtn.textContent = 'نسخ الرمز'; }, 2000);
        });
      });
    }

    // محاولة فتح تلقائية على أندرويد: إن كان التطبيق مثبتًا فتح فورًا،
    // وإلا بقي المستخدم في هذه الصفحة ليحمّله.
    if (code && (isAndroid || isIOS)) {
      setTimeout(openApp, 350);
    }
  });
})();
