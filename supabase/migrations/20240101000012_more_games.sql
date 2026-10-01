-- ============================================================
-- لمّتنا / Lametna — 0012 توسعة كتالوج الألعاب (8 ← 18 لعبة)
--
-- كل لعبة جديدة تعيد استخدام محرّكًا موجودًا بالفعل:
--   • إجابة واحدة : capitals, flags, riddles, islamic,
--                   sports, history, emoji_puzzle, fast_math
--   • محرك الكذاب : secret_job
--   • محرك القصة  : best_answer
-- لا منطق تسجيل نقاط جديد — فقط توسعة قوائم المفاتيح + بنك محتوى.
-- ============================================================

-- ============================================================
--  الألعاب الجديدة (10) — المجموع يصبح 18
-- ============================================================
insert into public.games (key, name_ar, name_en, description_ar, description_en, icon,
                          categories, min_players, max_players, default_rounds, round_seconds, sort_order) values
  ('capitals','عواصم ودول','Capitals',
   'ما عاصمة هذه الدولة؟ أسئلة سريعة عن دول العالم والوطن العربي.',
   'What is the capital of this country? Fast questions about the world.',
   '🏙️', '{global,fast,family}', 2, 16, 8, 25, 9),

  ('flags','أعلام الدول','Flags',
   'شاهد العلم وخمّن الدولة — من اليمن إلى أقصى العالم.',
   'See the flag and guess the country.',
   '🚩', '{global,fast,family}', 2, 16, 8, 25, 10),

  ('riddles','ألغاز وفوازير','Riddles',
   'فوازير شعبية وألغاز ذكاء — تلميحات تظهر تدريجيًا.',
   'Folk riddles and brain teasers with progressive hints.',
   '🧩', '{arabic,yemeni,family}', 2, 12, 6, 60, 11),

  ('islamic','معلومات دينية','Islamic Quiz',
   'أسئلة في القرآن والسيرة والفقه المبسّط.',
   'Questions on Quran, Seerah and basic fiqh.',
   '🕌', '{arabic,family}', 2, 16, 8, 30, 12),

  ('sports','رياضة','Sports',
   'كرة قدم وبطولات ولاعبون — للمشجعين فقط.',
   'Football, tournaments and players — for fans only.',
   '⚽', '{global,fast,competitive}', 2, 16, 8, 25, 13),

  ('history','تاريخ وحضارة','History',
   'تاريخ اليمن والعرب والعالم — أحداث وشخصيات ومعالم.',
   'Yemeni, Arab and world history — events, figures and landmarks.',
   '📜', '{arabic,yemeni,global}', 2, 16, 8, 30, 14),

  ('emoji_puzzle','إيموجي ولّغز','Emoji Puzzle',
   'رموز تعبيرية تختبئ خلفها كلمة أو مثل أو فيلم — خمّنها!',
   'Emojis hiding a word, a proverb or a movie — guess it!',
   '🤔', '{global,fast,family}', 2, 12, 8, 40, 15),

  ('fast_math','حساب سريع','Fast Math',
   'عمليات حسابية بسيطة والأسرع يكسب — لا آلة حاسبة!',
   'Simple arithmetic, fastest wins — no calculators!',
   '🔢', '{global,fast,competitive}', 2, 16, 10, 20, 16),

  ('secret_job','المهنة السرية','Secret Job',
   'الجميع يعرف المهنة إلا واحدًا. صِف عملك اليومي دون كشفها، ثم صوّتوا.',
   'Everyone knows the job except one. Describe your day without revealing it.',
   '🧑‍🔧', '{arabic,competitive}', 4, 12, 4, 60, 17),

  ('best_answer','أفضل جواب','Best Answer',
   'سؤال مفتوح، كل لاعب يكتب جوابه، ثم تصوّتون على الأطرف والأذكى.',
   'An open question — everyone answers, then you vote for the best.',
   '💡', '{family,arabic,global}', 3, 12, 5, 60, 18)
on conflict (key) do update set
  name_ar = excluded.name_ar, name_en = excluded.name_en,
  description_ar = excluded.description_ar, description_en = excluded.description_en,
  icon = excluded.icon, categories = excluded.categories,
  min_players = excluded.min_players, max_players = excluded.max_players,
  default_rounds = excluded.default_rounds, round_seconds = excluded.round_seconds,
  sort_order = excluded.sort_order;

-- ============================================================
--  بنك المحتوى
-- ============================================================

