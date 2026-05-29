# Auth System Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace email-based auth with username+password (virtual email mapping), add security-question password recovery, and fix all 11 known auth bugs.

**Architecture:** Virtual email (`username@darktrade.app`) bridges username-only registration to Supabase's email-based auth. A Supabase Edge Function with service_role handles password reset. All existing bugs (auto-login remote-repo sync, force-unwrap crashes, startup flash, silent catches, dead code) are fixed in the same pass.

**Tech Stack:** Flutter/Dart, Supabase Auth + Edge Functions, Provider, crypto package

---

### Task 1: Database Setup — Recreate profiles table + RLS

**Files:**
- Create: `supabase/migrations/20260530_recreate_profiles.sql`

- [ ] **Step 1: Create migration SQL file**

```bash
mkdir -p D:/DarkTradeApp/supabase/migrations
```

Create `supabase/migrations/20260530_recreate_profiles.sql`:

```sql
-- Drop old profiles table (no real users yet)
DROP TABLE IF EXISTS profiles CASCADE;

-- Recreate with new schema
CREATE TABLE profiles (
  id                    uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  username              text UNIQUE NOT NULL,
  display_name          text,
  security_question     text NOT NULL,
  security_answer_hash  text NOT NULL,
  created_at            timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can manage their own profile
CREATE POLICY "Users can manage own profile"
  ON profiles FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Anyone can read profiles for password recovery (username → security_question)
CREATE POLICY "Public can read profiles for recovery"
  ON profiles FOR SELECT
  USING (true);
```

- [ ] **Step 2: Run SQL in Supabase Dashboard**

Go to https://supabase.com/dashboard/project/pzugizdkhvppqadiaxgq → SQL Editor → paste and run the SQL above.
Expected: "Success. No rows returned."

- [ ] **Step 3: Delete old auth users**

Go to Supabase Dashboard → Authentication → Users → delete all existing users (they were test users with emails).
Expected: 0 users remaining.

- [ ] **Step 4: Commit**

```bash
cd D:/DarkTradeApp && git add supabase/migrations/20260530_recreate_profiles.sql && git commit -m "db: recreate profiles table with username, security_question, security_answer_hash"
```

---

### Task 2: Add crypto dep + remove dead Hive auth box

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/data/local/hive_service.dart`

- [ ] **Step 1: Add crypto dependency**

In `pubspec.yaml`, add after `enough_convert` line:
```yaml
  crypto: ^3.0.3
```

- [ ] **Step 2: Run pub get**

```bash
cd D:/DarkTradeApp && flutter pub get
```
Expected: exits 0.

- [ ] **Step 3: Remove dead `auth` box from HiveService**

In `lib/data/local/hive_service.dart`, delete:

Line 8 (`static const String authBox = 'auth';`), line 20 (`Hive.openBox(authBox),`), and line 28-29 (`static Box get auth => Hive.box(authBox);`).

Final file:
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'models/career.dart';
import 'models/trade_record.dart';

class HiveService {
  static const String careersBox = 'careers';
  static const String tradeHistoryBox = 'tradeHistory';
  static const String prefsBox = 'prefs';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CareerAdapter());
    Hive.registerAdapter(TradeRecordAdapter());
    Hive.registerAdapter(TradeTypeAdapter());
    Hive.registerAdapter(MarketTypeAdapter());
    await Future.wait([
      Hive.openBox<Career>(careersBox),
      Hive.openBox<TradeRecord>(tradeHistoryBox),
      Hive.openBox(prefsBox),
    ]);
  }

  static Box<Career> get careers => Hive.box<Career>(careersBox);
  static Box<TradeRecord> get tradeHistory =>
      Hive.box<TradeRecord>(tradeHistoryBox);
  static Box get prefs => Hive.box(prefsBox);
}
```

- [ ] **Step 4: Verify no remaining references**

