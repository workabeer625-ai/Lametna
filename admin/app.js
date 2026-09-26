// ============================================================
//  لمّتنا — لوحة تحكم المشرفين (SPA ثابتة، بدون خادم)
//
//  الأمان: هذه الصفحة تستخدم المفتاح العام (anon) فقط.
//  كل عملية إدارية تمر عبر RLS ودوال SECURITY DEFINER التي
//  تتحقق من public.is_admin(). إخفاء الأزرار هنا راحة للمستخدم
//  وليس حاجزًا أمنيًا.
// ============================================================
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const CFG = window.LAMETNA_CONFIG || {};
const configured =
  CFG.SUPABASE_URL &&
  CFG.SUPABASE_ANON_KEY &&
  !CFG.SUPABASE_URL.includes('YOUR-PROJECT-REF') &&
  !CFG.SUPABASE_ANON_KEY.includes('YOUR_PUBLIC');

const sb = configured
  ? createClient(CFG.SUPABASE_URL, CFG.SUPABASE_ANON_KEY, {
      auth: { persistSession: true, autoRefreshToken: true, storageKey: 'lametna-admin' },
    })
  : null;

const $ = (id) => document.getElementById(id);
const el = (tag, cls, text) => {
  const n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text !== undefined) n.textContent = text;
  return n;
};
const esc = (v) => (v === null || v === undefined ? '' : String(v));

let me = null; // { id, nickname, role }

// ---------- أدوات واجهة ----------
function toast(msg, kind = 'ok') {
  const t = $('toast');
  t.textContent = msg;
  t.className = `toast ${kind}`;
  setTimeout(() => t.classList.add('hidden'), 3200);
}

function fmtDate(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleString('ar', { dateStyle: 'short', timeStyle: 'short' });
}

function fmtAgo(iso) {
  if (!iso) return '—';
  const s = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 60) return 'الآن';
  if (s < 3600) return `قبل ${Math.floor(s / 60)} د`;
  if (s < 86400) return `قبل ${Math.floor(s / 3600)} س`;
  return `قبل ${Math.floor(s / 86400)} يوم`;
}

function errText(e) {
  const m = e?.message || String(e);
  if (m.includes('FORBIDDEN')) return 'ليست لديك صلاحية لهذه العملية.';
  if (m.includes('NOT_FOUND')) return 'العنصر غير موجود.';
  if (m.includes('Invalid login')) return 'البريد أو كلمة المرور غير صحيحة.';
  return m;
}

// ---------- الدخول ----------
async function signIn(ev) {
  ev.preventDefault();
  if (!sb) return;
  const btn = $('login-btn');
  btn.disabled = true;
  btn.textContent = 'جارٍ الدخول…';
  $('login-error').classList.add('hidden');
  try {
    const { error } = await sb.auth.signInWithPassword({
      email: $('login-email').value.trim(),
      password: $('login-password').value,
    });
    if (error) throw error;
    await afterAuth();
  } catch (e) {
    $('login-error').textContent = errText(e);
    $('login-error').classList.remove('hidden');
  } finally {
    btn.disabled = false;
    btn.textContent = 'دخول';
  }
}

async function afterAuth() {
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return showLogin();

  const { data: profile, error } = await sb
    .from('profiles')
    .select('id, nickname, role')
    .eq('id', user.id)
    .maybeSingle();

  if (error || !profile || !['admin', 'moderator'].includes(profile.role)) {
    await sb.auth.signOut();
    showLogin('هذا الحساب ليس مشرفًا. الدخول مرفوض.');
    return;
  }

  me = profile;
  $('who').textContent = `${profile.nickname} · ${user.email}`;
  $('role-chip').textContent = profile.role === 'admin' ? 'مدير' : 'مشرف';
  $('view-login').classList.add('hidden');
  $('view-dashboard').classList.remove('hidden');
  await loadTab('overview');
}

function showLogin(msg) {
  $('view-dashboard').classList.add('hidden');
  $('view-login').classList.remove('hidden');
  if (msg) {
    $('login-error').textContent = msg;
    $('login-error').classList.remove('hidden');
  }
}

// ---------- نظرة عامة ----------
const STAT_LABELS = {
  users_total: 'إجمالي اللاعبين',
  users_guests: 'حسابات الضيوف',
  users_new_7d: 'جدد (7 أيام)',
  rooms_open: 'غرف مفتوحة',
  rooms_playing: 'غرف تلعب الآن',
  sessions_24h: 'مباريات (24 س)',
  messages_24h: 'رسائل (24 س)',
  reports_open: 'بلاغات مفتوحة',
  bans_global: 'حظر عام',
  questions_total: 'أسئلة نشطة',
};

