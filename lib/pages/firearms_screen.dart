import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:acervo360/pages/dashboard_screen.dart';
import 'package:acervo360/services/api_service.dart';
import 'package:acervo360/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class FirearmAvatarPage extends StatefulWidget {
  const FirearmAvatarPage({
    super.key,
    required this.firearmId,
    required this.firearmName,
    required this.avatarUrl,
  });

  final String firearmId;
  final String firearmName;
  final String? avatarUrl;

  @override
  State<FirearmAvatarPage> createState() => _FirearmAvatarPageState();
}

class _FirearmAvatarPageState extends State<FirearmAvatarPage> {
  static const int maxAvatarBytes = 2 * 1024 * 1024;
  static const int minAvatarSize = 300;

  bool _loading = true;
  bool _saving = false;
  String? _currentUrl;
  Uint8List? _selectedBytes;
  String? _selectedExt;

  @override
  void initState() {
    super.initState();
    _loadCurrentAvatar();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadCurrentAvatar() async {
    final avatar = widget.avatarUrl?.trim() ?? '';
    if (avatar.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _currentUrl = ApiService.getPublicUrl(avatar);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleImagePicked(Uint8List bytes, String ext) async {
    if (bytes.lengthInBytes > maxAvatarBytes) {
      _showMessage('Arquivo muito grande. Maximo 2MB.');
      return;
    }

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      if (image.width < minAvatarSize || image.height < minAvatarSize) {
        _showMessage('Resolucao minima: 300x300.');
        return;
      }
    } catch (_) {
      _showMessage('Imagem invalida.');
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
            ],
          ),
        ),
      ),
    );
  }  Future<void> _saveAvatar() async {
    if (_selectedBytes == null || _selectedBytes!.isEmpty) {
      _showMessage('Selecione uma imagem primeiro.');
      return;
    }

    setState(() => _saving = true);
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_avatar_${DateTime.now().millisecondsSinceEpoch}.${_selectedExt ?? 'jpg'}');
      await tempFile.writeAsBytes(_selectedBytes!);

      final uploadedPath = await ApiService.uploadFile(tempFile, 'firearm-avatars');
      
      if (uploadedPath != null) {
        await ApiService.post('firearms', {
          'id': widget.firearmId,
          'avatar_url': uploadedPath,
        });
      }

      if (!mounted) return;
      _showMessage('Avatar atualizado.');
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Erro ao salvar avatar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeAvatar() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ApiService.post('firearms', {
        'id': widget.firearmId,
        'avatar_url': null,
      });
      if (!mounted) return;
      setState(() {
        _currentUrl = null;
        _selectedBytes = null;
        _selectedExt = null;
      });
      _showMessage('Avatar removido.');
      Navigator.pop(context, true);
    } catch (_) {
      _showMessage('Não foi possível remover o avatar.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _selectedBytes != null
        ? Image.memory(_selectedBytes!, fit: BoxFit.cover)
        : (_currentUrl != null
              ? Image.network(_currentUrl!, fit: BoxFit.cover)
              : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Avatar da arma')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.firearmName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: const Color(0xFFE2E8F0),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : ClipOval(
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: preview ??
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: Color(0xFF64748B),
                                  ),
                            ),
                          ),
                  ),
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
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
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
            OutlinedButton.icon(
              onPressed: _saving ? null : _showAvatarSourceChooser,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Selecionar imagem'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _saving ? null : _removeAvatar,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text(
                'Remover avatar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _saveAvatar,
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
        ),
      ),
    );
  }
}

class FirearmsPage extends StatefulWidget {
  const FirearmsPage({super.key});

  @override
  State<FirearmsPage> createState() => _FirearmsPageState();
}

