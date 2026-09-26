import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';

/// صفحات نصية: الخصوصية، الشروط، قوانين الاستخدام.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.titleKey, required this.sections});

  final String titleKey;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(titleKey))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: sections
            .map(((String, String) s) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(s.$1,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(s.$2, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = context.l10n.isArabic;
    return LegalScreen(
      titleKey: 'privacy_policy',
      sections: ar
          ? const <(String, String)>[
              ('ما الذي نجمعه',
                  'اسم مستعار، صورة رمزية جاهزة من داخل التطبيق، لغة الواجهة، ودولة اختيارية. '
                  'لا نطلب الاسم الحقيقي ولا رقم الهاتف ولا الموقع الجغرافي.'),
              ('ما الذي لا نجمعه',
                  'لا نستخدم الكاميرا ولا الميكروفون إطلاقًا، ولا نطلب صلاحياتهما. '
                  'لا نرفع صورًا شخصية ولا نسجّل صوتًا ولا فيديو.'),
              ('الدردشة',
                  'الرسائل نصية فقط، محدودة الطول، وتُحذف تلقائيًا بعد سبعة أيام. '
                  'قد يطّلع فريق الإشراف على الرسائل المُبلَّغ عنها فقط.'),
              ('بياناتك الخاصة بك',
                  'يمكنك حذف حسابك في أي وقت من الإعدادات؛ عندها يُخفى اسمك وتُخفى رسائلك نهائيًا.'),
              ('الأمان',
                  'البيانات محمية بسياسات Row Level Security على مستوى قاعدة البيانات، '
                  'ولا يمكن لأي لاعب قراءة بيانات غرفة ليس عضوًا فيها.'),
            ]
          : const <(String, String)>[
              ('What we collect',
                  'A nickname, a built-in avatar, your interface language and an optional country. '
                  'We never ask for your real name, phone number or location.'),
              ('What we never collect',
                  'No camera, no microphone, no permissions for either. '
                  'No personal photo uploads, no audio, no video.'),
              ('Chat',
                  'Text only, length limited, and automatically deleted after seven days. '
                  'Moderators can only review reported messages.'),
              ('Your data is yours',
                  'Delete your account any time from Settings; your name and messages are hidden permanently.'),
              ('Security',
                  'Row Level Security protects every table. A player can never read data '
                  'from a room they are not a member of.'),
            ],
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = context.l10n.isArabic;
    return LegalScreen(
      titleKey: 'terms',
      sections: ar
          ? const <(String, String)>[
              ('استخدام التطبيق', 'التطبيق للترفيه الجماعي. يجب أن يكون عمرك 13 سنة فأكثر.'),
              ('الحساب', 'أنت مسؤول عن اسمك المستعار وعن سلوكك داخل الغرف.'),
              ('النقاط والترتيب',
                  'النقاط تُحتسب على الخادم وحده، وأي محاولة للتلاعب تؤدي إلى الحظر.'),
              ('إيقاف الخدمة', 'قد نغلق غرفًا خاملة أو نحظر حسابات مخالفة دون إشعار مسبق.'),
            ]
          : const <(String, String)>[
              ('Using the app', 'Lametna is for group entertainment. You must be 13 or older.'),
              ('Your account', 'You are responsible for your nickname and your behaviour in rooms.'),
              ('Points and ranking',
                  'Points are computed on the server only. Tampering attempts lead to a ban.'),
              ('Service availability',
                  'We may close idle rooms or ban violating accounts without prior notice.'),
            ],
    );
  }
}

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = context.l10n.isArabic;
    return LegalScreen(
      titleKey: 'rules',
      sections: ar
          ? const <(String, String)>[
              ('احترام الجميع',
                  'ممنوع التنمر والسب والألفاظ الفاحشة. اللعب للمتعة لا للإساءة.'),
              ('ممنوع منعًا باتًا',
                  'العنصرية، الطائفية، التحريض، انتحال الشخصيات، ونشر بيانات الآخرين الشخصية.'),
              ('لا سياسة حساسة في الغرف العامة',
                  'الغرف العامة مساحة مشتركة للاعبين من كل الدول؛ تجنّب الخلافات الحساسة.'),
              ('لا روابط',
                  'الروابط ممنوعة في الدردشة لحماية اللاعبين من الاحتيال.'),
              ('اختلاف اللهجات مقبول',
                  'إجابتك من بلدك ليست خطأ. نقبل أكثر من رواية للمثل وأكثر من صيغة للكلمة.'),
              ('الإبلاغ',
                  'اضغط مطوّلًا على أي رسالة أو لاعب للإبلاغ أو الحظر الشخصي.'),
            ]
          : const <(String, String)>[
              ('Respect everyone',
                  'No bullying, insults or profanity. Play for fun, not to hurt.'),
              ('Strictly forbidden',
                  'Racism, sectarianism, incitement, impersonation and sharing personal data.'),
              ('No sensitive politics in public rooms',
                  'Public rooms are shared by players from many countries.'),
              ('No links', 'Links are blocked in chat to protect players from scams.'),
              ('Dialects are welcome',
                  'Your regional answer is not wrong. Multiple proverb variants are accepted.'),
              ('Reporting', 'Long-press a message or player to report or block.'),
            ],
    );
  }
}
