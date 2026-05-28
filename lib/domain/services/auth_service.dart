import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';

enum AuthState { guest, loggedIn }

class AuthService extends ChangeNotifier {
  AuthState _state = AuthState.guest;
  String? _username;
  String? _userId;
  bool _initialized = false;

  AuthState get state => _state;
  String? get username => _username;
  String? get userId => _userId;
  bool get isLoggedIn => _state == AuthState.loggedIn;
  bool get initialized => _initialized;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final session = SupabaseClientManager.instance.auth.currentSession;
      if (session != null) {
        _state = AuthState.loggedIn;
        _userId = session.user.id;
        await _loadProfile();
      }
    } catch (_) {
      // Supabase might not be initialized yet in test environments
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
          .select('username')
          .eq('id', uid)
          .maybeSingle();
      if (data != null) {
        _username = (data)['username'] as String?;
      }
    } catch (_) {
      // Profile might not exist yet
    }
  }

  /// Returns null on success, error message string on failure
  Future<String?> register(String username, String password) async {
    try {
      final email = '$username@darktrade.internal';
      final res = await SupabaseClientManager.instance.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user != null) {
        await SupabaseClientManager.instance.from('profiles').insert({
          'id': res.user!.id,
          'username': username,
          'display_name': username,
        });
        _state = AuthState.loggedIn;
        _userId = res.user!.id;
        _username = username;
        notifyListeners();
        return null;
      }
      return '注册失败，请重试';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '网络错误，请检查连接';
    }
  }

  /// Returns null on success, error message string on failure
  Future<String?> login(String username, String password) async {
    try {
      final email = '$username@darktrade.internal';
      await SupabaseClientManager.instance.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _state = AuthState.loggedIn;
      _userId = SupabaseClientManager.instance.auth.currentUser!.id;
      _username = username;
      await _loadProfile();
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '网络错误，请检查连接';
    }
  }

  Future<void> logout() async {
    try {
      await SupabaseClientManager.instance.auth.signOut();
    } catch (_) {
      // Ignore sign-out errors
    }
    _state = AuthState.guest;
    _username = null;
    _userId = null;
    notifyListeners();
  }
}
