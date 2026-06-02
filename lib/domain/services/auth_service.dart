import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';
import 'package:dark_trade_app/data/repositories/supabase_career_repo.dart';
import 'package:dark_trade_app/data/repositories/supabase_trade_history_repo.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/domain/services/watchlist_service.dart';

enum AuthState { guest, loggedIn }

class AuthService extends ChangeNotifier {
  AuthState _state = AuthState.guest;
  String? _username;
  String? _userId;
  String _membershipTier = 'free';
  bool _initialized = false;
  StreamSubscription? _authListener;

  CareerService? _careerService;
  TradeHistoryService? _tradeHistoryService;
  WatchlistService? _watchlistService;

  static const _virtualDomain = '@darktrade.app';

  // ---- public getters ----

  AuthState get state => _state;
  String? get username => _username;
  String? get userId => _userId;
  bool get isLoggedIn => _state == AuthState.loggedIn;
  bool get isVip => _membershipTier == 'vip';
  String get membershipTier => _membershipTier;
  bool get initialized => _initialized;

  AuthService() {
    _init();
  }

  // ---- wire services after provider tree is built ----

  void wireServices(CareerService cs, TradeHistoryService th, WatchlistService? ws) {
    _careerService = cs;
    _tradeHistoryService = th;
    _watchlistService = ws;
    if (_state == AuthState.loggedIn) {
      _setupRemoteRepos();
      _watchlistService?.onLogin(_userId!);
    }
  }

  // ---- internal helpers ----

  /// Generate an ASCII-safe virtual email from username.
  /// Uses SHA-256 so the same username always maps to the same email,
  /// supporting Chinese / emoji / any Unicode in the display name.
  String _virtualEmail(String username) {
    final hash = sha256
        .convert(utf8.encode('darktrade:${username.trim().toLowerCase()}'))
        .toString()
        .substring(0, 20);
    return '$hash$_virtualDomain';
  }

  String _hashAnswer(String answer) {
    return sha256.convert(utf8.encode(answer.trim().toLowerCase())).toString();
  }

  void _setupRemoteRepos() {
    _careerService?.setRemoteRepo(SupabaseCareerRepo());
    _tradeHistoryService?.setRemoteRepo(SupabaseTradeHistoryRepo());
  }

  void _clearRemoteRepos() {
    _careerService?.clearRemoteRepo();
    _tradeHistoryService?.clearRemoteRepo();
  }

  // ---- init + auto-login ----

  Future<void> _init() async {
    try {
      final session = SupabaseClientManager.instance.auth.currentSession;
      if (session != null) {
        _state = AuthState.loggedIn;
        _userId = session.user.id;
        await _loadProfile();
        // Remote repos wired via wireServices() after widget tree ready
      }
      _authListener = SupabaseClientManager.instance.auth.onAuthStateChange.listen(
        (event) {
          final s = event.session;
          if (s != null && _state != AuthState.loggedIn) {
            _state = AuthState.loggedIn;
            _userId = s.user.id;
            _loadProfile();
            _setupRemoteRepos();
            _watchlistService?.onLogin(s.user.id);
            notifyListeners();
          } else if (s == null && _state == AuthState.loggedIn) {
            _logoutLocal();
          }
        },
      );
    } catch (e) {
      debugPrint('[AuthService] _init error: $e');
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final data = await SupabaseClientManager.instance
          .from('profiles')
          .select('username, membership_tier')
          .eq('id', uid)
          .maybeSingle();
      if (data != null) {
        _username = data['username'] as String?;
        _membershipTier =
            data['membership_tier'] as String? ?? 'free';
      }
    } catch (e) {
      debugPrint('[AuthService] _loadProfile error: $e');
    }
  }

  // ---- register (username + password + security question) ----

  Future<String?> register({
    required String username,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      final virtualEmail = _virtualEmail(username);
      final res = await SupabaseClientManager.instance.auth.signUp(
        email: virtualEmail,
        password: password,
      );
      final user = res.user;
      if (user == null) return '注册失败，请重试';

      final uid = user.id;
      final answerHash = _hashAnswer(securityAnswer);

      try {
        await SupabaseClientManager.instance.from('profiles').insert({
          'id': uid,
          'username': username,
          'display_name': username,
          'security_question': securityQuestion.trim(),
          'security_answer_hash': answerHash,
        });
      } catch (e) {
        // Profile insert failed but auth user exists. User is still
        // logged in; profile can be repaired later or on next login.
        debugPrint('[AuthService] profile insert failed (auth user exists): $e');
      }

      _state = AuthState.loggedIn;
      _userId = uid;
      _username = username;
      _setupRemoteRepos();
      _watchlistService?.onLogin(uid);
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('[AuthService] register error: $e');
      return '网络错误，请检查连接';
    }
  }

  // ---- login (username + password) ----

  Future<String?> login({
    required String username,
    required String password,
  }) async {
    try {
      final virtualEmail = _virtualEmail(username);
      await SupabaseClientManager.instance.auth.signInWithPassword(
        email: virtualEmail,
        password: password,
      );
      final uid = SupabaseClientManager.instance.auth.currentUser?.id;
      if (uid == null) return '登录失败，请重试';
      _state = AuthState.loggedIn;
      _userId = uid;
      await _loadProfile();
      _setupRemoteRepos();
      _watchlistService?.onLogin(uid);
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('[AuthService] login error: $e');
      return '网络错误，请检查连接';
    }
  }

  // ---- password recovery step 1: get security question ----

  Future<String?> getSecurityQuestion(String username) async {
    try {
      final data = await SupabaseClientManager.instance
          .from('profiles')
          .select('security_question')
          .eq('username', username)
          .maybeSingle();
      if (data == null) return null;
      return data['security_question'] as String?;
    } catch (e) {
      debugPrint('[AuthService] getSecurityQuestion error: $e');
      return null;
    }
  }

  // ---- password recovery step 2: verify answer + reset ----

  Future<String?> resetPassword({
    required String username,
    required String answer,
    required String newPassword,
  }) async {
    try {
      final data = await SupabaseClientManager.instance
          .from('profiles')
          .select('id, security_answer_hash')
          .eq('username', username)
          .maybeSingle();

      if (data == null) return '用户名不存在';

      final storedHash = data['security_answer_hash'] as String?;
      if (storedHash != _hashAnswer(answer)) return '答案错误';

      final userId = data['id'] as String;

      final res = await SupabaseClientManager.instance.functions.invoke(
        'reset-password',
        body: {'user_id': userId, 'new_password': newPassword},
      );

      if (res.data != null) {
        final parsed = res.data as Map<String, dynamic>?;
        if (parsed != null && parsed['error'] != null) {
          return parsed['error'] as String?;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[AuthService] resetPassword error: $e');
      return '重置失败，请检查网络';
    }
  }

  // ---- logout ----

  Future<void> logout() async {
    try {
      await SupabaseClientManager.instance.auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] logout signOut error: $e');
    }
    _logoutLocal();
  }

  void _logoutLocal() {
    if (_state == AuthState.guest) return; // already logged out
    _state = AuthState.guest;
    _username = null;
    _userId = null;
    _membershipTier = 'free';
    _clearRemoteRepos();
    _watchlistService?.onLogout();
    notifyListeners();
  }

  // ---- VIP activation ----

  Future<void> activateVip() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await SupabaseClientManager.instance
          .from('profiles')
          .update({'membership_tier': 'vip'}).eq('id', uid);
      _membershipTier = 'vip';
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] activateVip error: $e');
    }
  }

  @override
  void dispose() {
    _authListener?.cancel();
    super.dispose();
  }
}