```bash
cd D:/DarkTradeApp && grep -rn "authBox\|HiveService\.auth\|\.auth\s*=" lib/
```
Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/local/hive_service.dart && git commit -m "chore: add crypto dep, remove dead Hive auth box"
```

---

### Task 3: Create Supabase Edge Function for password reset

**Files:**
- Create: `supabase/functions/reset-password/index.ts`

- [ ] **Step 1: Create Edge Function file**

```bash
mkdir -p D:/DarkTradeApp/supabase/functions/reset-password
```

Create `supabase/functions/reset-password/index.ts`:
```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers':
          'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    const { user_id, new_password } = await req.json();
    if (!user_id || !new_password || new_password.length < 6) {
      return new Response(
        JSON.stringify({ error: 'Invalid parameters' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { error } = await supabaseAdmin.auth.admin.updateUserById(
      user_id,
      { password: new_password },
    );

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (_) {
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
```

- [ ] **Step 2: Deploy to Supabase**

Go to https://supabase.com/dashboard/project/pzugizdkhvppqadiaxgq → Edge Functions → Create Function → name: `reset-password` → paste the code → Deploy.
Expected: status shows "Deployed".

- [ ] **Step 3: Commit**

```bash
cd D:/DarkTradeApp && git add supabase/functions/ && git commit -m "feat: add reset-password Edge Function"
```

---

### Task 4: Refactor AuthService — virtual email, security questions, bug fixes

**Files:**
- Modify: `lib/domain/services/auth_service.dart` (full rewrite)

- [ ] **Step 1: Write new AuthService**

Replace entire `lib/domain/services/auth_service.dart`:

```dart
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
  StreamSubscription<AuthStateEvent>? _authListener;

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

      // functions.invoke returns FunctionResponse; data is decoded JSON
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
```

- [ ] **Step 2: Verify compilation**

```bash
cd D:/DarkTradeApp && flutter analyze lib/domain/services/auth_service.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/domain/services/auth_service.dart && git commit -m "refactor(auth): rewrite AuthService — virtual email, security questions, bug fixes, auth listener"
```

---

### Task 5: Fix null safety in Supabase repositories

**Files:**
- Modify: `lib/data/repositories/supabase_career_repo.dart`
- Modify: `lib/data/repositories/supabase_trade_history_repo.dart`

- [ ] **Step 1: Fix supabase_career_repo.dart force-unwraps**

In `lib/data/repositories/supabase_career_repo.dart`, line 61 — change:
```dart
    final userId = SupabaseClientManager.instance.auth.currentUser!.id;
```
to:
```dart
    final userId = SupabaseClientManager.instance.auth.currentUser?.id;
    if (userId == null) return;
```

And line 77 — change:
```dart
    final userId = SupabaseClientManager.instance.auth.currentUser!.id;
```
to:
```dart
    final userId = SupabaseClientManager.instance.auth.currentUser?.id;
    if (userId == null) return;
```

- [ ] **Step 2: Fix supabase_trade_history_repo.dart force-unwraps**

In `lib/data/repositories/supabase_trade_history_repo.dart`, line 78 — change:
```dart
    final userId = SupabaseClientManager.instance.auth.currentUser!.id;
```
to:
```dart
    final userId = SupabaseClientManager.instance.auth.currentUser?.id;
    if (userId == null) return;
```

And line 94 — change:
```dart
    final userId = SupabaseClientManager.instance.auth.currentUser!.id;
```
to:
```dart
    final userId = SupabaseClientManager.instance.auth.currentUser?.id;
    if (userId == null) return;
```

- [ ] **Step 3: Verify compilation**

```bash
cd D:/DarkTradeApp && flutter analyze lib/data/repositories/
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/data/repositories/supabase_career_repo.dart lib/data/repositories/supabase_trade_history_repo.dart && git commit -m "fix: replace force-unwrap currentUser!.id with null guards in Supabase repos"
```

---

### Task 6: Rewrite AuthSheet UI

**Files:**
- Modify: `lib/presentation/pages/profile/auth_sheet.dart` (full rewrite)

- [ ] **Step 1: Write new AuthSheet**

Replace entire `lib/presentation/pages/profile/auth_sheet.dart`:

```dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/data/repositories/supabase_career_repo.dart';
import 'package:dark_trade_app/data/repositories/supabase_trade_history_repo.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/presentation/pages/profile/forgot_password_sheet.dart';
import 'package:dark_trade_app/presentation/pages/profile/migration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key});

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _questionCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(_isLogin ? '登录' : '注册',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Username
              TextFormField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                  labelText: '用户名',
                  hintText: '2-20 位字母、数字或汉字',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 2) return '用户名至少 2 位';
                  if (v.trim().length > 20) return '用户名最多 20 位';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '6 位以上',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return '密码至少 6 位';
                  return null;
                },
              ),
              // Register-only fields
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPwdCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '确认密码',
                    hintText: '再次输入密码',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusSm)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return '两次输入的密码不一致';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _questionCtrl,
                  decoration: InputDecoration(
                    labelText: '安全问题（找回密码用）',
                    hintText: '自定义问题，如：我小时候最喜欢的老师姓什么？',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusSm)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请设置安全问题';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _answerCtrl,
                  decoration: InputDecoration(
                    labelText: '答案',
                    hintText: '答案（请牢记，用于找回密码）',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusSm)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入答案';
                    return null;
                  },
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.down, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.unselectedBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isLogin ? '登录' : '注册',
                        style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _isLogin = !_isLogin;
                  _error = null;
                }),
                child:
                    Text(_isLogin ? '没有账号？去注册' : '已有账号？去登录'),
              ),
              if (_isLogin)
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppDimens.radiusLg)),
                      ),
                      builder: (_) => const ForgotPasswordSheet(),
                    );
                  },
                  child: const Text('忘记密码？',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    String? error;
    if (_isLogin) {
      error = await auth.login(username: username, password: password);
    } else {
      error = await auth.register(
        username: username,
        password: password,
        securityQuestion: _questionCtrl.text.trim(),
        securityAnswer: _answerCtrl.text.trim(),
      );
    }

    if (error != null) {
      setState(() {
        _error = error;
        _loading = false;
      });
      return;
    }

    if (!mounted) return;

    if (auth.isLoggedIn) {
      final careerService = context.read<CareerService>();
      final tradeHistory = context.read<TradeHistoryService>();

      careerService.setRemoteRepo(SupabaseCareerRepo());
      tradeHistory.setRemoteRepo(SupabaseTradeHistoryRepo());

      if (careerService.careers.isNotEmpty) {
        final shouldImport = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => MigrationDialog(
            careerCount: careerService.careers.length,
            onImport: () => Navigator.of(context).pop(true),
            onSkip: () => Navigator.of(context).pop(false),
          ),
        );
        if (shouldImport == true) {
          await careerService.migrateLocalToRemote();
          await tradeHistory.migrateLocalToRemote();
        }
      }
    }

    setState(() => _loading = false);
    if (mounted) Navigator.of(context).pop();
  }
}
```

- [ ] **Step 2: Verify compilation (ForgotPasswordSheet error is OK for now)**

```bash
cd D:/DarkTradeApp && flutter analyze lib/presentation/pages/profile/auth_sheet.dart
```
Expected: may error about missing `forgot_password_sheet.dart` — that's created in Task 7.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/profile/auth_sheet.dart && git commit -m "refactor(auth): rewrite AuthSheet — username fields, security question, confirm password, forgot password link"
```

