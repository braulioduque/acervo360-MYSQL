import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:acervo360/services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;


  bool get _newHasMinLength => _newPasswordController.text.length >= 8;
  bool get _newHasUppercase => RegExp(r'[A-Z]').hasMatch(_newPasswordController.text);
  bool get _newHasNumber => RegExp(r'[0-9]').hasMatch(_newPasswordController.text);
  bool get _newHasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(_newPasswordController.text);
  bool get _newHasConfirmInput => _confirmNewPasswordController.text.isNotEmpty;
  bool get _newPasswordsMatch =>
      _newHasConfirmInput && _confirmNewPasswordController.text == _newPasswordController.text;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a nova senha';
    }

    if (!_newHasMinLength) {
      return 'A senha deve ter ao menos 8 caracteres';
    }

    if (!_newHasUppercase) {
      return 'A senha deve ter ao menos 1 letra maiuscula';
    }

    if (!_newHasNumber) {
      return 'A senha deve ter ao menos 1 numero';
    }

    if (!_newHasSpecial) {
      return 'A senha deve ter ao menos 1 caractere especial';
    }

    return null;
  }

  String? _validateConfirmNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a nova senha';
    }

    if (value != _newPasswordController.text) {
      return 'As senhas nao coincidem';
    }

    return null;
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      final response = await ApiService.post('auth/change-password', {
        'currentPassword': _currentPasswordController.text,
        'newPassword': _newPasswordController.text,
      });

      if (response['error'] != null) {
        if (!mounted) return;
        _showMessage(response['error']);
        return;
      }

      if (!mounted) return;
      _showMessage('Senha alterada com sucesso.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      String message = 'Não foi possível alterar a senha agora.';
      
      // Tenta extrair a mensagem de erro formatada pelo servidor
      if (e.toString().contains('"error":"')) {
        try {
          final body = e.toString().split('): ').last;
          final data = Map<String, dynamic>.from(jsonDecode(body));
          message = data['error'] ?? message;
        } catch (_) {}
      } else if (e.toString().contains('401')) {
         message = 'Senha atual incorreta.';
      }

      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
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
    if (!_newHasConfirmInput) {
      return Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey, size: 18),
          const SizedBox(width: 8),
          Text(
            'Digite a confirmacao para validar',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      );
    }

    final color = _newPasswordsMatch ? Colors.green : Colors.redAccent;
    return Row(
      children: [
        Icon(_newPasswordsMatch ? Icons.check_circle : Icons.cancel, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          _newPasswordsMatch ? 'Senhas coincidem' : 'Senhas nao coincidem',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trocar senha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe a senha atual';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Senha atual',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed:
                          () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                      icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  validator: _validateNewPassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Nova senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _passwordRuleItem('Minimo de 8 caracteres', _newHasMinLength),
                const SizedBox(height: 4),
                _passwordRuleItem('Pelo menos 1 letra maiuscula', _newHasUppercase),
                const SizedBox(height: 4),
                _passwordRuleItem('Pelo menos 1 numero', _newHasNumber),
                const SizedBox(height: 4),
                _passwordRuleItem('Pelo menos 1 caractere especial', _newHasSpecial),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmNewPasswordController,
                  obscureText: _obscureConfirmNewPassword,
                  validator: _validateConfirmNewPassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Confirmar nova senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscureConfirmNewPassword = !_obscureConfirmNewPassword),
                      icon: Icon(
                        _obscureConfirmNewPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _confirmPasswordStatusItem(),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton.tonal(
                    onPressed: _isChangingPassword ? null : _changePassword,
                    child: _isChangingPassword
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Atualizar senha'),
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
