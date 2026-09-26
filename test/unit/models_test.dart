import 'package:flutter_test/flutter_test.dart';
import 'package:lametna/models/models.dart';

void main() {
  group('Profile', () {
    final Map<String, dynamic> raw = <String, dynamic>{
      'id': 'u1',
      'nickname': 'أبو علي',
      'avatar_key': 'coffee',
      'country_code': 'YE',
      'show_country': true,
      'total_points': 1200,
      'games_played': 10,
      'games_won': 4,
      'level': 3,
      'role': 'player',
      'created_at': '2024-05-01T10:00:00.000Z',
    };

    test('fromMap يقرأ الحقول', () {
      final Profile p = Profile.fromMap(raw);
      expect(p.nickname, 'أبو علي');
      expect(p.totalPoints, 1200);
      expect(p.winRate, closeTo(0.4, 0.001));
      expect(p.isAdmin, isFalse);
    });

    test('toUpdateMap لا يحتوي على النقاط أو الدور (ملك الخادم)', () {
      final Map<String, dynamic> update = Profile.fromMap(raw).toUpdateMap();
      expect(update.containsKey('total_points'), isFalse);
      expect(update.containsKey('games_won'), isFalse);
      expect(update.containsKey('role'), isFalse);
      expect(update['nickname'], 'أبو علي');
    });
  });

  group('Room', () {
    test('fromMap + isFull + isHost', () {
      final Room room = Room.fromMap(<String, dynamic>{
        'id': 'r1',
        'code': 'ABC123',
        'game_key': 'mafia',
        'host_id': 'u1',
        'status': 'waiting',
        'max_players': 8,
        'player_count': 8,
      });
      expect(room.isFull, isTrue);
      expect(room.isHost('u1'), isTrue);
      expect(room.isHost('u2'), isFalse);
      expect(room.status, RoomStatus.waiting);
    });

    test('لا يوجد حقل لكلمة مرور الغرفة في العميل إطلاقًا', () {
      final Room room = Room.fromMap(<String, dynamic>{
        'id': 'r1', 'code': 'ABC123', 'game_key': 'liar',
        'host_id': 'u1', 'has_password': true,
      });
      expect(room.hasPassword, isTrue);
      // النموذج يحمل علمًا منطقيًا فقط — لا هاش ولا كلمة مرور
      expect(room.toString().contains('password_hash'), isFalse);
    });
  });

  group('GameRound', () {
    test('يقرأ حرف جماد حيوان والفئات', () {
      final GameRound round = GameRound.fromMap(<String, dynamic>{
        'id': 'rd1',
        'session_id': 's1',
        'round_index': 2,
        'phase': 'collecting',
        'prompt': <String, dynamic>{
          'stage': 'answer',
          'letter': 'م',
          'categories': <String>['name', 'animal'],
        },
        'ends_at': '2030-01-01T00:00:00.000Z',
      });
      expect(round.letter, 'م');
      expect(round.categories, <String>['name', 'animal']);
      expect(round.isResolved, isFalse);
      expect(round.index, 2);
    });

    test('لا يعرض secret_data لأن الخادم لا يرسله', () {
      final GameRound round = GameRound.fromMap(<String, dynamic>{
        'id': 'rd1', 'session_id': 's1', 'round_index': 1,
        'phase': 'night', 'ends_at': '2030-01-01T00:00:00.000Z',
      });
      expect(round.isMafiaNight, isTrue);
      expect(round.prompt.containsKey('secret_data'), isFalse);
    });
  });

  group('MyMafiaRole', () {
    test('يربط الدور بالفعل الليلي الصحيح', () {
      expect(
        MyMafiaRole.fromMap(<String, dynamic>{'role': 'mafia', 'is_alive': true}).nightAction,
        'kill',
      );
      expect(
        MyMafiaRole.fromMap(<String, dynamic>{'role': 'doctor', 'is_alive': true}).nightAction,
        'heal',
      );
      expect(
        MyMafiaRole.fromMap(<String, dynamic>{'role': 'detective', 'is_alive': true})
            .nightAction,
        'investigate',
      );
      expect(
        MyMafiaRole.fromMap(<String, dynamic>{'role': 'citizen', 'is_alive': true}).nightAction,
        isNull,
      );
    });

    test('اللاعب الميت لا يستطيع التنفيذ ليلًا', () {
      final MyMafiaRole role =
          MyMafiaRole.fromMap(<String, dynamic>{'role': 'doctor', 'is_alive': false});
      expect(role.canActAtNight, isFalse);
    });

    test('شركاء المافيا يظهرون للمافيا فقط كما يرسلها الخادم', () {
      final MyMafiaRole role = MyMafiaRole.fromMap(<String, dynamic>{
        'role': 'mafia',
        'is_alive': true,
        'partners': <dynamic>[
          <String, dynamic>{'user_id': 'u2', 'nickname': 'سالم'},
        ],
      });
      expect(role.partners.single.nickname, 'سالم');

      final MyMafiaRole citizen =
          MyMafiaRole.fromMap(<String, dynamic>{'role': 'citizen', 'is_alive': true});
      expect(citizen.partners, isEmpty);
    });
  });
}