class _FirearmsPageState extends State<FirearmsPage> {
  String _formatDate(DateTime? date) {
    if (date == null) return 'Sem data';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _crafStatusLabel(DateTime? validUntil) {
    if (validUntil == null) return 'CRAF SEM VALIDADE';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(validUntil.year, validUntil.month, validUntil.day);

    if (dateOnly.isBefore(today)) return 'CRAF VENCIDA';

    final difference = dateOnly.difference(today).inDays;
    if (difference <= 31) return 'CRAF VENCENDO';

    return 'CRAF VALIDA';
  }

  Color _crafStatusColor(DateTime? validUntil) {
    if (validUntil == null) return const Color(0xFF94A3B8);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(validUntil.year, validUntil.month, validUntil.day);

    if (dateOnly.isBefore(today)) return const Color(0xFFF87171); // Red

    final difference = dateOnly.difference(today).inDays;
    if (difference <= 31) return Colors.orangeAccent;

    return const Color(0xFF34D399); // Green
  }

  Widget _pill(
    String text, {
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  final _firearms = <Map<String, dynamic>>[];
  late final TextEditingController _searchController;
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
    _loadFirearms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadFirearms() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('firearms');

      _firearms
        ..clear()
        ..addAll((data as List).cast<Map<String, dynamic>>());

      for (final firearm in _firearms) {
        final avatar = (firearm['avatar_url'] ?? '').toString().trim();
        if (avatar.isNotEmpty) {
          firearm['avatar_signed_url'] = ApiService.getPublicUrl(avatar);
        }

        final crafUrl = (firearm['craf_url'] ?? '').toString().trim();
        if (crafUrl.isNotEmpty) {
          firearm['craf_signed_url'] = ApiService.getPublicUrl(crafUrl);
        }
      }
    } catch (_) {
      _showMessage('Não foi possível carregar as armas.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteFirearm(String id) async {
    try {
      await ApiService.delete('firearms', id);
      await _loadFirearms();
    } catch (_) {
      _showMessage('Não foi possível excluir a arma.');
    }
  }

  Future<String?> _upsertFirearm({
    String? id,
    String? brand,
    String? model,
    String? caliber,
    String? serialNumber,
    DateTime? acquisitionDate,
    String? status,
    String? firearmType,
    String? registryType,
    String? crafNumber,
    DateTime? crafValidUntil,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{
      if (id != null) 'id': id,
      'brand': brand,
      'model': model,
      'caliber': caliber,
      'serial_number': serialNumber,
      'acquisition_date': acquisitionDate?.toIso8601String().split('T').first,
      'status': status ?? 'ativo',
      'firearm_type': firearmType,
      'registry_type': registryType,
      'craf_number': crafNumber,
      'craf_valid_until': crafValidUntil?.toIso8601String().split('T').first,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    final result = await ApiService.post('firearms', payload);
    return result['id']?.toString();
  }

  void _showFirearmDetails(Map<String, dynamic> firearm) {
    final colors = AppColors.of(context);
    Widget detailRow(String label, dynamic value, {Color? color, IconData? icon}) {
      final strValue = (value ?? '').toString().trim();
      if (strValue.isEmpty) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textSecondary)),
            Expanded(
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Expanded(child: Text(strValue, style: TextStyle(color: color ?? colors.textPrimary, fontWeight: color != null ? FontWeight.bold : null))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    DateTime? crafValidUntil;
    final crafValidRaw = (firearm['craf_valid_until'] ?? '').toString();
    if (crafValidRaw.isNotEmpty) {
      try {
        crafValidUntil = DateTime.parse(crafValidRaw);
      } catch (_) {}
    }

    final crafLabelDetails = _crafStatusLabel(crafValidUntil);
    final crafColorDetails = _crafStatusColor(crafValidUntil);
    final isWarningDetails = crafLabelDetails == 'CRAF VENCIDA' || crafLabelDetails == 'CRAF VENCENDO';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(firearm['model']?.toString() ?? 'Detalhes da Arma'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              detailRow('Marca', firearm['brand']),
              detailRow('Modelo', firearm['model']),
              detailRow('Calibre', firearm['caliber']),
              detailRow('Nº Série', firearm['serial_number']),
              detailRow('Tipo', firearm['firearm_type']),
              detailRow('Status', firearm['status']?.toString().toUpperCase()),
              detailRow('Data de Aquisição', 
                _formatDate(firearm['acquisition_date'] != null 
                  ? DateTime.tryParse(firearm['acquisition_date'].toString()) 
                  : null)
              ),
              const Divider(),
              detailRow('Registro', firearm['registry_type']),
              detailRow('Nº CRAF', firearm['craf_number']),
              detailRow('Validade CRAF',
                _formatDate(crafValidUntil),
                color: crafColorDetails,
                icon: isWarningDetails ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<String?> _saveFirearm({
    required GlobalKey<FormState> formKey,
    required void Function(bool) updateSaving,
    String? id,
    String? brand,
    String? model,
    String? caliber,
    String? serialNumber,
    DateTime? acquisitionDate,
    String? status,
    String? firearmType,
    String? registryType,
    String? crafNumber,
    DateTime? crafValidUntil,
    PlatformFile? crafPdf,
    bool removeCraf = false,
    bool removeAvatar = false,
  }) async {
    if (!(formKey.currentState?.validate() ?? false)) {
      _showMessage('Preencha os campos obrigatórios.');
      return null;
    }

    updateSaving(true);
    try {
      final firearmId = await _upsertFirearm(
        id: id,
        brand: brand?.trim().isEmpty ?? true ? null : brand!.trim(),
        model: model?.trim().isEmpty ?? true ? null : model!.trim(),
        caliber: caliber?.trim().isEmpty ?? true ? null : caliber!.trim(),
        serialNumber: serialNumber?.trim().isEmpty ?? true
            ? null
            : serialNumber!.trim(),
        acquisitionDate: acquisitionDate,
        status: status,
        firearmType: firearmType,
        registryType: registryType,
        crafNumber: crafNumber?.trim().isEmpty ?? true
            ? null
            : crafNumber!.trim(),
        crafValidUntil: crafValidUntil,
      );

      if (removeAvatar && id != null) {
        // Remove o avatar se solicitado e for uma edição
        await ApiService.post('firearms', {'id': firearmId, 'avatar_url': null});
      }

      if (crafPdf != null) {
        File? fileToUpload;
        if (crafPdf.path != null) {
          fileToUpload = File(crafPdf.path!);
        } else if (crafPdf.bytes != null) {
          final tempDir = Directory.systemTemp;
          fileToUpload = File('${tempDir.path}/temp_craf_${DateTime.now().millisecondsSinceEpoch}.${crafPdf.extension ?? 'pdf'}');
          await fileToUpload.writeAsBytes(crafPdf.bytes!);
        }

        if (fileToUpload != null) {
          final uploadedPath = await ApiService.uploadFile(fileToUpload, 'crafs');
          if (uploadedPath != null) {
            await ApiService.post('firearms', {'id': firearmId, 'craf_url': uploadedPath});
          }
        }
      } else if (removeCraf && id != null) {
        // Remove o CRAF se solicitado e for uma edição
        await ApiService.post('firearms', {'id': firearmId, 'craf_url': null});
      }

      if (!mounted) return null;
      _showMessage('Arma salva');
      return firearmId;
    } catch (e) {
      if (!mounted) return null;
      _showMessage('Não foi possível salvar a arma: $e');
    } finally {
      if (mounted) updateSaving(false);
    }

    return null;
  }

  Future<void> _openFirearmForm({Map<String, dynamic>? existing}) async {
    final formKey = GlobalKey<FormState>();
    final brand = TextEditingController(
      text: (existing?['brand'] ?? '').toString(),
    );
    final model = TextEditingController(
      text: (existing?['model'] ?? '').toString(),
    );
    final caliber = TextEditingController(
      text: (existing?['caliber'] ?? '').toString(),
    );
    final serial = TextEditingController(
      text: (existing?['serial_number'] ?? '').toString(),
    );
    final crafNumber = TextEditingController(
      text: (existing?['craf_number'] ?? '').toString(),
    );

    DateTime? acquisitionDate;
    final acquisitionRaw = (existing?['acquisition_date'] ?? '').toString();
    if (acquisitionRaw.isNotEmpty) {
      try {
        acquisitionDate = DateTime.parse(acquisitionRaw);
      } catch (_) {}
    }

    DateTime? crafValidUntil;
    final crafValidRaw = (existing?['craf_valid_until'] ?? '').toString();
    if (crafValidRaw.isNotEmpty) {
      try {
        crafValidUntil = DateTime.parse(crafValidRaw);
      } catch (_) {}
    }

    final firearmTypes = [
      'Carabina/Fuzil',
      'Espingarda',
      'Pistola',
      'Revolver',
      'Rifle/Fuzil',
    ];
    String? selectedFirearmType = (existing?['firearm_type'] ?? '').toString();
    if (selectedFirearmType.isEmpty) selectedFirearmType = null;

    final registryTypes = ['SIGMA', 'SINARM'];
    String? selectedRegistryType = (existing?['registry_type'] ?? '')
        .toString();
    if (selectedRegistryType.isEmpty) selectedRegistryType = null;

    final statusOptions = ['ativo', 'inativo', 'vendido'];
    String selectedStatus = (existing?['status'] ?? 'ativo').toString();
    if (!statusOptions.contains(selectedStatus)) {
      selectedStatus = 'ativo';
    }

    bool saving = false;
    PlatformFile? selectedCrafPdf;
    bool crafRemoved = false;
    bool avatarRemoved = false;

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final initial =
                  acquisitionDate ?? DateTime(now.year, now.month, now.day);
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(1970),
                lastDate: now,
                initialDate: initial,
                locale: const Locale('pt', 'BR'),
              );
              if (picked == null) return;
              if (!context.mounted) return;
              setModalState(() => acquisitionDate = picked);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    16,
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
                              existing == null ? 'Nova arma' : 'Editar arma',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Fechar',
                            onPressed: saving
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFirearmType,
                        items: firearmTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) => setModalState(
                                () => selectedFirearmType = value,
                              ),
                        decoration: const InputDecoration(
                          labelText: 'Tipo de armamento',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Selecione o tipo'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: saving ? null : pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data de aquisição',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            acquisitionDate == null
                                ? 'Selecionar data'
                                : '${acquisitionDate!.day.toString().padLeft(2, '0')}/'
                                      '${acquisitionDate!.month.toString().padLeft(2, '0')}/'
                                      '${acquisitionDate!.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: brand,
                        decoration: const InputDecoration(
                          labelText: 'Fabricante',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: model,
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: caliber,
                        decoration: const InputDecoration(
                          labelText: 'Calibre',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: serial,
                        decoration: const InputDecoration(
                          labelText: 'Número de série',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o número de série'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRegistryType,
                        items: registryTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) => setModalState(
                                () => selectedRegistryType = value,
                              ),
                        decoration: const InputDecoration(
                          labelText: 'Tipo de registro',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Selecione o tipo de registro'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: crafNumber,
                        decoration: const InputDecoration(
                          labelText: 'Registro do armamento (CRAF)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o registro do armamento'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      FormField<DateTime>(
                        initialValue: crafValidUntil,
                        validator: (v) => v == null ? 'Informe a validade do CRAF' : null,
                        builder: (fieldState) {
                          return InkWell(
                            onTap: saving
                                ? null
                                : () async {
                                    final now = DateTime.now();
                                    final initial =
                                        crafValidUntil ??
                                        DateTime(now.year, now.month, now.day);
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(1970),
                                      lastDate: DateTime(2100),
                                      initialDate: initial,
                                      locale: const Locale('pt', 'BR'),
                                    );
                                    if (picked == null) return;
                                    if (!context.mounted) return;
                                    setModalState(() => crafValidUntil = picked);
                                    fieldState.didChange(picked);
                                  },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Validade do CRAF',
                                border: const OutlineInputBorder(),
                                errorText: fieldState.errorText,
                              ),
                              child: Text(
                                crafValidUntil == null
                                    ? 'Selecionar data'
                                    : '${crafValidUntil!.day.toString().padLeft(2, '0')}/'
                                          '${crafValidUntil!.month.toString().padLeft(2, '0')}/'
                                          '${crafValidUntil!.year}',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        items: statusOptions
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setModalState(() => selectedStatus = value);
                              },
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.file_present, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedCrafPdf != null
                                    ? selectedCrafPdf!.name
                                    : (crafRemoved 
                                        ? 'Nenhum CRAF anexado'
                                        : (existing?['craf_url'] != null
                                            ? 'CRAF já anexado'
                                            : 'Nenhum CRAF anexado')),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: saving
                                  ? null
                                  : () async {
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
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 12),
                                                  child: Text(
                                                    'Documento do CRAF',
                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
                                                  ),
                                                ),
                                                ListTile(
                                                  leading: Icon(Icons.file_upload_outlined, color: colors.accent),
                                                  title: Text('Anexar arquivo', style: TextStyle(color: colors.textPrimary)),
                                                  onTap: () async {
                                                    Navigator.pop(ctx);
                                                    final result = await FilePicker.pickFiles(
                                                      type: FileType.custom,
                                                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
                                                      withData: true,
                                                    );
                                                    if (result != null && result.files.isNotEmpty) {
                                                      setModalState(() => selectedCrafPdf = result.files.first);
                                                    }
                                                  },
                                                ),
                                                ListTile(
                                                  leading: Icon(Icons.camera_alt_outlined, color: colors.accent),
                                                  title: Text('Tirar foto', style: TextStyle(color: colors.textPrimary)),
                                                  onTap: () async {
                                                    Navigator.pop(ctx);
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
                                                      setModalState(() {
                                                        selectedCrafPdf = PlatformFile(
                                                          name: photo.name,
                                                          size: bytes.length,
                                                          bytes: bytes,
                                                        );
                                                      });
                                                    } catch (e) {
                                                      if (mounted) _showMessage('Não foi possível acessar a câmera.');
                                                    }
                                                  },
                                                ),
                                                if (selectedCrafPdf != null || (existing?['craf_url'] != null && !crafRemoved))
                                                  ListTile(
                                                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                    title: const Text('Remover anexo', style: TextStyle(color: Colors.redAccent)),
                                                    onTap: () {
                                                      Navigator.pop(ctx);
                                                      setModalState(() {
                                                        selectedCrafPdf = null;
                                                        crafRemoved = true;
                                                      });
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              child: const Text('Anexar arquivo'),
                            ),
                          ],
                        ),
                      ),
                      if (existing != null && (existing['avatar_url'] != null && !avatarRemoved))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            icon: const Icon(Icons.no_photography_outlined, size: 18),
                            label: const Text('Remover foto da arma'),
                            onPressed: () {
                              setModalState(() => avatarRemoved = true);
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final firearmId = await _saveFirearm(
                                  formKey: formKey,
                                  updateSaving: (value) =>
                                      setModalState(() => saving = value),
                                  id: existing?['id']?.toString(),
                                  brand: brand.text,
                                  model: model.text,
                                  caliber: caliber.text,
                                  serialNumber: serial.text,
                                  acquisitionDate: acquisitionDate,
                                  status: selectedStatus,
                                  firearmType: selectedFirearmType,
                                  registryType: selectedRegistryType,
                                  crafNumber: crafNumber.text,
                                  crafValidUntil: crafValidUntil,
                                  crafPdf: selectedCrafPdf,
                                  removeCraf: crafRemoved,
                                  removeAvatar: avatarRemoved,
                                );

                                if (firearmId != null && context.mounted) {
                                  Navigator.pop(context);
                                  await _loadFirearms();
                                }
                              },
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Salvar arma'),
                      ),
                      if (existing != null)
                        TextButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final id = existing['id']?.toString();
                                  if (id == null) return;
                                  final colors = AppColors.of(context);
                                  final confirmed = await showDialog<bool>(
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
                                                'Excluir Armamento',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                  color: colors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Esta ação é DEFINITIVA e não poderá ser desfeita.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Todos os registros associados a esta arma serão removidos permanentemente, incluindo:',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: colors.textSecondary,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              ...[
                                                'Avatar da arma',
                                                'Documento do CRAF',
                                                'Todas as GTEs vinculadas',
                                                'Todos os documentos PDF das GTes',
                                              ].map((item) => Padding(
                                                    padding: const EdgeInsets.only(bottom: 6),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.remove_circle_outline,
                                                            size: 14, color: colors.textSecondary.withOpacity(0.6)),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            item,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: colors.textSecondary,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )),
                                              const SizedBox(height: 20),
                                              Divider(color: colors.textSecondary.withOpacity(0.1)),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Deseja realmente excluir esta arma e todos os seus dados?',
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
                                                        backgroundColor: Colors.redAccent,
                                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12)),
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
                                    ),
                                  ) ?? false;
                                  if (!confirmed) return;
                                  await _deleteFirearm(id);
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: const Text(
                            'Excluir arma',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                    ],
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

    final filtered = _firearms.where((f) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final brand = (f['brand'] ?? '').toString().toLowerCase();
      final model = (f['model'] ?? '').toString().toLowerCase();
      final serial = (f['serial_number'] ?? '').toString().toLowerCase();
      final caliber = (f['caliber'] ?? '').toString().toLowerCase();
      return brand.contains(query) ||
          model.contains(query) ||
          serial.contains(query) ||
          caliber.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          },
        ),
        title: const Text('Minhas Armas'),
        actions: [
          IconButton(
            onPressed: () => _openFirearmForm(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _firearms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text('Nenhuma arma cadastrada'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _openFirearmForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Cadastrar arma'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Pesquisar por marca, modelo, série...',
                          hintStyle: TextStyle(color: colors.textMuted),
                          prefixIcon: Icon(Icons.search, color: colors.accent),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: colors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: colors.textMuted,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma arma encontrada',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tente pesquisar por outro termo',
                                    style: TextStyle(color: colors.textMuted),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton(
                                    onPressed: () => _searchController.clear(),
                                    child: const Text('Limpar pesquisa'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final firearm = filtered[index];
                                final brand = (firearm['brand'] ?? '').toString();
                                final model = (firearm['model'] ?? '').toString();
                                final String avatarUrl;
                                if (firearm['avatar_signed_url'] != null &&
                                    firearm['avatar_signed_url']
                                        .toString()
                                        .startsWith('http')) {
                                  avatarUrl =
                                      firearm['avatar_signed_url'].toString();
                                } else if (firearm['avatar_url'] != null &&
                                    firearm['avatar_url']
                                        .toString()
                                        .startsWith('http')) {
                                  avatarUrl = firearm['avatar_url'].toString();
                                } else {
                                  avatarUrl = '';
                                }
                                final titleText = [
                                  brand,
                                  model,
                                ].where((e) => e.isNotEmpty).join(' ');
                                final displayTitle = titleText.isEmpty
                                    ? 'Arma sem nome'
                                    : titleText;
                                final firearmType =
                                    (firearm['firearm_type'] ?? '').toString();
                                final serialNumber =
                                    (firearm['serial_number'] ?? '').toString();
                                final registryType =
                                    (firearm['registry_type'] ?? '').toString();
                                final crafNumber =
                                    (firearm['craf_number'] ?? '').toString();
                                DateTime? crafValidUntil;
                                final crafValidRaw =
                                    (firearm['craf_valid_until'] ?? '')
                                        .toString();
                                if (crafValidRaw.isNotEmpty) {
                                  try {
                                    crafValidUntil = DateTime.parse(crafValidRaw);
                                  } catch (_) {}
                                }
                                final crafLabel =
                                    _crafStatusLabel(crafValidUntil);
                                final crafColor =
                                    _crafStatusColor(crafValidUntil);

                                return InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _showFirearmDetails(firearm),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: colors.card,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: colors.cardBorder),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            final updated =
                                                await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FirearmAvatarPage(
                                                  firearmId: firearm['id']
                                                          ?.toString() ??
                                                      '',
                                                  firearmName: displayTitle,
                                                  avatarUrl: firearm['avatar_url']
                                                      ?.toString(),
                                                ),
                                              ),
                                            );
                                            if (updated == true) {
                                              await _loadFirearms();
                                            }
                                          },
                                          child: Container(
                                            width: 88,
                                            height: 88,
                                            decoration: BoxDecoration(
                                              color: colors.inputFill,
                                              borderRadius: BorderRadius.circular(16),
                                              image: avatarUrl.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                          avatarUrl),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: avatarUrl.isNotEmpty
                                                ? null
                                                : const Icon(
                                                    Icons.inventory_2_outlined,
                                                    color: Color(0xFF94A3B8),
                                                    size: 30,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (firearmType.isNotEmpty)
                                                    _pill(
                                                      firearmType.toUpperCase(),
                                                      background:
                                                          const Color(0xFF1E293B),
                                                      foreground:
                                                          const Color(0xFF60A5FA),
                                                    ),
                                                  const Spacer(),
                                                  _pill(
                                                    crafLabel,
                                                    background:
                                                        crafColor.withValues(
                                                      alpha: 0.15,
                                                    ),
                                                    foreground: crafColor,
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(
                                                        left: 6),
                                                    child: IconButton(
                                                      tooltip: 'Editar Arma',
                                                      icon: Icon(
                                                        Icons.edit,
                                                        color: colors.accent,
                                                        size: 20,
                                                      ),
                                                      onPressed: () =>
                                                          _openFirearmForm(
                                                              existing: firearm),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                displayTitle,
                                                style: TextStyle(
                                                  color: colors.textPrimary,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              if (serialNumber.isNotEmpty)
                                                Text(
                                                  'Serie: $serialNumber',
                                                  style: TextStyle(
                                                    color: colors.textMuted,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              if (registryType.isNotEmpty ||
                                                  crafNumber.isNotEmpty)
                                                Text(
                                                  'Registro ${registryType.isEmpty ? '' : registryType}: $crafNumber',
                                                  style: TextStyle(
                                                    color: colors.textMuted,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    (crafLabel == 'CRAF VENCIDA' ||
                                                            crafLabel ==
                                                                'CRAF VENCENDO')
                                                        ? Icons
                                                            .warning_amber_rounded
                                                        : Icons
                                                            .check_circle_outline,
                                                    size: 14,
                                                    color: crafColor,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Validade CRAF: ${_formatDate(crafValidUntil)}',
                                                    style: TextStyle(
                                                      color: crafColor,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  if ((firearm['craf_signed_url'] ??
                                                          firearm['craf_url'] ??
                                                          '')
                                                      .toString()
                                                      .isNotEmpty)
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                                right: 8),
                                                        child: SizedBox(
                                                          height: 40,
                                                          child: FilledButton.icon(
                                                            style: FilledButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xFF374151),
                                                              foregroundColor:
                                                                  Colors.white,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                            ),
                                                            onPressed: () {
                                                              final url = (firearm[
                                                                          'craf_signed_url'] ??
                                                                      firearm[
                                                                          'craf_url'])
                                                                  .toString();
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (_) =>
                                                                      CrafViewerPage(
                                                                    title:
                                                                        'CRAF - $displayTitle',
                                                                    url: url,
                                                                    isPdf: url
                                                                            .toLowerCase()
                                                                            .contains(
                                                                                '.pdf') ||
                                                                        url
                                                                            .toLowerCase()
                                                                            .contains(
                                                                                'pdf'),
                                                                    fileName:
                                                                        'Documento Anexo',
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            icon: const Icon(
                                                                Icons.picture_as_pdf,
                                                                size: 16),
                                                            label: const Text(
                                                                'Ver CRAF'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 40,
                                                      child: OutlinedButton(
                                                        style: OutlinedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              const Color(
                                                                  0xFFE5E7EB),
                                                          backgroundColor:
                                                              const Color(
                                                                  0xFF1F2937),
                                                          side: const BorderSide(
                                                            color: Color(0xFF334155),
                                                          ),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(12),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            _showFirearmDetails(
                                                                firearm),
                                                        child: const Text(
                                                            'Ver Detalhes'),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
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

class CrafViewerPage extends StatefulWidget {
  const CrafViewerPage({
    super.key,
    required this.title,
    required this.url,
    required this.isPdf,
    required this.fileName,
  });

  final String title;
  final String url;
  final bool isPdf;
  final String fileName;

  @override
  State<CrafViewerPage> createState() => _CrafViewerPageState();
}

class _CrafViewerPageState extends State<CrafViewerPage> {
  Future<Uint8List> _downloadPdf() async {
    final response = await http.get(Uri.parse(widget.url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      if (bytes.length < 4 || bytes[0] != 0x25 || bytes[1] != 0x50 || bytes[2] != 0x44 || bytes[3] != 0x46) {
        throw Exception('O arquivo salvo está corrompido ou vazio (Assinatura %PDF não encontrada). É provável que o arquivo tenha sido gravado com 0 bytes no momento do upload. Por favor, reenvie o anexo na tela de Edição e selecione o PDF novamente.');
      }
      return bytes;
    } else {
      throw Exception('Falha ao baixar do servidor: HTTP ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: widget.url.startsWith('http')
                ? (widget.isPdf
                    ? FutureBuilder<Uint8List>(
                        future: _downloadPdf(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Erro ao carregar documento:\n\n${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasData) {
                            return SfPdfViewer.memory(snapshot.data!);
                          }
                          return const SizedBox();
                        },
                      )
                    : InteractiveViewer(
                        child: Center(
                          child: Image.network(widget.url, fit: BoxFit.contain),
                        ),
                      ))
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Erro: A URL do documento é inválida ou não pôde ser gerada.\nURL Original: ${widget.url}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