async function loadOverview() {
  const grid = $('stat-grid');
  grid.innerHTML = '';
  const { data, error } = await sb.rpc('admin_stats');
  if (error) return toast(errText(error), 'err');

  for (const [key, label] of Object.entries(STAT_LABELS)) {
    const card = el('div', 'stat');
    card.append(el('span', 'stat-value', Number(data[key] ?? 0).toLocaleString('ar')));
    card.append(el('span', 'stat-label', label));
    if (key === 'reports_open' && Number(data[key]) > 0) card.classList.add('alert');
    grid.append(card);
  }

  const quotas = $('quota-list');
  quotas.innerHTML = '';
  const limits = CFG.FREE_TIER || {};
  const rows = [
    ['الغرف المفتوحة المتزامنة', Number(data.rooms_open ?? 0), limits.realtimeConcurrent, 'اتصال'],
    ['اللاعبون المسجّلون', Number(data.users_total ?? 0), limits.monthlyActiveUsers, 'مستخدم'],
  ];
  for (const [label, value, max, unit] of rows) {
    if (!max) continue;
    const pct = Math.min(100, Math.round((value / max) * 100));
    const row = el('div', 'quota');
    row.append(el('div', 'quota-label', `${label}: ${value.toLocaleString('ar')} / ${max.toLocaleString('ar')} ${unit}`));
    const bar = el('div', 'bar');
    const fill = el('div', 'bar-fill');
    fill.style.width = `${pct}%`;
    if (pct > 80) fill.classList.add('hot');
    bar.append(fill);
    row.append(bar);
    quotas.append(row);
  }
}

// ---------- البلاغات ----------
async function loadReports() {
  const box = $('reports-list');
  box.innerHTML = '<p class="muted">جارٍ التحميل…</p>';
  let q = sb
    .from('reports')
    .select('id, reason, details, status, created_at, handled_at, room_id, message_id, reporter_id, reported_id')
    .order('created_at', { ascending: false })
    .limit(100);
  const status = $('report-status').value;
  if (status) q = q.eq('status', status);

  const { data, error } = await q;
  if (error) { box.innerHTML = ''; return toast(errText(error), 'err'); }
  if (!data.length) { box.innerHTML = '<p class="muted">لا توجد بلاغات.</p>'; return; }

  const names = await nicknamesFor([
    ...data.map((r) => r.reporter_id),
    ...data.map((r) => r.reported_id),
  ]);

  box.innerHTML = '';
  for (const r of data) {
    const item = el('div', 'item');
    const head = el('div', 'item-head');
    head.append(el('span', 'badge ' + r.status, r.status));
    head.append(el('strong', '', `${names[r.reported_id] ?? '—'}`));
    head.append(el('span', 'muted tiny', `بلاغ من ${names[r.reporter_id] ?? '—'} · ${fmtAgo(r.created_at)}`));
    item.append(head);
    item.append(el('div', 'item-body', `السبب: ${esc(r.reason)}${r.details ? ' — ' + esc(r.details) : ''}`));

    if (r.status === 'open' || r.status === 'reviewing') {
      const actions = el('div', 'item-actions');
      actions.append(actionBtn('معالجة بدون حظر', 'ghost', () => resolveReport(r.id, 'resolved', null)));
      actions.append(actionBtn('حظر 3 أيام', 'warn', () => resolveReport(r.id, 'resolved', 3)));
      actions.append(actionBtn('حظر 30 يومًا', 'warn', () => resolveReport(r.id, 'resolved', 30)));
      if (me.role === 'admin') {
        actions.append(actionBtn('حظر دائم', 'danger', () => resolveReport(r.id, 'resolved', 0)));
      }
      actions.append(actionBtn('رفض البلاغ', 'ghost', () => resolveReport(r.id, 'rejected', null)));
      item.append(actions);
    } else {
      item.append(el('div', 'muted tiny', `عولج ${fmtDate(r.handled_at)}`));
    }
    box.append(item);
  }
}

async function resolveReport(id, status, banDays) {
  if (banDays === 0 && !confirm('حظر دائم لهذا الحساب. متأكد؟')) return;
  const { error } = await sb.rpc('admin_resolve_report', {
    p_report: id,
    p_status: status,
    p_ban_days: banDays,
  });
  if (error) return toast(errText(error), 'err');
  toast('تم تنفيذ الإجراء');
  loadReports();
}

