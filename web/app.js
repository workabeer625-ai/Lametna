"use strict";

const sections = {
  comprehension: { title: "الفهم والاستيعاب", icon: "١", color: "var(--primary)" },
  vocabulary: { title: "الأصوات والمفردات", icon: "٢", color: "var(--yellow)" },
  structure: { title: "الأنماط والتراكيب", icon: "٣", color: "var(--purple)" },
  writing: { title: "التعبير والكتابة", icon: "٤", color: "var(--blue)" }
};

const units = [
  {
    id: "u1", number: 1, title: "قيم إسلامية", color: "#2f9b83", pages: "٨–٣٩",
    lessons: ["أخلاقنا", "زيارة الأقارب", "حسن الجوار", "الإحسان إلى الوالدين"],
    models: [
      {
        id: "u1-a", level: "تأسيسي", name: "النموذج الأول", focus: "فهم المقروء والقيم السلوكية",
        questions: [
          choice("إلى أين ذهب آدم وأخته آسية؟", ["إلى الحديقة", "إلى المكتبة", "إلى المدرسة", "إلى القرية"], 1, "أخلاقنا"),
          choice("ماذا يُسمّى ما فعله آدم حين أعطى المرأة العجوز مكانه؟", ["الإيثار", "الإهمال", "التبذير", "الكسل"], 0, "أخلاقنا"),
          choice("ماذا تُسمّى زيارة الأهل والأقارب؟", ["حسن الجوار", "صلة الرحم", "قيمة العمل", "النظافة"], 1, "زيارة الأقارب"),
          choice("أين كان جار هيثم المريض؟", ["في المدرسة", "في السوق", "في المستشفى", "في القرية"], 2, "حسن الجوار"),
          choice("اختر الكلمة التي تبدأ بصوت الحرف نفسه في كلمة «جار».", ["جبل", "بيت", "ثمر", "ولد"], 0, "الأصوات", "vocabulary"),
          choice("أكمل: بِرُّ الوالدين رمز أخلاقي و____.", ["ديني", "بعيد", "قصير", "ثقيل"], 0, "الإحسان إلى الوالدين", "vocabulary"),
          order("رتّب الكلمات لتكوّن جملة مفيدة.", ["جاره", "زار", "هيثم", "المريض"], "زار هيثم جاره المريض", "حسن الجوار"),
          choice("اختر الجملة الصحيحة.", ["الأقارب نزور في العيد", "نزور الأقارب في العيد", "في الأقارب العيد نزور", "العيد في نزور الأقارب"], 1, "زيارة الأقارب", "structure"),
          choice("الإحسان إلى الوالدين خُلُقٌ كريم.", ["صحيح", "خطأ"], 0, "الإحسان إلى الوالدين", "structure"),
          write("اكتب بخط جميل جملةً عن خُلُقٍ حسن تحب أن تتحلّى به.", "مثال: أساعد الكبير وأحترم والديّ.", "الخط والتعبير")
        ]
      },
      {
        id: "u1-b", level: "متوسط", name: "النموذج الثاني", focus: "المفردات وترتيب الجمل",
        questions: [
          choice("لماذا بقيت المرأة العجوز واقفة في الحافلة؟", ["لأنها نسيت حقيبتها", "لأنها لم تجد مقعدًا فارغًا", "لأنها أرادت النزول", "لأنها كانت تنتظر آدم"], 1, "أخلاقنا"),
          choice("بماذا تلقّى أهل القرية نبيلًا وأسرته؟", ["بالغضب", "بالصمت", "بالترحيب", "بالعتاب"], 2, "زيارة الأقارب"),
          choice("ماذا جمعت هاني وبَيان من البساتين؟", ["باقات الزهور", "أكياس الحلوى", "أقلامًا", "كتبًا"], 0, "زيارة الأقارب"),
          choice("متى زار والد هيثم الجار بعد عودته إلى المنزل؟", ["في اليوم الثالث", "بعد أسبوع", "في الشهر التالي", "قبل سفره"], 0, "حسن الجوار"),
          choice("اختر عكس كلمة «مريض».", ["سليم", "متعب", "حزين", "بعيد"], 0, "المفردات", "vocabulary"),
          choice("أي كلمة تناسب الصورة الذهنية 🏥؟", ["مكتبة", "مستشفى", "بستان", "منزل"], 1, "المفردات", "vocabulary"),
          order("رتّب الكلمات.", ["للرحم", "الأقارب", "صلة", "زيارة"], "زيارة الأقارب صلة للرحم", "زيارة الأقارب"),
          text("أكمل بالكلمة المناسبة: أحسنْ إلى ____.", ["والديك", "الوالدين"], "الإحسان إلى الوالدين", "structure"),
          choice("أي سلوك يدل على حسن الجوار؟", ["إزعاج الجار", "زيارة الجار المريض", "رفع الصوت", "رمي النفايات"], 1, "حسن الجوار", "structure"),
          write("اكتب جملة قصيرة تصف فيها كيف تساعد والديك في المنزل.", "مثال: أرتب غرفتي وأساعد أمي.", "التعبير")
        ]
      },
      {
        id: "u1-c", level: "إتقان", name: "النموذج الثالث", focus: "مراجعة شاملة للوحدة",
        questions: [
          choice("لماذا مرض جار هيثم؟", ["لأنه سافر طويلًا", "لأنه تناول ثمارًا غير مغسولة", "لأنه لم ينم", "لأنه لعب في الحديقة"], 1, "حسن الجوار"),
          choice("ماذا فعل هيثم في اليوم التالي عندما عرف أن جاره في المستشفى؟", ["نسي الأمر", "بحث عنه في المستشفى", "ذهب إلى السوق", "عاد إلى المدرسة"], 1, "حسن الجوار"),
          choice("ما القيمة التي نتعلمها من موقف آدم؟", ["الإيثار", "الكسل", "الخوف", "الإسراف"], 0, "أخلاقنا"),
          choice("إلى ماذا يدعونا نشيد «الإحسان إلى الوالدين»؟", ["اللعب", "بر الوالدين", "السفر", "جمع الزهور"], 1, "الإحسان إلى الوالدين"),
          choice("ما جمع كلمة «جار»؟", ["جيران", "جوارٌ", "جاريات", "أجور"], 0, "المفردات", "vocabulary"),
          choice("أي كلمة تبدأ بحرف الحاء؟", ["حَسَن", "جَمَل", "خالد", "سعيد"], 0, "الأصوات", "vocabulary"),
          order("رتّب الكلمات.", ["مكارم", "من", "الإيمان", "الأخلاق"], "الإيمان من مكارم الأخلاق", "أخلاقنا"),
          choice("اختر الفعل المناسب: ____ نبيلٌ أقاربه في العيد.", ["زار", "يزرع", "كتب", "رسم"], 0, "الأنماط", "structure"),
          choice("الجملة الصحيحة هي:", ["شكرَت المرأةُ آدمَ", "شكرَ المرأةُ آدمَ", "آدمَ المرأةُ شكرت", "المرأةَ شكرتْ آدمُ"], 0, "الأنماط", "structure"),
          write("اكتب نصيحة من سطر واحد لصديقك عن بر الوالدين أو حسن الجوار.", "اكتب جملة واضحة تبدأ بفعل مناسب.", "التعبير")
        ]
      }
    ]
  },
  {
    id: "u2", number: 2, title: "قيم إنسانية", color: "#a069bd", pages: "٣٩–٧٠",
    lessons: ["الحرية", "قيمة العمل", "الصدق", "المستقبل"],
    models: [
      {
        id: "u2-a", level: "تأسيسي", name: "النموذج الأول", focus: "الحرية والعمل والصدق",
        questions: [
          choice("ماذا طلب الكلب السمين من الكلب الهزيل؟", ["أن يترك الحديقة", "أن يعيش معه", "أن يعطيه السلسلة", "أن يذهب إلى القرية"], 1, "الحرية"),
          choice("لماذا كان صاحب الكلب السمين يربطه ليلًا؟", ["ليحرسه", "ليمنعه من الطعام", "ليعلمه القراءة", "ليأخذه للسوق"], 0, "الحرية"),
          choice("ماذا اختار خليل من تركة أبيه؟", ["الأرض", "كيس الذهب", "منزلًا", "كتابًا"], 1, "قيمة العمل"),
          choice("ماذا اختار خالد؟", ["الأرض", "الذهب", "السلسلة", "السيارة"], 0, "قيمة العمل"),
          choice("اختر عكس كلمة «الحرية».", ["القيد", "العمل", "الصدق", "النجاح"], 0, "المفردات", "vocabulary"),
          choice("أي كلمة تدل على إنجاز مفيد؟", ["عمل", "كسل", "نوم", "لهو"], 0, "المفردات", "vocabulary"),
          order("رتّب الكلمات.", ["الثروة", "يزيد", "العمل", "والخير"], "العمل يزيد الثروة والخير", "قيمة العمل"),
          choice("أكمل: الصدق ____ صاحبه.", ["ينجي", "يؤذي", "يؤخر", "يُغضب"], 0, "الصدق", "structure"),
          choice("اختار خالد الأرض فعمل فيها وزرعها.", ["صحيح", "خطأ"], 0, "قيمة العمل", "structure"),
          write("اكتب عملًا نافعًا تتمنى أن تقوم به في المستقبل.", "مثال: أتعلم جيدًا لأصبح طبيبًا نافعًا.", "المستقبل")
        ]
      },
      {
        id: "u2-b", level: "متوسط", name: "النموذج الثاني", focus: "فهم الأحداث وبناء الجملة",
        questions: [
          choice("ماذا نسيت خديجة أن تكتب؟", ["الواجب الحسابي", "القصة التي طلبتها المعلمة", "رسالة لصديقتها", "نشيد المستقبل"], 1, "الصدق"),
          choice("ما العذر غير الصحيح الذي اقترحته دلال؟", ["أن أم خديجة في المستشفى", "أن خديجة كانت نائمة", "أن الكتاب ضاع", "أنها زارت القرية"], 0, "الصدق"),
          choice("ماذا فعلت خديجة بعد سماع كلام دلال؟", ["ضحكت", "فكرت في كلامها", "خرجت من المدرسة", "كتبت الكذبة"], 1, "الصدق"),
          choice("ماذا يطلب الطفل في نشيد المستقبل؟", ["العلم الكثير", "المال فقط", "اللعب طوال اليوم", "السفر"], 0, "المستقبل"),
          choice("اختر عكس كلمة «صغير».", ["قريب", "كبير", "قصير", "قليل"], 1, "المفردات", "vocabulary"),
          choice("أي كلمتين لهما معنى متقارب؟", ["الصدق والأمانة", "الحرية والقيد", "العمل والكسل", "الصغير والكبير"], 0, "المفردات", "vocabulary"),
          order("رتّب الكلمات.", ["للعلم", "سوف", "والاجتهاد", "أسعى"], "سوف أسعى للعلم والاجتهاد", "المستقبل"),
          choice("اختر الفعل المناسب: ____ خالدٌ الأرضَ.", ["زرع", "ربط", "كذب", "نسي"], 0, "قيمة العمل", "structure"),
          choice("الكلب الهزيل فضّل الحرية على الطعام.", ["صحيح", "خطأ"], 0, "الحرية", "structure"),
          write("اكتب جملةً تبين فيها لماذا تحب الصدق.", "مثال: أحب الصدق لأنه ينجي صاحبه.", "الصدق")
        ]
      },
      {
        id: "u2-c", level: "إتقان", name: "النموذج الثالث", focus: "مراجعة شاملة للوحدة",
        questions: [
          choice("لماذا رفض الكلب الهزيل أن يعيش مع الكلب السمين؟", ["لأنه يكره الطعام", "لأنه يحب الحرية", "لأنه يخاف البيت", "لأنه يريد سلسلة"], 1, "الحرية"),
          choice("ماذا حدث لذهب خليل؟", ["ازداد", "تحول إلى أرض", "أنفقه حتى انتهى", "أعطاه لخالد"], 2, "قيمة العمل"),
          choice("كيف صارت ثروة خالد؟", ["تزداد يومًا بعد يوم", "انتهت سريعًا", "بقيت كما هي", "ضاعت"], 0, "قيمة العمل"),
          choice("ما القرار الصحيح لخديجة؟", ["قول الحقيقة للمعلمة", "الكذب", "ترك المدرسة", "لوم دلال"], 0, "الصدق"),
          choice("ما مفرد «أعمال»؟", ["عَمَل", "عامل", "عميل", "معمول"], 0, "المفردات", "vocabulary"),
          choice("أي كلمة تبدأ بصوت الصاد؟", ["صدق", "سلسلة", "زراعة", "حرية"], 0, "الأصوات", "vocabulary"),
          order("رتّب الكلمات.", ["أفضل", "الحرية", "من", "القيد"], "الحرية أفضل من القيد", "الحرية"),
          text("أكمل: بالعمل يزداد ____.", ["الخير", "الخير والثروة", "الثراء"], "قيمة العمل", "structure"),
          choice("الجملة الصحيحة هي:", ["يطلب الطفلُ العلمَ", "يطلب العلمُ الطفلَ", "الطفلَ يطلب العلمُ", "العلمَ الطفلُ يطلب"], 0, "الأنماط", "structure"),
          write("اكتب ماذا تحب أن تكون في المستقبل، ولماذا؟", "اكتب جملة أو جملتين واضحتين.", "المستقبل")
        ]
      }
    ]
  },
  {
    id: "u3", number: 3, title: "البيئة الاجتماعية", color: "#e08b3d", pages: "٧٠–١٠١",
    lessons: ["القرية", "غرس الأشجار", "نظافة الشارع", "نشيد البيئة"],
    models: [
      {
        id: "u3-a", level: "تأسيسي", name: "النموذج الأول", focus: "القرية والعناية بالبيئة",
        questions: [
          choice("ماذا شاهد التلاميذ في اللوحة؟", ["صورة قرية صغيرة", "صورة مستشفى", "صورة حافلة", "صورة بحر"], 0, "القرية"),
          choice("بماذا تمتاز القرية؟", ["بجوها النقي ومناظرها الجميلة", "بكثرة السيارات", "بالمصانع الكبيرة", "بالضوضاء"], 0, "القرية"),
          choice("ما فائدة الشجرة؟", ["تزيد الأرض خضرة وتنشر الظل", "تملأ الطريق نفايات", "تزيد الضوضاء", "تمنع المطر"], 0, "غرس الأشجار"),
          choice("أين توضع الزجاجات الفارغة؟", ["في الطريق", "في برميل القمامة", "تحت الشجرة", "في النهر"], 1, "نظافة الشارع"),
          choice("اختر جمع كلمة «شجرة».", ["أشجار", "شجور", "شُجيرة", "شجراتٌ"], 0, "المفردات", "vocabulary"),
          choice("أي كلمة تناسب الرمز 🌽؟", ["الذرة", "الشجرة", "الطريق", "الزجاجة"], 0, "المفردات", "vocabulary"),
          order("رتّب الكلمات.", ["الأرض", "الأشجار", "تزيّن", "الخضراء"], "الأشجار تزين الأرض الخضراء", "غرس الأشجار"),
          choice("اختر الفعل المناسب: ____ الفلاحُ الذرةَ.", ["يزرع", "يرمي", "يكسر", "ينسى"], 0, "القرية", "structure"),
          choice("نظافة الشارع مهمة عامل النظافة وحده.", ["صحيح", "خطأ"], 1, "نظافة الشارع", "structure"),
          write("اكتب جملةً تصف فيها قريتك أو مدينتك.", "مثال: قريتي جميلة وهواؤها نقي.", "التعبير")
        ]
      },
      {
        id: "u3-b", level: "متوسط", name: "النموذج الثاني", focus: "المفردات والسلوك البيئي",
        questions: [
          choice("من أين أخذ سامي فواكه لذيذة؟", ["من المزرعة", "من المكتبة", "من المستشفى", "من الحافلة"], 0, "القرية"),
          choice("لماذا تُغرس الأشجار في الحدائق والاستراحات؟", ["لكي يستريح الناس في ظلها", "لتسد الطريق", "لتخفي المنازل", "لتمنع الزراعة"], 0, "غرس الأشجار"),
          choice("ماذا فعلت زينب بالزجاجات التي وجدتها؟", ["كسرتها", "أخذتها إلى برميل القمامة", "تركتها", "ألقتها في الماء"], 1, "نظافة الشارع"),
          choice("ماذا طلبت زهراء من زينب؟", ["أن تتأخر", "أن تساعدها", "أن ترمي النفايات", "أن تعود للمنزل"], 0, "نظافة الشارع"),
          choice("اختر عكس كلمة «نظافة».", ["جمال", "أشجار", "قذارة", "خضرة"], 2, "المفردات", "vocabulary"),
          choice("أي الكلمات تدل على مكان زراعي؟", ["مزرعة", "شارع", "مدرسة", "مستشفى"], 0, "المفردات", "vocabulary"),
          order("رتّب الكلمات.", ["مهمة", "نظافة", "الجميع", "الشارع"], "نظافة الشارع مهمة الجميع", "نظافة الشارع"),
          text("أكمل: الشجرة تنشر ____ بأوراقها.", ["الظل", "ظلا", "الظلال"], "غرس الأشجار", "structure"),
          choice("الجملة الصحيحة هي:", ["يحترم الناسُ عاملَ النظافة", "يحترم عاملُ النظافة الناسَ", "الناسَ النظافةُ يحترم", "عاملَ يحترم النظافة"], 0, "الأنماط", "structure"),
          write("اكتب نصيحة لزميل يرمي النفايات في الشارع.", "مثال: ضع النفايات في المكان المخصص لها.", "التعبير")
        ]
      },
      {
        id: "u3-c", level: "إتقان", name: "النموذج الثالث", focus: "مراجعة شاملة للوحدة",
        questions: [
          choice("ماذا يزرع أهل القرية؟", ["الذرة والقمح", "الأقلام", "السيارات", "الكتب"], 0, "القرية"),
          choice("ما العبارة المكتوبة على اللوحة؟", ["اعتنوا بالشجرة لتصبح بلادنا جميلة", "ارموا النفايات في الطريق", "اقطعوا الأشجار", "اتركوا الحديقة"], 0, "غرس الأشجار"),
          choice("لماذا نحترم عامل النظافة؟", ["لأنه يبذل جهده في خدمتنا", "لأنه يرمي النفايات", "لأنه يقطع الأشجار", "لأنه يغلق الطريق"], 0, "نظافة الشارع"),
          choice("ماذا يوجد في البيئة بحسب النشيد؟", ["سهل وجبال", "مصنع فقط", "شارع فقط", "حافلات كثيرة"], 0, "نشيد البيئة"),
          choice("ما مفرد «ثمار»؟", ["ثمرة", "ثامر", "ثمور", "مثمرة"], 0, "المفردات", "vocabulary"),
          choice("أي كلمة تبدأ بحرف الزاي؟", ["زهرة", "شجرة", "نظافة", "طريق"], 0, "الأصوات", "vocabulary"),
          order("رتّب الكلمات.", ["بلادنا", "غرس", "يجمل", "الأشجار"], "غرس الأشجار يجمل بلادنا", "غرس الأشجار"),
          choice("اختر الكلمة المناسبة: ____ زينب الزجاجةَ.", ["حملت", "زرع", "كتب", "نام"], 0, "الأنماط", "structure"),
          choice("الأرض الطيبة تعطينا خير الثمار.", ["صحيح", "خطأ"], 0, "نشيد البيئة", "structure"),
          write("اكتب جملتين عن عمل تقوم به للمحافظة على البيئة.", "اكتب جملتين قصيرتين وواضحتين.", "البيئة")
        ]
      }
    ]
  },
  {
    id: "u4", number: 4, title: "الصحة والسلامة", color: "#4d91c8", pages: "١٠١–١٣١",
    lessons: ["سمية تشتري حلوى", "شهاب في الشارع", "صالح وأولاده في رحلة", "صحتي"],
    models: [
      {
        id: "u4-a", level: "تأسيسي", name: "النموذج الأول", focus: "الغذاء الصحي وسلامة الطريق",
        questions: [
          choice("ما الذي اشترته سمية من البائع؟", ["حلوى مكشوفة", "فاكهة مغسولة", "كتابًا", "دواءً"], 0, "سمية تشتري حلوى"),
          choice("ماذا شعرت سمية في المساء؟", ["بنشاط", "بألم شديد جعلها تبكي", "بالفرح", "بالنعاس فقط"], 1, "سمية تشتري حلوى"),
          choice("أين رمى شهاب الأوراق والقشور أولًا؟", ["في سلة المهملات", "على الأرض", "في البيت", "في الحديقة"], 1, "شهاب في الشارع"),
          choice("بماذا نصح الطبيب سمية؟", ["ألا تأكل الأطعمة المكشوفة", "أن تكثر من الحلوى", "أن تلعب في الشارع", "أن تترك الدواء"], 0, "سمية تشتري حلوى"),
          choice("اختر عكس كلمة «مكشوفة».", ["مغطاة", "نظيفة", "حلوة", "كبيرة"], 0, "المفردات", "vocabulary"),
          choice("أي كلمة تناسب الرمز 🚦؟", ["إشارة المرور", "المستشفى", "الدواء", "الحلوى"], 0, "المفردات", "vocabulary"),
          order("رتّب الكلمات.", ["العلاج", "من", "الوقاية", "خير"], "الوقاية خير من العلاج", "الصحة"),
          choice("اختر الفعل المناسب: ____ شهابٌ القشورَ.", ["جمع", "زرع", "قرأ", "رسم"], 0, "شهاب في الشارع", "structure"),
          choice("نرمي النفايات في المكان المخصص لها.", ["صحيح", "خطأ"], 0, "السلامة", "structure"),
          write("اكتب نصيحة قصيرة تحافظ بها على صحة صديقك.", "مثال: لا تأكل الطعام المكشوف.", "التعبير")
        ]
      },
      {
        id: "u4-b", level: "متوسط", name: "النموذج الثاني", focus: "الرحلة والصحة والنظافة",
        questions: [
          choice("إلى أين سافر صالح مع أولاده؟", ["وادي ظهر", "المدرسة", "المستشفى", "السوق"], 0, "صالح وأولاده في رحلة"),
          choice("ماذا فعلت الأسرة عند وصولها إلى دار الحجر؟", ["التقطت بعض الصور", "عادت فورًا", "زرعت الذرة", "اشترت الحلوى"], 0, "صالح وأولاده في رحلة"),
          choice("ماذا أعجب رضية في الرحلة؟", ["مدرجات خضراء وانسياب الماء", "زحام السيارات", "الأطعمة المكشوفة", "كثرة القمامة"], 0, "صالح وأولاده في رحلة"),
          choice("لماذا اعتذر شهاب للشيخ؟", ["لأنه أدرك خطأ رمي النفايات", "لأنه تأخر عن المدرسة", "لأنه أضاع كتابه", "لأنه قطع شجرة"], 0, "شهاب في الشارع"),
          choice("ما مفرد «أدوية»؟", ["دواء", "داء", "طبيب", "دوّامة"], 0, "المفردات", "vocabulary"),
          choice("أي كلمة تدل على لون؟", ["أخضر", "وادي", "رحلة", "طبيب"], 0, "المفردات", "vocabulary"),
          order("رتّب الكلمات.", ["على", "المحافظة", "واجب", "الصحة"], "المحافظة على الصحة واجب", "صحتي"),
          text("أكمل: النظافة من ____.", ["الإيمان", "الايمان"], "شهاب في الشارع", "structure"),
          choice("الجملة الصحيحة هي:", ["وصف الطبيبُ الدواءَ", "وصف الدواءُ الطبيبَ", "الطبيبَ الدواءُ وصف", "الدواءَ وصف الطبيبِ"], 0, "الأنماط", "structure"),
          write("اكتب جملة تصف منظرًا أعجبك في رحلة.", "مثال: أعجبتني الجبال الخضراء والهواء النقي.", "التعبير")
        ]
      },
      {
        id: "u4-c", level: "إتقان", name: "النموذج الثالث", focus: "مراجعة شاملة للوحدة",
        questions: [
          choice("كيف ذهب والد سمية بها إلى الطبيب؟", ["بالسيارة", "سيرًا", "بالحافلة", "بالطائرة"], 0, "سمية تشتري حلوى"),
          choice("ماذا يحدث إذا رمى كل إنسان قمامته في الشارع؟", ["ينتشر الذباب والأمراض", "يصبح الشارع أجمل", "تنمو الأشجار", "يصبح الهواء أنقى"], 0, "شهاب في الشارع"),
          choice("ماذا أحب أسيل في الرحلة؟", ["الشوكة الناعمة", "الحلوى", "السيارات", "السوق"], 0, "صالح وأولاده في رحلة"),
          choice("إلى ماذا يدعونا نشيد «صحتي»؟", ["النشاط والمحافظة على الصحة", "السهر", "أكل المكشوف", "ترك الرياضة"], 0, "صحتي"),
          choice("اختر جمع كلمة «صورة».", ["صُوَر", "صوّار", "تصوير", "صورتان"], 0, "المفردات", "vocabulary"),
          choice("أي كلمة تبدأ بصوت الشين؟", ["شارع", "صالح", "سمية", "طبيب"], 0, "الأصوات", "vocabulary"),
          order("رتّب الكلمات.", ["في", "شهاب", "النفايات", "السلة", "وضع"], "وضع شهاب النفايات في السلة", "شهاب في الشارع"),
          choice("اختر الكلمة المناسبة: ____ صالحٌ مع أولاده.", ["سافر", "تسافر", "سافرت", "يسافرون"], 0, "الأنماط", "structure"),
          choice("الطعام المكشوف قد يسبب المرض.", ["صحيح", "خطأ"], 0, "الصحة", "structure"),
          write("اكتب عادتين صحيتين تقوم بهما كل يوم.", "مثال: أغسل يدي، وأتناول طعامًا نظيفًا.", "صحتي")
        ]
      }
    ]
  },
  {
    id: "u5", number: 5, title: "مهن وحرف", color: "#df698f", pages: "١٣١–١٦٠",
    lessons: ["حصة الرسم", "الولد النبيل", "جدي يتعلم", "الفلاح"],
    models: [
      {
        id: "u5-a", level: "تأسيسي", name: "النموذج الأول", focus: "الرسم والتعاون والعمل",
        questions: [
          choice("إلى كم مجموعة قسمت المعلمة الطالبات؟", ["مجموعتين", "ثلاث مجموعات", "أربع مجموعات", "خمس مجموعات"], 1, "حصة الرسم"),
          choice("ماذا رسمت المجموعة الأولى؟", ["علم اليمن على سيارة طويلة", "طائرًا", "زهرات", "فلاحًا"], 0, "حصة الرسم"),
          choice("من الذي ساعد الأعمى على عبور الشارع؟", ["ظافر", "عامر", "الجد", "الفلاح"], 0, "الولد النبيل"),
          choice("متى يستيقظ الفلاح؟", ["مع الفجر", "بعد الظهر", "في المساء", "منتصف الليل"], 0, "الفلاح"),
          choice("اختر جمع كلمة «طائر».", ["طيور", "طيران", "طائرة", "طائران"], 0, "المفردات", "vocabulary"),
          choice("أي أداة تستخدم في الرسم؟", ["فرشاة", "محراث", "مظلة", "عصا"], 0, "المفردات", "vocabulary"),
          order("رتّب الكلمات.", ["المجموعة", "اليمن", "علم", "رسمت", "الأولى"], "رسمت المجموعة الأولى علم اليمن", "حصة الرسم"),
          choice("اختر الفعل المناسب: ____ الفلاحُ الأرضَ.", ["يحرث", "يرسم", "يعبر", "يقرأ"], 0, "الفلاح", "structure"),
          choice("مساعدة المحتاج عمل نبيل.", ["صحيح", "خطأ"], 0, "الولد النبيل", "structure"),
          write("اكتب جملة عن مهنة تحبها.", "مثال: أحب مهنة المعلم لأنه ينشر العلم.", "التعبير")
        ]
      },
      {
        id: "u5-b", level: "متوسط", name: "النموذج الثاني", focus: "القراءة والمهن والسلوك النبيل",
        questions: [
          choice("لماذا قال الوالد لظافر: أنا مسرور منك؟", ["لأنه حافظ على استخدام المظلة", "لأنه رسم لوحة", "لأنه زرع الأرض", "لأنه قرأ كتابًا"], 0, "الولد النبيل"),
          choice("ما العمل العظيم الذي قام به ظافر؟", ["ساعد الأعمى على عبور الشارع", "اشترى سيارة", "رسم طائرًا", "حمل كتابًا"], 0, "الولد النبيل"),
          choice("أين يراجع عامر دروسه؟", ["عند جده غالب", "في السوق", "في الحقل", "في السيارة"], 0, "جدي يتعلم"),
          choice("لماذا أراد الجد أن يتعلم؟", ["ليعرف كل صغيرة وكبيرة", "ليذهب إلى النوم", "ليبيع الكتاب", "ليترك العمل"], 0, "جدي يتعلم"),
          choice("اختر عكس كلمة «النبيل».", ["الكريم", "اللئيم", "المتعلم", "النشيط"], 1, "المفردات", "vocabulary"),
          choice("أي كلمة تناسب الرمز 🎨؟", ["ألوان", "محراث", "شارع", "مظلة"], 0, "المفردات", "vocabulary"),
          order("رتّب الكلمات.", ["يستمتع", "الجد", "عامر", "كان", "بقراءة"], "كان الجد يستمتع بقراءة عامر", "جدي يتعلم"),
          text("أكمل: من سار على الدرب ____.", ["وصل"], "جدي يتعلم", "structure"),
          choice("الجملة الصحيحة هي:", ["ساعد ظافرُ الرجلَ الأعمى", "ساعد الرجلُ ظافرَ الأعمى", "الأعمى ظافرَ ساعد", "ظافرَ ساعد الرجلُ"], 0, "الأنماط", "structure"),
          write("اكتب كيف تساعد شخصًا يحتاج إلى العون.", "مثال: أمسك بيد الكبير وأساعده على عبور الطريق.", "التعبير")
        ]
      },
      {
        id: "u5-c", level: "إتقان", name: "النموذج الثالث", focus: "مراجعة شاملة للوحدة",
        questions: [
          choice("ماذا رسمت المجموعة الثانية؟", ["طائرًا يطير", "علم اليمن", "زهرات في سطل", "حافلة"], 0, "حصة الرسم"),
          choice("لماذا كان الجد يصغي إلى عامر؟", ["ليستفيد من قراءة الدروس", "ليطلب منه اللعب", "لينام", "ليذهب إلى الحقل"], 0, "جدي يتعلم"),
          choice("ماذا يحمل الجد بين يديه في أحد الأيام؟", ["كتابًا", "محراثًا", "فرشاة", "مظلة"], 0, "جدي يتعلم"),
          choice("ماذا يفعل الفلاح بعد صلاة الفجر؟", ["يمضي إلى الحقل", "يعود للنوم", "يرسم", "يذهب للسوق"], 0, "الفلاح"),
          choice("ما مفرد «ألوان»؟", ["لون", "تلوين", "ملوّن", "ألونة"], 0, "المفردات", "vocabulary"),
          choice("أي كلمة تبدأ بصوت الظاء؟", ["ظافر", "طائر", "عامر", "غلاف"], 0, "الأصوات", "vocabulary"),
          order("رتّب الكلمات.", ["الفجر", "الفلاح", "بعد", "الحقل", "إلى", "يمضي"], "يمضي الفلاح إلى الحقل بعد الفجر", "الفلاح"),
          choice("اختر الكلمة المناسبة: ____ عامرٌ دروسَه.", ["يراجع", "تحرث", "رسمت", "يساعدون"], 0, "الأنماط", "structure"),
          choice("التعلم مفيد للصغير والكبير.", ["صحيح", "خطأ"], 0, "جدي يتعلم", "structure"),
          write("اكتب جملتين تصف فيهما عمل الفلاح أو الرسام.", "احرص على ترتيب الكلمات وعلامة النقطة.", "التعبير")
        ]
      }
    ]
  }
];

