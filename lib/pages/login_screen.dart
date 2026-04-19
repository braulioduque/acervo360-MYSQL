import 'package:acervo360/pages/dashboard_screen.dart';
import 'package:acervo360/pages/terms_of_use_screen.dart';
import 'package:acervo360/pages/subscription_screen.dart';
import 'package:acervo360/services/api_service.dart';
import 'package:acervo360/services/biometric_service.dart';
import 'package:acervo360/services/subscription_service.dart';
import 'package:acervo360/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:acervo360/pages/forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isSubmitting = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final enabled = await BiometricService.isBiometricEnabled();
    final supported = await BiometricService.isDeviceSupported();
    if (mounted) {
      setState(() => _biometricAvailable = enabled && supported);
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isSubmitting = true);
    try {
      final authenticated = await BiometricService.authenticate();
      if (!authenticated) {
        if (mounted) _showMessage('Autenticação biométrica cancelada.');
        return;
      }

      final credentials = await BiometricService.getSavedCredentials();
      if (credentials == null) {
        if (mounted) {
          _showMessage('Credenciais não encontradas. Faça login manualmente.');
          await BiometricService.disableBiometric();
          setState(() => _biometricAvailable = false);
        }
        return;
      }

      final data = await ApiService.login(credentials.email, credentials.password);
      if (data['error'] != null) {
        if (mounted) _showMessage(data['error']);
        return;
      }

      if (!mounted) return;

      final userId = data['user']['id'];
      if (userId != null) {
        final isActive = await SubscriptionService.isSubscriptionActive(userId);
        if (!mounted) return;

        if (!isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionScreen(showExpiredMessage: true),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } catch (_) {
      if (mounted) _showMessage('Falha na autenticação biométrica.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu e-mail';
    }

    final input = value.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(input)) {
      return 'Informe um e-mail válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe sua senha';
    }

    if (value.length < 6) {
      return 'A senha deve ter ao menos 6 caracteres';
    }

    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      final data = await ApiService.login(email, password);
      if (data['error'] != null) {
        if (mounted) _showMessage(data['error']);
        return;
      }

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', email);
      } else {
        await prefs.remove('remembered_email');
      }

      // Atualizar credenciais biométricas se ativada
      final biometricEnabled = await BiometricService.isBiometricEnabled();
      if (biometricEnabled) {
        await BiometricService.enableBiometric(email, password);
      }

      if (!mounted) return;

      final userId = data['user']['id'];
      if (userId != null) {
        final isActive = await SubscriptionService.isSubscriptionActive(userId);
        if (!mounted) return;

        if (!isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionScreen(showExpiredMessage: true),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Não foi possível autenticar agora. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    );
  }

  void _openRegisterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfUsePage(showButtons: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield,
                        color: colors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Gerenciar Acervo',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      'assets/images/login_banner.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Acesso Seguro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apenas pessoal autorizado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'E-mail',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: colors.textPrimary),
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    hintText: 'voce@dominio.com',
                    hintStyle: TextStyle(color: colors.textMuted),
                    prefixIcon: Icon(Icons.person, color: colors.textMuted),
                    filled: true,
                    fillColor: colors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    errorStyle: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Senha',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: colors.textPrimary),
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    hintText: 'Digite sua senha',
                    hintStyle: TextStyle(color: colors.textMuted),
                    prefixIcon: Icon(Icons.lock, color: colors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: colors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: colors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    errorStyle: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: _isSubmitting
                                ? null
                                : (val) => setState(() => _rememberMe = val ?? false),
                            side: BorderSide(color: colors.textMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lembrar-me',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _isSubmitting ? null : _handleForgotPassword,
                      child: Text(
                        'Esqueci minha senha',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ENTRAR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.login_rounded),
                            ],
                          ),
                  ),
                ),
                // ── Botão Biometria ──
                if (_biometricAvailable) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: colors.cardBorder),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: colors.cardBorder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _handleBiometricLogin,
                      icon: const Icon(Icons.fingerprint_rounded, size: 28),
                      label: const Text(
                        'ENTRAR COM BIOMETRIA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.accent,
                        side: BorderSide(
                          color: colors.accent.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem uma conta? ',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _isSubmitting ? null : _openRegisterScreen,
                      child: Text(
                        'Cadastre-se',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: colors.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '256-BIT AES ENCRYPTION',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
