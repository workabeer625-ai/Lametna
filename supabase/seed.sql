-- ============================================================
-- لمّتنا / Lametna — Seed data
-- Idempotent: safe to re-run (`supabase db reset` or psql -f).
-- ============================================================

-- ---------- avatars (bundled in assets/avatars/) --------------
insert into public.avatars (key, name_ar, name_en, sort_order) values
  ('coffee',  'قهوة',    'Coffee',  1),
  ('lion',    'أسد',     'Lion',    2),
  ('falcon',  'صقر',     'Falcon',  3),
  ('camel',   'جمل',     'Camel',   4),
  ('star',    'نجمة',    'Star',    5),
  ('moon',    'قمر',     'Moon',    6),
  ('palm',    'نخلة',    'Palm',    7),
  ('jambiya', 'جنبية',   'Jambiya', 8),
  ('lantern', 'فانوس',   'Lantern', 9),
  ('mountain','جبل',     'Mountain',10),
  ('sea',     'بحر',     'Sea',     11),
  ('book',    'كتاب',    'Book',    12)
on conflict (key) do update set name_ar = excluded.name_ar, name_en = excluded.name_en;

-- ---------- countries -----------------------------------------
insert into public.countries (code, name_ar, name_en, flag_emoji, region) values
  ('YE','اليمن','Yemen','🇾🇪','arab'),
  ('SA','السعودية','Saudi Arabia','🇸🇦','arab'),
  ('AE','الإمارات','UAE','🇦🇪','arab'),
  ('EG','مصر','Egypt','🇪🇬','arab'),
  ('OM','عُمان','Oman','🇴🇲','arab'),
  ('QA','قطر','Qatar','🇶🇦','arab'),
  ('KW','الكويت','Kuwait','🇰🇼','arab'),
  ('BH','البحرين','Bahrain','🇧🇭','arab'),
  ('JO','الأردن','Jordan','🇯🇴','arab'),
  ('SY','سوريا','Syria','🇸🇾','arab'),
  ('LB','لبنان','Lebanon','🇱🇧','arab'),
  ('IQ','العراق','Iraq','🇮🇶','arab'),
  ('PS','فلسطين','Palestine','🇵🇸','arab'),
  ('SD','السودان','Sudan','🇸🇩','arab'),
  ('LY','ليبيا','Libya','🇱🇾','arab'),
  ('TN','تونس','Tunisia','🇹🇳','arab'),
  ('DZ','الجزائر','Algeria','🇩🇿','arab'),
  ('MA','المغرب','Morocco','🇲🇦','arab'),
  ('MR','موريتانيا','Mauritania','🇲🇷','arab'),
  ('SO','الصومال','Somalia','🇸🇴','arab'),
  ('DJ','جيبوتي','Djibouti','🇩🇯','arab'),
  ('KM','جزر القمر','Comoros','🇰🇲','arab'),
  ('TR','تركيا','Turkey','🇹🇷','other'),
  ('MY','ماليزيا','Malaysia','🇲🇾','other'),
  ('ID','إندونيسيا','Indonesia','🇮🇩','other'),
  ('IN','الهند','India','🇮🇳','other'),
  ('PK','باكستان','Pakistan','🇵🇰','other'),
  ('GB','بريطانيا','United Kingdom','🇬🇧','other'),
  ('US','أمريكا','United States','🇺🇸','other'),
  ('DE','ألمانيا','Germany','🇩🇪','other'),
  ('FR','فرنسا','France','🇫🇷','other'),
  ('CA','كندا','Canada','🇨🇦','other'),
  ('AU','أستراليا','Australia','🇦🇺','other'),
  ('ZZ','دولة أخرى','Other','🌍','other')
on conflict (code) do update set name_ar = excluded.name_ar;

