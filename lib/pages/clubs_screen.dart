import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:acervo360/services/api_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:acervo360/pages/dashboard_screen.dart';
import 'package:acervo360/theme/app_theme.dart';

class ClubsPage extends StatefulWidget {
  const ClubsPage({super.key});

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class ClubAvatarPage extends StatefulWidget {
  const ClubAvatarPage({
    super.key,
    required this.clubId,
    required this.clubName,
    required this.logoUrl,
    this.status,
    this.ownerId,
    this.isAdmin = false,
  });

  final String clubId;
  final String clubName;
  final String? logoUrl;
  final String? status;
  final String? ownerId;
  final bool isAdmin;

  @override
  State<ClubAvatarPage> createState() => _ClubAvatarPageState();
}

class _ClubAvatarPageState extends State<ClubAvatarPage> {
  static const int maxAvatarBytes = 2 * 1024 * 1024;


  bool _loading = true;
  bool _saving = false;
  String? _currentUrl;
  Uint8List? _selectedBytes;
  String? _selectedExt;

  @override
  void initState() {
    super.initState();
    _loadCurrentLogo();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadCurrentLogo() async {
    final logo = widget.logoUrl?.trim() ?? '';
    if (logo.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      if (logo.startsWith('http')) {
        _currentUrl = logo;
      } else {
        _currentUrl = ApiService.getPublicUrl(logo);
      }
    } catch (_) {
      _currentUrl = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleImagePicked(Uint8List bytes, String ext) async {
    if (bytes.lengthInBytes > maxAvatarBytes) {
      _showMessage('Arquivo muito grande. Maximo 2MB.');
      return;
    }

    setState(() {
      _selectedBytes = bytes;
      _selectedExt = ext;
    });
  }

  Future<void> _pickImageFromGallery() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) return;
    
    await _handleImagePicked(file.bytes!, (file.extension ?? 'jpg').toLowerCase());
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      final ext = photo.path.split('.').last.toLowerCase();
      
      await _handleImagePicked(bytes, ext);
    } catch (e) {
      _showMessage('Não foi possível acessar a câmera.');
    }
  }