function choice(prompt, options, answer, lesson, section = "comprehension") {
  return { type: "choice", section, prompt, options, answer, lesson, points: 2 };
}
function text(prompt, answers, lesson, section = "structure") {
  return { type: "text", section, prompt, answers, answer: answers[0], lesson, points: 2 };
}
function order(prompt, words, answer, lesson) {
  return { type: "order", section: "structure", prompt, words, answer, answers: [answer], lesson, points: 2 };
}
function write(prompt, hint, lesson) {
  return { type: "write", section: "writing", prompt, hint, lesson, points: 0 };
}

const allModels = units.flatMap(unit => unit.models.map(model => ({ ...model, unit })));
const arabicDigits = new Intl.NumberFormat("ar-EG", { useGrouping: false });
const $ = selector => document.querySelector(selector);

const refs = {
  homeView: $("#homeView"), examView: $("#examView"), modelGrid: $("#modelGrid"), unitFilters: $("#unitFilters"),
  sideNav: $("#sideNav"), sidebar: $("#sidebar"), backdrop: $("#sidebarBackdrop"), menuButton: $("#menuButton"),
  printButton: $("#printButton"), questionList: $("#questionList"), examForm: $("#examForm"), resultDialog: $("#resultDialog"),
  studentName: $("#studentName"), studentClass: $("#studentClass"), examDate: $("#examDate"), toast: $("#toast")
};

