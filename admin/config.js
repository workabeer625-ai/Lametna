// ============================================================
//  لمّتنا — إعدادات لوحة التحكم
//  ⚠️ ضع هنا المفتاح العام (anon) فقط. لا تضع service_role إطلاقًا:
//     هذا الملف يُرسل إلى المتصفح ويمكن لأي شخص قراءته.
//  الصلاحيات تُفرض من RLS ومن دالة require_admin() في قاعدة البيانات.
// ============================================================
window.LAMETNA_CONFIG = {
  SUPABASE_URL: 'https://lvlrhbsafzepnqawlmud.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_wF1oNbuK5nyNwrTeZ3NVBw_C-b3SDg4',

  // حدود الخطة المجانية لعرض شريط الاستهلاك (قابلة للتعديل)
  FREE_TIER: {
    dbSizeMb: 500,
    monthlyActiveUsers: 50000,
    realtimeConcurrent: 200,
    edgeInvocations: 500000,
    storageMb: 1024,
  },
};