  void _showAvatarSourceChooser() {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: colors.accent),
                title: Text('Escolher da galeria', style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: colors.accent),
                title: Text('Tirar foto', style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromCamera();
                },
              ),
              if (_currentUrl != null || _selectedBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remover logo', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeAvatar() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ApiService.post('clubs', {
        'id': widget.clubId,
        'logo_url': null,
      });
      if (!mounted) return;
      setState(() {
        _currentUrl = null;
        _selectedBytes = null;
        _selectedExt = null;
      });
      _showMessage('Avatar removido.');
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Erro: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAvatar() async {
    if (_selectedBytes == null || _selectedBytes!.isEmpty) {
      _showMessage('Selecione uma imagem primeiro.');
      return;
    }

    setState(() => _saving = true);
    try {
      final tempFile = File(p.join(Directory.systemTemp.path, 'temp_club_logo.${_selectedExt ?? "png"}'));
      await tempFile.writeAsBytes(_selectedBytes!);
      
      final cloudPath = await ApiService.uploadFile(tempFile, 'club-logos');

      // Se chegar aqui, o cloudPath não é null (ApiService.uploadFile lança exceção se falhar)
      await ApiService.post('clubs', {
        'id': widget.clubId,
        'logo_url': cloudPath,
      });

      if (!mounted) return;
      _showMessage('Avatar atualizado.');
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Erro ao salvar avatar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isApproved = widget.status == 'A';
    final isNotOwner = false; // logic would need to be based on profile loaded or backend check
    final canEdit = widget.isAdmin || !isApproved;

    final preview = _selectedBytes != null
        ? Image.memory(_selectedBytes!, fit: BoxFit.cover)
        : (_currentUrl != null ? Image.network(_currentUrl!, fit: BoxFit.cover) : null);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: Text(canEdit ? 'Avatar do clube' : 'Ver Logo'),
        backgroundColor: colors.scaffold,
        foregroundColor: colors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.clubName,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: const Color(0xFF1E293B),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : ClipOval(
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: preview ??
                                  const Icon(
                                    Icons.shield_outlined,
                                    size: 48,
                                    color: Color(0xFF64748B),
                                  ),
                            ),
                          ),
                  ),
                  if (canEdit)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: InkWell(
                        onTap: _saving ? null : _showAvatarSourceChooser,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0B1220),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (canEdit)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _showAvatarSourceChooser,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Selecionar imagem'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _saving ? null : _removeAvatar,
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    label: const Text(
                      'Remover logo',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _saveAvatar,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar avatar'),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    isApproved 
                      ? 'Este clube já foi validado e sua logo não pode mais ser alterada.'
                      : 'Você não possui permissão para alterar a logo deste clube.',
                    style: TextStyle(color: colors.textMuted, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClubsPageState extends State<ClubsPage> {
  static const _states = ['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'];
  final _clubs = <Map<String, dynamic>>[];
  final _citiesCache = <String, List<String>>{};
  
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool _loading = true;


  @override
  void initState() {
    super.initState();
    _initUser();
    _loadClubs();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _currentUserId;

  Future<void> _initUser() async {
    final id = await ApiService.getUserId();
    if (mounted) setState(() => _currentUserId = id);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  Future<void> _loadClubs() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('user_clubs/me');

      _clubs.clear();
      for (final row in data as List) {
        if (row['clubs'] != null) {
          final clubDict = Map<String, dynamic>.from(row['clubs'] as Map);
          clubDict['user_club_id'] = row['id'];
          _clubs.add(clubDict);
        } else if (row['id'] != null && row['name'] != null) {
          final clubDict = Map<String, dynamic>.from(row as Map);
          // Map user_club_id for deletion logic
          if (row['user_club_id'] != null) {
            clubDict['user_club_id'] = row['user_club_id'];
          }
          _clubs.add(clubDict);
        }
      }

      // Sort alphabetically by name
      _clubs.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      for (final club in _clubs) {
        final logo = (club['logo_url'] ?? '').toString().trim();
        if (logo.isEmpty) continue;
        if (logo.startsWith('http')) {
          club['logo_signed_url'] = logo;
          continue;
        }
        try {
          club['logo_signed_url'] = ApiService.getPublicUrl(logo);
        } catch (_) {
          club['logo_signed_url'] = null;
        }
      }
    } catch (e) {
      _showMessage('Erro ao carregar clubes: $e');
    } catch (_) {
      _showMessage('Nao foi possivel carregar os clubes.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _deleteClub(String userClubId, {String? globalClubId, String? ownerId, String? status, String? logoPath}) async {
    if (globalClubId == null) return false;

    try {
      // 1. Get GTes for this club
      final gtes = await ApiService.get('gtes');
      final filteredGtes = (gtes as List).where((g) => g['destination_club_id'] == globalClubId).toList();
      final gteCount = filteredGtes.length;

      // 2. Diálogo de Confirmação com Alerta de Dependência
      if (!mounted) return false;
      final colors = AppColors.of(context);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: colors.card,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (gteCount > 0 ? Colors.orangeAccent : Colors.redAccent).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      gteCount > 0 ? Icons.warning_amber_rounded : Icons.delete_forever_rounded,
                      color: gteCount > 0 ? Colors.orangeAccent : Colors.redAccent,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    gteCount > 0 ? 'Excluir com GTes' : 'Remover Clube',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (gteCount > 0) ...[
                    Text(
                      'Este clube possui $gteCount GTes vinculadas.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ao confirmar, todas essas GTes e seus documentos PDFs também serão apagados permanentemente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ] else ...[
                    Text(
                      status == 'N' && ownerId == _currentUserId
                          ? 'Este é um clube cadastrado por você. A exclusão será GLOBAL e removerá a logo permanentemente.'
                          : 'Deseja remover este clube da sua lista pessoal?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Divider(color: colors.textSecondary.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text(
                    'Tem certeza que deseja prosseguir?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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
                            backgroundColor: gteCount > 0 ? Colors.orangeAccent : Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            gteCount > 0 ? 'Excluir Tudo' : 'Excluir',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (confirm != true) return false;

      setState(() => _loading = true);

      if (gteCount > 0) {
        for (var g in filteredGtes) {
          await ApiService.delete('gtes', g['id']);
        }
      }

      // 4. Excluir Clube ou Vínculo
      // logic is handled by backend or multiple calls
      // If user is "owner" (needs profile check)
      if (status == 'N') {
        await ApiService.delete('clubs', globalClubId);
      } else {
        await ApiService.delete('user_clubs', userClubId);
      }

      await _loadClubs();
      _showMessage('Removido com sucesso.');
      return true;
    } catch (e) {
      _showMessage('Erro ao excluir: $e');
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _upsertClub({
    required String? userClubId,
    required String? selectedGlobalClubId,
    required String? originalGlobalClubId,
    required String name,
    String? crNumber,
    String? cnpj,
    String? phone,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? documentNumber,
    String? city,
    String? state,
    String? logoUrl,
  }) async {
    final clubPayload = <String, dynamic>{
      'name': name,
      'cr_number': crNumber,
      'cnpj': cnpj,
      'phone': phone,
      'street': street,
      'number': number,
      'complement': complement,
      'neighborhood': neighborhood,
      'document_number': documentNumber,
      'city': city,
      'state': state,
      'logo_url': logoUrl,
    };

    if (userClubId != null) {
      if (originalGlobalClubId != selectedGlobalClubId) {
        if (selectedGlobalClubId != null) {
          await ApiService.post('user_clubs', {
            'id': userClubId,
            'club_id': selectedGlobalClubId,
          });
          return selectedGlobalClubId;
        } else {
          final response = await ApiService.post('clubs', clubPayload);
          final newClubId = response['id'];
          await ApiService.post('user_clubs', {
            'id': userClubId,
            'club_id': newClubId,
          });
          return newClubId;
        }
      } else {
        if (selectedGlobalClubId != null) {
          clubPayload['id'] = selectedGlobalClubId;
          await ApiService.post('clubs', clubPayload);
          return selectedGlobalClubId;
        }
      }
    } else {
      if (selectedGlobalClubId != null) {
        await ApiService.post('user_clubs', {
          'club_id': selectedGlobalClubId,
        });
        return selectedGlobalClubId;
      } else {
        final response = await ApiService.post('clubs', clubPayload);
        final newClubId = response['id'];
        await ApiService.post('user_clubs', {
          'club_id': newClubId,
        });
        return newClubId;
      }
    }
    
    throw Exception('Houve falha ao salvar o clube');
  }

  Future<String?> _saveClub({
    required GlobalKey<FormState> formKey,
    required BuildContext modalContext,
    required void Function(bool) updateSaving,
    required String? userClubId,
    required String? selectedGlobalClubId,
    required String? originalGlobalClubId,
    required String name,
    String? crNumber,
    String? cnpj,
    String? phone,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? documentNumber,
    String? city,
    String? state,
    String? existingLogoUrl,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      _showMessage('Sessao expirada. Faca login novamente.');
      return null;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      _showMessage('Preencha os campos obrigatorios.');
      return null;
    }

    if (modalContext.mounted) {
      updateSaving(true);
    }
    try {
      final clubId = await _upsertClub(
        userClubId: userClubId,
        selectedGlobalClubId: selectedGlobalClubId,
        originalGlobalClubId: originalGlobalClubId,
        name: name.trim(),
        crNumber: crNumber?.trim().isEmpty ?? true ? null : crNumber!.trim(),
        cnpj: cnpj?.trim().isEmpty ?? true ? null : cnpj!.trim(),
        phone: phone?.trim().isEmpty ?? true ? null : phone!.trim(),
        street: street?.trim().isEmpty ?? true ? null : street!.trim(),
        number: number?.trim().isEmpty ?? true ? null : number!.trim(),
        complement: complement?.trim().isEmpty ?? true ? null : complement!.trim(),
        neighborhood: neighborhood?.trim().isEmpty ?? true ? null : neighborhood!.trim(),
        documentNumber: documentNumber?.trim().isEmpty ?? true ? null : documentNumber!.trim(),
        city: city,
        state: state,
        logoUrl: existingLogoUrl,
      );

      if (!mounted) return null;
      _showMessage('Clube salvo');
      return clubId;
    } catch (e) {
      if (!mounted) return null;
      _showMessage('Erro ao salvar o clube: $e');
    } finally {
      if (mounted) {
        if (modalContext.mounted) {
          updateSaving(false);
        }
      }
    }

    return null;
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

  Future<void> _openClubForm({Map<String, dynamic>? existing}) async {
    final String? existingUserClubId = existing?['user_club_id']?.toString();
    final String? originalGlobalClubId = existing?['id']?.toString();
    String? selectedGlobalClubId = existing?['id']?.toString();

    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: (existing?['name'] ?? '').toString());
    final documentNumber =
        TextEditingController(text: (existing?['document_number'] ?? '').toString());
    final crNumber = TextEditingController(text: (existing?['cr_number'] ?? '').toString());
    final cnpj = TextEditingController(text: (existing?['cnpj'] ?? '').toString());
    final phone = TextEditingController(text: (existing?['phone'] ?? '').toString());
    final street = TextEditingController(text: (existing?['street'] ?? '').toString());
    final number = TextEditingController(text: (existing?['number'] ?? '').toString());
    final complement = TextEditingController(text: (existing?['complement'] ?? '').toString());
    final neighborhood = TextEditingController(text: (existing?['neighborhood'] ?? '').toString());
    final city = TextEditingController(text: (existing?['city'] ?? '').toString());

    String? selectedState = (existing?['state'] ?? '').toString().trim().toUpperCase();
    if (selectedState.isEmpty) selectedState = null;

    String? selectedCity = city.text.trim().isEmpty ? null : city.text.trim();
    List<String> cities = [];
    bool loadingCities = false;
    bool saving = false;
    String? currentLogoUrl = existing?['logo_url']?.toString();

 
    final phoneFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
      initialText: phone.text,
    );

    if (!mounted) return;

    if (selectedState != null) {
      try {
        cities = await _citiesByState(selectedState);
      } catch (_) {}
    }

    if (selectedCity != null && selectedCity.isNotEmpty && !cities.contains(selectedCity)) {
      cities = [...cities, selectedCity]..sort();
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.of(context).card,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                existing == null ? 'Novo clube' : 'Editar clube',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.of(context).textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Fechar',
                              onPressed:
                                  saving ? null : () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: AppColors.of(context).textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Autocomplete<Map<String, dynamic>>(
                          displayStringForOption: (option) => option['name']?.toString() ?? '',
                          optionsBuilder: (textEditingValue) async {
                            final term = textEditingValue.text.trim();
                            if (term.length < 3) return const Iterable.empty();
                            try {
                              final data = await ApiService.get('clubs/search', queryParams: {'query': term});
                              return data.cast<Map<String, dynamic>>();
                            } catch (_) {
                              // Se der erro de query, retorna vazio
                              return const Iterable.empty();
                            }
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 8.0,
                                color: AppColors.of(context).cardBorder,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 350),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option['name']?.toString() ?? '', style: TextStyle(color: AppColors.of(context).textPrimary)),
                                        subtitle: Text('CR: ${option['cr_number'] ?? 'N/A'}', style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
                                        onTap: () {
                                          onSelected(option);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          onSelected: (selection) {
                            name.text = selection['name']?.toString() ?? '';
                            selectedGlobalClubId = selection['id']?.toString();
                            
                            cnpj.text = selection['cnpj']?.toString() ?? '';
                            phone.text = selection['phone']?.toString() ?? '';
                            crNumber.text = selection['cr_number']?.toString() ?? '';
                            street.text = selection['street']?.toString() ?? '';
                            number.text = selection['number']?.toString() ?? '';
                            complement.text = selection['complement']?.toString() ?? '';
                            neighborhood.text = selection['neighborhood']?.toString() ?? '';
                            documentNumber.text = selection['document_number']?.toString() ?? '';
                            
                            final dbState = selection['state']?.toString().toUpperCase();
                            final dbCity = selection['city']?.toString();
                            
                            setModalState(() {
                              currentLogoUrl = selection['logo_url']?.toString();
                            });

                            if (dbState != null && _states.contains(dbState)) {

                              setModalState(() {
                                selectedState = dbState;
                                selectedCity = null;
                                loadingCities = true;
                              });
                              _citiesByState(dbState).then((fetched) {
                                if (context.mounted) {
                                  setModalState(() {
                                    cities = fetched;
                                    if (dbCity != null && fetched.contains(dbCity)) {
                                      selectedCity = dbCity;
                                    }
                                    loadingCities = false;
                                  });
                                }
                              });
                            } else {
                              setModalState(() {});
                            }
                          },
                          fieldViewBuilder: (ctx, ctrl, focus, onEdit) {
                             if (ctrl.text.isEmpty && name.text.isNotEmpty) {
                               ctrl.text = name.text;
                             }

                             ctrl.addListener(() {
                               if (ctrl.text != name.text) {
                                 name.text = ctrl.text;
                                 if (selectedGlobalClubId != null) {
                                    selectedGlobalClubId = null;
                                 }
                               }
                             });
                             
                             return TextFormField(
                                controller: ctrl,
                                focusNode: focus,
                                style: TextStyle(color: AppColors.of(context).textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Nome do clube para buscar',
                                  labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome do clube' : null,
                             );
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: crNumber,
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          decoration: InputDecoration(
                            labelText: 'CR do clube (opcional)',
                            labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: cnpj,
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(14),
                          ],
                          decoration: InputDecoration(
                            labelText: 'CNPJ (opcional)',
                            labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: phone,
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            phoneFormatter,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Telefone para contato (opcional)',
                            labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: documentNumber,
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Documento (opcional)',
                            labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: street,
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Rua / Logradouro',
                            labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: number,
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Número',
                            labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: complement,
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Complemento (opcional)',
                            labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: neighborhood,
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Bairro',
                            labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          dropdownColor: AppColors.of(context).card,
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          initialValue: selectedState,
                          items: _states
                              .map((uf) => DropdownMenuItem(value: uf, child: Text(uf)))
                              .toList(),
                          onChanged: saving
                              ? null
                              : (value) async {
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
                          decoration: InputDecoration(
                            labelText: 'Estado',
                            labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Selecione o estado' : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          dropdownColor: AppColors.of(context).card,
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          initialValue: selectedCity,
                          items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (saving || loadingCities || selectedState == null)
                              ? null
                              : (v) => setModalState(() => selectedCity = v),
                          decoration: InputDecoration(
                            labelText: loadingCities ? 'Carregando cidades...' : 'Cidade',
                            labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.of(context).cardBorder)),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Selecione a cidade' : null,
                        ),
                        const SizedBox(height: 12),
                         FilledButton(
                          onPressed:
                              saving
                                  ? null
                                  : () async {
                                    final cityValue =
                                        selectedCity ??
                                        (city.text.trim().isEmpty
                                            ? null
                                            : city.text.trim());
                                    final clubId = await _saveClub(
                                      formKey: formKey,
                                      modalContext: context,
                                      updateSaving:
                                          (value) =>
                                              setModalState(() => saving = value),
                                      userClubId: existingUserClubId,
                                      selectedGlobalClubId: selectedGlobalClubId,
                                      originalGlobalClubId: originalGlobalClubId,
                                      name: name.text,
                                      crNumber: crNumber.text,
                                      cnpj: cnpj.text,
                                      phone: phone.text,
                                      street: street.text,
                                      number: number.text,
                                      complement: complement.text,
                                      neighborhood: neighborhood.text,
                                      documentNumber: documentNumber.text,
                                      city: cityValue,
                                      state: selectedState,
                                      existingLogoUrl: currentLogoUrl,
                                    );

  
                                    if (clubId != null && context.mounted) {
                                      Navigator.pop(context);
                                      await _loadClubs();
                                    }
                                  },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Salvar clube'),
                        ),
                        if (existing != null)
                          TextButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    final idToDel = existingUserClubId;
                                    if (idToDel == null) return;
                                    final success = await _deleteClub(
                                      idToDel,
                                      globalClubId: existing['id']?.toString(),
                                      ownerId: existing['owner_user_id']?.toString(),
                                      status: existing['status']?.toString(),
                                      logoPath: existing['logo_url']?.toString(),
                                    );
                                    if (success && context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            child: const Text('Excluir clube', style: TextStyle(color: Colors.redAccent)),
                          ),
                        const SizedBox(height: 20),
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final filtered = _clubs.where((club) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (club['name'] ?? '').toString().toLowerCase();
      final city = (club['city'] ?? '').toString().toLowerCase();
      final cr = (club['cr_number'] ?? '').toString().toLowerCase();
      return name.contains(q) || city.contains(q) || cr.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        backgroundColor: colors.scaffold,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          },
        ),
        title: const Text('Meus clubes'),
        foregroundColor: colors.textPrimary,
        actions: [
          IconButton(
            onPressed: () => _openClubForm(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_clubs.isNotEmpty || _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Pesquisar por nome ou cidade...',
                        hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: colors.textMuted,
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: colors.card,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty ? Icons.search_off_outlined : Icons.shield_outlined,
                                  size: 48,
                                  color: const Color(0xFF64748B),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Nenhum resultado para sua pesquisa'
                                      : 'Nenhum clube cadastrado',
                                  style: const TextStyle(color: Color(0xFF94A3B8)),
                                  textAlign: TextAlign.center,
                                ),
                                if (_searchQuery.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: () => _openClubForm(),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Cadastrar clube'),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => _searchController.clear(),
                                    child: const Text('Limpar pesquisa', style: TextStyle(color: Color(0xFF3B82F6))),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final club = filtered[index];
                            final name = (club['name'] ?? '').toString();
                            final logo = (club['logo_signed_url'] ?? '').toString();
                            final city = (club['city'] ?? '').toString();
                            final state = (club['state'] ?? '').toString();
                            final phone = (club['phone'] ?? '').toString();
                            final crNumber = (club['cr_number'] ?? '').toString();
                            final locationLabel = [city, state].where((e) => e.isNotEmpty).join(', ');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: colors.cardBorder),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            final updated = await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ClubAvatarPage(
                                                  clubId: club['id']?.toString() ?? '',
                                                  clubName: name.isEmpty ? 'Clube sem nome' : name,
                                                  logoUrl: club['logo_url']?.toString(),
                                                  status: club['status']?.toString(),
                                                  ownerId: club['owner_user_id']?.toString(),
                                                ),
                                              ),
                                            );
                                            if (updated == true) {
                                              await _loadClubs();
                                            }
                                          },
                                          child: Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF334155),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white10),
                                              image: logo.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(logo),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: logo.isNotEmpty
                                                ? null
                                                : const Icon(
                                                    Icons.shield_outlined,
                                                    color: Colors.white70,
                                                    size: 30,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name.isEmpty ? 'Clube sem nome' : name,
                                                      style: TextStyle(
                                                        color: colors.textPrimary,
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                  if (club['status'] == 'N' && club['owner_user_id'] == _currentUserId) ...[
                                                    IconButton(
                                                      onPressed: () => _openClubForm(existing: club),
                                                      icon: const Icon(Icons.edit, size: 18, color: Colors.white60),
                                                      tooltip: 'Editar Clube',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  IconButton(
                                                    onPressed: () => _deleteClub(
                                                      club['user_club_id']?.toString() ?? '',
                                                      globalClubId: club['id']?.toString(),
                                                      ownerId: club['owner_user_id']?.toString(),
                                                      status: club['status']?.toString(),
                                                      logoPath: club['logo_url']?.toString(),
                                                    ),
                                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                    tooltip: 'Remover Clube',
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (locationLabel.isNotEmpty)
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on_outlined,
                                                      size: 14,
                                                      color: Color(0xFF60A5FA),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        locationLabel,
                                                        style: TextStyle(
                                                          color: colors.textMuted,
                                                          fontSize: 12,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (phone.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.call_outlined,
                                                        size: 14,
                                                        color: Color(0xFF60A5FA),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        phone,
                                                        style: TextStyle(
                                                          color: colors.textMuted,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(height: 1, color: colors.cardBorder),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        Text(
                                          crNumber.isEmpty ? 'CR: não informado' : 'CR: $crNumber',
                                          style: TextStyle(
                                            color: colors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        SizedBox(
                                          height: 34,
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFFE5E7EB),
                                              backgroundColor: const Color(0xFF1F2937),
                                              side: const BorderSide(color: Colors.white10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ClubDetailsPage(
                                                    club: club,
                                                    currentUserId: _currentUserId,
                                                    onEdit: () => _openClubForm(existing: club),
                                                  ),
                                                ),
                                              );
                                              await _loadClubs();
                                            },
                                            child: const Text('Ver Detalhes'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

class ClubDetailsPage extends StatelessWidget {
  const ClubDetailsPage({
    super.key,
    required this.club,
    required this.onEdit,
    this.currentUserId,
  });

  final Map<String, dynamic> club;
  final VoidCallback onEdit;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final name = (club['name'] ?? '').toString();
    final logo = (club['logo_signed_url'] ?? '').toString();

    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.of(context).scaffold,
        elevation: 0,
        leading: (club['status'] == 'N' && club['owner_user_id'] == currentUserId) ? IconButton(
          icon: Icon(Icons.edit, color: AppColors.of(context).textPrimary),
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
        ) : null,
        title: Text(name.isEmpty ? 'Detalhes do Clube' : name),
        foregroundColor: AppColors.of(context).textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10, width: 2),
                        image: logo.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(logo),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: logo.isNotEmpty
                          ? null
                          : const Icon(
                              Icons.shield_outlined,
                              color: Colors.white70,
                              size: 50,
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name.isEmpty ? 'Clube sem nome' : name,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (club['cr_number'] != null &&
                        club['cr_number'].toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'CR: ${club['cr_number']}',
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Informações Gerais'),
              _buildDetailRow(context, 'CR do Clube', club['cr_number']),
              _buildDetailRow(context, 'CNPJ', club['cnpj']),
              _buildDetailRow(context, 'Telefone', club['phone']),
              _buildDetailRow(context, 'Documento', club['document_number']),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Localização'),
              _buildDetailRow(context, 'Logradouro', club['street']),
              _buildDetailRow(context, 'Número', club['number']),
              _buildDetailRow(context, 'Bairro', club['neighborhood']),
              _buildDetailRow(context, 'Complemento', club['complement']),
              _buildDetailRow(
                context,
                'Cidade / UF',
                [
                  club['city'],
                  club['state'],
                ].where((e) => e != null && e.toString().isNotEmpty).join(' - '),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF60A5FA),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, dynamic value) {
    final displayValue = (value?.toString() ?? '').trim();
    if (displayValue.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