let currentModel = null;
let responses = {};
let timerSeconds = 0;
let timerHandle = null;
let activeFilter = "all";
let resultMode = false;

function renderNavigation() {
  refs.sideNav.innerHTML = units.map(unit => `
    <section class="side-unit" style="--unit-color:${unit.color}">
      <div class="side-unit__label"><i></i><span>الوحدة ${toArabic(unit.number)} · ${unit.title}</span></div>
      ${unit.models.map((model, index) => `
        <button class="side-link" type="button" data-model="${model.id}">
          <b>${toArabic(index + 1)}</b><span>${model.name}</span>
        </button>`).join("")}
    </section>`).join("");
}

function renderFilters() {
  const filters = [{ id: "all", title: "الكل" }, ...units.map(unit => ({ id: unit.id, title: `الوحدة ${toArabic(unit.number)}` }))];
  refs.unitFilters.innerHTML = filters.map(item => `<button class="filter-pill ${item.id === activeFilter ? "active" : ""}" type="button" data-filter="${item.id}">${item.title}</button>`).join("");
}

function renderModels() {
  const list = activeFilter === "all" ? allModels : allModels.filter(model => model.unit.id === activeFilter);
  refs.modelGrid.innerHTML = list.map((model, index) => {
    const globalIndex = allModels.findIndex(item => item.id === model.id) + 1;
    return `<article class="model-card" style="--unit-color:${model.unit.color}" data-unit="${model.unit.id}">
      <div class="model-card__top">
        <span class="model-card__number">${toArabic(globalIndex)}</span>
        <span class="model-card__tag">${model.level}</span>
      </div>
      <h3>${model.name} · ${model.unit.title}</h3>
      <p>${model.focus}</p>
      <div class="model-card__footer">
        <div class="model-card__details"><span>◷ ١٥ دقيقة</span><span>◇ ١٠ تدريبات</span></div>
        <button class="model-card__start" type="button" data-model="${model.id}" aria-label="ابدأ ${model.name}">←</button>
      </div>
    </article>`;
  }).join("");
}

