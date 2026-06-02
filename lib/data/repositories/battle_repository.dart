import 'dart:math';

import 'package:dark_trade_app/data/models/battle_room.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';

abstract class BattleRepository {
  Future<BattleRoom> createRoom(
      String name, int durationDays, double initialBalance);

  Future<BattleRoom?> findRoomByInviteCode(String code);

  Future<BattleRoom?> getRoom(String roomId);

  Future<List<BattleRoom>> getUserRooms(String userId);

  Future<List<BattleParticipant>> getParticipants(String roomId);

  Future<void> joinRoom(String roomId, String userId, String careerId);

  Future<void> cancelRoom(String roomId);

  Future<void> completeRoom(String roomId, String winnerId);

  Future<int> participantCount(String roomId);
}

class SupabaseBattleRepo implements BattleRepository {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I,O,0,1

  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  String _generateInviteCode() {
    final random = Random();
    return List.generate(6, (_) => _chars[random.nextInt(_chars.length)])
        .join();
  }

  @override
  Future<BattleRoom> createRoom(
      String name, int durationDays, double initialBalance) async {
    final userId = SupabaseClientManager.instance.auth.currentUser?.id;
    if (userId == null) throw Exception('未登录');

    final id = _generateId();
    // Retry loop for unique invite code
    String inviteCode;
    for (int i = 0; i < 5; i++) {
      inviteCode = _generateInviteCode();
      try {
        await SupabaseClientManager.instance.from('battle_rooms').insert({
          'id': id,
          'invite_code': inviteCode,
          'name': name,
          'creator_id': userId,
          'duration_days': durationDays,
          'initial_balance': initialBalance,
          'status': 'waiting',
        });
        break;
      } catch (_) {
        if (i == 4) rethrow;
        continue;
      }
    }

    final room = await getRoom(id);
    return room!;
  }

  @override
  Future<BattleRoom?> findRoomByInviteCode(String code) async {
    final data = await SupabaseClientManager.instance
        .from('battle_rooms')
        .select()
        .eq('invite_code', code.toUpperCase())
        .maybeSingle();

    if (data == null) return null;
    return BattleRoom.fromJson(data);
  }

  @override
  Future<BattleRoom?> getRoom(String roomId) async {
    final data = await SupabaseClientManager.instance
        .from('battle_rooms')
        .select()
        .eq('id', roomId)
        .maybeSingle();

    if (data == null) return null;
    return BattleRoom.fromJson(data);
  }

  @override
  Future<List<BattleRoom>> getUserRooms(String userId) async {
    // Rooms created by user
    final created = await SupabaseClientManager.instance
        .from('battle_rooms')
        .select()
        .eq('creator_id', userId);

    // Rooms where user is a participant
    final participantData = await SupabaseClientManager.instance
        .from('battle_participants')
        .select('room_id')
        .eq('user_id', userId);

    final participantRoomIds = (participantData)
        .map((r) => r['room_id'] as String)
        .toSet();

    final allRooms = <BattleRoom>[];
    final seenIds = <String>{};

    void addFromList(dynamic list) {
      if (list is! List) return;
      for (final item in list) {
        final room = BattleRoom.fromJson(item);
        if (seenIds.add(room.id)) {
          allRooms.add(room);
        }
      }
    }

    addFromList(created);

    // Fetch participant rooms if needed
    for (final roomId in participantRoomIds) {
      if (!seenIds.contains(roomId)) {
        final roomData = await SupabaseClientManager.instance
            .from('battle_rooms')
            .select()
            .eq('id', roomId)
            .maybeSingle();
        if (roomData != null) {
          final room = BattleRoom.fromJson(roomData);
          if (seenIds.add(room.id)) {
            allRooms.add(room);
          }
        }
      }
    }

    allRooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allRooms;
  }

  @override
  Future<List<BattleParticipant>> getParticipants(String roomId) async {
    final data = await SupabaseClientManager.instance
        .from('battle_participants')
        .select()
        .eq('room_id', roomId);

    return data
        .map((j) => BattleParticipant.fromJson(j))
        .toList();
  }

  @override
  Future<void> joinRoom(
      String roomId, String userId, String careerId) async {
    final id = _generateId();
    await SupabaseClientManager.instance
        .from('battle_participants')
        .insert({
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'career_id': careerId,
    });
  }

  @override
  Future<int> participantCount(String roomId) async {
    final data = await SupabaseClientManager.instance
        .from('battle_participants')
        .select()
        .eq('room_id', roomId);

    return data.length;
  }

  @override
  Future<void> cancelRoom(String roomId) async {
    await SupabaseClientManager.instance
        .from('battle_rooms')
        .update({'status': 'cancelled'}).eq('id', roomId);
  }

  @override
  Future<void> completeRoom(String roomId, String winnerId) async {
    await SupabaseClientManager.instance
        .from('battle_rooms')
        .update({
      'status': 'completed',
      'winner_id': winnerId,
    }).eq('id', roomId);
  }
}
