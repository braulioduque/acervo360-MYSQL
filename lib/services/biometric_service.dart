import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final _auth = LocalAuthentication();

  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyBiometricEmail = 'biometric_email';
  static const _keyBiometricPassword = 'biometric_password';

  /// Verifica se o dispositivo suporta biometria.
  static Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;

      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Verifica se o usuário ativou a biometria.
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Ativa a biometria e salva as credenciais localmente.
  static Future<void> enableBiometric(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, true);
    await prefs.setString(_keyBiometricEmail, email);
    await prefs.setString(_keyBiometricPassword, password);
  }

  /// Desativa a biometria e limpa as credenciais salvas.
  static Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, false);
    await prefs.remove(_keyBiometricEmail);
    await prefs.remove(_keyBiometricPassword);
  }

  /// Solicita autenticação biométrica ao SO.
  /// Retorna `true` se autenticado com sucesso.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Use sua biometria para acessar o app',
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }

  /// Retorna as credenciais salvas (email, password).
  /// Retorna `null` se não houver credenciais.
  static Future<({String email, String password})?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyBiometricEmail);
    final password = prefs.getString(_keyBiometricPassword);

    if (email == null || password == null || email.isEmpty || password.isEmpty) {
      return null;
    }

    return (email: email, password: password);
  }
}
