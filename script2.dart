import 'dart:io';

Future<void> main() async {
  final file = File('lib/pages/admin_clubs_screen.dart');
  var content = await file.readAsString();

  final regexSaveClub = RegExp(r'Future<void> _saveClub\([^)]+\) async \{[\s\S]*?(?=Future<void> _deleteClub|\Z)', multiLine: true);
  final regexDeleteClub = RegExp(r'Future<void> _deleteClub\(Map<String, dynamic> club\) async \{[\s\S]*?(?=Widget build|\Z)', multiLine: true);

  content = content.replaceAll(regexSaveClub, '''Future<void> _saveClub(Map<String, dynamic>? existing) async {
    if (!formKey.currentState!.validate()) return;

    setState(() => saving = true);
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showMessage('Sessão expirada. Faça login novamente.');
      setState(() => saving = false);
      return;
    }

    try {
      final clubData = {
        'name': name.text.trim(),
        'cnpj': cnpj.text.trim(),
        'phone': phone.text.trim(),
        'street': street.text.trim(),
        'number': number.text.trim(),
        'neighborhood': neighborhood.text.trim(),
        'complement': complement.text.trim(),
        'state': selectedState,
        'city': selectedCity,
        'cr_number': crNumber.text.trim(),
        'document_number': documentNumber.text.trim(),
      };

      if (existing != null) {
        await _supabase.from('clubs').update(clubData).eq('id', existing['id']);
      } else {
        clubData['status'] = 'A'; // Admin adding is auto-approved
        await _supabase.from('clubs').insert(clubData);
      }

      _showMessage(existing == null ? 'Clube adicionado!' : 'Clube atualizado!');
      _loadAdminClubs();
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      _showMessage('Erro ao salvar clube: \');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  ''');

  content = content.replaceAll(regexDeleteClub, '''Future<void> _deleteClub(Map<String, dynamic> club) async {
    if (_saving) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atenção: Exclusão Global', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Tem certeza que deseja excluir esse clube do banco de dados MUNDIAL? Qualquer atirador que tenha selecionado ele perderá o vínculo instantaneamente! Essa ação é irreversível.'),
        backgroundColor: AppColors.of(context).card,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.of(context).textPrimary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Globalmente', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await _supabase.from('clubs').delete().eq('id', club['id']);
      _showMessage('Clube global excluído.');
      _loadAdminClubs();
    } catch (e) {
      _showMessage('Erro ao excluir: \');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _approveClub(Map<String, dynamic> club) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _supabase.from('clubs').update({'status': 'A'}).eq('id', club['id']);
      _showMessage('Clube aprovado e oficializado!');
      _loadAdminClubs();
    } catch (e) {
      _showMessage('Erro ao aprovar: \');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ''');

  content = content.replaceAll('return _upsertClub(', '// removed');
  content = content.replaceAll(
    RegExp(r'Future<String> _upsertClub\(\{[\s\S]*?\}', multiLine: true), ''
  );

  await file.writeAsString(content);
}
