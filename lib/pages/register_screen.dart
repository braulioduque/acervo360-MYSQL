import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:acervo360/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(_passwordController.text);
  bool get _hasConfirmInput => _confirmPasswordController.text.isNotEmpty;
  bool get _passwordsMatch =>
      _hasConfirmInput && _confirmPasswordController.text == _passwordController.text;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu nome completo';
    }

    if (value.trim().length < 3) {
      return 'Nome muito curto';
    }

    return null;
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
      return 'Informe uma senha';
    }

    if (!_hasMinLength) {
      return 'A senha deve ter ao menos 8 caracteres';
    }

    if (!_hasUppercase) {
      return 'A senha deve ter ao menos 1 letra maiúscula';
    }

    if (!_hasNumber) {
      return 'A senha deve ter ao menos 1 número';
    }

    if (!_hasSpecial) {
      return 'A senha deve ter ao menos 1 caractere especial';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a senha';
    }

    if (value != _passwordController.text) {
      return 'As senhas não coincidem';
    }

    return null;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    setState(() => _isSubmitting = true);
    setState(() => _isSubmitting = true);
    try {
      final data = await ApiService.register(email, password, name);
      
      if (data['error'] != null) {
        if (!mounted) return;
        _showMessage(data['error']);
        return;
      }

      if (!mounted) return;
      _showMessage('Conta criada com sucesso!');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível criar a conta agora.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _passwordRuleItem(String label, bool ok) {
    final color = ok ? Colors.green : Colors.redAccent;
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _confirmPasswordStatusItem() {
    if (!_hasConfirmInput) {
      return Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey, size: 18),
          const SizedBox(width: 8),
          Text(
            'Digite a confirmação para validar',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      );
    }

    final color = _passwordsMatch ? Colors.green : Colors.redAccent;
    return Row(
      children: [
        Icon(_passwordsMatch ? Icons.check_circle : Icons.cancel, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          _passwordsMatch ? 'Senhas coincidem' : 'Senhas não coincidem',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: _validateName,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  inputFormatters: [
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) => newValue.copyWith(
                        text: newValue.text.toLowerCase(),
                      ),
                    ),
                  ],
                  validator: _validateEmail,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _passwordRuleItem('Mínimo de 8 caracteres', _hasMinLength),
                const SizedBox(height: 4),
                _passwordRuleItem('Pelo menos 1 letra maiúscula', _hasUppercase),
                const SizedBox(height: 4),
                _passwordRuleItem('Pelo menos 1 número', _hasNumber),
                const SizedBox(height: 4),
                _passwordRuleItem('Pelo menos 1 caractere especial', _hasSpecial),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Confirmar senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _confirmPasswordStatusItem(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _handleRegister,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Criar conta'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
















