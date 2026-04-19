import 'package:acervo360/models/subscription_plan.dart';
import 'package:acervo360/services/api_service.dart';
import 'package:flutter/foundation.dart';

class SubscriptionService {
  /// Retorna a lista de planos de assinatura ativos.
  static Future<List<SubscriptionPlan>> listPlans() async {
    try {
      final response = await ApiService.get('subscriptions/plans');
      return (response as List)
          .map((data) => SubscriptionPlan.fromMap(data))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Verifica se o usuário tem assinatura ativa.
  /// Retorna `true` se ativa, `false` se expirada ou inexistente.
  /// Garante que o usuário tenha uma assinatura.
  /// Se não existir, cria um trial de 30 dias.
  static Future<void> ensureSubscriptionExists(String userId) async {
    try {
      await ApiService.post('subscriptions/ensure', {});
    } catch (_) {
      // Silencia erros
    }
  }

  /// Verifica se o usuário tem assinatura ativa.
  /// Retorna `true` se ativa, `false` se expirada ou inexistente.
  static Future<bool> isSubscriptionActive(String userId) async {
    try {
      // Garante que exista uma assinatura (cria trial se necessário)
      await ensureSubscriptionExists(userId);

      final row = await ApiService.get('subscriptions/me');
      if (row == null) return false;

      final plan = row['plan'] as String?;
      final endDateStr = row['end_date'] as String?;

      if (plan == 'lifetime') return true;
      if (endDateStr == null) return false;

      final endDate = DateTime.tryParse(endDateStr);
      if (endDate == null) return false;

      final now = DateTime.now().toUtc();
      if (now.isAfter(endDate)) {
        return false;
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  /// Retorna os dados da assinatura do usuário.
  static Future<Map<String, dynamic>?> getSubscription(String userId) async {
    try {
      return await ApiService.get('subscriptions/me') as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Simula a compra de um plano.
  static Future<bool> purchasePlan(String userId, String plan, double price) async {
    try {
      final response = await ApiService.post('subscriptions/purchase', {
        'userId': userId,
        'plan': plan,
        'price': price,
      });
      return response['success'] == true;
    } catch (e) {
      debugPrint('Erro em purchasePlan: $e');
      return false;
    }
  }

  /// Retorna quantos dias restam na assinatura atual.
  static Future<int> daysRemaining(String userId) async {
    final sub = await getSubscription(userId);
    if (sub == null) return 0;

    if (sub['plan'] == 'lifetime') return 99999;

    final endDateStr = sub['end_date'] as String?;
    if (endDateStr == null) return 0;

    final endDate = DateTime.tryParse(endDateStr);
    if (endDate == null) return 0;

    final diff = endDate.difference(DateTime.now().toUtc()).inDays;
    return diff > 0 ? diff : 0;
  }
}
