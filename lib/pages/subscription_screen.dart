import 'package:acervo360/models/subscription_plan.dart';
import 'package:acervo360/services/api_service.dart';
import 'package:acervo360/services/subscription_service.dart';
import 'package:acervo360/theme/app_theme.dart';
import 'package:acervo360/pages/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  /// Se true, exibe mensagem de expiração do trial.
  final bool showExpiredMessage;

  const SubscriptionScreen({super.key, this.showExpiredMessage = false});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedPlan;
  bool _isProcessing = false;
  bool _isLoading = true;
  List<SubscriptionPlan> _plans = [];
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    final plans = await SubscriptionService.listPlans();
    if (mounted) {
      setState(() {
        _plans = plans;
        _isLoading = false;
        // Seleciona o recomendado por padrão
        final recommended = plans.where((p) => p.isRecommended).toList();
        if (recommended.isNotEmpty) {
          _selectedPlan = recommended.first.planKey;
        } else if (plans.isNotEmpty) {
          _selectedPlan = plans.first.planKey;
        }
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handlePurchase() async {
    if (_selectedPlan == null) {
      _showMessage('Selecione um plano antes de continuar.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = await ApiService.getUserId();
      
      if (userId != null) {
        // Encontrar o objeto do plano para pegar o preço
        final selectedPlanObj = _plans.firstWhere(
          (p) => p.planKey == _selectedPlan,
          orElse: () => _plans.first,
        );
        
        // Registra o interesse e dispara o e-mail no backend
        await SubscriptionService.purchasePlan(userId, _selectedPlan!, selectedPlanObj.price);
      }
    } catch (e) {
      // Erro ao registrar interesse
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }

    if (!mounted) return;

    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header highlight
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    Text(
                      'Em breve!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'O pagamento direto pelo app estará disponível em breve. Enquanto isso, nossa equipe pode ativar sua assinatura manualmente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: colors.inputFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.message_rounded,
                            color: Color(0xFF25D366),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ativação via WhatsApp',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '(31) 8412-6733',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: () {
                          // Navega para o Dashboard limpando a pilha de telas
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const DashboardPage()),
                            (route) => false,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Entendido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Botão Voltar (apenas quando não é tela de expiração) ──
                if (!widget.showExpiredMessage)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: colors.textSecondary,
                        size: 22,
                      ),
                      tooltip: 'Voltar',
                    ),
                  )
                else
                  const SizedBox(height: 16),

                // ── Ícone topo ──
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E56D1), Color(0xFF3B82F6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E56D1).withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Título ──
                Text(
                  'Escolha seu plano',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue usando o app com todos os recursos liberados',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Mensagem de expiração ──
                if (widget.showExpiredMessage)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.redAccent.withValues(alpha: 0.15),
                          Colors.orange.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_off_rounded, color: Colors.redAccent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seu período de teste terminou',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Para continuar usando todas as funcionalidades e não perder nenhum prazo, escolha um plano abaixo.',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Lista de Planos ──
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                    ),
                  )
                else if (_plans.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text(
                        'Nenhum plano disponível no momento.',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  )
                else
                  ..._plans.map((plan) {
                    final monthlyPlan = _plans.firstWhere(
                      (p) => p.planKey == 'monthly',
                      orElse: () => _plans.first,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildPlanCard(
                        plan: plan,
                        monthlyPrice: monthlyPlan.price,
                      ),
                    );
                  }),

                const SizedBox(height: 16),

                // ── Botão Assinar ──
                SizedBox(
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _selectedPlan != null
                          ? const LinearGradient(
                              colors: [Color(0xFF1E56D1), Color(0xFF3B82F6)],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade700,
                                Colors.grey.shade600,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _selectedPlan != null
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1E56D1).withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handlePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rocket_launch_rounded, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'ASSINAR AGORA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Banner promocional ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: colors.accent.withValues(alpha: 0.8),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mantenha suas documentações sempre em dia. Assine e tenha tranquilidade durante todo o ano.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Rodapé legal ──
                Text(
                  'Ao assinar, você concorda com nossos Termos de Uso e Política de Privacidade. '
                  'A assinatura será ativada imediatamente após a confirmação. '
                  'Planos com renovação serão cobrados automaticamente no vencimento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required double monthlyPrice,
  }) {
    final colors = AppColors.of(context);
    final isSelected = _selectedPlan == plan.planKey;
    final subtitle = plan.calculateSavings(monthlyPrice) ?? '';
    
    // Mapeamento básico de nomes de ícones para IconData
    IconData? cardIcon;
    if (plan.iconName == 'all_inclusive_rounded') {
      cardIcon = Icons.all_inclusive_rounded;
    }

    final borderColor = isSelected
        ? const Color(0xFF1E56D1)
        : plan.isRecommended
            ? const Color(0xFF1E56D1).withValues(alpha: 0.4)
            : colors.cardBorder;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan.planKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E56D1).withValues(alpha: 0.12)
              : colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E56D1).withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topo: Badge + Radio
            Row(
              children: [
                if (plan.badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (cardIcon != null && plan.badge == null) ...[
                  Icon(cardIcon, color: const Color(0xFF1E56D1), size: 20),
                  const SizedBox(width: 6),
                ],
                const Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1E56D1)
                          : Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    color: isSelected
                        ? const Color(0xFF1E56D1)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Título do plano
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Preço
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(plan.price),
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : colors.textPrimary.withValues(alpha: 0.9),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    plan.monthsCount == 0 ? ' uma vez' : '/${plan.periodLabel}',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Subtítulo (Economia ou override)
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