-- ---------- عواصم ودول ----------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, choices) values
  ('capitals','ar','yemen',1,'ما عاصمة اليمن؟','صنعاء','{"صنعا"}','["صنعاء","عدن","تعز","الحديدة"]'),
  ('capitals','ar','arab',1,'ما عاصمة السعودية؟','الرياض','{"رياض"}','["جدة","الرياض","مكة","الدمام"]'),
  ('capitals','ar','arab',1,'ما عاصمة مصر؟','القاهرة','{"قاهرة"}','["الإسكندرية","أسوان","القاهرة","الأقصر"]'),
  ('capitals','ar','arab',1,'ما عاصمة الأردن؟','عمّان','{"عمان"}','["إربد","عمّان","العقبة","الزرقاء"]'),
  ('capitals','ar','arab',2,'ما عاصمة المغرب؟','الرباط','{"رباط"}','["الدار البيضاء","مراكش","الرباط","فاس"]'),
  ('capitals','ar','arab',2,'ما عاصمة سلطنة عُمان؟','مسقط','{"مسقط"}','["صلالة","نزوى","مسقط","صحار"]'),
  ('capitals','ar','arab',2,'ما عاصمة السودان؟','الخرطوم','{"خرطوم"}','["بورتسودان","أم درمان","الخرطوم","كسلا"]'),
  ('capitals','ar','global',1,'ما عاصمة فرنسا؟','باريس','{}','["ليون","باريس","مرسيليا","نيس"]'),
  ('capitals','ar','global',1,'ما عاصمة اليابان؟','طوكيو','{}','["أوساكا","كيوتو","طوكيو","ناغويا"]'),
  ('capitals','ar','global',2,'ما عاصمة تركيا؟','أنقرة','{"انقرة"}','["إسطنبول","أنقرة","إزمير","بورصة"]'),
  ('capitals','ar','global',2,'ما عاصمة أستراليا؟','كانبيرا','{"كانبرا"}','["سيدني","ملبورن","كانبيرا","بيرث"]'),
  ('capitals','ar','global',3,'ما عاصمة كندا؟','أوتاوا','{"اوتاوا"}','["تورنتو","مونتريال","أوتاوا","فانكوفر"]'),
  ('capitals','en','global',1,'What is the capital of Yemen?','Sanaa','{"Sana''a"}','["Aden","Sanaa","Taiz","Hodeidah"]'),
  ('capitals','en','global',1,'What is the capital of Japan?','Tokyo','{}','["Osaka","Kyoto","Tokyo","Nagoya"]')
on conflict do nothing;

-- ---------- أعلام الدول ----------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, choices) values
  ('flags','ar','yemen',1,'🇾🇪 ما هذه الدولة؟','اليمن','{"يمن"}','["اليمن","سوريا","مصر","العراق"]'),
  ('flags','ar','arab',1,'🇸🇦 ما هذه الدولة؟','السعودية','{"سعودية"}','["السعودية","باكستان","الجزائر","موريتانيا"]'),
  ('flags','ar','arab',1,'🇦🇪 ما هذه الدولة؟','الإمارات','{"الامارات","امارات"}','["الكويت","الإمارات","الأردن","فلسطين"]'),
  ('flags','ar','arab',2,'🇴🇲 ما هذه الدولة؟','عُمان','{"عمان","سلطنة عمان"}','["قطر","البحرين","عُمان","الكويت"]'),
  ('flags','ar','arab',1,'🇪🇬 ما هذه الدولة؟','مصر','{}','["مصر","العراق","سوريا","اليمن"]'),
  ('flags','ar','arab',2,'🇲🇦 ما هذه الدولة؟','المغرب','{"مغرب"}','["تونس","المغرب","تركيا","الجزائر"]'),
  ('flags','ar','arab',2,'🇵🇸 ما هذه الدولة؟','فلسطين','{}','["الأردن","السودان","فلسطين","الكويت"]'),
  ('flags','ar','global',1,'🇯🇵 ما هذه الدولة؟','اليابان','{"يابان"}','["الصين","كوريا","اليابان","تايلاند"]'),
  ('flags','ar','global',1,'🇹🇷 ما هذه الدولة؟','تركيا','{}','["تونس","تركيا","باكستان","أذربيجان"]'),
  ('flags','ar','global',2,'🇧🇷 ما هذه الدولة؟','البرازيل','{"برازيل"}','["الأرجنتين","البرتغال","البرازيل","المكسيك"]'),
  ('flags','ar','global',2,'🇩🇪 ما هذه الدولة؟','ألمانيا','{"المانيا"}','["بلجيكا","ألمانيا","النمسا","هولندا"]'),
  ('flags','ar','global',3,'🇮🇩 ما هذه الدولة؟','إندونيسيا','{"اندونيسيا"}','["بولندا","موناكو","إندونيسيا","سنغافورة"]')
on conflict do nothing;

-- ---------- ألغاز وفوازير ---------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, hints) values
  ('riddles','ar','arab',1,'شيء كلما أخذت منه كبر. ما هو؟','الحفرة','{"حفرة","الحفره"}','{"موجود في الأرض","تحفره بيدك","كلما أخذت ترابه زاد حجمه"}'),
  ('riddles','ar','arab',1,'له أسنان ولا يعض. ما هو؟','المشط','{"مشط","الممشط"}','{"تستخدمه يوميًا","في الحمام","للشعر"}'),
  ('riddles','ar','arab',2,'يمشي بلا رجلين ويبكي بلا عينين. ما هو؟','السحاب','{"سحاب","الغيم","غيم"}','{"في السماء","يتحرك مع الريح","ينزل منه المطر"}'),
  ('riddles','ar','arab',1,'ما الشيء الذي يكتب ولا يقرأ؟','القلم','{"قلم"}','{"في جيبك","تمسكه بيدك","به حبر"}'),
  ('riddles','ar','arab',2,'بيت لا باب له ولا نافذة، وساكنه أصفر. ما هو؟','البيضة','{"بيضة","البيضه"}','{"من المطبخ","تأكله في الفطور","يخرج منه كتكوت"}'),
  ('riddles','ar','yemen',2,'شيء إن أطعمته عاش وإن سقيته مات. ما هو؟','النار','{"نار"}','{"حار جدًا","يُستخدم في الطبخ","يحتاج حطبًا"}'),
  ('riddles','ar','arab',2,'ما الشيء الذي كلما زاد نقص؟','العمر','{"عمر","السن"}','{"لا تراه","يزيد كل سنة","كلما كبرت قلّ ما تبقى منه"}'),
  ('riddles','ar','arab',3,'أخوان لا يلتقيان أبدًا مهما ساروا. ما هما؟','قضبان القطار','{"قضبان السكة","السكة","سكة القطار","القضبان"}','{"من حديد","خارج المدينة","يسير عليهما القطار"}'),
  ('riddles','ar','arab',1,'ما الشيء الذي يسمع بلا أذن ويتكلم بلا لسان؟','الهاتف','{"هاتف","التلفون","الجوال","الموبايل"}','{"جهاز","في جيبك","يصلك به صوت البعيد"}'),
  ('riddles','ar','arab',2,'يرتفع ولا ينزل أبدًا. ما هو؟','العمر','{"عمر","السن"}','{"لا يُرى","يزداد كل عام","لا يعود للوراء"}')
