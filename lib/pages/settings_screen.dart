import 'package:flutter/material.dart';
import 'package:acervo360/services/api_service.dart';
import 'package:acervo360/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _urlController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiService.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ApiService.setBaseUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas. Reinicie o app se necessário.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: colors.scaffold,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Servidor Backend',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Defina a URL base da API para conexão com o banco de dados local ou remoto.',
            style: TextStyle(color: colors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'URL da API',
              labelStyle: TextStyle(color: colors.textMuted),
              hintText: 'http://localhost:3000',
              hintStyle: TextStyle(color: colors.textMuted.withOpacity(0.5)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.accent),
              ),
              filled: true,
              fillColor: colors.card,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Salvar Alterações'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _urlController.text = 'http://localhost:3000';
            },
            child: Text(
              'Resetar para Padrão (Localhost)',
              style: TextStyle(color: colors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
