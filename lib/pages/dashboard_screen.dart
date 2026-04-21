import 'package:acervo360/pages/account_screen.dart';
import 'package:acervo360/pages/clubs_screen.dart';
import 'package:acervo360/pages/firearms_screen.dart';
import 'package:acervo360/pages/gtes_screen.dart';
import 'package:acervo360/pages/habitualities_screen.dart';
import 'package:acervo360/pages/admin_screen.dart';
import 'package:acervo360/pages/subscription_screen.dart';
import 'package:acervo360/services/subscription_service.dart';
import 'package:acervo360/theme/app_theme.dart';
import 'package:acervo360/pages/settings_screen.dart';
import 'package:acervo360/services/api_service.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  bool _isAdmin = false;

  final GlobalKey<_HomeTabState> _homeKey = GlobalKey<_HomeTabState>();
  final GlobalKey<GtesPageState> _gtesKey = GlobalKey<GtesPageState>();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final data = await ApiService.getMyProfile();
      if (mounted && data['is_admin'] == 'S') {
        setState(() => _isAdmin = true);
      }
    } catch (_) {}
  }

  void _onTabTapped(int index) {
    if (index == 0 && _currentIndex == 0) {
      _homeKey.currentState?._loadDashboardData();
    } else if (index == 0) {
      _homeKey.currentState?._loadDashboardData();
    }
    setState(() => _currentIndex = index);
  }

  void _onAddGte() {
    setState(() => _currentIndex = 3);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gtesKey.currentState?.openGteForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tabs = [
      _HomeTab(
        key: _homeKey,
        onTabSelected: _onTabTapped,
        onAddGte: _onAddGte,
      ),
      const FirearmsPage(),
      const ClubsPage(),
      GtesPage(key: _gtesKey),
      const HabitualitiesPage(),
      const AccountPage(),
      if (_isAdmin) const AdminPage(),
    ];

    List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Início'),
      const BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Armas'),
      const BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Clubes'),
      const BottomNavigationBarItem(icon: Icon(Icons.description), label: 'GTes'),
      const BottomNavigationBarItem(icon: Icon(Icons.history_edu_rounded), label: 'Habit.'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
      if (_isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
    ];

    // Se a aba selecionada atual estiver fora do limite (ex: perdeu permissão de admin), volta pro Início
    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colors.scaffold,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: navItems,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Tab Home
// ──────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab({super.key, required this.onTabSelected, required this.onAddGte});

  final void Function(int) onTabSelected;
  final VoidCallback onAddGte;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _loadingProfile = true;
  String _userName = '';
  String _userRole = '';
  String _userCr = '';
  int _firearmsCount = 0;
  int _clubsCount = 0;
  int _gtesCount = 0;
  int _habitualitiesCount = 0;
  List<Map<String, dynamic>> _alerts = [];
  String? _avatarUrl;
  bool _isTrial = false;
  int _daysRemaining = 0;
  // Realtime removed

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Realtime setup removed

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait<dynamic>([
        ApiService.getMyProfile(),
        ApiService.get('firearms'),
        ApiService.get('user_clubs/me'),
        ApiService.get('gtes'),
        ApiService.get('habitualities'),
      ]);

      if (!mounted) return;

      final profile = results[0] as Map<String, dynamic>?;
      final firearms = results[1] as List;
      final clubs = results[2] as List;
      final gtes = results[3] as List;
      final habitualities = results[4] as List;

      final crCategories = profile?['cr_categories'];
      String roleLabel = '';
      if (crCategories != null) {
        if (crCategories is List) {
          roleLabel = crCategories.cast<dynamic>().map((e) => e.toString()).join(', ');
        } else if (crCategories is String) {
          roleLabel = crCategories;
        }
      }

      String? avatarPath = profile?['avatar_url']?.toString().trim();
      String? avatarSignedUrl;
      if (avatarPath != null && avatarPath.isNotEmpty) {
        avatarSignedUrl = ApiService.getPublicUrl(avatarPath);
      }

      setState(() {
        _userName = profile?['full_name'] ?? profile?['email'] ?? 'Usuário';
        _userCr = (profile?['cr_number'] ?? '').toString();
        _userRole = roleLabel;
        _firearmsCount = firearms.length;
        _clubsCount = clubs.length;
        _gtesCount = gtes.length;
        _habitualitiesCount = habitualities.length;
        _avatarUrl = avatarSignedUrl;

        final List<Map<String, dynamic>> newAlerts = [];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final upcomingLimit = today.add(const Duration(days: 61));

        final crValidUntilStr = profile?['cr_valid_until']?.toString();
        if (crValidUntilStr != null && crValidUntilStr.isNotEmpty) {
          final expiry = DateTime.tryParse(crValidUntilStr);
          if (expiry != null) {
            final expiryClean = DateTime(expiry.year, expiry.month, expiry.day);
            if (expiryClean.isBefore(upcomingLimit)) {
              final isExpired = expiryClean.isBefore(today);
              final diffDays = expiryClean.difference(today).inDays.abs();
              newAlerts.add({
                'title': 'Doc. do CR',
                'subtitle': isExpired ? 'Vencido há $diffDays dias' : 'Vencendo em $diffDays dias',
                'date': _formatShortDate(expiry),
                'color': isExpired ? Colors.redAccent : Colors.orangeAccent,
                'expiryDate': expiryClean,
              });
            }
          }
        }

        for (var f in firearms) {
          final validUntilStr = f['craf_valid_until']?.toString();
          if (validUntilStr != null && validUntilStr.isNotEmpty) {
            final expiry = DateTime.tryParse(validUntilStr);
            if (expiry != null) {
              final expiryClean = DateTime(expiry.year, expiry.month, expiry.day);
              if (expiryClean.isBefore(upcomingLimit)) {
                final isExpired = expiryClean.isBefore(today);
                final diffDays = expiryClean.difference(today).inDays.abs();
                final brand = f['brand'] ?? '';
                final model = f['model'] ?? '';
                final title = 'CRAF - $brand $model'.trim();
                newAlerts.add({
                  'title': title.isEmpty ? 'CRAF - Arma sem identificação' : title,
                  'subtitle': isExpired ? 'Vencido há $diffDays dias' : 'Vencendo em $diffDays dias',
                  'date': _formatShortDate(expiry),
                  'color': isExpired ? Colors.redAccent : Colors.orangeAccent,
                  'expiryDate': expiryClean,
                });
              }
            }
          }
        }

        for (var g in gtes) {
          final expiresAtStr = g['expires_at']?.toString();
          if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
            final expiry = DateTime.tryParse(expiresAtStr);
            if (expiry != null) {
              final expiryClean = DateTime(expiry.year, expiry.month, expiry.day);
              if (expiryClean.isBefore(upcomingLimit)) {
                final isExpired = expiryClean.isBefore(today);
                final diffDays = expiryClean.difference(today).inDays.abs();
                
                final brand = g['firearm_brand'] ?? '';
                final model = g['firearm_model'] ?? '';
                final clubName = g['destination_club_name'] ?? '';
                
                String title = 'GTe - $brand $model'.trim();
                if (title.isEmpty) title = 'GTe - Arma sem identificação';
                
                String subtitle = isExpired ? 'Vencida há $diffDays dias' : 'Vencendo em $diffDays dias';
                if (clubName.isNotEmpty) subtitle += ' - $clubName';
                
                newAlerts.add({
                  'title': title,
                  'subtitle': subtitle,
                  'date': _formatShortDate(expiry),
                  'color': isExpired ? Colors.redAccent : Colors.orangeAccent,
                  'expiryDate': expiryClean,
                });
              }
            }
          }
        }

        newAlerts.sort((a, b) => (a['expiryDate'] as DateTime).compareTo(b['expiryDate'] as DateTime));
        _alerts = newAlerts;
        _loadingProfile = false;
      });

      final sub = await SubscriptionService.getSubscription('me');
      if (mounted && sub != null) {
        final remaining = await SubscriptionService.daysRemaining('me');
        if (mounted) {
          setState(() {
            _isTrial = sub['plan'] == 'trial';
            _daysRemaining = remaining;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    }
  }

  String _formatShortDate(DateTime date) {
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: colors.card,
                    backgroundImage:
                        _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null
                        ? Icon(Icons.person, color: colors.textMuted, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _loadingProfile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 18,
                              width: 140,
                              decoration: BoxDecoration(
                                color: colors.cardBorder,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 12,
                              width: 100,
                              decoration: BoxDecoration(
                                color: colors.cardBorder,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              [         
                                if (_userCr.isNotEmpty) 'CR: $_userCr',
                                if (_userRole.isNotEmpty) _userRole,
                              ].join(' | '),
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.settings, color: colors.textPrimary, size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Badge(
                    label: Text(_alerts.length.toString()),
                    isLabelVisible: _alerts.isNotEmpty,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.notifications, color: colors.textPrimary, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isTrial)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.accent.withValues(alpha: 0.3), colors.card],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: colors.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trial · $_daysRemaining dias restantes',
                              style: TextStyle(
                                color: colors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Assine um plano e tenha tranquilidade o ano todo.',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: colors.accent,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Row(
              children: [
                _summaryCard(
                  'ARMAS',
                  _loadingProfile ? '--' : '$_firearmsCount',
                  colors.accent,
                  true,
                  onTap: () => widget.onTabSelected(1),
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  'CLUBES',
                  _loadingProfile ? '--' : '$_clubsCount',
                  colors.card,
                  false,
                  onTap: () => widget.onTabSelected(2),
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  'GTES',
                  _loadingProfile ? '--' : '$_gtesCount',
                  colors.card,
                  false,
                  secondaryTextColor: colors.accent,
                  onTap: () => widget.onTabSelected(3),
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  'HABIT.',
                  _loadingProfile ? '--' : '$_habitualitiesCount',
                  colors.card,
                  false,
                  onTap: () => widget.onTabSelected(4),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'AÇÕES RÁPIDAS',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onAddGte,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Nova GTe',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onTabSelected(4),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_edu_rounded, color: colors.textPrimary, size: 24),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              '+ Habitualidades',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VENCENDO EM BREVE/ALERTAS',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lista completa em breve.')),
                    );
                  },
                  child: Text(
                    'Ver todos',
                    style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _loadingProfile
                ? const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ))
                : _alerts.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Tudo em dia! Nenhuma GTe, CR ou CRAF vencendo.',
                            style: TextStyle(color: colors.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    : Column(
                        children: _alerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _alertItem(
                            alert['title'],
                            alert['subtitle'],
                            alert['date'],
                            alert['color'],
                          ),
                        )).toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String count, Color bgColor, bool isActive,
      {Color? secondaryTextColor, VoidCallback? onTap}) {
    final colors = AppColors.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: colors.cardBorder, width: 1) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive ? colors.textSecondary : colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  color: secondaryTextColor ?? colors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alertItem(String title, String subtitle, String date, Color accentColor) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              accentColor == Colors.redAccent
                  ? Icons.warning_amber_rounded
                  : Icons.hourglass_empty_rounded,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: colors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