on conflict do nothing;

-- ---------- معلومات دينية ----------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, choices) values
  ('islamic','ar','arab',1,'كم عدد أركان الإسلام؟','خمسة','{"5","خمسه"}','["أربعة","خمسة","ستة","سبعة"]'),
  ('islamic','ar','arab',1,'ما أطول سورة في القرآن الكريم؟','البقرة','{"سورة البقرة"}','["آل عمران","النساء","البقرة","الكهف"]'),
  ('islamic','ar','arab',1,'كم عدد سور القرآن الكريم؟','114','{"مئة وأربعة عشر"}','["110","112","114","116"]'),
  ('islamic','ar','arab',2,'في أي شهر فُرض الصيام؟','رمضان','{"شهر رمضان"}','["شعبان","رمضان","شوال","محرم"]'),
  ('islamic','ar','arab',2,'ما أول سورة نزلت من القرآن؟','العلق','{"سورة العلق","اقرأ"}','["الفاتحة","العلق","المدثر","القلم"]'),
  ('islamic','ar','arab',1,'كم عدد ركعات صلاة المغرب؟','ثلاث','{"3","ثلاثة","ثلاث ركعات"}','["اثنتان","ثلاث","أربع","خمس"]'),
  ('islamic','ar','arab',2,'ما اسم الصحابي الملقب بأمين الأمة؟','أبو عبيدة بن الجراح','{"ابو عبيدة","أبو عبيدة"}','["أبو بكر","عمر بن الخطاب","أبو عبيدة بن الجراح","خالد بن الوليد"]'),
  ('islamic','ar','arab',2,'ما أقصر سورة في القرآن؟','الكوثر','{"سورة الكوثر"}','["الإخلاص","الكوثر","العصر","الناس"]'),
  ('islamic','ar','arab',1,'إلى أي جهة يتجه المسلمون في الصلاة؟','الكعبة','{"مكة","القبلة","البيت الحرام"}','["المسجد الأقصى","الكعبة","المسجد النبوي","جبل عرفات"]'),
  ('islamic','ar','arab',3,'كم عدد أجزاء القرآن الكريم؟','30','{"ثلاثون","ثلاثين"}','["20","25","30","40"]')
on conflict do nothing;

-- ---------- رياضة ----------------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, choices) values
  ('sports','ar','global',1,'كم عدد لاعبي فريق كرة القدم داخل الملعب؟','11','{"أحد عشر","احد عشر"}','["9","10","11","12"]'),
  ('sports','ar','global',1,'كل كم سنة تُقام بطولة كأس العالم؟','4','{"أربع","أربع سنوات"}','["2","3","4","5"]'),
  ('sports','ar','global',2,'ما الدولة التي فازت بكأس العالم 2022؟','الأرجنتين','{"الارجنتين"}','["فرنسا","البرازيل","الأرجنتين","ألمانيا"]'),
  ('sports','ar','arab',2,'ما الدولة العربية التي استضافت كأس العالم 2022؟','قطر','{}','["الإمارات","السعودية","قطر","المغرب"]'),
  ('sports','ar','arab',2,'أول منتخب عربي يصل إلى نصف نهائي كأس العالم؟','المغرب','{"مغرب"}','["السعودية","تونس","المغرب","مصر"]'),
  ('sports','ar','global',1,'كم عدد لاعبي فريق كرة السلة داخل الملعب؟','5','{"خمسة","خمس"}','["4","5","6","7"]'),
  ('sports','ar','global',2,'في أي رياضة يُستخدم مصطلح "لوف" (Love) للصفر؟','التنس','{"تنس","كرة المضرب"}','["الغولف","التنس","الكريكت","البولينغ"]'),
  ('sports','ar','global',2,'ما النادي الإسباني الملقب بالملكي؟','ريال مدريد','{"ريال","الريال"}','["برشلونة","أتلتيكو مدريد","ريال مدريد","إشبيلية"]'),
  ('sports','ar','global',3,'كم مدة شوط كرة القدم الواحد بالدقائق؟','45','{"خمسة وأربعون"}','["30","40","45","50"]'),
  ('sports','ar','global',2,'من يُلقب بـ"البرغوث" في كرة القدم؟','ميسي','{"ليونيل ميسي","messi"}','["رونالدو","ميسي","نيمار","مارادونا"]')
on conflict do nothing;