function openModel(id, options = {}) {
  const model = allModels.find(item => item.id === id);
  if (!model) return;
  currentModel = model;
  resultMode = false;
  const saved = options.fresh ? null : getSaved(model.id);
  responses = saved?.responses || {};
  timerSeconds = saved?.timer || 0;

  document.documentElement.style.setProperty("--unit-color", model.unit.color);
  refs.homeView.hidden = true;
  refs.examView.hidden = false;
  refs.printButton.hidden = false;
  $("#examUnitBadge").textContent = `الوحدة ${toArabic(model.unit.number)} · ${model.unit.title}`;
  $("#examCode").textContent = `FORM ${String(allModels.indexOf(model) + 1).padStart(2, "0")}`;
  $("#examTitle").textContent = model.name;
  $("#examSubtitle").textContent = `اختبار قصير في الوحدة ${toArabic(model.unit.number)} — الصف الثاني الأساسي`;
  refs.studentName.value = saved?.studentName || "";
  refs.studentClass.value = saved?.studentClass || "";
  refs.examDate.value = saved?.date || formatDate();
  renderQuestions();
  updateProgress();
  updateActiveNav();
  closeSidebar();
  startTimer();
  window.scrollTo({ top: 0, behavior: options.instant ? "auto" : "smooth" });
  history.replaceState(null, "", `#${model.id}`);
  setTimeout(() => $("#mainContent").focus({ preventScroll: true }), 50);
}

