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

      if (!mounted) return;
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
