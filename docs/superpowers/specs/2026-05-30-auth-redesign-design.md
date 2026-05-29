# Auth System Redesign: Virtual Email Mapping

**Date:** 2026-05-30
**Status:** Design Approved
**Topic:** Replace email-based auth with zero-friction username+password registration, add security questions for password recovery, and fix all known auth bugs.

---

## 1. Goals

- **Zero-friction registration:** Username + password only, no email required by the user
- **Password recovery:** Custom security question + answer
- **Bug fixes:** Fix auto-login remote-repo sync, force-unwrap crashes, startup flash, silent error swallowing
- **Code quality:** Remove dead code, add auth state listener, proper null safety

---

## 2. Approach: Virtual Email Mapping

Supabase Auth requires an email for `signUp()` and `signInWithPassword()`. We generate a virtual email behind the scenes:

```
User input:   username + password
              ↓
AuthService:  username@darktrade.app (virtual, invisible to user)
              ↓
Supabase:     signUp / signInWithPassword with virtual email
```

The user never sees or needs to know about the virtual email.

---

## 3. Database Schema

### 3.1 `profiles` table (rebuild in Supabase dashboard)

```sql
profiles (
  id                    uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  username              text UNIQUE NOT NULL,
  display_name          text,
  security_question     text NOT NULL,
  security_answer_hash  text NOT NULL,
  created_at            timestamptz DEFAULT now()
)
```

- `username` — user-facing identifier, unique constraint enforced at DB level
- `security_answer_hash` — SHA-256 hash of the answer (never store plaintext)
- Old profiles table should be dropped and recreated since there are no real users yet

### 3.2 `auth.users` table (managed by Supabase)

- `email` stores `{username}@darktrade.app`
- `password` managed by Supabase's built-in hashing

---

## 4. API Design

### 4.1 AuthService (refactored)

```dart
class AuthService extends ChangeNotifier {
  AuthState _state;          // guest | loggedIn
  String? _username;
  String? _userId;
  bool _initialized = false; // true after _init() completes
  String? _error;

  // --- Public API ---

  /// Register with username + password + security question.
  /// Returns null on success, error message string on failure.
  Future<String?> register({
    required String username,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  });

  /// Login with username + password.
  /// Returns null on success, error message string on failure.
  Future<String?> login({
    required String username,
    required String password,
  });

  /// Step 1 of password recovery: get the security question for a username.
  /// Returns the question string, or null if username not found.
  Future<String?> getSecurityQuestion(String username);

  /// Step 2 of password recovery: verify answer and reset password.
  /// Returns null on success, error message string on failure.
  Future<String?> resetPassword({
    required String username,
    required String answer,
    required String newPassword,
  });

  /// Logout: clear Supabase session and reset all state.
  Future<void> logout();
}
```

### 4.2 Virtual Email Helper

```dart
String _virtualEmail(String username) => '$username@darktrade.app';
```

### 4.3 Answer Hashing

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String _hashAnswer(String answer) {
  return sha256.convert(utf8.encode(answer.trim().toLowerCase())).toString();
}
```

---

## 5. Flow Diagrams

### 5.1 Registration Flow

```
User: enters username + password + security question + answer
       ↓
AuthSheet._submit():
  1. Validate form (username 2-20 chars, password 6+ chars, confirm match,
     question not empty, answer not empty)
  2. Set _loading = true
  3. Call auth.register(username, password, question, answer)
       ↓
AuthService.register():
  1. virtualEmail = '$username@darktrade.app'
  2. Supabase signUp(email: virtualEmail, password: password)
  3. If res.user == null → return error
  4. Hash answer → sha256(answer.trim().toLowerCase())
  5. Insert into profiles (id, username, display_name, security_question,
     security_answer_hash)
  6. Set _state = loggedIn, _userId, _username
  7. _setupRemoteRepos()
  8. notifyListeners()
  9. Return null (success)
       ↓
AuthSheet._submit() (continued):
  4. If error → display red error text, _loading = false, return
  5. If success → show migration dialog if local data exists
  6. _loading = false (AFTER migration dialog)
  7. Close sheet
```

### 5.2 Login Flow

```
User: enters username + password
       ↓
AuthService.login():
  1. virtualEmail = '$username@darktrade.app'
  2. Supabase signInWithPassword(email: virtualEmail, password: password)
  3. On success: set _state, _userId, call _loadProfile()
  4. _setupRemoteRepos()
  5. notifyListeners()
```

### 5.3 Auto-Login (App Restart)

```
AuthService._init():
  1. Check Supabase currentSession
  2. If session exists → _state = loggedIn, _userId = session.user.id
  3. _loadProfile() → get username from profiles
  4. *** _setupRemoteRepos() ***  ← FIX: was missing before
  5. _initialized = true, notifyListeners()
```

### 5.4 Password Recovery Flow

```
User: taps "忘记密码？" on login sheet
       ↓
Step 1 — ForgotPasswordSheet:
  User enters username
  → auth.getSecurityQuestion(username)
  → If null: "用户名不存在"
  → If found: show the question
       ↓