function renderQuestions() {
  let lastSection = null;
  refs.questionList.innerHTML = currentModel.questions.map((question, index) => {
    const section = sections[question.section];
    const heading = lastSection !== question.section
      ? `<div class="question-section-title" style="--section-color:${section.color}"><span>${section.icon}</span><h2>${section.title}</h2><i></i></div>` : "";
    lastSection = question.section;
    const value = responses[index] ?? "";
    let control = "";
    if (question.type === "choice") {
      control = `<div class="option-grid">${question.options.map((option, optionIndex) => `
        <label class="option-label" data-option="${optionIndex}">
          <input type="radio" name="q${index}" value="${optionIndex}" ${String(value) === String(optionIndex) ? "checked" : ""}>
          <i class="option-radio"></i><span>${option}</span>
        </label>`).join("")}</div>`;
    } else if (question.type === "order") {
      control = `<div class="word-chips">${question.words.map(word => `<span>${word}</span>`).join("")}</div>
        <input class="answer-input" name="q${index}" value="${escapeHtml(value)}" placeholder="اكتب الجملة بعد ترتيبها" autocomplete="off">`;
    } else if (question.type === "text") {
      control = `<input class="answer-input" name="q${index}" value="${escapeHtml(value)}" placeholder="اكتب الإجابة هنا" autocomplete="off">`;
    } else {
      control = `<textarea class="writing-input" name="q${index}" placeholder="اكتب هنا...">${escapeHtml(value)}</textarea>`;
    }
    return `${heading}<section class="question-card ${hasValue(value) ? "answered" : ""}" data-question="${index}" style="--section-color:${section.color}">
      <div class="question-head">
        <span class="question-number">${toArabic(index + 1)}</span>
        <div class="question-copy"><p>${question.prompt}</p><small>${question.lesson}</small></div>
        <span class="question-points">${question.type === "write" ? "تُراجع مع المعلم" : "درجتان"}</span>
      </div>
      ${control}
      <div class="feedback" aria-live="polite"></div>
    </section>`;
  }).join("");
}

