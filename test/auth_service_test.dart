import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';

void main() {
  group('AuthService initial state', () {
    late AuthService auth;

    setUp(() {
      auth = AuthService();
    });

    test('starts as guest', () {
      expect(auth.isLoggedIn, false);
      expect(auth.state, AuthState.guest);
      expect(auth.username, isNull);
      expect(auth.userId, isNull);
    });

    test('initialized is true after construction (init runs synchronously when Supabase unavailable)', () {
      // _init() runs synchronously because SupabaseClientManager.instance
      // throws LateInitializationError, which is caught, and _initialized
      // is set to true before the constructor returns.
      expect(auth.initialized, true);
    });
  });

  group('Answer hashing', () {
    String hash(String answer) {
      return sha256
          .convert(utf8.encode(answer.trim().toLowerCase()))
          .toString();
    }

    test('same input produces same hash', () {
      expect(hash('My Answer'), hash('My Answer'));
    });

    test('case insensitive', () {
      expect(hash('My Answer'), hash('my answer'));
    });

    test('whitespace trimmed', () {
      expect(hash('  hello  '), hash('hello'));
    });

    test('different answers produce different hashes', () {
      expect(hash('one'), isNot(hash('two')));
    });
  });
}