---

### Task 7: Create ForgotPasswordSheet

**Files:**
- Create: `lib/presentation/pages/profile/forgot_password_sheet.dart`

- [ ] **Step 1: Create ForgotPasswordSheet**

Create `lib/presentation/pages/profile/forgot_password_sheet.dart`:

```dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _usernameCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  String? _question;
  bool _questionLoaded = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _answerCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('找回密码',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_questionLoaded) ...[
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    hintText: '输入你注册时用的用户名',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusSm)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入用户名';
                    return null;
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('安全问题',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_question!,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _answerCtrl,
                  decoration: InputDecoration(
                    labelText: '答案',
                    hintText: '输入你设置的答案',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusSm)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入答案';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPwdCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '新密码',
                    hintText: '6 位以上',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusSm)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return '密码至少 6 位';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPwdCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '确认新密码',
                    hintText: '再次输入新密码',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusSm)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  validator: (v) {
                    if (v != _newPwdCtrl.text) return '两次输入的密码不一致';
                    return null;
                  },
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.down, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.unselectedBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_questionLoaded ? '重置密码' : '查询安全问题',
                        style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();

    if (!_questionLoaded) {
      final username = _usernameCtrl.text.trim();
      final question = await auth.getSecurityQuestion(username);
      if (question == null) {
        setState(() {
          _error = '用户名不存在';
          _loading = false;
        });
        return;
      }
      setState(() {
        _question = question;
        _questionLoaded = true;
        _loading = false;
      });
    } else {
      final username = _usernameCtrl.text.trim();
      final answer = _answerCtrl.text.trim();
      final newPassword = _newPwdCtrl.text;

      final error = await auth.resetPassword(
        username: username,
        answer: answer,
        newPassword: newPassword,
      );

      if (error != null) {
        setState(() {
          _error = error;
          _loading = false;
        });
        return;
      }

      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('密码已重置，请重新登录'),
            backgroundColor: AppColors.gold,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd D:/DarkTradeApp && flutter analyze lib/presentation/pages/profile/
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/profile/forgot_password_sheet.dart && git commit -m "feat: add ForgotPasswordSheet — security question password recovery flow"
```

