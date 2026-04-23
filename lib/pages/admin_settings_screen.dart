import 'package:flutter/material.dart';
import 'package:acervo360/services/api_service.dart';
import 'package:acervo360/theme/app_theme.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  final TextEditingController _crController = TextEditingController();
  final TextEditingController _crafController = TextEditingController();
  final TextEditingController _gteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ApiService.getAppSettings();
      setState(() {
        _crController.text = (settings['cr_days'] ?? 90).toString();
        _crafController.text = (settings['craf_days'] ?? 90).toString();
        _gteController.text = (settings['gte_days'] ?? 45).toString();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar configurações: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ApiService.updateAppSettings({
        'cr_days': int.parse(_crController.text),
        'craf_days': int.parse(_crafController.text),
        'gte_days': int.parse(_gteController.text),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas com sucesso!')),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text('Prazos de Alerta'),
        backgroundColor: colors.card,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONFIGURAÇÃO DE PRAZOS',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Defina com quantos dias de antecedência o sistema deve começar a mostrar alertas no dashboard.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    _buildInputField(
                      label: 'Dias para alerta de CR',
                      controller: _crController,
                      icon: Icons.badge_outlined,
                      context: context,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'Dias para alerta de CRAF',
                      controller: _crafController,
                      icon: Icons.inventory_2_outlined,
                      context: context,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'Dias para alerta de GTe',
                      controller: _gteController,
                      icon: Icons.description_outlined,
                      context: context,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'SALVAR CONFIGURAÇÕES',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required BuildContext context,
  }) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: colors.accent),
            filled: true,
            fillColor: colors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.accent, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Obrigatório';
            if (int.tryParse(value) == null) return 'Valor inválido';
            return null;
          },
        ),
      ],
    );
  }
}
