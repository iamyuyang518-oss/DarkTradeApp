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

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pop();
  }
}
