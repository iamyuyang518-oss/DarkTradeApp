import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  SupabaseClientManager._();

  static const _url = 'https://pzugizdkhvppqadiaxgq.supabase.co';
  static const _anonKey = 'sb_publishable_opvEIIVFPbsIUgAAbefc4Q_fzxbwsY7';

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
