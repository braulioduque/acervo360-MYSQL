import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:acervo360/services/api_service.dart';
import 'package:acervo360/theme/app_theme.dart';

class HabitualityStatsPage extends StatefulWidget {
  const HabitualityStatsPage({super.key});

  @override
  State<HabitualityStatsPage> createState() => _HabitualityStatsPageState();
}

class _HabitualityStatsPageState extends State<HabitualityStatsPage> {
  bool _loading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();
  
  Map<String, dynamic> _stats = {
    'byFirearm': [],
    'byClub': [],
  };

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final data = await ApiService.getHabitualityStats(startStr, endStr);
      setState(() {
        _stats = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar estatísticas: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.of(context).accent,
              onPrimary: Colors.white,
              surface: AppColors.of(context).card,
              onSurface: AppColors.of(context).textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final byFirearm = (_stats['byFirearm'] as List? ?? []);
    final byClub = (_stats['byClub'] as List? ?? []);
    
    int totalHabitualities = 0;
    for (var f in byFirearm) {
      totalHabitualities += _toInt(f['habituality_count']);
    }

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text('Resumo de Habitualidades'),
        backgroundColor: colors.scaffold,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Selecionar Período',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(colors),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadStats,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(colors, totalHabitualities),
                          const SizedBox(height: 24),
                          _buildSectionTitle(colors, 'Por Arma', Icons.inventory_2_outlined),
                          const SizedBox(height: 12),
                          if (byFirearm.isEmpty)
                            _buildEmptySection(colors, 'Nenhuma habitualidade por arma no período.')
                          else
                            ...byFirearm.map((f) => _buildFirearmStatCard(colors, f)),
                          const SizedBox(height: 24),
                          _buildSectionTitle(colors, 'Por Clube / Local', Icons.location_on_outlined),
                          const SizedBox(height: 12),
                          if (byClub.isEmpty)
                            _buildEmptySection(colors, 'Nenhuma habitualidade por clube no período.')
                          else
                            ...byClub.map((c) => _buildClubStatCard(colors, c)),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(AppColors colors) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.card,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 14, color: colors.accent),
          const SizedBox(width: 8),
          Text(
            '${fmt.format(_startDate)} até ${fmt.format(_endDate)}',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _selectDateRange,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('ALTERAR', style: TextStyle(color: colors.accent, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppColors colors, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.accent, colors.accent.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL DE HABITUALIDADES',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            '$total',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'no período selecionado',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(AppColors colors, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.accent),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildFirearmStatCard(AppColors colors, Map<String, dynamic> f) {
    final count = _toInt(f['habituality_count']);
    final shots = _toInt(f['total_shots']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${f['brand']} ${f['model']}',
                      style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'SIGMA: ${f['sigma_number'] ?? 'N/I'} • ${f['caliber'] ?? ''}',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(colors, 'Habitualidades', '$count', Icons.history_edu_rounded),
              const SizedBox(width: 24),
              _buildStatItem(colors, 'Total de Disparos', '$shots', Icons.ads_click),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClubStatCard(AppColors colors, Map<String, dynamic> c) {
    final count = _toInt(c['habituality_count']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              c['club_name'] ?? 'Local não identificado',
              style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(AppColors colors, String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: colors.textMuted),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: colors.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptySection(AppColors colors, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(color: colors.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }
}
