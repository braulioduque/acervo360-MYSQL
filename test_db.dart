import 'package:supabase/supabase.dart';

Future<void> main() async {
  print('Inicializando...');
  try {
    final client = SupabaseClient('https://svjkcjgatplhlazzmzin.supabase.co', 'sb_publishable_rVrwVM1pXF54q6S1MqI2mg_SPisIR0g');
    print('Testando schema de clubs...');
    final data = await client.from('clubs').select().limit(1);
    print('Tabela clubs listada. Ok: $data');

    print('Testando schema de user_clubs...');
    final userClubsData = await client.from('user_clubs').select().limit(1);
    print('Tabela user_clubs listada. Ok: $userClubsData');
  } catch (e) {
    print('Erro: $e');
  }
}
