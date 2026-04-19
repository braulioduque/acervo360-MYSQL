import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AddressesPage extends StatefulWidget {
  final String? initialType;
  const AddressesPage({super.key, this.initialType});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  static const _states = [
    'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'
  ];

  final _citiesCache = <String, List<String>>{};
  final _addresses = <String, Map<String, dynamic>>{};

  bool _loading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initUser();
    _loadAddresses().then((_) {
      if (widget.initialType != null && mounted) {
        _openAddressForm(widget.initialType!);
      }
    });
  }

  Future<void> _initUser() async {
    final id = await ApiService.getUserId();
    if (mounted) setState(() => _currentUserId = id);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _label(String type) => type == 'primary' ? 'Endereco Principal' : 'Endereco Secundario';

  String _summary(String type) {
    final data = _addresses[type];
    if (data == null) return 'Nao cadastrado';
    final street = (data['street'] ?? '').toString();
    final number = (data['number'] ?? '').toString();
    final city = (data['city'] ?? '').toString();
    final state = (data['state_code'] ?? '').toString();
    return '$street, $number - $city/$state';
  }

  Future<List<String>> _citiesByState(String uf) async {
    if (_citiesCache.containsKey(uf)) return _citiesCache[uf]!;
    final uri = Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$uf/municipios');
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Falha ao carregar cidades');

    final body = jsonDecode(res.body) as List;
    final cities = body
        .whereType<Map>()
        .map((e) => (e['nome'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList()
      ..sort();

    _citiesCache[uf] = cities;
    return cities;
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('profile_addresses/me');

      _addresses.clear();
      for (final row in data as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final type = (map['address_type'] ?? '').toString();
        if (type.isNotEmpty) _addresses[type] = map;
      }
    } catch (_) {
      _showMessage('Nao foi possivel carregar enderecos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upsertAddress(String type, Map<String, dynamic> payload) async {
    await ApiService.post('profile_addresses/upsert', {
      ...payload,
      'address_type': type,
    });

    await _loadAddresses();
  }

  Future<void> _deleteAddress(String type) async {
    final user = _currentUserId;
    if (user == null) return;

    if (type == 'primary' && _addresses.containsKey('secondary')) {
      final colors = AppColors.of(context);
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: colors.card,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Atenção',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Não é possível excluir o endereço principal enquanto existir um endereço secundário. Exclua o endereço secundário primeiro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Entendi', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    final addressId = _addresses[type]?['id'];
    if (addressId != null) {
      try {
        final gtes = await ApiService.get('gtes');
        final gteInUse = (gtes as List).any((gte) => gte['profile_address_id'] == addressId);
        
        if (gteInUse) {
          if (!mounted) return;
          final colors = AppColors.of(context);
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: colors.card,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Atenção',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Não é possível excluir este endereço porque ele está vinculado a uma ou mais GTes. Altere o endereço nas GTes ou exclua as GTes vinculadas primeiro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Entendi', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Erro ao verificar dependências da GTe: $e');
      }
    }

    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: colors.card,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Confirmar Exclusão',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Deseja realmente excluir este endereço permanentemente? Esta ação não poderá ser desfeita.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Excluir',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;

    if (!confirmed) return;

    await ApiService.delete('profile_addresses', addressId!);
    await _loadAddresses();
  }

  Future<void> _openAddressForm(String type) async {
    if (type == 'secondary' && !_addresses.containsKey('primary')) {
      final colors = AppColors.of(context);
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: colors.card,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: colors.accent,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Atenção',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Para cadastrar um endereço secundário, é necessário primeiro cadastrar o endereço principal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Entendi', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    final existing = _addresses[type];

    final formKey = GlobalKey<FormState>();
    final street = TextEditingController(text: (existing?['street'] ?? '').toString());
    final number = TextEditingController(text: (existing?['number'] ?? '').toString());
    final complement = TextEditingController(text: (existing?['complement'] ?? '').toString());
    final neighborhood = TextEditingController(text: (existing?['neighborhood'] ?? '').toString());
    final postalCode = TextEditingController(text: (existing?['postal_code'] ?? '').toString());

    String? selectedState = (existing?['state_code'] ?? '').toString().toUpperCase();
    if (selectedState.isEmpty) selectedState = null;
    String? selectedCity = (existing?['city'] ?? '').toString();
    if (selectedCity.isEmpty) selectedCity = null;

    List<String> cities = [];
    bool loadingCities = false;
    bool saving = false;

    if (selectedState != null) {
      try {
        cities = await _citiesByState(selectedState);
      } catch (_) {}
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(_label(type), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        TextFormField(controller: street, decoration: const InputDecoration(labelText: 'Rua / Logradouro', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a rua' : null),
                        const SizedBox(height: 10),
                        TextFormField(controller: number, decoration: const InputDecoration(labelText: 'Numero', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o numero' : null),
                        const SizedBox(height: 10),
                        TextFormField(controller: complement, decoration: const InputDecoration(labelText: 'Complemento', border: OutlineInputBorder())),
                        const SizedBox(height: 10),
                        TextFormField(controller: neighborhood, decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o bairro' : null),
                        const SizedBox(height: 10),
                        AbsorbPointer(
                          absorbing: saving,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedState,
                            items: _states.map((uf) => DropdownMenuItem(value: uf, child: Text(uf))).toList(),
                            onChanged: (value) async {
                              if (value == null) return;
                              setModalState(() {
                                selectedState = value;
                                    selectedCity = null;
                                    cities = [];
                                    loadingCities = true;
                                  });
                                  try {
                                    final fetched = await _citiesByState(value);
                                    if (!context.mounted) return;
                                    setModalState(() => cities = fetched);
                                  } catch (_) {
                                    _showMessage('Nao foi possivel carregar cidades.');
                                  } finally {
                                    if (context.mounted) {
                                      setModalState(() => loadingCities = false);
                                    }
                                  }
                                },
                            validator: (v) => (v == null || v.isEmpty) ? 'Selecione o estado' : null,
                            decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AbsorbPointer(
                          absorbing: saving,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCity,
                            items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (loadingCities || selectedState == null) ? null : (v) => setModalState(() => selectedCity = v),
                            validator: (v) => (v == null || v.isEmpty) ? 'Selecione a cidade' : null,
                            decoration: InputDecoration(labelText: loadingCities ? 'Carregando cidades...' : 'Cidade', border: const OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(controller: postalCode, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CEP',  border: OutlineInputBorder()), validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length == 8 ? null : 'CEP deve ter 8 digitos'),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!(formKey.currentState?.validate() ?? false)) return;
                                  if (selectedState == null || selectedCity == null) return;
  
                                  setModalState(() => saving = true);
                                  try {
                                    final payload = {
                                      'street': street.text.trim(),
                                      'number': number.text.trim(),
                                      'complement': complement.text.trim().isEmpty ? null : complement.text.trim(),
                                      'neighborhood': neighborhood.text.trim(),
                                      'state_code': selectedState,
                                      'city': selectedCity,
                                      'postal_code': postalCode.text.replaceAll(RegExp(r'\D'), ''),
                                    };
                                    if (context.mounted) Navigator.pop(context);
                                    await _upsertAddress(type, payload);
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    setModalState(() => saving = false);
                                    _showMessage('Nao foi possivel salvar endereco.');
                                  }
                                },
                          child: const Text('Salvar endereço'),
                        ),
                        if (existing != null)
                          TextButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    if (context.mounted) Navigator.pop(context);
                                    await _deleteAddress(type);
                                  },
                            child: const Text('Excluir endereço', style: TextStyle(color: Colors.redAccent)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      street.dispose();
      number.dispose();
      complement.dispose();
      neighborhood.dispose();
      postalCode.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Enderecos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.home_work_outlined),
                    title: const Text('Endereco Principal'),
                    subtitle: Text(_summary('primary')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openAddressForm('primary'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: const Text('Endereco Secundario'),
                    subtitle: Text(_summary('secondary')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openAddressForm('secondary'),
                  ),
                ),
              ],
            ),
    );
  }
}