-- ---------- games ------------------------------------------------
insert into public.games (key, name_ar, name_en, description_ar, description_en, icon,
                          categories, min_players, max_players, default_rounds, round_seconds, sort_order) values
  ('animal_plant_object','جماد حيوان نبات','Categories',
   'حرف عشوائي وفئات متعددة — اكتب بسرعة قبل انتهاء الوقت.',
   'A random letter and multiple categories — write fast before the timer ends.',
   '✍️', '{arabic,family,fast,competitive}', 2, 12, 5, 90, 1),

  ('mafia','المافيا','Mafia',
   'ليل ونهار، أدوار سرية، نقاش وتصويت. من المافيا بيننا؟',
   'Night and day, secret roles, discussion and voting. Who is the mafia?',
   '🕵️', '{global,competitive}', 5, 16, 40, 120, 2),

  ('who_am_i','من أنا؟','Who Am I?',
   'شخصية سرية وأسئلة بنعم أو لا حتى تصل إلى التخمين الصحيح.',
   'A secret character and yes/no questions until you guess right.',
   '❓', '{arabic,global,family}', 3, 10, 5, 120, 3),

  ('true_false','صح أم خطأ','True or False',
   'معلومات عربية ويمنية وعالمية — أجب بسرعة واكسب نقاطًا.',
   'Arab, Yemeni and world facts — answer fast and score.',
   '✅', '{global,fast,family}', 2, 16, 8, 25, 4),

  ('guess_word','خمن الكلمة','Guess the Word',
   'تلميحات تظهر تدريجيًا، وكلما أسرعت زادت نقاطك.',
   'Hints reveal progressively — the faster you are, the more points you get.',
   '🔤', '{arabic,fast,competitive}', 2, 12, 6, 60, 5),

  ('liar','الكذاب بيننا','The Liar',
   'الجميع يعرف الكلمة إلا واحدًا. صِف الكلمة دون كشفها، ثم صوّتوا.',
   'Everyone knows the word except one. Describe it without revealing it, then vote.',
   '🎭', '{arabic,competitive}', 4, 12, 4, 60, 6),

  ('proverbs','أكمل المثل','Finish the Proverb',
   'أمثال عربية ويمنية — أكمل المثل، ونقبل أكثر من رواية.',
   'Arab and Yemeni proverbs — complete them; several variants are accepted.',
   '📜', '{yemeni,arabic,family}', 2, 12, 8, 40, 7),

  ('group_story','القصة الجماعية','Group Story',
   'كل لاعب يضيف جملة، ثم تصوّتون على أجمل جملة.',
   'Each player adds a sentence, then you vote for the best one.',
   '📖', '{family,arabic}', 3, 10, 4, 90, 8)
on conflict (key) do update set
  name_ar = excluded.name_ar, name_en = excluded.name_en,
  description_ar = excluded.description_ar, description_en = excluded.description_en,
  categories = excluded.categories, min_players = excluded.min_players,
  max_players = excluded.max_players, round_seconds = excluded.round_seconds;

-- ---------- achievements ------------------------------------------
insert into public.achievements (key, name_ar, name_en, description_ar, description_en, icon, points) values
  ('first_win','أول انتصار','First Win','فزت بأول مباراة لك','Won your first match','🥇',50),
  ('mafia_king','ملك المافيا','Mafia King','فزت 3 مرات في المافيا','Won 3 mafia matches','🕶️',150),
  ('fast_answer','أسرع إجابة','Fastest Answer','كنت الأسرع في جولة','Fastest answer in a round','⚡',30),
  ('apo_expert','خبير جماد حيوان','Categories Expert','300 نقطة في جماد حيوان نبات','300 points in Categories','✍️',100),
  ('proverbs_champion','بطل الأمثال','Proverbs Champion','فزت 3 مرات في أكمل المثل','Won 3 proverb matches','📜',100),
  ('active_player','لاعب نشيط','Active Player','لعبت 20 مباراة','Played 20 matches','🔥',80),
  ('streak_master','فوز متتالي','Win Streak','3 انتصارات متتالية','3 wins in a row','🏆',120)
on conflict (key) do update set name_ar = excluded.name_ar;

-- ---------- moderation dictionary (extend from the admin panel) ------
insert into public.banned_words (word, severity, locale) values
  ('كلب',1,'ar'), ('حمار',1,'ar'), ('غبي',1,'ar'), ('حقير',2,'ar'),
  ('يلعن',2,'ar'), ('قذر',2,'ar'), ('خنزير',2,'ar'), ('تافه',1,'ar'),
  ('idiot',1,'en'), ('stupid',1,'en'), ('moron',2,'en')
on conflict (word) do nothing;

-- ============================================================
--  CONTENT BANK
-- ============================================================

