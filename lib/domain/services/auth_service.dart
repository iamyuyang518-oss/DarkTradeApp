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

enum AuthState { guest, loggedIn }

class AuthService extends ChangeNotifier {
  AuthState _state = AuthState.guest;
  String? _username;
  String? _userId;
  bool _initialized = false;
  StreamSubscription? _authListener;

  CareerService? _careerService;
  TradeHistoryService? _tradeHistoryService;

  // ---- public getters ----

  AuthState get state => _state;
  String? get username => _username;
  String? get userId => _userId;
  bool get isLoggedIn => _state == AuthState.loggedIn;
  bool get initialized => _initialized;

  AuthService() {
    _init();
  }

  // ---- wire services after provider tree is built ----

  void wireServices(CareerService cs, TradeHistoryService th) {
    _careerService = cs;
    _tradeHistoryService = th;
    if (_state == AuthState.loggedIn) {
      _setupRemoteRepos();
    }
  }

  // ---- internal helpers ----

  String _virtualEmail(String username) => '$username@darktrade.app';

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
    } catch (e) {
      debugPrint('[AuthService] _init error: $e');
    }
    _initialized = true;
    notifyListeners();

    _authListener = SupabaseClientManager.instance.auth.onAuthStateChange.listen(
      (event) {
        final s = event.session;
        if (s != null && _state != AuthState.loggedIn) {
          _state = AuthState.loggedIn;
          _userId = s.user.id;
          _loadProfile();
          _setupRemoteRepos();
          notifyListeners();
        } else if (s == null && _state == AuthState.loggedIn) {
          _logoutLocal();
        }
      },
    );
  }

  Future<void> _loadProfile() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final data = await SupabaseClientManager.instance
          .from('profiles')
          .select('username')
          .eq('id', uid)
          .maybeSingle();
      if (data != null) {
        _username = (data)['username'] as String?;
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
      if (res.user == null) return '注册失败，请重试';

      final uid = res.user!.id;
      final answerHash = _hashAnswer(securityAnswer);

      await SupabaseClientManager.instance.from('profiles').insert({
        'id': uid,
        'username': username,
        'display_name': username,
        'security_question': securityQuestion.trim(),
        'security_answer_hash': answerHash,
      });

      _state = AuthState.loggedIn;
      _userId = uid;
      _username = username;
      _setupRemoteRepos();
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
      return (data)['security_question'] as String?;
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

      final storedHash = (data)['security_answer_hash'] as String?;
      if (storedHash != _hashAnswer(answer)) return '答案错误';

      final userId = (data)['id'] as String;

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
    _state = AuthState.guest;
    _username = null;
    _userId = null;
    _clearRemoteRepos();
    notifyListeners();
  }

  @override
  void dispose() {
    _authListener?.cancel();
    super.dispose();
  }
}
