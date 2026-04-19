import 'dart:io';

Future<void> main() async {
  final file = File('lib/pages/clubs_screen.dart');
  var content = await file.readAsString();

  content = content.replaceAll('ClubsPage', 'AdminClubsPage');
  content = content.replaceAll('clubs_screen.dart', 'admin_clubs_screen.dart');

  // Change the DB selection logic
  content = content.replaceAll(
    '''      final data = await _supabase
          .from('user_clubs')
          .select('id, user_id, club_id, clubs(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _clubs.clear();
      for (final row in data as List) {
        if (row['clubs'] != null) {
          final clubDict = Map<String, dynamic>.from(row['clubs'] as Map);
          clubDict['user_club_id'] = row['id'];
          _clubs.add(clubDict);
        }
      }''',
    '''      final data = await _supabase
          .from('clubs')
          .select('*')
          .order('name');

      _clubs.clear();
      for (final row in data as List) {
        final clubDict = Map<String, dynamic>.from(row as Map);
        _clubs.add(clubDict);
      }'''
  );

  // Replace delete function
  final regexDelete = RegExp(r'Future<void> _deleteClub\([^{]*\{[\s\S]*?\}    \} catch \([^\)]*\) \{[\s\S]*?\}[\s\S]*?\}');
  content = content.replaceAll(regexDelete, '''Future<void> _deleteClub(Map<String, dynamic> club) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exclusão Global', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Isso removerá o clube do banco de dados MUNDIAL. Essa ação é irreversível.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('clubs').delete().eq('id', club['id']);
      _loadAdminClubs();
    } catch (_) {
      _showMessage('Nao foi possivel excluir o clube.');
    }
  }''');

  // Replace the _saveClub logic (remove user_clubs upsert logic completely)
  final regexUpsertAndSave = RegExp(r'Future<String> _upsertClub\(\{[\s\S]*?\} catch \(\_\) \{[\s\S]*?return null;\s*\}');
  
  content = content.replaceAll(regexUpsertAndSave, '''Future<void> _saveClub(Map<String, dynamic>? existing) async {
    if (!formKey.currentState!.validate()) return;
    updateSaving(true);
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
        clubData['status'] = 'A'; // Admin approval
        await _supabase.from('clubs').insert(clubData);
      }

      _showMessage('Clube salvo!');
      _loadAdminClubs();
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      _showMessage('Falha ao salvar clube.');
    } finally {
      updateSaving(false);
    }
  }''');

  await File('lib/pages/admin_clubs_screen.dart').writeAsString(content);
}
