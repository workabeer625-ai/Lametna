enum MafiaRole { mafia, citizen, doctor, detective, guard }

MafiaRole mafiaRoleFrom(String? value) => MafiaRole.values.firstWhere(
      (MafiaRole r) => r.name == value,
      orElse: () => MafiaRole.citizen,
    );

/// دور اللاعب السري — يصل من RPC `my_mafia_role` ولا يُخزَّن محليًا بشكل دائم.
class MyMafiaRole {
  const MyMafiaRole({
    required this.role,
    required this.isAlive,
    this.partners = const <MafiaPartner>[],
  });

  final MafiaRole role;
  final bool isAlive;
  final List<MafiaPartner> partners;

  bool get isMafia => role == MafiaRole.mafia;
  bool get canActAtNight => role != MafiaRole.citizen && isAlive;

  String? get nightAction {
    switch (role) {
      case MafiaRole.mafia: return 'kill';
      case MafiaRole.doctor: return 'heal';
      case MafiaRole.detective: return 'investigate';
      case MafiaRole.guard: return 'protect';
      case MafiaRole.citizen: return null;
    }
  }

  factory MyMafiaRole.fromMap(Map<String, dynamic> map) => MyMafiaRole(
        role: mafiaRoleFrom(map['role'] as String?),
        isAlive: (map['is_alive'] ?? true) as bool,
        partners: ((map['partners'] ?? const <dynamic>[]) as List<dynamic>)
            .map((dynamic e) =>
                MafiaPartner.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList(),
      );
}

class MafiaPartner {
  const MafiaPartner({required this.userId, required this.nickname});
  final String userId;
  final String nickname;

  factory MafiaPartner.fromMap(Map<String, dynamic> map) => MafiaPartner(
        userId: (map['user_id'] ?? '') as String,
        nickname: (map['nickname'] ?? '') as String,
      );
}