---

### Task 8: Update MainTabsPage — add initialized loading guard + wire services

**Files:**
- Modify: `lib/app/main_tabs_page.dart`

- [ ] **Step 1: Add auth import + wire services in initState + loading guard in build**

In `lib/app/main_tabs_page.dart`, add import:
```dart
import 'package:dark_trade_app/domain/services/auth_service.dart';
```

In `initState()`, after `super.initState()`, wire services:
```dart
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final careerService = context.read<CareerService>();
    final tradeHistory = context.read<TradeHistoryService>();
    auth.wireServices(careerService, tradeHistory);
    context.read<TradeSelectionService>().addListener(_onTradeSelectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding());
  }
```

Replace the `build` method body to check `auth.initialized`:

Wrap the Column in the body with:
```dart
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: MainTabsPage.background,
      body: auth.initialized
          ? Column(
              children: [
                const GuestBanner(),
                Expanded(
                  child: IndexedStack(index: _index, children: _pages),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MainTabsPage.selectedGold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('正在加载...',
                      style: TextStyle(
                          color: MainTabsPage.unselectedGray, fontSize: 14)),
                ],
              ),
            ),
      bottomNavigationBar: auth.initialized
          ? Theme(
              data: Theme.of(context).copyWith(
                splashColor:
                    MainTabsPage.selectedGold.withValues(alpha: 0.12),
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                type: BottomNavigationBarType.fixed,
                backgroundColor: MainTabsPage.background,
                selectedItemColor: MainTabsPage.selectedGold,
                unselectedItemColor: MainTabsPage.unselectedGray,
                selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 12),
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.show_chart_outlined),
                      activeIcon: Icon(Icons.show_chart),
                      label: '行情'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      activeIcon: Icon(Icons.account_balance_wallet),
                      label: '资产'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.swap_horiz_outlined),
                      activeIcon: Icon(Icons.swap_horiz),
                      label: '交易'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      activeIcon: Icon(Icons.person),
                      label: '个人'),
                ],
              ),
            )
          : null,
    );
  }
```

- [ ] **Step 2: Verify compilation**

```bash
cd D:/DarkTradeApp && flutter analyze lib/app/main_tabs_page.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/app/main_tabs_page.dart && git commit -m "fix: add auth.initialized loading guard + wire services for auto-login remote repos"
```

