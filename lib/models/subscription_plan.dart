class SubscriptionPlan {
  final String id;
  final String planKey;
  final String title;
  final double price;
  final String periodLabel;
  final int monthsCount;
  final String? subtitleOverride;
  final String? badge;
  final bool isRecommended;
  final String? iconName;
  final int sortOrder;

  SubscriptionPlan({
    required this.id,
    required this.planKey,
    required this.title,
    required this.price,
    required this.periodLabel,
    required this.monthsCount,
    this.subtitleOverride,
    this.badge,
    this.isRecommended = false,
    this.iconName,
    this.sortOrder = 0,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id']?.toString() ?? '',
      planKey: map['plan_key']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      periodLabel: map['period_label']?.toString() ?? '',
      monthsCount: int.tryParse(map['months_count']?.toString() ?? '0') ?? 0,
      subtitleOverride: map['subtitle_override']?.toString(),
      badge: map['badge']?.toString(),
      isRecommended: map['is_recommended'] == 1 || map['is_recommended'] == true || map['is_recommended'] == '1',
      iconName: map['icon_name']?.toString(),
      sortOrder: int.tryParse(map['sort_order']?.toString() ?? '0') ?? 0,
    );
  }

  /// Calcula a economia comparada ao plano mensal.
  /// Retorna nulo se o plano for o mensal ou se não houver plano mensal para comparar.
  String? calculateSavings(double monthlyPrice) {
    if (subtitleOverride != null) return subtitleOverride;
    if (monthsCount <= 1) return null; // Plano mensal ou vitalício sem comparação direta fácil aqui

    final pricePerMonth = price / monthsCount;
    if (pricePerMonth >= monthlyPrice) return null;

    final savingsPercent = ((1 - (pricePerMonth / monthlyPrice)) * 100).round();
    return 'Economize $savingsPercent% em relação ao mensal';
  }
}
