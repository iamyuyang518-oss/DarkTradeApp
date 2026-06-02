import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/data/models/battle_room.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/battle_service.dart';

class BattleDetailPage extends StatefulWidget {
  final String roomId;

  const BattleDetailPage({super.key, required this.roomId});

  @override
  State<BattleDetailPage> createState() => _BattleDetailPageState();
}

class _BattleDetailPageState extends State<BattleDetailPage> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final battle = context.read<BattleService>();
      battle.loadRoomDetail(widget.roomId);
      battle.startPolling(widget.roomId);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    context.read<BattleService>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final battle = context.watch<BattleService>();
    final auth = context.watch<AuthService>();
    final room = battle.currentRoom;
    final participants = battle.participantsFor(widget.roomId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(room?.name ?? '对战详情'),
        backgroundColor: AppColors.background,
      ),
      body: _buildBody(battle, auth, room, participants),
    );
  }

  Widget _buildBody(
    BattleService battle,
    AuthService auth,
    BattleRoom? room,
    List<BattleParticipant> participants,
  ) {
    if (battle.isLoading && room == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (battle.error != null && room == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(battle.error!,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => battle.loadRoomDetail(widget.roomId),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.gold),
                ),
                child: const Text('重试',
                    style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
        ),
      );
    }

    if (room == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Status header
        _buildStatusHeader(room),
        // Scoreboard
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Player 1 (creator)
              _buildPlayerCard(room, participants, 0, auth),
              const SizedBox(height: 16),
              // VS divider
              const Center(
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Player 2 or placeholder
              participants.length >= 2
                  ? _buildPlayerCard(room, participants, 1, auth)
                  : _buildWaitingOpponent(),
            ],
          ),
        ),
        // Bottom actions
        if (room.status == BattleRoomStatus.waiting &&
            room.creatorId == auth.userId)
          _buildCancelButton(battle, room),
        if (room.status == BattleRoomStatus.completed)
          _buildCompletedActions(battle),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStatusHeader(BattleRoom room) {
    Color statusColor;
    switch (room.status) {
      case BattleRoomStatus.waiting:
        statusColor = AppColors.gold;
      case BattleRoomStatus.active:
        statusColor = AppColors.up;
      case BattleRoomStatus.completed:
        statusColor = AppColors.textSecondary;
      case BattleRoomStatus.cancelled:
        statusColor = AppColors.unselectedText;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  room.status.displayLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (room.status == BattleRoomStatus.active && room.endsAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                room.countdownText,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (room.status == BattleRoomStatus.completed &&
              room.winnerId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('👑', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    room.winnerId ==
                            SupabaseClientManager
                                .instance.auth.currentUser?.id
                        ? '恭喜你获胜！'
                        : '对手获胜',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(
    BattleRoom room,
    List<BattleParticipant> participants,
    int index,
    AuthService auth,
  ) {
    if (index >= participants.length) return const SizedBox.shrink();

    final participant = participants[index];
    final isCurrentUser = participant.userId == auth.userId;
    final isWinner = room.winnerId == participant.userId;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchCareerStats(participant.careerId, participant.userId),
      builder: (context, snapshot) {
        final careerData = snapshot.data;
        final pnl = (careerData?['total_pnl'] as num?)?.toDouble() ?? 0;
        final initialBalance =
            (careerData?['initial_balance'] as num?)?.toDouble() ?? 100000;
        final trades = (careerData?['total_trades'] as num?)?.toInt() ?? 0;
        final wins = (careerData?['winning_trades'] as num?)?.toInt() ?? 0;
        final returnRate =
            initialBalance > 0 ? (pnl / initialBalance) * 100 : 0.0;
        final winRate = trades > 0 ? (wins / trades) * 100 : 0.0;
        final username = careerData?['username'] as String? ?? '未知用户';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? AppColors.gold.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: isCurrentUser
                ? Border.all(color: AppColors.gold, width: 1)
                : Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Player identity row
              Row(
                children: [
                  const Icon(Icons.person, color: AppColors.gold, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    username,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '我',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (isWinner)
                    const Icon(Icons.emoji_events,
                        color: AppColors.gold, size: 24),
                ],
              ),
              const SizedBox(height: 16),
              // Return rate
              Text(
                returnRate >= 0
                    ? '+${returnRate.toStringAsFixed(1)}%'
                    : '${returnRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: returnRate >= 0 ? AppColors.up : AppColors.down,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '收益率',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                      '盈亏', '¥${pnl >= 0 ? "+" : ""}${pnl.toStringAsFixed(0)}',
                      pnl >= 0 ? AppColors.up : AppColors.down),
                  _statItem('交易', '$trades 笔', AppColors.textPrimary),
                  _statItem('胜率', '${winRate.toStringAsFixed(0)}%',
                      AppColors.textPrimary),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingOpponent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_add, size: 48, color: AppColors.unselectedText),
          SizedBox(height: 12),
          Text(
            '等待对手加入...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '分享邀请码给你的好友',
            style: TextStyle(
              color: AppColors.unselectedText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BattleService battle, BattleRoom room) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('取消对战',
                    style: TextStyle(color: AppColors.textPrimary)),
                content: const Text('确定要取消这个对战房间吗？',
                    style: TextStyle(color: AppColors.textSecondary)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('暂不',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('确定取消',
                        style: TextStyle(color: AppColors.down)),
                  ),
                ],
              ),
            );

            if (confirmed == true && mounted) {
              await battle.cancelRoom(room.id);
              if (mounted) {
                Navigator.pop(context);
              }
            }
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.down),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('取消对战',
              style: TextStyle(color: AppColors.down)),
        ),
      ),
    );
  }

  Widget _buildCompletedActions(BattleService battle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('返回列表',
                  style: TextStyle(color: AppColors.gold)),
            ),
          ),
        ],
      ),
    );
  }

  /// Fetches career stats and the profile username for a participant.
  Future<Map<String, dynamic>?> _fetchCareerStats(
      String careerId, String userId) async {
    try {
      final careerData = await SupabaseClientManager.instance
          .from('careers')
          .select('total_pnl, initial_balance, total_trades, winning_trades')
          .eq('id', careerId)
          .maybeSingle();

      // Also fetch username from profiles
      final profileData = await SupabaseClientManager.instance
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();

      if (careerData == null) return null;

      final result = Map<String, dynamic>.from(careerData);
      if (profileData != null) {
        result['username'] =
            profileData['username'] as String? ??
                '未知用户';
      }

      return result;
    } catch (e) {
      return null;
    }
  }
}