// ---------- الغرف ----------
async function loadRooms() {
  const box = $('rooms-list');
  box.innerHTML = '<p class="muted">جارٍ التحميل…</p>';
  let q = sb
    .from('rooms')
    .select('id, code, title, game_key, status, is_public, max_players, created_at, last_activity_at, closed_at, host_id, room_players(count)')
    .order('last_activity_at', { ascending: false })
    .limit(100);
  if ($('rooms-open-only').checked) q = q.is('closed_at', null);
  const term = $('room-search').value.trim();
  if (term) q = q.or(`code.ilike.%${term}%,title.ilike.%${term}%`);

  const { data, error } = await q;
  if (error) { box.innerHTML = ''; return toast(errText(error), 'err'); }
  if (!data.length) { box.innerHTML = '<p class="muted">لا توجد غرف.</p>'; return; }

  box.innerHTML = '';
  for (const r of data) {
    const item = el('div', 'item');
    const head = el('div', 'item-head');
    head.append(el('code', 'code', r.code));
    head.append(el('strong', '', esc(r.title) || r.game_key));
    head.append(el('span', 'badge ' + r.status, r.status));
    head.append(el('span', 'muted tiny', `${r.room_players?.[0]?.count ?? 0}/${r.max_players} · ${r.is_public ? 'عامة' : 'خاصة'} · ${fmtAgo(r.last_activity_at)}`));
    item.append(head);
    if (!r.closed_at && me.role === 'admin') {
      const actions = el('div', 'item-actions');
      actions.append(actionBtn('إغلاق الغرفة', 'danger', () => closeRoom(r.id)));
      item.append(actions);
    }
    box.append(item);
  }
}

async function closeRoom(id) {
  if (!confirm('إغلاق هذه الغرفة وإخراج اللاعبين؟')) return;
  const { error } = await sb
    .from('rooms')
    .update({ status: 'cancelled', closed_at: new Date().toISOString() })
    .eq('id', id);
  if (error) return toast(errText(error), 'err');
  toast('أُغلقت الغرفة');
  loadRooms();
}

// ---------- اللاعبون ----------
async function loadPlayers() {
  const box = $('players-list');
  box.innerHTML = '<p class="muted">جارٍ التحميل…</p>';
  let q = sb
    .from('profiles')
    .select('id, nickname, avatar_key, country_code, role, is_guest, total_points, games_played, created_at, deleted_at')
    .order('total_points', { ascending: false })
    .limit(100);
  const term = $('player-search').value.trim();
  if (term) q = q.ilike('nickname', `%${term}%`);

  const { data, error } = await q;
  if (error) { box.innerHTML = ''; return toast(errText(error), 'err'); }
  box.innerHTML = '';
  if (!data.length) { box.innerHTML = '<p class="muted">لا نتائج.</p>'; return; }

  for (const p of data) {
    const item = el('div', 'item');
    const head = el('div', 'item-head');
    head.append(el('strong', '', esc(p.nickname)));
    if (p.country_code) head.append(el('span', 'chip', p.country_code));
    if (p.is_guest) head.append(el('span', 'chip', 'ضيف'));
    if (p.role !== 'player') head.append(el('span', 'chip role', p.role));
    if (p.deleted_at) head.append(el('span', 'badge rejected', 'محذوف'));
    head.append(el('span', 'muted tiny', `${p.total_points} نقطة · ${p.games_played} مباراة · انضم ${fmtAgo(p.created_at)}`));
    item.append(head);

    if (me.role === 'admin' && !p.deleted_at && p.id !== me.id) {
      const actions = el('div', 'item-actions');
      actions.append(actionBtn('حظر 7 أيام', 'warn', () => banUser(p.id, 7)));
      actions.append(actionBtn('حظر دائم', 'danger', () => banUser(p.id, 0)));
      item.append(actions);
    }
    box.append(item);
  }
}

async function banUser(userId, days) {
  const reason = prompt('سبب الحظر:');
  if (reason === null) return;
  const { error } = await sb.from('bans').insert({
    user_id: userId,
    scope: 'global',
    reason: reason || 'admin',
    created_by: me.id,
    expires_at: days === 0 ? null : new Date(Date.now() + days * 86400000).toISOString(),
  });
  if (error) return toast(errText(error), 'err');
  toast('تم الحظر');
  loadPlayers();
}