function handleAnswer(event) {
  const field = event.target;
  if (!field.name?.startsWith("q")) return;
  const index = Number(field.name.slice(1));
  responses[index] = field.value;
  const card = field.closest(".question-card");
  card?.classList.toggle("answered", hasValue(field.value));
  if (resultMode) clearCorrection(card);
  saveProgress();
  updateProgress();
}

function updateProgress() {
  if (!currentModel) return;
  const answered = currentModel.questions.filter((_, index) => hasValue(responses[index])).length;
  const percent = Math.round((answered / currentModel.questions.length) * 100);
  $("#examProgress").style.width = `${percent}%`;
  $("#miniProgress").style.width = `${percent}%`;
  $("#answeredCount").textContent = `${toArabic(answered)} من ${toArabic(currentModel.questions.length)}`;
  $("#progressCopy").textContent = `أكملت ${toArabic(percent)}٪ من النموذج`;
}

function submitExam(event) {
  event.preventDefault();
  const firstEmpty = currentModel.questions.findIndex((question, index) => question.type !== "write" && !hasValue(responses[index]));
  if (firstEmpty !== -1) {
    showToast("أكمل الأسئلة الموضوعية أولًا، بقيت إجابات فارغة.");
    refs.questionList.querySelector(`[data-question="${firstEmpty}"]`)?.scrollIntoView({ behavior: "smooth", block: "center" });
    return;
  }

  resultMode = true;
  let correct = 0;
  let wrong = 0;
  currentModel.questions.forEach((question, index) => {
    const card = refs.questionList.querySelector(`[data-question="${index}"]`);
    clearCorrection(card);
    const feedback = card.querySelector(".feedback");
    if (question.type === "write") {
      card.classList.add("manual");
      feedback.textContent = `إجابة كتابية: ${question.hint}`;
      return;
    }
    const isCorrect = checkAnswer(question, responses[index]);
    card.classList.add(isCorrect ? "correct" : "wrong");
    if (isCorrect) {
      correct++;
      feedback.textContent = "إجابة صحيحة، أحسنت!";
    } else {
      wrong++;
      feedback.textContent = `الإجابة الصحيحة: ${getCorrectAnswer(question)}`;
    }
    if (question.type === "choice") {
      card.querySelectorAll(".option-label").forEach((label, optionIndex) => {
        if (optionIndex === question.answer) label.classList.add("answer-correct");
        if (label.querySelector("input").checked && optionIndex !== question.answer) label.classList.add("answer-wrong");
      });
    }
  });

  const total = correct + wrong;
  const percent = Math.round((correct / total) * 100);
  const heading = percent >= 90 ? "ممتاز يا بطل!" : percent >= 70 ? "أحسنت، واصل التقدّم!" : percent >= 50 ? "محاولة طيبة!" : "لنراجع معًا";
  const message = percent >= 90 ? "إجابات رائعة تدل على فهم متقن للوحدة." : percent >= 70 ? "نتيجة جميلة، راجع الأسئلة المعلّمة ثم حاول مرة أخرى." : "راجع دروس الوحدة والإجابات الصحيحة، ثم أعد المحاولة بثقة.";
  $("#resultHeading").textContent = heading;
  $("#resultMessage").textContent = message;
  $("#resultScore").textContent = `${toArabic(percent)}٪`;
  $("#correctCount").textContent = toArabic(correct);
  $("#wrongCount").textContent = toArabic(wrong);
  $("#resultRing").style.setProperty("--score", `${percent * 3.6}deg`);
  saveProgress({ completed: true, score: percent });
  refs.resultDialog.showModal();
}

