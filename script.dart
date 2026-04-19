import 'dart:io';

Future<void> main() async {
  final file = File('lib/pages/admin_clubs_screen.dart');
  var content = await file.readAsString();

  content = content.replaceAll(
    '''      final data = await _supabase
          .from('user_clubs')
          .select('id, user_id, club_id, clubs(*)')
          .eq('user_id', user.id);''',
    '''      final data = await _supabase
          .from('clubs')
          .select('*')
          .order('name');'''
  );

  content = content.replaceAll(
    '''      final List<Map<String, dynamic>> parsedObjects = [];
      for (var row in data) {
        if (row['clubs'] != null) {
          final clubDict = Map<String, dynamic>.from(row['clubs'] as Map);
          clubDict['user_club_id'] = row['id'];
          parsedObjects.add(clubDict);
        }
      }''',
    '''      final List<Map<String, dynamic>> parsedObjects = [];
      for (var row in data) {
        final clubDict = Map<String, dynamic>.from(row as Map);
        parsedObjects.add(clubDict);
      }'''
  );

  content = content.replaceAll(
    '''    final String? existingGlobalClubId = existing?['id']?.toString();
    final String? existingUserClubId = existing?['user_club_id']?.toString();

    name.text = existing?['name']?.toString() ?? '';
    selectedGlobalClubId = existingGlobalClubId;''',
    '''    final String? existingGlobalClubId = existing?['id']?.toString();

    name.text = existing?['name']?.toString() ?? '';
    selectedGlobalClubId = existingGlobalClubId;'''
  );

  await file.writeAsString(content);
}