---

### Task 9: Update ProfilePage — wire change password button

**Files:**
- Modify: `lib/presentation/pages/profile/profile_page.dart`

- [ ] **Step 1: Wire "修改密码" button to ForgotPasswordSheet**

In `lib/presentation/pages/profile/profile_page.dart`, add import:
```dart
import 'package:dark_trade_app/presentation/pages/profile/forgot_password_sheet.dart';
```

Replace the existing "修改密码" menu item (currently a stub at line 126-128):
```dart
              if (isLoggedIn)
                _menuItem('修改密码', Icons.lock_outline, () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppDimens.radiusLg)),
                    ),
                    builder: (_) => const ForgotPasswordSheet(),
                  );
                }),
```

- [ ] **Step 2: Also simplify logout — remove manual clearRemoteRepo calls**

In ProfilePage, the logout handler (line 143-149) manually calls `clearRemoteRepo()`. Since AuthService now handles this via `_logoutLocal()`, simplify to:
```dart
                  onPressed: () async {
                    await auth.logout();
                  },
```

- [ ] **Step 3: Verify compilation**

```bash
cd D:/DarkTradeApp && flutter analyze lib/presentation/pages/profile/profile_page.dart
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/profile/profile_page.dart && git commit -m "fix: wire change-password to ForgotPasswordSheet, simplify logout"
```

---

### Task 10: Clean CareerService._isLoggedIn flag

**Files:**
- Modify: `lib/domain/services/career_service.dart`

- [ ] **Step 1: Remove `_isLoggedIn`**

In `lib/domain/services/career_service.dart`:

Remove line 13: `bool _isLoggedIn = false;`
Remove line 25: `bool get isLoggedIn => _isLoggedIn;`
In `setRemoteRepo` (line 41-44), remove `_isLoggedIn = true;`:
```dart
  void setRemoteRepo(CareerRepository repo) {
    _remoteRepo = repo;
  }
```
In `clearRemoteRepo` (line 46-49), remove `_isLoggedIn = false;`:
```dart
  void clearRemoteRepo() {
    _remoteRepo = null;
  }
```

- [ ] **Step 2: Verify no remaining references**

```bash
cd D:/DarkTradeApp && grep -rn "isLoggedIn" lib/
```
Expected: only references inside `auth_service.dart` (which is correct).

- [ ] **Step 3: Verify compilation**

```bash
cd D:/DarkTradeApp && flutter analyze lib/domain/services/career_service.dart
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/domain/services/career_service.dart && git commit -m "chore: remove dead CareerService._isLoggedIn flag"
```

---

### Task 11: Write tests

**Files:**
- Create: `test/auth_service_test.dart`
- Create: `test/auth_sheet_test.dart`

- [ ] **Step 1: Write AuthService unit tests**

Create `test/auth_service_test.dart`:

```dart
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

    test('initialized is false before async init completes', () {
      expect(auth.initialized, false);
    });

    test('initialized becomes true after init completes', () async {
      // _init() runs in constructor as fire-and-forget
      // Wait for it to complete (may contact Supabase or fail)
      await Future.delayed(const Duration(seconds: 2));
      expect(auth.initialized, true);
    });
  });

  group('Answer hashing', () {
    // Replicates the hashing logic used by AuthService
    String hash(String answer) {
      return sha256
          .convert(utf8.encode(answer.trim().toLowerCase()))
          .toString();
    }

    test('same input → same hash', () {
      expect(hash('My Answer'), hash('My Answer'));
    });

    test('case insensitive', () {
      expect(hash('My Answer'), hash('my answer'));
    });

    test('whitespace trimmed', () {
      expect(hash('  hello  '), hash('hello'));
    });

    test('different answers → different hashes', () {
      expect(hash('one'), isNot(hash('two')));
    });
  });
}
```

- [ ] **Step 2: Write AuthSheet widget tests**

