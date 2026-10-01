<div dir="rtl">

# landing — صفحة روابط الدعوة

موقع ثابت صغير (HTML + CSS + JS عادي، بلا بناء وبلا خادم) يخدم غرضين:

1. `https://نطاقك/r/AB12CD` → يفتح تطبيق لمّتنا مباشرة على غرفة الرمز.
2. من لا يملك التطبيق → يرى الرمز وزرّ التحميل.

## النشر

**الأسهل (GitHub Pages):** Settings → Pages → Source: **GitHub Actions**، ثم ادفع إلى `main`.
الـ workflow `.github/workflows/landing.yml` ينشر هذا المجلد تلقائيًا على
`https://workabeer625-ai.github.io/Lametna/`.

**أو يدويًا:**

```bash
cd landing
npx vercel deploy --prod          # أو
npx netlify deploy --prod --dir=. # أو
npx wrangler pages deploy . --project-name lametna
```

## بعد النشر

1. عدّل `config.js` → `DOWNLOAD_URL` برابط الـ APK.
2. ضع نطاقك في `android/app/src/main/res/values/strings.xml` → `app_link_host`.
3. أضف `APP_LINK_BASE` في `env.json` ثم أعد بناء التطبيق.
4. (موصى به) ضع بصمة SHA-256 لمفتاح التوقيع في `.well-known/assetlinks.json`
   ليفتح الرابط التطبيق بلا مرور بالمتصفح.

الشرح الكامل: **[../docs/DEEP_LINKS.md](../docs/DEEP_LINKS.md)**

## الملفات

| الملف | الدور |
|-------|-------|
| `index.html` | الصفحة الرئيسية + زر التحميل |
| `r/index.html` | صفحة الدعوة (`/r/CODE`) |
| `404.html` | نفس صفحة الدعوة، لاستضافات بلا إعادة توجيه (GitHub Pages) |
| `app.js` | استخراج الرمز ومحاولة فتح التطبيق عبر `intent://` |
| `config.js` | رابط التحميل ومعرّف التطبيق |
| `.well-known/assetlinks.json` | توثيق App Links (ضع بصمتك) |
| `vercel.json` · `netlify.toml` · `_redirects` | إعادة توجيه `/r/*` |

</div>
