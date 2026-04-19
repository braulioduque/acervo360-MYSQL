import 'package:flutter/material.dart';
import 'package:acervo360/services/api_service.dart';
import 'package:acervo360/theme/app_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  int _step = 1; // 1: Email, 2: Code + New Password
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(_passwordController.text);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _passwordRuleItem(String label, bool ok, AppColors colors) {
    final color = ok ? Colors.green : colors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.circle_outlined, color: color, size: 14),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('auth/forgot-password', {
        'email': _emailController.text.trim(),
      });
      
      if (response['error'] != null) {
        _showMessage(response['error']);
      } else {
        _showMessage('Código enviado! Verifique seu e-mail.');
        setState(() => _step = 2);
      }
    } catch (e) {
      _showMessage('Erro ao enviar código: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_hasMinLength || !_hasUppercase || !_hasNumber || !_hasSpecial) {
      _showMessage('A senha não atende aos requisitos de segurança');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('auth/reset-password', {
        'email': _emailController.text.trim(),
        'token': _pinController.text.trim(),
        'newPassword': _passwordController.text,
      });

      if (response['error'] != null) {
        _showMessage(response['error']);
      } else {
        _showMessage('Senha redefinida com sucesso!');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showMessage('Erro ao redefinir senha: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        backgroundColor: colors.scaffold,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Recuperar Senha',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                _step == 1 ? Icons.email_outlined : Icons.lock_reset_outlined,
                size: 80,
                color: colors.accent,
              ),
              const SizedBox(height: 24),
              Text(
                _step == 1 
                  ? 'Informe seu e-mail para receber um código de recuperação.' 
                  : 'Digite o código de 6 dígitos enviado e sua nova senha.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              if (_step == 1) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: _buildInputDecoration('E-mail', Icons.email, colors),
                  validator: (v) => v == null || !v.contains('@') ? 'E-mail inválido' : null,
                ),
              ] else ...[
                // Mostrar e-mail como somente leitura
                TextFormField(
                  initialValue: _emailController.text,
                  readOnly: true,
                  style: TextStyle(color: colors.textMuted),
                  decoration: _buildInputDecoration('E-mail', Icons.email, colors),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: colors.textPrimary, letterSpacing: 8, fontWeight: FontWeight.bold, fontSize: 20),
                  textAlign: TextAlign.center,
                  decoration: _buildInputDecoration('Código PIN', Icons.numbers, colors),
                  validator: (v) => v?.length != 6 ? 'O código deve ter 6 dígitos' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: colors.textPrimary),
                  decoration: _buildInputDecoration('Nova Senha', Icons.lock, colors).copyWith(
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: colors.textMuted),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if ((v?.length ?? 0) < 8) return 'A senha deve ter ao menos 8 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _passwordRuleItem('Mínimo de 8 caracteres', _hasMinLength, colors),
                _passwordRuleItem('Pelo menos 1 letra maiúscula', _hasUppercase, colors),
                _passwordRuleItem('Pelo menos 1 número', _hasNumber, colors),
                _passwordRuleItem('Pelo menos 1 caractere especial', _hasSpecial, colors),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_step == 1 ? _sendCode : _resetPassword),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _step == 1 ? 'ENVIAR CÓDIGO' : 'REDEFINIR SENHA',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                ),
              ),
              if (_step == 2)
                TextButton(
                  onPressed: () => setState(() => _step = 1),
                  child: Text('Deseja trocar o e-mail?', style: TextStyle(color: colors.textMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, AppColors colors) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.textMuted),
      prefixIcon: Icon(icon, color: colors.textMuted),
      filled: true,
      fillColor: colors.inputFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.cardBorder)),
    );
  }
}