Create `test/auth_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/data/repositories/career_repository.dart';
import 'package:dark_trade_app/data/repositories/trade_history_repository.dart';
import 'package:dark_trade_app/data/local/models/career.dart';
import 'package:dark_trade_app/data/local/models/trade_record.dart';
import 'package:dark_trade_app/presentation/pages/profile/auth_sheet.dart';

class _FakeCareerRepo implements CareerRepository {
  @override
  Future<List<Career>> loadCareers() async => [];
  @override
  Future<void> saveCareer(Career career) async {}
  @override
  Future<void> deleteCareer(String id) async {}
  @override
  Future<void> saveAllCareers(List<Career> careers) async {}
  @override
  Future<List<Career>> migrateFromLocal() async => [];
}

class _FakeTradeHistoryRepo implements TradeHistoryRepository {
  @override
  Future<List<TradeRecord>> loadRecords(String careerId) async => [];
  @override
  Future<void> saveRecord(TradeRecord record) async {}
  @override
  Future<void> deleteRecord(String id) async {}
  @override
  Future<void> saveAllRecords(List<TradeRecord> records) async {}
  @override
  Future<List<TradeRecord>> migrateFromLocal(String careerId) async => [];
}

void main() {
  group('AuthSheet UI', () {
    late AuthService auth;
    late CareerService careerService;
    late TradeHistoryService tradeHistory;

    Widget buildWidget() {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: auth),
              ChangeNotifierProvider.value(value: careerService),
              ChangeNotifierProvider.value(value: tradeHistory),
            ],
            child: const AuthSheet(),
          ),
        ),
      );
    }

    setUp(() {
      auth = AuthService();
      careerService = CareerService(
        localRepo: _FakeCareerRepo(),
        tradeHistoryRepo: _FakeTradeHistoryRepo(),
      );
      tradeHistory = TradeHistoryService(localRepo: _FakeTradeHistoryRepo());
    });

    testWidgets('shows login form by default', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('登录'), findsWidgets); // title + button
      expect(find.text('用户名'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.text('忘记密码？'), findsOneWidget);
      expect(find.text('确认密码'), findsNothing);
      expect(find.text('安全问题（找回密码用）'), findsNothing);
    });

    testWidgets('can toggle to register mode', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('没有账号？去注册'));
      await tester.pump();

      expect(find.text('注册'), findsWidgets);
      expect(find.text('确认密码'), findsOneWidget);
      expect(find.text('安全问题（找回密码用）'), findsOneWidget);
      expect(find.text('答案'), findsOneWidget);
      expect(find.text('忘记密码？'), findsNothing);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Tap the login button
      await tester.tap(find.text('登录').last);
      await tester.pump();

      expect(find.text('用户名至少 2 位'), findsOneWidget);
      expect(find.text('密码至少 6 位'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3: Run tests**

```bash
cd D:/DarkTradeApp && flutter test test/auth_service_test.dart test/auth_sheet_test.dart
```
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/auth_service_test.dart test/auth_sheet_test.dart && git commit -m "test: add AuthService unit tests and AuthSheet widget tests"
```

---

### Task 12: Run full check

**Files:** (none — verification only)

- [ ] **Step 1: Run flutter analyze on entire project**

```bash
cd D:/DarkTradeApp && flutter analyze
```
Expected: no errors.

- [ ] **Step 2: Run all tests**

```bash
cd D:/DarkTradeApp && flutter test
```
Expected: all tests pass.

- [ ] **Step 3: Verify acceptance criteria**

Checklist:
- [ ] Registration uses username (no email field)
- [ ] Login uses username (no email field)
- [ ] ForgotPasswordSheet is accessible from login
- [ ] Auto-login sets remote repos (via wireServices)
- [ ] No `currentUser!` force-unwrap remains
- [ ] Guest-mode flash fixed (initialized loading guard)
- [ ] All catch blocks use `debugPrint`
- [ ] Dead Hive auth box removed
- [ ] Tests pass
