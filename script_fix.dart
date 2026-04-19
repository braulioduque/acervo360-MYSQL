import 'dart:io';

void main() {
  final file = File('lib/pages/admin_clubs_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(r'\${', r'${');
  content = content.replaceAll(r'\$e', r'$e');
  file.writeAsStringSync(content);
}