Step 2 — Answer & Reset:
  User enters answer + new password + confirm new password
  → auth.resetPassword(username, answer, newPassword)
  → Internally:
    1. Fetch profile by username to get user_id and answer_hash
    2. Hash provided answer, compare to stored hash
    3. If mismatch → "答案错误"
    4. If match → call Supabase Edge Function "reset-password"
       with { user_id, new_password }
    5. Edge Function uses service_role to call
       supabase.auth.admin.updateUserById(userId, { password: newPassword })
    6. Return null (success)
  → Show "密码已重置，请重新登录"
  → Close sheet, return to login form

Note: Password reset requires a Supabase Edge Function because the
client-side updateUser() requires the user to be logged in, and
resetPasswordForEmail() sends an email to the virtual address which
the user cannot access. The Edge Function runs with service_role
permissions server-side.
```

---

## 6. Bug Fixes (from existing code analysis)

| # | Issue | Fix |
|---|-------|-----|
| 1 | Auto-login doesn't set remote repos | Call `_setupRemoteRepos()` inside `_init()` after successful session restore |
| 2 | Force-unwrap `currentUser!.id` crashes | Replace all `!` with null guards; return early or throw descriptive errors |
| 3 | Constructor fire-and-forget `_init()` causes guest→loggedIn flash | Add `initialized` check in widget tree; show loading/splash until true |
| 4 | Silent `catch (_) {}` everywhere | At minimum `debugPrint`; surface critical errors via `_error` field |
| 5 | `_loading = false` before migration dialog | Move `_loading = false` to AFTER the full post-login flow completes |
| 6 | `register()` doesn't check email-confirmation edge case | Not applicable after redesign (virtual email, no confirmation) |
| 7 | Dead Hive `auth` box | Remove from `HiveService` |
| 8 | No `onAuthStateChange` listener | Subscribe in `_init()`, react to token expiry/refresh/remote sign-out |
| 9 | No test coverage | Write unit tests for AuthService, widget tests for AuthSheet |
| 10 | `login()` force-unwraps `currentUser!` | Use null guard (see fix 2) |
| 11 | `CareerService._isLoggedIn` dead flag | Evaluate and remove or keep in sync with AuthService via listener |

---

## 7. UI Changes

### 7.1 AuthSheet — Login Mode

- Replace "邮箱" field with "用户名"
- Add "忘记密码？" text button below login button

### 7.2 AuthSheet — Register Mode

- Replace "邮箱" field with "用户名"
- Add "确认密码" field with match validation
- Add "安全问题" field (custom question input)
- Add "答案" field (answer input)
- Remove any remaining email-related UI

### 7.3 New: ForgotPasswordSheet

- Step 1: username input → fetch and display security question
- Step 2: answer input + new password + confirm password → reset
- States: loading, error, success

### 7.4 New: SplashScreen / Loading Guard

- In the widget tree (likely `main_tabs_page.dart` or `app.dart`), check `auth.initialized`
- If `false`, show a simple loading indicator (or branded splash) instead of the main content
- Prevents the guest-mode flash on auto-login restarts

---

## 8. Files Changed

| File | Change |
|------|--------|
| `lib/domain/services/auth_service.dart` | Major refactor: virtual email, security questions, bug fixes, auth listener |
| `lib/presentation/pages/profile/auth_sheet.dart` | New fields, password recovery link, form restructuring |
| `lib/presentation/pages/profile/forgot_password_sheet.dart` | **New file** — password recovery flow |
| `supabase/functions/reset-password/index.ts` | **New file** — Edge Function for password reset (service_role) |
| `lib/data/remote/supabase_client.dart` | Add `onAuthStateChange` subscription setup |
| `lib/data/local/hive_service.dart` | Remove unused `auth` box |
| `lib/app/main_tabs_page.dart` | Add `initialized` loading guard, fix remote repo setup on auto-login |
| `lib/presentation/pages/profile/profile_page.dart` | Minor: update to show username instead of email |
| `lib/data/repositories/supabase_career_repo.dart` | Replace `currentUser!.id` with null guard |
| `lib/data/repositories/supabase_trade_history_repo.dart` | Replace `currentUser!.id` with null guard |
| `lib/domain/services/career_service.dart` | Review `_isLoggedIn` flag |
| `lib/domain/services/trade_history_service.dart` | Review for consistency |
| `pubspec.yaml` | Add `crypto` dependency (for SHA-256 hashing) |
| `test/auth_service_test.dart` | **New file** — auth unit tests |
| `test/auth_sheet_test.dart` | **New file** — auth widget tests |

---

## 9. Dependencies

- `crypto: ^3.0.3` — SHA-256 hashing for security answers (already a transitive dep via Supabase; may need explicit addition)

---

## 10. Acceptance Criteria

- [ ] User can register with username + password + security question + answer (no email)
- [ ] User can login with username + password
- [ ] User can recover password using security question
- [ ] App auto-login works correctly after restart (includes remote repo setup)
- [ ] No null-safety violations in auth code
- [ ] No guest-mode flash on app startup
- [ ] All errors are surfaced to user, not silently swallowed
- [ ] Dead `auth` Hive box removed
- [ ] Unit tests pass for AuthService core flows
- [ ] Widget tests pass for AuthSheet