-- ---------- تاريخ وحضارة -----------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, choices) values
  ('history','ar','yemen',1,'ما اسم السد الشهير في اليمن القديم؟','سد مأرب','{"مأرب","سد مارب"}','["سد النهضة","سد مأرب","سد أسوان","سد الموصل"]'),
  ('history','ar','yemen',2,'ما اسم المملكة اليمنية القديمة التي حكمتها بلقيس؟','سبأ','{"مملكة سبأ","سبا"}','["حمير","سبأ","معين","قتبان"]'),
  ('history','ar','yemen',2,'أي مدينة يمنية تُلقب بـ"مانهاتن الصحراء"؟','شبام','{"شبام حضرموت"}','["زبيد","شبام","ثلا","جبلة"]'),
  ('history','ar','arab',1,'في أي عام هاجر النبي ﷺ إلى المدينة؟','622','{"622 م","622م"}','["610","622","630","632"]'),
  ('history','ar','arab',2,'من القائد المسلم الذي فتح الأندلس؟','طارق بن زياد','{"طارق"}','["خالد بن الوليد","عمرو بن العاص","طارق بن زياد","صلاح الدين"]'),
  ('history','ar','arab',2,'من حرّر القدس في معركة حطين؟','صلاح الدين الأيوبي','{"صلاح الدين"}','["نور الدين زنكي","صلاح الدين الأيوبي","قطز","بيبرس"]'),
  ('history','ar','global',2,'في أي عام انتهت الحرب العالمية الثانية؟','1945','{}','["1918","1939","1945","1950"]'),
  ('history','ar','global',2,'من أول إنسان وصل إلى سطح القمر؟','نيل آرمسترونغ','{"ارمسترونغ","نيل ارمسترونج"}','["يوري غاغارين","نيل آرمسترونغ","باز ألدرين","جون غلين"]'),
  ('history','ar','global',3,'ما الحضارة التي بنت الأهرامات؟','الفراعنة','{"المصريون القدماء","الفرعونية"}','["السومريون","الفراعنة","البابليون","الإغريق"]'),
  ('history','ar','arab',3,'ما أول عاصمة للدولة الأموية؟','دمشق','{"الشام"}','["بغداد","الكوفة","دمشق","المدينة"]')
on conflict do nothing;

-- ---------- إيموجي ولّغز ------------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers, hints) values
  ('emoji_puzzle','ar','yemen',1,'☕🇾🇪 = ؟','القهوة اليمنية','{"قهوة يمنية","البن اليمني","قهوة"}','{"مشروب","فخر اليمن","تُصدَّر للعالم"}'),
  ('emoji_puzzle','ar','arab',1,'🌙⭐🕌 = ؟','رمضان','{"شهر رمضان"}','{"شهر","صيام","يأتي مرة في السنة"}'),
  ('emoji_puzzle','ar','arab',1,'🦁👑 = ؟','ملك الغابة','{"الأسد","اسد","ملك الغاب"}','{"حيوان","مفترس","لقبه ملك"}'),
  ('emoji_puzzle','ar','global',2,'⚽🏆🌍 = ؟','كأس العالم','{"المونديال","كاس العالم"}','{"رياضة","كل أربع سنوات","بطولة"}'),
  ('emoji_puzzle','ar','arab',2,'📚🎓 = ؟','التخرج','{"تخرج","الدراسة","الجامعة"}','{"مناسبة","بعد سنوات دراسة","قبعة وشهادة"}'),
  ('emoji_puzzle','ar','arab',2,'🐪🏜️ = ؟','سفينة الصحراء','{"الجمل","جمل"}','{"حيوان","يتحمل العطش","لقبه سفينة"}'),
  ('emoji_puzzle','ar','global',2,'🍎📱💻 = ؟','آبل','{"apple","ابل","شركة آبل"}','{"شركة","تقنية","شعارها فاكهة"}'),
  ('emoji_puzzle','ar','arab',3,'🕐💰 = ؟','الوقت من ذهب','{"الوقت كالذهب","الوقت ذهب"}','{"مثل مشهور","عن الزمن","الذهب فيه"}'),
  ('emoji_puzzle','ar','global',1,'🌧️☂️ = ؟','المطر','{"مطر","الشتاء"}','{"طقس","ينزل من السماء","تحتاج معه مظلة"}'),
  ('emoji_puzzle','ar','arab',2,'🐦🤲 = ؟','عصفور في اليد','{"عصفور باليد","عصفور في اليد خير من عشرة على الشجرة"}','{"مثل","عن القناعة","فيه طائر"}')
on conflict do nothing;

-- ---------- حساب سريع ----------------------------------------------
insert into public.questions (game_key, locale, region, difficulty, body, answer, alt_answers) values
  ('fast_math','ar','global',1,'7 + 8 = ؟','15','{"خمسة عشر"}'),
  ('fast_math','ar','global',1,'12 × 3 = ؟','36','{"ستة وثلاثون"}'),
  ('fast_math','ar','global',1,'45 − 19 = ؟','26','{}'),
  ('fast_math','ar','global',2,'144 ÷ 12 = ؟','12','{"اثنا عشر"}'),
  ('fast_math','ar','global',2,'25 × 4 = ؟','100','{"مئة","مائة"}'),
  ('fast_math','ar','global',2,'9 × 9 = ؟','81','{"واحد وثمانون"}'),
  ('fast_math','ar','global',2,'٪20 من 150 = ؟','30','{"ثلاثون"}'),
  ('fast_math','ar','global',3,'17 × 6 = ؟','102','{}'),
  ('fast_math','ar','global',3,'(8 + 4) × 5 = ؟','60','{"ستون"}'),
  ('fast_math','ar','global',3,'√169 = ؟','13','{"ثلاثة عشر"}'),
  ('fast_math','en','global',1,'7 + 8 = ?','15','{}'),
  ('fast_math','en','global',2,'25 x 4 = ?','100','{}')
on conflict do nothing;