function checkAnswer(question, value) {
  if (question.type === "choice") return Number(value) === question.answer;
  const accepted = question.answers || [question.answer];
  return accepted.some(answer => normalize(value) === normalize(answer));
}

function getCorrectAnswer(question) {
  return question.type === "choice" ? question.options[question.answer] : question.answer;
}

function clearCorrection(card) {
  if (!card) return;
  card.classList.remove("correct", "wrong", "manual");
  card.querySelectorAll(".answer-correct, .answer-wrong").forEach(item => item.classList.remove("answer-correct", "answer-wrong"));
  const feedback = card.querySelector(".feedback");
  if (feedback) feedback.textContent = "";
}

function showHome() {
  stopTimer();
  currentModel = null;
  refs.examView.hidden = true;
  refs.homeView.hidden = false;
  refs.printButton.hidden = true;
  document.querySelectorAll(".side-link").forEach(link => link.classList.remove("active"));
  history.replaceState(null, "", location.pathname + location.search);
  closeSidebar();
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function resetCurrentModel() {
  if (!currentModel || !window.confirm("هل تريد مسح جميع الإجابات في هذا النموذج؟")) return;
  localStorage.removeItem(storageKey(currentModel.id));
  responses = {};
  timerSeconds = 0;
  resultMode = false;
  renderQuestions();
  updateProgress();
  refs.studentName.value = "";
  refs.studentClass.value = "";
  refs.examDate.value = formatDate();
  showToast("تم مسح الإجابات. يمكنك البدء من جديد.");
}

function saveProgress(extra = {}) {
  if (!currentModel) return;
  const payload = {
    responses,
    timer: timerSeconds,
    studentName: refs.studentName.value,
    studentClass: refs.studentClass.value,
    date: refs.examDate.value,
    updatedAt: Date.now(),
    ...extra
  };
  localStorage.setItem(storageKey(currentModel.id), JSON.stringify(payload));
  const status = $("#saveStatus");
  status.textContent = "تم الحفظ ✓";
  clearTimeout(saveProgress.timeout);
  saveProgress.timeout = setTimeout(() => status.textContent = "يُحفظ تلقائيًا", 1200);
}

function getSaved(id) {
  try { return JSON.parse(localStorage.getItem(storageKey(id)) || "null"); }
  catch { return null; }
}

function storageKey(id) { return `lughaty-exam-${id}`; }

function startTimer() {
  stopTimer();
  updateTimer();
  timerHandle = setInterval(() => {
    timerSeconds++;
    updateTimer();
    if (timerSeconds % 10 === 0) saveProgress();
  }, 1000);
}
function stopTimer() { if (timerHandle) clearInterval(timerHandle); timerHandle = null; }
function updateTimer() {
  const minutes = String(Math.floor(timerSeconds / 60)).padStart(2, "0");
  const seconds = String(timerSeconds % 60).padStart(2, "0");
  $("#timer").innerHTML = `<i></i> ${toArabic(minutes)}:${toArabic(seconds)}`;
}

function updateActiveNav() {
  document.querySelectorAll(".side-link").forEach(link => link.classList.toggle("active", link.dataset.model === currentModel?.id));
}
function openSidebar() { refs.sidebar.classList.add("open"); refs.menuButton.setAttribute("aria-expanded", "true"); }
function closeSidebar() { refs.sidebar.classList.remove("open"); refs.menuButton.setAttribute("aria-expanded", "false"); }
function showToast(message) {
  refs.toast.textContent = message;
  refs.toast.classList.add("show");
  clearTimeout(showToast.timeout);
  showToast.timeout = setTimeout(() => refs.toast.classList.remove("show"), 2600);
}
function normalize(value) {
  return String(value || "").trim().replace(/[ًٌٍَُِّْـ]/g, "").replace(/[إأآ]/g, "ا").replace(/ة/g, "ه").replace(/ى/g, "ي").replace(/[،,.!?؟؛:]/g, "").replace(/\s+/g, " ");
}
function hasValue(value) { return String(value ?? "").trim().length > 0; }
function toArabic(value) { return String(value).replace(/\d/g, digit => "٠١٢٣٤٥٦٧٨٩"[digit]); }
function escapeHtml(value) {
  return String(value ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
function formatDate() {
  return new Intl.DateTimeFormat("ar-YE", { year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date());
}

function bindEvents() {
  document.addEventListener("click", event => {
    const modelButton = event.target.closest("[data-model]");
    if (modelButton) openModel(modelButton.dataset.model);
    const filterButton = event.target.closest("[data-filter]");
    if (filterButton) {
      activeFilter = filterButton.dataset.filter;
      renderFilters();
      renderModels();
    }
  });
  refs.examForm.addEventListener("input", handleAnswer);
  refs.examForm.addEventListener("change", handleAnswer);
  [refs.studentName, refs.studentClass, refs.examDate].forEach(input => input.addEventListener("input", () => saveProgress()));
  refs.examForm.addEventListener("submit", submitExam);
  $("#startFirstButton").addEventListener("click", () => openModel("u1-a"));
  $("#homeLink").addEventListener("click", event => { event.preventDefault(); showHome(); });
  $("#backButton").addEventListener("click", showHome);
  $("#clearButton").addEventListener("click", resetCurrentModel);
  refs.printButton.addEventListener("click", () => window.print());
  refs.menuButton.addEventListener("click", () => refs.sidebar.classList.contains("open") ? closeSidebar() : openSidebar());
  refs.backdrop.addEventListener("click", closeSidebar);
  $("#dialogClose").addEventListener("click", () => refs.resultDialog.close());
  $("#reviewButton").addEventListener("click", () => { refs.resultDialog.close(); refs.questionList.scrollIntoView({ behavior: "smooth" }); });
  $("#retryButton").addEventListener("click", () => { refs.resultDialog.close(); resetCurrentModel(); });
  $("#themeButton").addEventListener("click", () => {
    document.body.classList.toggle("dark");
    const dark = document.body.classList.contains("dark");
    localStorage.setItem("lughaty-theme", dark ? "dark" : "light");
    $("#themeButton").textContent = dark ? "☀" : "☾";
  });
  window.addEventListener("beforeunload", () => { if (currentModel) saveProgress(); });
}

function init() {
  if (localStorage.getItem("lughaty-theme") === "dark") {
    document.body.classList.add("dark");
    $("#themeButton").textContent = "☀";
  }
  renderNavigation();
  renderFilters();
  renderModels();
  bindEvents();
  const idFromHash = location.hash.replace("#", "");
  if (allModels.some(model => model.id === idFromHash)) openModel(idFromHash, { instant: true });
}

init();
