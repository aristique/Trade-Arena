import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/validators.dart';

/// Экран входа с проверкой полей.
/// Настоящей авторизации пока нет: входит любой, кто прошёл проверку.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return; // ошибки уже под полями
    context.go('/market'); // go, а не push: экран входа уходит из стека
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        // Прокрутка нужна, чтобы при открытой клавиатуре не было переполнения
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      color: scheme.onPrimary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Добро пожаловать\nв TradeArena',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Торгуйте реальными акциями США, Индии и Европы '
                  'на виртуальные \$10 000 и соревнуйтесь с друзьями.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: validateEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: validatePassword,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: Icon(Icons.visibility_off_outlined),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Забыли пароль?'),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _submit, child: const Text('Войти')),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Text('Нет аккаунта? Зарегистрируйтесь'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