-- ---------- المهنة السرية (محرك الكذاب) -------------------------------
-- body = المهنة الحقيقية، metadata.decoy = المهنة التي يراها الكذاب
insert into public.questions (game_key, locale, region, difficulty, body, metadata) values
  ('secret_job','ar','arab',1,'طبيب','{"category":"مهن صحية","decoy":"ممرض"}'),
  ('secret_job','ar','arab',1,'معلم','{"category":"تعليم","decoy":"مدير مدرسة"}'),
  ('secret_job','ar','arab',1,'طبّاخ','{"category":"مطاعم","decoy":"نادل"}'),
  ('secret_job','ar','yemen',2,'بائع قات','{"category":"أسواق","decoy":"بائع خضار"}'),
  ('secret_job','ar','yemen',2,'صاحب مقهى','{"category":"أسواق","decoy":"بائع عصير"}'),
  ('secret_job','ar','arab',2,'مهندس معماري','{"category":"هندسة","decoy":"مقاول بناء"}'),
  ('secret_job','ar','arab',1,'سائق تاكسي','{"category":"مواصلات","decoy":"سائق حافلة"}'),
  ('secret_job','ar','arab',2,'صحفي','{"category":"إعلام","decoy":"مذيع"}'),
  ('secret_job','ar','arab',2,'مبرمج','{"category":"تقنية","decoy":"مصمم مواقع"}'),
  ('secret_job','ar','arab',1,'حلاق','{"category":"خدمات","decoy":"كوافير"}'),
  ('secret_job','ar','arab',2,'صيدلي','{"category":"مهن صحية","decoy":"طبيب أسنان"}'),
  ('secret_job','ar','arab',3,'محاسب','{"category":"إدارة","decoy":"موظف بنك"}')
on conflict do nothing;

-- ---------- أفضل جواب (محرك القصة الجماعية) ----------------------------
insert into public.questions (game_key, locale, region, difficulty, body) values
  ('best_answer','ar','arab',1,'لو امتلكت مليون ريال اليوم، ما أول شيء ستفعله؟'),
  ('best_answer','ar','yemen',1,'ما أفضل طبق يمني على الإطلاق ولماذا؟'),
  ('best_answer','ar','arab',1,'ما أغرب عذر سمعته في حياتك؟'),
  ('best_answer','ar','global',1,'لو استطعت السفر عبر الزمن، إلى أي سنة تذهب؟'),
  ('best_answer','ar','arab',1,'ما النصيحة التي تتمنى لو سمعتها قبل خمس سنوات؟'),
  ('best_answer','ar','yemen',2,'لو كنت وزيرًا ليوم واحد، ما أول قرار تتخذه؟'),
  ('best_answer','ar','arab',1,'ما أجمل مكان زرته في حياتك؟'),
  ('best_answer','ar','global',2,'لو اخترعت تطبيقًا جديدًا، ماذا سيفعل؟'),
  ('best_answer','ar','arab',1,'ما الشيء الذي لا تستطيع العيش بدونه؟'),
  ('best_answer','ar','arab',2,'صف نفسك بثلاث كلمات فقط.'),
  ('best_answer','ar','yemen',2,'ما أطرف موقف حدث لك في سوق شعبي؟'),
  ('best_answer','ar','global',1,'لو كان لك قوة خارقة واحدة، ماذا تختار؟')
on conflict do nothing;

-- ---------- إنجاز جديد ------------------------------------------------
insert into public.achievements (key, name_ar, name_en, description_ar, description_en, icon, points) values
  ('explorer','مستكشف الألعاب','Game Explorer','جرّبت 10 ألعاب مختلفة','Played 10 different games','🧭',100)
on conflict (key) do update set name_ar = excluded.name_ar;

-- إعادة تعريف دالتي توليد الجولة وحسمها لدعم الألعاب الجديدة.
-- لا تغيير في المنطق — توسعة قوائم المفاتيح فقط.

create or replace function public._begin_round(p_session uuid, p_index int)
returns public.rounds
language plpgsql security definer set search_path = public as $$
declare
  v_s        public.game_sessions;
  v_game     public.games;
  v_room     public.rooms;
  v_round    public.rounds;
  v_seconds  int;
  v_prompt   jsonb := '{}'::jsonb;
  v_secret   jsonb := '{}'::jsonb;
  v_phase    round_phase := 'collecting';
  v_letters  constant text[] := array['ا','ب','ت','ج','ح','خ','د','ر','س','ش','ص','ط','ع','ف','ق','ك','ل','م','ن','ه','و','ي'];
  v_q        public.questions;
  v_players  uuid[];
  v_liar     uuid;
  v_assign   jsonb := '{}'::jsonb;
  v_pid      uuid;
  v_i        int := 0;