-- ---------- صح أم خطأ / True-False ----------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, choices) values
  ('true_false','ar','yemen',1,'صنعاء القديمة مدرجة في قائمة التراث العالمي لليونسكو.','صح','["صح","خطأ"]'),
  ('true_false','ar','yemen',1,'سقطرى جزيرة يمنية تشتهر بشجرة دم الأخوين.','صح','["صح","خطأ"]'),
  ('true_false','ar','yemen',2,'عدن عاصمة اليمن الحالية المعترف بها دستوريًا.','خطأ','["صح","خطأ"]'),
  ('true_false','ar','yemen',1,'السلطة والبنة من الأكلات اليمنية المشهورة.','صح','["صح","خطأ"]'),
  ('true_false','ar','yemen',2,'جبل النبي شعيب أعلى قمة في شبه الجزيرة العربية.','صح','["صح","خطأ"]'),
  ('true_false','ar','arab',1,'نهر النيل أطول نهر في أفريقيا.','صح','["صح","خطأ"]'),
  ('true_false','ar','arab',1,'الرياض عاصمة المملكة العربية السعودية.','صح','["صح","خطأ"]'),
  ('true_false','ar','arab',2,'مدينة البتراء تقع في لبنان.','خطأ','["صح","خطأ"]'),
  ('true_false','ar','arab',1,'اللغة العربية تُكتب من اليمين إلى اليسار.','صح','["صح","خطأ"]'),
  ('true_false','ar','global',1,'الشمس نجم.','صح','["صح","خطأ"]'),
  ('true_false','ar','global',1,'الماء يتجمد عند 100 درجة مئوية.','خطأ','["صح","خطأ"]'),
  ('true_false','ar','global',2,'كوكب المشتري أكبر كواكب المجموعة الشمسية.','صح','["صح","خطأ"]'),
  ('true_false','ar','global',2,'الحوت الأزرق أكبر حيوان على وجه الأرض.','صح','["صح","خطأ"]'),
  ('true_false','ar','global',3,'عدد عظام جسم الإنسان البالغ 206 عظمة.','صح','["صح","خطأ"]'),
  ('true_false','en','global',1,'The Sun is a star.','True','["True","False"]'),
  ('true_false','en','global',1,'Water freezes at 100 degrees Celsius.','False','["True","False"]'),
  ('true_false','en','yemen',1,'Socotra is a Yemeni island famous for the dragon blood tree.','True','["True","False"]'),
  ('true_false','en','global',2,'Jupiter is the largest planet in the Solar System.','True','["True","False"]')
on conflict do nothing;

-- ---------- أكمل المثل / Proverbs -------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers) values
  ('proverbs','ar','arab',1,'الصديق وقت …','الضيق','{"الضيقة","وقت الضيق"}'),
  ('proverbs','ar','arab',1,'في التأني السلامة وفي العجلة …','الندامة','{"الندم"}'),
  ('proverbs','ar','arab',1,'من جدّ …','وجد','{"وجد ومن زرع حصد"}'),
  ('proverbs','ar','arab',2,'الطيور على أشكالها …','تقع','{}'),
  ('proverbs','ar','arab',1,'خير الكلام ما قلّ …','ودلّ','{"و دل","ودل"}'),
  ('proverbs','ar','arab',2,'رُبَّ أخٍ لك لم …','تلده أمك','{"تلده امك"}'),
  ('proverbs','ar','arab',2,'عصفور في اليد خير من عشرة على …','الشجرة','{"شجرة"}'),
  ('proverbs','ar','yemen',2,'اللي ما يعرف الصقر …','يشويه','{"يشويهـ","يشوية"}'),
  ('proverbs','ar','yemen',2,'من طلب العلا سهر …','الليالي','{"الليل"}'),
  ('proverbs','ar','yemen',3,'الجار قبل …','الدار','{}'),
  ('proverbs','ar','yemen',2,'ما كل ما يتمنى المرء …','يدركه','{"يدركهـ"}'),
  ('proverbs','ar','yemen',3,'اللي ما له أول ما له …','تالي','{"آخر","اخر"}'),
  ('proverbs','ar','arab',1,'الوقت من …','ذهب','{"الذهب"}'),
  ('proverbs','ar','arab',2,'إن كان الكلام من فضة فالسكوت من …','ذهب','{"الذهب"}')
on conflict do nothing;

-- ---------- خمن الكلمة / Guess the Word ---------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, hints) values
  ('guess_word','ar','yemen',1,'خمّن الكلمة','صنعاء','{"صنعا"}','{"مدينة عربية","عاصمة تاريخية","مدينتها القديمة تراث عالمي","تشتهر بباب اليمن"}'),
  ('guess_word','ar','yemen',2,'خمّن الكلمة','سقطرى','{"سقطرا","سوقطرى"}','{"مكان في اليمن","جزيرة","بها نباتات نادرة","شجرة دم الأخوين"}'),
  ('guess_word','ar','yemen',1,'خمّن الكلمة','المندي','{"مندي"}','{"أكلة","تُطهى تحت الأرض","معها أرز","لحم أو دجاج"}'),
  ('guess_word','ar','arab',1,'خمّن الكلمة','القهوة','{"قهوة","البن"}','{"مشروب","لونه غامق","يمني الأصل","تشرب في الصباح"}'),
  ('guess_word','ar','arab',2,'خمّن الكلمة','الأهرامات','{"اهرامات","الاهرامات"}','{"معلم أثري","في مصر","مثلثة الشكل","من عجائب الدنيا"}'),
  ('guess_word','ar','global',2,'خمّن الكلمة','الإنترنت','{"انترنت","الانترنت"}','{"اختراع حديث","يربط العالم","يحتاج اتصالًا","تستخدمه الآن"}'),
  ('guess_word','ar','global',1,'خمّن الكلمة','الشمس','{"شمس"}','{"جرم سماوي","مصدر ضوء","نراها نهارًا","نجم"}'),
  ('guess_word','ar','arab',2,'خمّن الكلمة','الجنبية','{"جنبية"}','{"قطعة تراثية","تُلبس في الوسط","يمنية","خنجر"}'),
  ('guess_word','en','global',1,'Guess the word','coffee','{"café"}','{"a drink","dark colour","originally from Yemen","morning ritual"}'),
  ('guess_word','en','global',2,'Guess the word','pyramid','{"pyramids"}','{"a monument","in Egypt","triangular","ancient wonder"}')
