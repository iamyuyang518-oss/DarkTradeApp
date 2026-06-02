/// Status of a battle room.
enum BattleRoomStatus {
  waiting,
  active,
  completed,
  cancelled;

  String get displayLabel {
    switch (this) {
      case BattleRoomStatus.waiting:
        return '等待中';
      case BattleRoomStatus.active:
        return '进行中';
      case BattleRoomStatus.completed:
        return '已结束';
      case BattleRoomStatus.cancelled:
        return '已取消';
    }
  }

  bool get isOver => this == completed || this == cancelled;
  bool get isLive => this == active;
}

/// A battle room where two players compete on trading return rate.
class BattleRoom {
  final String id;
  final String inviteCode;
  final String name;
  final String creatorId;
  final int durationDays;
  final double initialBalance;
  final BattleRoomStatus status;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final DateTime createdAt;
  final String? winnerId;

  const BattleRoom({
    required this.id,
    required this.inviteCode,
    required this.name,
    required this.creatorId,
    required this.durationDays,
    required this.initialBalance,
    required this.status,
    this.startedAt,
    this.endsAt,
    required this.createdAt,
    this.winnerId,
  });

  factory BattleRoom.fromJson(Map<String, dynamic> json) {
    return BattleRoom(
      id: json['id'] as String? ?? '',
      inviteCode: json['invite_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 3,
      initialBalance:
          (json['initial_balance'] as num?)?.toDouble() ?? 100000,
      status: _parseStatus(json['status'] as String?),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      winnerId: json['winner_id'] as String?,
    );
  }

  static BattleRoomStatus _parseStatus(String? s) {
    switch (s) {
      case 'active':
        return BattleRoomStatus.active;
      case 'completed':
        return BattleRoomStatus.completed;
      case 'cancelled':
        return BattleRoomStatus.cancelled;
      default:
        return BattleRoomStatus.waiting;
    }
  }

  /// Remaining time as a human-readable string.
  String get countdownText {
    if (endsAt == null) return '';
    final diff = endsAt!.difference(DateTime.now());
    if (diff.isNegative) return '已结束';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return '剩余 $days 天 $hours 小时';
    if (hours > 0) return '剩余 $hours 小时 $minutes 分';
    if (minutes > 0) return '剩余 $minutes 分钟';
    return '即将结束';
  }
}

/// A participant in a battle room.
class BattleParticipant {
  final String id;
  final String roomId;
  final String userId;
  final String careerId;
  final DateTime joinedAt;

  const BattleParticipant({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.careerId,
    required this.joinedAt,
  });

  factory BattleParticipant.fromJson(Map<String, dynamic> json) {
    return BattleParticipant(
      id: json['id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      careerId: json['career_id'] as String? ?? '',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
    );
  }
}
