import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  SupabaseClientManager._();

  // Replace with actual values before deployment
  static const _url = 'YOUR_SUPABASE_URL';
  static const _anonKey = 'YOUR_SUPABASE_ANON_KEY';

  static late final SupabaseClient client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
    client = Supabase.instance.client;
  }

  static SupabaseClient get instance => client;
}