on conflict do nothing;

-- ---------- من أنا؟ / Who Am I --------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, metadata) values
  ('who_am_i','ar','yemen',2,'شخصية يمنية','عبده خال','{}','{"category":"أدب"}'),
  ('who_am_i','ar','yemen',1,'شخصية يمنية','أبو بكر سالم','{"ابو بكر سالم"}','{"category":"فن"}'),
  ('who_am_i','ar','yemen',2,'شخصية يمنية','توكل كرمان','{}','{"category":"مجتمع"}'),
  ('who_am_i','ar','yemen',2,'شخصية يمنية تاريخية','بلقيس','{"ملكة سبأ","بلقيس ملكة سبا"}','{"category":"تاريخ"}'),
  ('who_am_i','ar','arab',1,'شخصية عربية','أحمد شوقي','{"احمد شوقي","أمير الشعراء"}','{"category":"أدب"}'),
  ('who_am_i','ar','arab',1,'شخصية عربية','نجيب محفوظ','{}','{"category":"أدب"}'),
  ('who_am_i','ar','arab',2,'شخصية عربية','ابن بطوطة','{}','{"category":"رحالة"}'),
  ('who_am_i','ar','arab',1,'شخصية عربية','أم كلثوم','{"ام كلثوم"}','{"category":"فن"}'),
  ('who_am_i','ar','global',1,'شخصية عالمية','ألبرت أينشتاين','{"اينشتاين","albert einstein"}','{"category":"علوم"}'),
  ('who_am_i','ar','global',1,'شخصية عالمية','ليونيل ميسي','{"ميسي","messi"}','{"category":"رياضة"}'),
  ('who_am_i','ar','global',2,'شخصية عالمية','نيلسون مانديلا','{"مانديلا"}','{"category":"سياسة"}'),
  ('who_am_i','ar','global',2,'شخصية عالمية','ابن سينا','{"avicenna"}','{"category":"طب"}')
on conflict do nothing;

-- ---------- الكذاب بيننا / Liar words --------------------------------
-- body = the real word, metadata.decoy = the word given to the liar
insert into public.questions (game_key, locale, region, difficulty, body, metadata) values
  ('liar','ar','yemen',1,'المندي','{"category":"أكلات","decoy":"الكبسة"}'),
  ('liar','ar','yemen',1,'صنعاء','{"category":"مدن","decoy":"تعز"}'),
  ('liar','ar','yemen',2,'الجنبية','{"category":"تراث","decoy":"العمامة"}'),
  ('liar','ar','arab',1,'القهوة','{"category":"مشروبات","decoy":"الشاي"}'),
  ('liar','ar','arab',1,'المدرسة','{"category":"أماكن","decoy":"الجامعة"}'),
  ('liar','ar','arab',2,'الطائرة','{"category":"مواصلات","decoy":"القطار"}'),
  ('liar','ar','global',1,'كرة القدم','{"category":"رياضة","decoy":"كرة السلة"}'),
  ('liar','ar','global',2,'الهاتف','{"category":"أجهزة","decoy":"الحاسوب"}'),
  ('liar','ar','arab',1,'رمضان','{"category":"مناسبات","decoy":"العيد"}'),
  ('liar','ar','yemen',2,'البن اليمني','{"category":"منتجات","decoy":"التمر"}')
on conflict do nothing;

-- ---------- القصة الجماعية / Group story openings -----------------------
insert into public.questions (game_key, locale, region, difficulty, body) values
  ('group_story','ar','yemen',1,'في زقاق قديم من أزقة صنعاء، فتح رجلٌ بابًا لم يُفتح منذ أربعين سنة…'),
  ('group_story','ar','arab',1,'وصلت رسالة إلى هاتف الجميع في اللحظة نفسها، وكان مكتوبًا فيها سطر واحد…'),
  ('group_story','ar','global',1,'استيقظ سكان المدينة ذات صباح فوجدوا أن الساعات كلها توقفت عند الرقم نفسه…'),
  ('group_story','ar','yemen',1,'في سوق الملح، باع تاجرٌ صندوقًا مغلقًا واشترط ألا يُفتح قبل الغروب…'),
  ('group_story','ar','arab',1,'قرر أصدقاء الطفولة أن يجتمعوا بعد عشرين عامًا، لكن أحدهم لم يأتِ…')
on conflict do nothing;