begin
  select * into v_s from public.game_sessions where id = p_session;
  select * into v_room from public.rooms where id = v_s.room_id;
  select * into v_game from public.games where key = v_s.game_key;
  v_seconds := coalesce((v_s.config ->> 'round_seconds')::int, v_game.round_seconds);

  select array_agg(user_id order by seat) into v_players
    from public.room_players
   where room_id = v_s.room_id and left_at is null and not is_spectator and is_alive;

  if v_s.game_key = 'animal_plant_object' then
    v_prompt := jsonb_build_object(
      'stage','answer',
      'letter', v_letters[1 + floor(random() * array_length(v_letters,1))::int],
      'categories', coalesce(v_s.config -> 'categories',
        '["name","animal","plant","object","country","city","food","job"]'::jsonb)
    );

  elsif v_s.game_key = 'mafia' then
    if p_index % 2 = 1 then
      v_phase := 'night';
      v_seconds := coalesce((v_s.config ->> 'night_seconds')::int, 45);
      v_prompt := jsonb_build_object('stage','night','cycle', (p_index + 1) / 2);
    else
      v_phase := 'voting';
      v_seconds := coalesce((v_s.config ->> 'day_seconds')::int, 120);
      v_prompt := jsonb_build_object('stage','day','cycle', p_index / 2);
    end if;

  elsif v_s.game_key in ('true_false','guess_word','proverbs','who_am_i','capitals','flags','riddles','islamic','sports','history','emoji_puzzle','fast_math') then
    select * into v_q from public.questions
     where game_key = v_s.game_key and is_active and locale = v_room.locale
       and id <> all (coalesce(
             (select array_agg((r.prompt ->> 'question_id')::bigint)
                from public.rounds r
               where r.session_id = p_session and r.prompt ? 'question_id'), '{}'::bigint[]))
     order by random() limit 1;
    if v_q.id is null then
      select * into v_q from public.questions
       where game_key = v_s.game_key and is_active order by random() limit 1;
    end if;
    if v_q.id is null then raise exception 'NO_CONTENT_FOR_GAME'; end if;

    v_prompt := jsonb_build_object(
      'stage','answer',
      'question_id', v_q.id,
      'body', v_q.body,
      'choices', v_q.choices,
      -- guess_word reveals hints progressively on the client using a server clock
      'hints', case when v_s.game_key in ('guess_word','riddles') then to_jsonb(v_q.hints) else '[]'::jsonb end,
      'metadata', v_q.metadata
    );
    v_secret := jsonb_build_object('answer', v_q.answer, 'alt', to_jsonb(v_q.alt_answers));

  elsif v_s.game_key in ('liar','secret_job') then
    select * into v_q from public.questions where game_key = v_s.game_key and is_active
     order by random() limit 1;
    if v_q.id is null then raise exception 'NO_CONTENT_FOR_GAME'; end if;
    v_liar := v_players[1 + floor(random() * array_length(v_players,1))::int];
    foreach v_pid in array v_players loop
      v_assign := v_assign || jsonb_build_object(
        v_pid::text,
        case when v_pid = v_liar then coalesce(v_q.metadata ->> 'decoy', '') else v_q.body end);
    end loop;
    v_prompt := jsonb_build_object('stage','describe', 'category', coalesce(v_q.metadata ->> 'category',''));
    v_secret := jsonb_build_object('liar', v_liar, 'word', v_q.body, 'assignments', v_assign);

  elsif v_s.game_key in ('group_story','best_answer') then
    select * into v_q from public.questions where game_key = v_s.game_key and is_active
     order by random() limit 1;
    v_prompt := jsonb_build_object('stage','write',
                'opening', coalesce(v_q.body, 'كان يا ما كان…'));
  else
    raise exception 'UNKNOWN_GAME %', v_s.game_key;
  end if;

  insert into public.rounds (session_id, round_index, phase, prompt, secret_data, starts_at, ends_at)
  values (p_session, p_index, v_phase, v_prompt, v_secret, now(), now() + make_interval(secs => v_seconds))
  returning * into v_round;

  update public.game_sessions set current_round = p_index where id = p_session;
  perform public.touch_room(v_s.room_id);
  return v_round;
end $$;

