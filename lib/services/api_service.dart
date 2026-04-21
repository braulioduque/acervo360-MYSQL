import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String _baseUrlCached = 'https://data.inforfile.com.br';
  
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrlCached = prefs.getString('api_base_url') ?? 'https://data.inforfile.com.br';
  }

  static String get baseUrl => _baseUrlCached;

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
    _baseUrlCached = url;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', id);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveToken(data['session']['access_token']);
      await saveUserId(data['user']['id']);
      await saveUserEmail(data['user']['email']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'full_name': fullName}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveToken(data['session']['access_token']);
      await saveUserId(data['user']['id']);
      await saveUserEmail(data['user']['email']);
    }
    return data;
  }

  static Future<void> logout() async {
    await removeToken();
  }

  // Profile
  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/profiles/me'), headers: await _headers());
    return jsonDecode(response.body);
  }

  static Future<void> updateProfile(Map<String, dynamic> profile) async {
    await http.post(
      Uri.parse('$baseUrl/profiles/upsert'),
      headers: await _headers(),
      body: jsonEncode(profile),
    );
  }

  // Generic CRUD
  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('$baseUrl/$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Erro na requisição GET: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro na requisição POST (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body);
  }

  static Future<void> delete(String endpoint, String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$endpoint/$id'), headers: await _headers());
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro na requisição DELETE: ${response.statusCode}');
    }
  }

  // Upload
  static Future<String> uploadFile(File file, String folder) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/$folder'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['path'];
    }
    throw Exception('Erro no upload: ${response.statusCode}');
  }

  static String getPublicUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl/uploads/$path';
  }
}
