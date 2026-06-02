import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dark_trade_app/data/local/models/career.dart';
import 'package:dark_trade_app/data/models/battle_room.dart';
import 'package:dark_trade_app/data/repositories/battle_repository.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';

class BattleService extends ChangeNotifier {
  final BattleRepository _repo = SupabaseBattleRepo();

  List<BattleRoom> _rooms = [];
  final Map<String, List<BattleParticipant>> _participants = {};
  BattleRoom? _currentRoom;
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;
  String? _lastInviteCode;

  // --- public getters ---

  List<BattleRoom> get rooms => List.unmodifiable(_rooms);
  BattleRoom? get currentRoom => _currentRoom;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastInviteCode => _lastInviteCode;

  List<BattleParticipant> participantsFor(String roomId) =>
      _participants[roomId] ?? [];

  // --- fetch ---

  Future<void> fetchUserRooms() async {
    final uid = SupabaseClientManager.instance.auth.currentUser?.id;
    if (uid == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rooms = await _repo.getUserRooms(uid);
      _error = null;
    } catch (e) {
      debugPrint('[BattleService] fetchUserRooms error: $e');
      _error = '加载对战列表失败，请检查网络连接';
      _rooms = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- create ---

  /// Creates a battle room. Returns the invite code on success, null on failure.
  Future<String?> createRoom(String name, int durationDays,
      {double initialBalance = 100000}) async {
    final uid = SupabaseClientManager.instance.auth.currentUser?.id;
    if (uid == null) {
      _error = '请先登录';
      notifyListeners();
      return null;
    }

    // Check: user already in an active/waiting room?
    final hasActive = await _hasActiveBattle(uid);
    if (hasActive) {
      _error = '你已参与一个进行中的对战，请先完成';
      notifyListeners();
      return null;
    }

    _error = null;

    try {
      final room = await _repo.createRoom(name, durationDays, initialBalance);
      _lastInviteCode = room.inviteCode;
      _rooms.insert(0, room);
      _error = null;
      notifyListeners();
      return room.inviteCode;
    } catch (e) {
      debugPrint('[BattleService] createRoom error: $e');
      _error = '创建失败，请检查网络连接';
      notifyListeners();
      return null;
    }
  }

  // --- join ---

  /// Joins a room by invite code. Returns the room on success, null on failure.
  Future<BattleRoom?> joinRoom(String inviteCode,
      {required Future<Career> Function(String name, double initialBalance)
          createCareer}) async {
    final uid = SupabaseClientManager.instance.auth.currentUser?.id;
    if (uid == null) {
      _error = '请先登录';
      notifyListeners();
      return null;
    }

    _error = null;

    try {
      // Find room
      final room = await _repo.findRoomByInviteCode(inviteCode);
      if (room == null) {
        _error = '邀请码无效或房间不存在';
        notifyListeners();
        return null;
      }

      // Validate
      if (room.status != BattleRoomStatus.waiting) {
        _error = '对战已经开始或已结束，无法加入';
        notifyListeners();
        return null;
      }

      if (room.creatorId == uid) {
        _error = '不能加入自己创建的房间';
        notifyListeners();
        return null;
      }

      final count = await _repo.participantCount(room.id);
      if (count >= 2) {
        _error = '房间已满';
        notifyListeners();
        return null;
      }

      // Check: user already in an active/waiting room?
      final hasActive = await _hasActiveBattle(uid);
      if (hasActive) {
        _error = '你已参与一个进行中的对战，请先完成';
        notifyListeners();
        return null;
      }

      // Create battle career
      final career = await createCareer('对战: ${room.name}', room.initialBalance);
      await _repo.joinRoom(room.id, uid, career.id);

      // Activate room if full
      int newCount = await _repo.participantCount(room.id);
      if (newCount >= 2) {
        await _activateRoom(room);
      }

      _error = null;
      notifyListeners();
      await fetchUserRooms();
      return room;
    } catch (e) {
      debugPrint('[BattleService] joinRoom error: $e');
      _error = '加入失败，请检查网络连接';
      notifyListeners();
      return null;
    }
  }

  // --- cancel ---

  Future<bool> cancelRoom(String roomId) async {
    try {
      await _repo.cancelRoom(roomId);
      // Update local state
      final idx = _rooms.indexWhere((r) => r.id == roomId);
      if (idx >= 0) {
        final room = _rooms[idx];
        _rooms[idx] = BattleRoom(
          id: room.id,
          inviteCode: room.inviteCode,
          name: room.name,
          creatorId: room.creatorId,
          durationDays: room.durationDays,
          initialBalance: room.initialBalance,
          status: BattleRoomStatus.cancelled,
          startedAt: room.startedAt,
          endsAt: room.endsAt,
          createdAt: room.createdAt,
          winnerId: room.winnerId,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[BattleService] cancelRoom error: $e');
      _error = '取消失败';
      notifyListeners();
      return false;
    }
  }

  // --- polling ---

  void startPolling(String roomId) {
    stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshRoom(roomId);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refreshRoom(String roomId) async {
    try {
      final room = await _repo.getRoom(roomId);
      if (room == null) return;

      final participants = await _repo.getParticipants(roomId);
      _currentRoom = room;
      _participants[roomId] = participants;

      // Check if battle should be completed
      if (room.status == BattleRoomStatus.active &&
          room.endsAt != null &&
          DateTime.now().isAfter(room.endsAt!)) {
        await _settleBattle(room, participants);
      }

      // Stop polling if battle is over
      if (room.status.isOver) {
        stopPolling();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[BattleService] _refreshRoom error: $e');
    }
  }

  // --- detail ---

  Future<void> loadRoomDetail(String roomId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final room = await _repo.getRoom(roomId);
      if (room != null) {
        _currentRoom = room;
        final participants = await _repo.getParticipants(roomId);
        _participants[roomId] = participants;
      }
      _error = null;
    } catch (e) {
      debugPrint('[BattleService] loadRoomDetail error: $e');
      _error = '加载失败';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearInviteCode() {
    _lastInviteCode = null;
  }

  // --- internal ---

  Future<bool> _hasActiveBattle(String userId) async {
    try {
      final rooms = await _repo.getUserRooms(userId);
      return rooms.any((r) =>
          r.status == BattleRoomStatus.active ||
          r.status == BattleRoomStatus.waiting);
    } catch (_) {
      return false;
    }
  }

  Future<void> _activateRoom(BattleRoom room) async {
    final now = DateTime.now();
    final endsAt = now.add(Duration(days: room.durationDays));
    await SupabaseClientManager.instance
        .from('battle_rooms')
        .update({
      'status': 'active',
      'started_at': now.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
    }).eq('id', room.id);
  }

  Future<void> _settleBattle(
      BattleRoom room, List<BattleParticipant> participants) async {
    if (participants.length < 2) return;

    // Fetch both careers to compare return rates
    String? winnerId;
    double bestRate = double.negativeInfinity;

    for (final p in participants) {
      try {
        final data = await SupabaseClientManager.instance
            .from('careers')
            .select('total_pnl, initial_balance')
            .eq('id', p.careerId)
            .maybeSingle();

        if (data != null) {
          final json = data;
          final pnl = (json['total_pnl'] as num?)?.toDouble() ?? 0;
          final balance =
              (json['initial_balance'] as num?)?.toDouble() ?? 1;
          final rate = balance > 0 ? pnl / balance : 0.0;
          if (rate > bestRate) {
            bestRate = rate;
            winnerId = p.userId;
          }
        }
      } catch (_) {
        continue;
      }
    }

    if (winnerId != null) {
      await _repo.completeRoom(room.id, winnerId);
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