create or replace function public.resolve_round(p_round uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_round   public.rounds;
  v_s       public.game_sessions;
  v_room    uuid;
  v_alive   int;
  v_submitted int;
  v_result  jsonb := '{}'::jsonb;
  v_stage   text;
  v_letter  text;
  v_cats    text[];
  v_cat     text;
  v_ans     record;
  v_val     text;
  v_norm    text;
  v_dups    jsonb;
  v_pts     int;
  v_rank    int;
  v_killed  uuid;
  v_saved   boolean := false;
  v_lynched uuid;
  v_top     int;
  v_winner  text;
  v_liar    uuid;
  v_accused uuid;
  v_correct boolean;
  v_fuzzy   boolean;
begin
  select * into v_round from public.rounds where id = p_round for update;
  if not found then raise exception 'ROUND_NOT_FOUND'; end if;
  if v_round.resolved_at is not null then return coalesce(v_round.result, '{}'::jsonb); end if;

  select * into v_s from public.game_sessions where id = v_round.session_id;
  v_room := v_s.room_id;
  if not public.is_room_member(v_room) and not public.is_admin() then
    -- also allow the service role (Edge Function cron) which has no auth.uid()
    if auth.uid() is not null then raise exception 'NOT_A_MEMBER'; end if;
  end if;

  select count(*) into v_alive from public.room_players
   where room_id = v_room and left_at is null and not is_spectator and is_alive;

  v_stage := coalesce(v_round.prompt ->> 'stage', 'answer');

  -- Early resolution is allowed only when everyone who *can* act has acted.
  if now() < v_round.ends_at then
    if v_stage in ('answer','describe','write') then
      select count(*) into v_submitted from public.answers where round_id = p_round;
    elsif v_stage in ('vote','day') then
      select count(distinct voter_id) into v_submitted from public.votes where round_id = p_round;
    elsif v_stage = 'night' then
      select count(*) into v_submitted from public.mafia_actions where round_id = p_round;
      select count(*) into v_alive from public.mafia_roles
       where session_id = v_s.id and is_alive and role <> 'citizen';
    else
      v_submitted := 0;
    end if;
    if v_submitted < v_alive then
      return jsonb_build_object('pending', true, 'ends_at', v_round.ends_at);
    end if;
  end if;

  -- =========================================================
  -- جماد حيوان نبات  /  Animal-Plant-Object
  -- =========================================================
  if v_s.game_key = 'animal_plant_object' then
    v_letter := v_round.prompt ->> 'letter';
    select array_agg(value::text) into v_cats
      from jsonb_array_elements_text(v_round.prompt -> 'categories') as t(value);

    v_dups := '{}'::jsonb;
    foreach v_cat in array v_cats loop
      -- count normalised duplicates per category
      v_dups := v_dups || jsonb_build_object(v_cat, coalesce((
        select jsonb_object_agg(n, c) from (
          select public.normalize_ar(a.payload ->> v_cat) as n, count(*) as c
            from public.answers a
           where a.round_id = p_round and coalesce(a.payload ->> v_cat,'') <> ''
           group by 1
        ) d), '{}'::jsonb));
    end loop;

    for v_ans in select * from public.answers where round_id = p_round loop
      v_pts := 0;
      foreach v_cat in array v_cats loop
        v_val  := coalesce(v_ans.payload ->> v_cat, '');
        v_norm := public.normalize_ar(v_val);
        if v_norm <> '' and left(v_norm, 1) = public.normalize_ar(v_letter) then
          if coalesce(((v_dups -> v_cat) ->> v_norm)::int, 1) > 1 then
            v_pts := v_pts + 5;
          else
            v_pts := v_pts + 10;
          end if;
        end if;
      end loop;
      perform public._award(p_round, v_ans.user_id, v_pts);
    end loop;

    -- optional speed bonus for the first valid submission
    if coalesce((v_s.config ->> 'speed_bonus')::boolean, true) then
      perform public._award(p_round, (
        select user_id from public.answers where round_id = p_round
         order by elapsed_ms asc nulls last limit 1), 5);
    end if;

    select jsonb_build_object('stage','scored','letter', v_letter,
             'answers', coalesce(jsonb_agg(jsonb_build_object(
               'user_id', a.user_id, 'nickname', p.nickname,
               'payload', a.payload, 'points', a.points) order by a.points desc), '[]'::jsonb))
      into v_result
      from public.answers a join public.profiles p on p.id = a.user_id
     where a.round_id = p_round;

  -- =========================================================
  -- صح/خطأ، خمن الكلمة، الأمثال، من أنا  (single correct answer)
  -- =========================================================
  elsif v_s.game_key in ('true_false','guess_word','proverbs','who_am_i','capitals','flags','riddles','islamic','sports','history','emoji_puzzle','fast_math') then
    v_fuzzy := v_s.game_key in ('proverbs','who_am_i','guess_word','riddles','emoji_puzzle');
    v_rank := 0;
    for v_ans in
      select a.*, p.nickname from public.answers a join public.profiles p on p.id = a.user_id
       where a.round_id = p_round order by a.elapsed_ms asc nulls last
    loop
      v_correct := public.answer_matches(
        v_ans.payload ->> 'value',
        v_round.secret_data ->> 'answer',
        (select array_agg(x) from jsonb_array_elements_text(coalesce(v_round.secret_data -> 'alt','[]'::jsonb)) t(x)),
        v_fuzzy);
      if v_correct then
        v_rank := v_rank + 1;
        v_pts := 10 + case v_rank when 1 then 5 when 2 then 3 when 3 then 1 else 0 end;
      else
        v_pts := 0;
      end if;
      perform public._award(p_round, v_ans.user_id, v_pts);
      update public.answers set payload = payload || jsonb_build_object('correct', v_correct)
       where id = v_ans.id;
    end loop;

    select jsonb_build_object('stage','scored',
             'correct_answer', v_round.secret_data ->> 'answer',
             'answers', coalesce(jsonb_agg(jsonb_build_object(
               'user_id', a.user_id, 'nickname', p.nickname,
               'value', a.payload ->> 'value',
               'correct', coalesce((a.payload ->> 'correct')::boolean,false),
               'points', a.points) order by a.points desc), '[]'::jsonb))
      into v_result
      from public.answers a join public.profiles p on p.id = a.user_id
     where a.round_id = p_round;

  -- =========================================================
  -- الكذاب بيننا  /  The liar among us  (2 stages)
  -- =========================================================
  elsif v_s.game_key in ('liar','secret_job') then
    if v_stage = 'describe' then
      update public.rounds
         set prompt = prompt || jsonb_build_object('stage','vote',
                        'descriptions', coalesce((
                          select jsonb_agg(jsonb_build_object(
                                   'user_id', a.user_id, 'nickname', p.nickname,
                                   'text', a.payload ->> 'value'))
                            from public.answers a join public.profiles p on p.id = a.user_id
                           where a.round_id = p_round), '[]'::jsonb)),
             ends_at = now() + interval '60 seconds'
       where id = p_round;
      perform public.touch_room(v_room);
      return jsonb_build_object('stage','vote','advanced', true);
    end if;

    v_liar := (v_round.secret_data ->> 'liar')::uuid;
    select target_user, count(*) into v_accused, v_top from public.votes
     where round_id = p_round and kind = 'liar'
     group by target_user order by count(*) desc limit 1;

    for v_ans in select voter_id, target_user from public.votes where round_id = p_round and kind = 'liar' loop
      if v_ans.target_user = v_liar then perform public._award(p_round, v_ans.voter_id, 10); end if;
    end loop;
    if v_accused is distinct from v_liar then
      perform public._award(p_round, v_liar, 20);
    end if;

    v_result := jsonb_build_object('stage','scored',
      'liar', v_liar, 'word', v_round.secret_data ->> 'word',
      'accused', v_accused, 'caught', (v_accused is not distinct from v_liar));

  -- =========================================================
  -- القصة الجماعية  /  Group story  (write → vote)
  -- =========================================================
  elsif v_s.game_key in ('group_story','best_answer') then
    if v_stage = 'write' then
      update public.rounds
         set prompt = prompt || jsonb_build_object('stage','vote',
                        'lines', coalesce((
                          select jsonb_agg(jsonb_build_object(
                                   'user_id', a.user_id, 'nickname', p.nickname,
                                   'text', a.payload ->> 'value') order by a.created_at)
                            from public.answers a join public.profiles p on p.id = a.user_id
                           where a.round_id = p_round), '[]'::jsonb)),
             ends_at = now() + interval '45 seconds'
       where id = p_round;
      perform public.touch_room(v_room);
      return jsonb_build_object('stage','vote','advanced', true);
    end if;

    for v_ans in select a.user_id, count(v.id) as votes
                   from public.answers a
                   left join public.votes v on v.round_id = p_round
                        and v.kind = 'story_line' and v.target_user = a.user_id
                  where a.round_id = p_round group by a.user_id
    loop
      perform public._award(p_round, v_ans.user_id, 5 + (v_ans.votes * 5)::int);
    end loop;

    select jsonb_build_object('stage','scored','lines', v_round.prompt -> 'lines',
             'best', (select v.target_user from public.votes v
                       where v.round_id = p_round and v.kind = 'story_line'
                       group by v.target_user order by count(*) desc limit 1))
      into v_result;

  -- =========================================================
  -- المافيا  /  Mafia
  -- =========================================================
  elsif v_s.game_key = 'mafia' then
    if v_round.phase = 'night' then
      -- mafia pick by internal majority; ties broken randomly
      select target_id into v_killed from public.mafia_actions
       where round_id = p_round and action = 'kill'
       group by target_id order by count(*) desc, random() limit 1;

      if v_killed is not null then
        v_saved := exists (select 1 from public.mafia_actions
                            where round_id = p_round and action in ('heal','protect')
                              and target_id = v_killed);
        if not v_saved then
          update public.mafia_roles set is_alive = false, died_round = v_round.round_index
           where session_id = v_s.id and user_id = v_killed;
          update public.room_players set is_alive = false, state = 'dead'
           where room_id = v_room and user_id = v_killed;
        end if;
      end if;

      v_result := jsonb_build_object(
        'stage','night_result',
        'killed', case when v_killed is not null and not v_saved then v_killed else null end,
        'killed_nickname', case when v_killed is not null and not v_saved
                                then (select nickname from public.profiles where id = v_killed) end,
        'saved', v_saved);
    else
      -- day: lynch by plurality; a tie means nobody is lynched
      select target_user, count(*) into v_lynched, v_top from public.votes
       where round_id = p_round and kind = 'lynch' and target_user is not null
       group by target_user order by count(*) desc limit 1;

      if v_lynched is not null and (
           select count(*) from (
             select count(*) c from public.votes
              where round_id = p_round and kind = 'lynch' and target_user is not null
              group by target_user having count(*) = v_top) t) > 1 then
        v_lynched := null; -- tie
      end if;

      if v_lynched is not null then
        update public.mafia_roles set is_alive = false, died_round = v_round.round_index, revealed = true
         where session_id = v_s.id and user_id = v_lynched;
        update public.room_players set is_alive = false, state = 'dead'
         where room_id = v_room and user_id = v_lynched;
      end if;

      v_result := jsonb_build_object(
        'stage','day_result', 'lynched', v_lynched,
        'lynched_nickname', (select nickname from public.profiles where id = v_lynched),
        'lynched_role', (select role from public.mafia_roles
                          where session_id = v_s.id and user_id = v_lynched),
        'votes', coalesce((select jsonb_agg(jsonb_build_object('target', target_user, 'count', c))
                             from (select target_user, count(*) c from public.votes
                                    where round_id = p_round and kind = 'lynch'
                                    group by target_user) t), '[]'::jsonb));
    end if;

    -- survival points
    update public.room_players set score = score + 5
     where room_id = v_room and is_alive and not is_spectator and left_at is null;
  end if;

  -- ---------- close the round -------------------------------
  update public.rounds
     set resolved_at = now(), phase = 'revealed', result = v_result
   where id = p_round;
  perform public.touch_room(v_room);

  -- ---------- advance the session ----------------------------
  if v_s.game_key = 'mafia' then
    v_winner := public._mafia_check_win(v_s.id);
    if v_winner is not null then
      update public.mafia_roles set revealed = true where session_id = v_s.id;
      v_result := v_result || jsonb_build_object('game_over', true, 'winning_side', v_winner,
        'final', public._finish_session(v_s.id,
          (select array_agg(user_id) from public.mafia_roles
            where session_id = v_s.id and ((v_winner = 'mafia' and role = 'mafia')
                                        or (v_winner = 'citizens' and role <> 'mafia'))),
          'mafia_' || v_winner));
    else
      perform public._begin_round(v_s.id, v_round.round_index + 1);
    end if;
  else
    if v_round.round_index >= v_s.total_rounds then
      v_result := v_result || jsonb_build_object('game_over', true,
        'final', public._finish_session(v_s.id, null, 'rounds_complete'));
    else
      perform public._begin_round(v_s.id, v_round.round_index + 1);
    end if;
  end if;

  update public.rounds set result = v_result where id = p_round;
  return v_result;
end $$;
