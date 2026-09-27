# لوحة تحكم لمّتنا — Admin Dashboard

صفحة ثابتة (HTML + CSS + JavaScript عادي) بلا خطوة بناء وبلا خادم.
تتصل بـ Supabase مباشرة عبر `@supabase/supabase-js` من CDN.

## الأمان

- تستخدم **المفتاح العام (anon) فقط**. لا تضع `service_role` هنا أبدًا — الملف يصل إلى المتصفح.
- كل صلاحية تُفرض في قاعدة البيانات: سياسات RLS + `public.is_admin()` داخل
  `admin_stats()` و `admin_resolve_report()`. إخفاء الأزرار في الواجهة راحة بصرية لا أكثر.
- الدخول مقصور على حساب ملفه الشخصي `role in ('admin','moderator')`؛ غير ذلك يُسجَّل خروجه فورًا.

## التشغيل محليًا

```bash
cp config.js config.local.js   # اختياري
# عدّل config.js وضع SUPABASE_URL و SUPABASE_ANON_KEY
python3 -m http.server 4321
# ثم افتح http://localhost:4321
```

## ترقية حساب إلى مشرف

من SQL Editor في Supabase:

```sql
update public.profiles set role = 'admin'
 where id = (select id from auth.users where email = 'you@example.com');
```

## النشر المجاني

| المنصة | الأمر |
|---|---|
| Vercel | `npx vercel deploy --prod` داخل `admin/` |
| Netlify | `npx netlify deploy --prod --dir=.` داخل `admin/` |
| Cloudflare Pages | `npx wrangler pages deploy . --project-name lametna-admin` |
| GitHub Pages | ارفع محتوى `admin/` إلى فرع `gh-pages` |

بعد النشر أضف نطاق اللوحة في Supabase → Authentication → URL Configuration → Redirect URLs.