// ---------- الحظر ----------
async function loadBans() {
  const box = $('bans-list');
  box.innerHTML = '<p class="muted">جارٍ التحميل…</p>';
  const { data, error } = await sb
    .from('bans')
    .select('id, user_id, room_id, scope, reason, created_at, expires_at, created_by')
    .order('created_at', { ascending: false })
    .limit(100);
  if (error) { box.innerHTML = ''; return toast(errText(error), 'err'); }
  if (!data.length) { box.innerHTML = '<p class="muted">لا توجد حالات حظر.</p>'; return; }

  const names = await nicknamesFor(data.flatMap((b) => [b.user_id, b.created_by]));
  box.innerHTML = '';
  for (const b of data) {
    const expired = b.expires_at && new Date(b.expires_at) < new Date();
    const item = el('div', 'item');
    const head = el('div', 'item-head');
    head.append(el('strong', '', names[b.user_id] ?? b.user_id.slice(0, 8)));
    head.append(el('span', 'badge ' + (expired ? 'resolved' : 'open'), expired ? 'منتهٍ' : b.scope === 'global' ? 'عام' : 'غرفة'));
    head.append(el('span', 'muted tiny', `${esc(b.reason)} · بواسطة ${names[b.created_by] ?? '—'} · ${fmtAgo(b.created_at)}`));
    item.append(head);
    item.append(el('div', 'muted tiny', b.expires_at ? `ينتهي ${fmtDate(b.expires_at)}` : 'دائم'));
    if (me.role === 'admin' && !expired) {
      const actions = el('div', 'item-actions');
      actions.append(actionBtn('رفع الحظر', 'ghost', () => unban(b.id)));
      item.append(actions);
    }
    box.append(item);
  }
}

async function unban(id) {
  const { error } = await sb.from('bans').delete().eq('id', id);
  if (error) return toast(errText(error), 'err');
  toast('رُفع الحظر');
  loadBans();
}

// ---------- سجل العمليات ----------
async function loadAudit() {
  const box = $('audit-list');
  box.innerHTML = '<p class="muted">جارٍ التحميل…</p>';
  const { data, error } = await sb
    .from('audit_logs')
    .select('id, actor_id, action, entity, entity_id, metadata, created_at')
    .order('created_at', { ascending: false })
    .limit(150);
  if (error) { box.innerHTML = ''; return toast(errText(error), 'err'); }
  if (!data.length) { box.innerHTML = '<p class="muted">السجل فارغ.</p>'; return; }

  const names = await nicknamesFor(data.map((a) => a.actor_id));
  box.innerHTML = '';
  for (const a of data) {
    const item = el('div', 'item compact');
    const head = el('div', 'item-head');
    head.append(el('code', 'code', a.action));
    head.append(el('span', '', `${a.entity ?? ''} ${a.entity_id ?? ''}`.trim()));
    head.append(el('span', 'muted tiny', `${names[a.actor_id] ?? 'النظام'} · ${fmtDate(a.created_at)}`));
    item.append(head);
    box.append(item);
  }
}

// ---------- مساعدات ----------
async function nicknamesFor(ids) {
  const unique = [...new Set(ids.filter(Boolean))];
  if (!unique.length) return {};
  const { data } = await sb.from('profiles').select('id, nickname').in('id', unique);
  return Object.fromEntries((data ?? []).map((p) => [p.id, p.nickname]));
}

function actionBtn(label, kind, onClick) {
  const b = el('button', `btn small ${kind}`, label);
  b.addEventListener('click', async () => {
    b.disabled = true;
    try { await onClick(); } finally { b.disabled = false; }
  });
  return b;
}

// ---------- التبويبات ----------
let currentTab = 'overview';
const LOADERS = {
  overview: loadOverview,
  reports: loadReports,
  rooms: loadRooms,
  players: loadPlayers,
  bans: loadBans,
  audit: loadAudit,
};

async function loadTab(tab) {
  currentTab = tab;
  document.querySelectorAll('.tab').forEach((t) =>
    t.classList.toggle('active', t.dataset.tab === tab));
  document.querySelectorAll('.panel').forEach((p) =>
    p.classList.toggle('active', p.id === `tab-${tab}`));
  try {
    await LOADERS[tab]();
  } catch (e) {
    toast(errText(e), 'err');
  }
}

// ---------- الإقلاع ----------
function debounce(fn, ms = 350) {
  let t;
  return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); };
}

function boot() {
  if (!configured) {
    $('config-warning').classList.remove('hidden');
    $('login-btn').disabled = true;
    return;
  }
  $('login-form').addEventListener('submit', signIn);
  $('logout-btn').addEventListener('click', async () => {
    await sb.auth.signOut();
    me = null;
    location.reload();
  });
  $('refresh-btn').addEventListener('click', () => loadTab(currentTab));
  $('tabs').addEventListener('click', (e) => {
    const tab = e.target.closest('.tab');
    if (tab) loadTab(tab.dataset.tab);
  });
  $('report-status').addEventListener('change', loadReports);
  $('rooms-open-only').addEventListener('change', loadRooms);
  $('room-search').addEventListener('input', debounce(loadRooms));
  $('player-search').addEventListener('input', debounce(loadPlayers));

  sb.auth.getSession().then(({ data }) => {
    if (data.session) afterAuth();
  });
}

boot();
