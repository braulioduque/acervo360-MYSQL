import 'package:acervo360/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:acervo360/theme/app_theme.dart';
import 'package:acervo360/pages/clubs_screen.dart';
import 'package:acervo360/pages/dashboard_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AdminClubsPage extends StatefulWidget {
  const AdminClubsPage({super.key});

  @override
  State<AdminClubsPage> createState() => _AdminClubsPageState();
}

class _AdminClubsPageState extends State<AdminClubsPage> {
  final _clubs = <Map<String, dynamic>>[];
  final _signedUrls = <String, String>{};
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadClubs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('clubs');
      _clubs.clear();
      _signedUrls.clear();
      
      if (data is! List) {
        final errorMsg = (data is Map && data.containsKey('error')) ? data['error'] : 'Erro inesperado do servidor';
        throw Exception(errorMsg);
      }
      
      for (final row in data) {
        final club = Map<String, dynamic>.from(row as Map);
        _clubs.add(club);
        
        final logo = club['logo_url']?.toString() ?? '';
        if (logo.isNotEmpty) {
          if (logo.startsWith('http')) {
            _signedUrls[club['id'].toString()] = logo;
          } else {
            try {
              _signedUrls[club['id'].toString()] = ApiService.getPublicUrl(logo);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar os clubes: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteClub(dynamic clubId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: const Text('Exclusão Global', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
            'Atenção! Isso removerá este clube permanentemente para TODOS os usuários e apagará o avatar do servidor. Tem certeza?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: TextStyle(color: AppColors.of(context).textPrimary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.delete('clubs', clubId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clube e avatar excluídos.')));
      }
      _loadClubs();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _approveClub(String clubId) async {
    try {
      await ApiService.post('clubs', {
        'id': clubId,
        'status': 'A',
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clube aprovado com sucesso.')));
      _loadClubs();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao aprovar: $e')));
    }
  }

  Future<void> _openClubForm({Map<String, dynamic>? club}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: club?['name']?.toString() ?? '');
    final cnpj = TextEditingController(text: club?['cnpj']?.toString() ?? '');
    final phone = TextEditingController(text: club?['phone']?.toString() ?? '');
    final crNumber = TextEditingController(text: club?['cr_number']?.toString() ?? '');
    final street = TextEditingController(text: club?['street']?.toString() ?? '');
    final number = TextEditingController(text: club?['number']?.toString() ?? '');
    final city = TextEditingController(text: club?['city']?.toString() ?? '');
    final state = TextEditingController(text: (club?['state']?.toString() ?? '').toUpperCase());
    final complement = TextEditingController(text: club?['complement']?.toString() ?? '');
    final neighborhood = TextEditingController(text: club?['neighborhood']?.toString() ?? '');
    final documentNumber = TextEditingController(text: club?['document_number']?.toString() ?? '');
    
    final phoneFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
      initialText: club?['phone']?.toString() ?? '',
    );
    
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(club == null ? 'Geral: Novo Clube' : 'Editar Clube Global',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.of(context).textPrimary)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: name,
                        style: TextStyle(color: AppColors.of(context).textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Nome do Clube',
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cnpj,
                              style: TextStyle(color: AppColors.of(context).textPrimary),
                              decoration: InputDecoration(
                                labelText: 'CNPJ',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: crNumber,
                              style: TextStyle(color: AppColors.of(context).textPrimary),
                              decoration: InputDecoration(
                                labelText: 'CR Número',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: street,
                              style: TextStyle(color: AppColors.of(context).textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Rua',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: number,
                              style: TextStyle(color: AppColors.of(context).textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Número',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: city,
                              style: TextStyle(color: AppColors.of(context).textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Cidade',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: state,
                              maxLength: 2,
                              style: TextStyle(color: AppColors.of(context).textPrimary),
                              decoration: InputDecoration(
                                labelText: 'UF',
                                counterText: '',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: neighborhood,
                              style: TextStyle(color: AppColors.of(context).textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Bairro',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: complement,
                              style: TextStyle(color: AppColors.of(context).textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Complemento',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: phone,
                              inputFormatters: [phoneFormatter],
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: AppColors.of(context).textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Telefone',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: documentNumber,
                              style: TextStyle(color: AppColors.of(context).textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Nº Documento',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: saving ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => saving = true);
                            try {
                              final data = {
                                'name': name.text.trim(),
                                'cnpj': cnpj.text.trim(),
                                'cr_number': crNumber.text.trim(),
                                'street': street.text.trim(),
                                'number': number.text.trim(),
                                'city': city.text.trim(),
                                'state': state.text.trim(),
                                'phone': phone.text.trim(),
                                'complement': complement.text.trim(),
                                'neighborhood': neighborhood.text.trim(),
                                'document_number': documentNumber.text.trim(),
                              };
                              if (club == null) {
                                data['status'] = 'A';
                                await ApiService.post('clubs', data);
                              } else {
                                data['id'] = club['id'];
                                await ApiService.post('clubs', data);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadClubs();
                            } catch (e) {
                              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Erro: $e')));
                            } finally {
                              if (ctx.mounted) setModalState(() => saving = false);
                            }
                          },
                          child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Salvar Cadastro Global'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final filtered = _clubs.where((club) {
      final name = (club['name'] ?? '').toString().toLowerCase();
      final cnpj = (club['cnpj'] ?? '').toString().toLowerCase();
      final city = (club['city'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || cnpj.contains(_searchQuery) || city.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        title: const Text('Gestão Global de Clubes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardPage()),
              (route) => false,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openClubForm(),
        backgroundColor: colors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome, CNPJ ou cidade...',
                hintStyle: TextStyle(color: colors.textMuted),
                prefixIcon: Icon(Icons.search, color: colors.accent),
                filled: true,
                fillColor: colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: colors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'Nenhum clube encontrado.' : 'Nenhum resultado para "$_searchQuery"',
                              style: TextStyle(color: colors.textMuted),
                            ),
                            if (_searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () => _searchController.clear(),
                                child: const Text('Limpar pesquisa'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final club = filtered[index];
                          final isPending = club['status'] == 'N';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isPending ? Colors.orangeAccent : colors.cardBorder, width: isPending ? 2 : 1),
                            ),
                            child: ListTile(
                              leading: GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => ClubAvatarPage(
                                        clubId: club['id'].toString(),
                                        clubName: club['name'] ?? '',
                                        logoUrl: club['logo_url'],
                                        status: club['status'],
                                        ownerId: club['owner_id']?.toString(),
                                        isAdmin: true,
                                      ),
                                    ),
                                  );
                                  if (result == true) _loadClubs();
                                },
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: colors.scaffold,
                                  backgroundImage: _signedUrls.containsKey(club['id'].toString())
                                      ? NetworkImage(_signedUrls[club['id'].toString()]!)
                                      : null,
                                  child: !_signedUrls.containsKey(club['id'].toString())
                                      ? Icon(Icons.shield_outlined, color: colors.textMuted)
                                      : null,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  Expanded(child: Text(club['name'] ?? '', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold))),
                                  if (isPending)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(12)),
                                      child: const Text('Pendente', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  if ((club['cnpj'] ?? '').toString().isNotEmpty)
                                    Text('CNPJ: ${club['cnpj']}', style: TextStyle(color: colors.textSecondary)),
                                  if ((club['city'] ?? '').toString().isNotEmpty)
                                    Text('${club['city']} - ${club['state']}', style: TextStyle(color: colors.textSecondary)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (isPending)
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, 36)),
                                          onPressed: () => _approveClub(club['id']),
                                          icon: const Icon(Icons.check, size: 16, color: Colors.white),
                                          label: const Text('Aprovar', style: TextStyle(color: Colors.white)),
                                        ),
                                      if (isPending) const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
                                          onPressed: () => _openClubForm(club: club),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Editar'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () => _deleteClub(club['id']),
                                        style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.1)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
