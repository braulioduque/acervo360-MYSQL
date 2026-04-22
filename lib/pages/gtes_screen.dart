import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:uuid/uuid.dart';

import 'package:acervo360/pages/dashboard_screen.dart';
import 'package:acervo360/theme/app_theme.dart';
import 'package:acervo360/services/api_service.dart';

class GtesPage extends StatefulWidget {
  const GtesPage({super.key});

  @override
  State<GtesPage> createState() => GtesPageState();
}

class GtesPageState extends State<GtesPage> {
  final _gtes = <Map<String, dynamic>>[];
  final _firearms = <Map<String, dynamic>>[];
  final _clubs = <Map<String, dynamic>>[];
  final _addresses = <Map<String, dynamic>>[];
  String _searchQuery = '';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sem data';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'valid':
        return const Color(0xFF34D399); // Green
      case 'submitted':
        return const Color(0xFF60A5FA); // Blue
      case 'warning':
        return Colors.orange;
      case 'expired':
      case 'cancelled':
        return const Color(0xFFF87171); // Red
      case 'draft':
      default:
        return const Color(0xFF94A3B8); // Gray
    }
  }

  String _statusTranslation(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovada';
      case 'valid':
        return 'Válida';
      case 'warning':
        return 'Vencendo';
      case 'submitted':
        return 'Enviada';
      case 'expired':
        return 'Vencida';
      case 'cancelled':
        return 'Cancelada';
      case 'draft':
      default:
        return 'Rascunho';
    }
  }

  String _getGteEffectiveStatus(Map<String, dynamic> gte) {
    String baseStatus = gte['status']?.toString() ?? 'draft';
    final expiresAtStr = gte['expires_at']?.toString();
    if (baseStatus == 'approved' && expiresAtStr != null && expiresAtStr.isNotEmpty) {
      final expiresAt = DateTime.tryParse(expiresAtStr);
      if (expiresAt != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final expDate = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
        final difference = expDate.difference(today).inDays;

        if (difference < 0) return 'expired';
        if (difference <= 31) return 'warning';
        return 'valid';
      }
    }
    return baseStatus;
  }

  List<Map<String, dynamic>> _getFilteredGtes() {
    if (_searchQuery.trim().isEmpty) return _gtes;
    
    final query = _searchQuery.toLowerCase().trim();
    
    return _gtes.where((gte) {
      final firearmBrand = (gte['firearm_brand'] ?? '').toString().toLowerCase();
      final firearmModel = (gte['firearm_model'] ?? '').toString().toLowerCase();
      final firearmName = '$firearmBrand $firearmModel';
      
      final clubName = (gte['destination_club_name'] ?? '').toString().toLowerCase();
      
      final effectiveStatus = _getGteEffectiveStatus(gte);
      final statusLabel = _statusTranslation(effectiveStatus).toLowerCase();
      
      final protocol = (gte['protocol_number'] ?? '').toString().toLowerCase();

      return firearmName.contains(query) || 
             clubName.contains(query) || 
             statusLabel.contains(query) ||
             protocol.contains(query);
    }).toList();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('gtes'),
        ApiService.get('firearms'),
        ApiService.get('user_clubs/me'),
        ApiService.get('profile_addresses/me'),
      ]);

      _gtes.clear();
      _gtes.addAll((results[0] as List).cast<Map<String, dynamic>>());
      
      _firearms.clear();
      _firearms.addAll((results[1] as List).cast<Map<String, dynamic>>());

      _clubs.clear();
      _clubs.addAll((results[2] as List).cast<Map<String, dynamic>>());

      _addresses.clear();
      _addresses.addAll((results[3] as List).cast<Map<String, dynamic>>());
      
      // Update gte_url to be absolute if needed, or signed urls are not needed if public
      // Since our local backend serves uploads publicly under /uploads, 
      // we can just use the path as is or prepend baseUrl.
      // ApiService.baseUrl + gte_url
    } catch (_) {
      _showMessage('Não foi possível carregar as GTes.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteGte(String id) async {
    try {
      await ApiService.delete('gtes', id);
      _showMessage('GTe excluída com sucesso.');
      await _loadData();
    } catch (e) {
      _showMessage('Não foi possível excluir a GTe: $e');
    }
  }

  void _showGteDetails(Map<String, dynamic> gte) {
    final colors = AppColors.of(context);
    Widget detailRow(
      String label,
      dynamic value, {
      Color? color,
      IconData? icon,
    }) {
      final strValue = (value ?? '').toString().trim();
      if (strValue.isEmpty) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      strValue,
                      style: TextStyle(
                        color: color ?? colors.textPrimary,
                        fontWeight: color != null ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final firearmBrand = (gte['firearm_brand'] ?? '').toString();
    final firearmModel = (gte['firearm_model'] ?? '').toString();
    final firearmName = firearmBrand.isNotEmpty || firearmModel.isNotEmpty
        ? '$firearmBrand $firearmModel'
        : 'Arma não informada';

    final originStr = gte['origin_street'] != null
        ? '${gte['origin_street']}, ${gte['origin_number']}'
        : 'Não informada';

    final destStr = gte['destination_club_name']?.toString() ?? 'Não informado';

    final expiresAt = gte['expires_at'] != null
        ? DateTime.tryParse(gte['expires_at'].toString())
        : null;
    final issuedAt = gte['issued_at'] != null
        ? DateTime.tryParse(gte['issued_at'].toString())
        : null;
    String displayStatus = gte['status']?.toString() ?? 'draft';

    if (displayStatus == 'approved' && expiresAt != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expDate = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
      final difference = expDate.difference(today).inDays;
      if (difference < 0) {
        displayStatus = 'expired';
      } else if (difference <= 31) {
        displayStatus = 'warning';
      } else {
        displayStatus = 'valid';
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalhes da GTe'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              detailRow('Armamento', firearmName),
              detailRow(
                'Status',
                _statusTranslation(displayStatus).toUpperCase(),
                color: _statusColor(displayStatus),
              ),
              detailRow('Protocolo', gte['protocol_number']),
              detailRow('Origem', originStr),
              detailRow('Destino', destStr),
              detailRow('Emissão', _formatDate(issuedAt)),
              detailRow(
                'Validade',
                _formatDate(expiresAt),
                color:
                    (displayStatus == 'expired' || displayStatus == 'warning')
                    ? _statusColor(displayStatus)
                    : null,
                icon: (displayStatus == 'expired' || displayStatus == 'warning')
                    ? Icons.warning_amber_rounded
                    : null,
              ),
              detailRow('Observações', gte['notes']),
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

  Widget _requirementItem(String label, bool ok) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.green : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: ok ? colors.textMuted : colors.textPrimary,
                decoration: ok ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openGteForm({Map<String, dynamic>? existing}) async {
    await _loadData();

    // Validação de pré-requisitos para novos cadastros
    if (existing == null) {
      final hasFirearm = _firearms.isNotEmpty;
      final hasClub = _clubs.isNotEmpty;
      final hasPrimaryAddress = _addresses.any((a) => a['address_type'] == 'primary');

      if (!hasFirearm || !hasClub || !hasPrimaryAddress) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text('Atenção'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Para emitir uma GTe, você precisa ter cadastrado pelo menos:'),
                const SizedBox(height: 16),
                _requirementItem('Uma Arma', hasFirearm),
                _requirementItem('Um Clube de Destino', hasClub),
                _requirementItem('Um Endereço Principal', hasPrimaryAddress),
                const SizedBox(height: 16),
                const Text('Por favor, complete esses cadastros antes de prosseguir. O cadastro pode ser realizado nos menus abaixo.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final formKey = GlobalKey<FormState>();
    final protocolNumber = TextEditingController(
      text: (existing?['protocol_number'] ?? '').toString(),
    );
    final notes = TextEditingController(
      text: (existing?['notes'] ?? '').toString(),
    );

    String? selectedFirearm = existing?['firearm_id']?.toString();
    if (selectedFirearm != null && !_firearms.any((f) => f['id'].toString() == selectedFirearm)) {
      selectedFirearm = null;
    }

    String? selectedOrigin = existing?['profile_address_id']?.toString();
    if (selectedOrigin != null && !_addresses.any((a) => a['id'].toString() == selectedOrigin)) {
      selectedOrigin = null;
    }

    String? selectedDestination = existing?['destination_club_id']?.toString();
    if (selectedDestination != null && !_clubs.any((c) => c['id'].toString() == selectedDestination)) {
      selectedDestination = null;
    }

    String selectedStatus = existing?['status']?.toString() ?? 'draft';

    DateTime? issuedAt;
    final issuedRaw = (existing?['issued_at'] ?? '').toString();
    if (issuedRaw.isNotEmpty) {
      try {
        issuedAt = DateTime.parse(issuedRaw);
      } catch (_) {}
    }

    DateTime? expiresAt;
    final expiresRaw = (existing?['expires_at'] ?? '').toString();
    if (expiresRaw.isNotEmpty) {
      try {
        expiresAt = DateTime.parse(expiresRaw);
      } catch (_) {}
    }

    final statusOptions = [
      'draft',
      'submitted',
      'approved',
      'expired',
      'cancelled',
    ];
    bool saving = false;
    PlatformFile? selectedGtePdf;
    bool gteRemoved = false;

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
                              existing == null ? 'Nova GTe' : 'Editar GTe',
                              style: const TextStyle(
                                fontSize: 19,
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
                       AbsorbPointer(
                         absorbing: saving,
                         child: DropdownButtonFormField<String>(
                           initialValue: selectedStatus,
                           items: statusOptions
                               .map(
                                 (s) => DropdownMenuItem(
                                   value: s,
                                   child: Text(_statusTranslation(s)),
                                 ),
                               )
                               .toList(),
                           onChanged: saving
                               ? null
                               : (v) => selectedStatus = v ?? 'draft',
                           decoration: const InputDecoration(
                             labelText: 'Status da GTe',
                             border: OutlineInputBorder(),
                           ),
                           validator: (v) => (v == null || v.isEmpty) ? 'Selecione o status' : null,
                         ),
                       ),
                       const SizedBox(height: 10),
                       AbsorbPointer(
                        absorbing: saving,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedFirearm,
                          items: _firearms
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f['id'].toString(),
                                  child: Text(
                                    '${f['brand']} ${f['model']} (${f['caliber']})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: saving ? null : (v) => selectedFirearm = v,
                          decoration: const InputDecoration(
                            labelText: 'Armamento',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Selecione uma arma'
                              : null,
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AbsorbPointer(
                        absorbing: saving,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedOrigin,
                          items: _addresses.map((addr) {
                            final type = addr['address_type'] == 'primary'
                                ? 'Principal'
                                : 'Secundário';
                            return DropdownMenuItem(
                              value: addr['id'].toString(),
                              child: Text(
                                '$type - ${addr['street']}, ${addr['number']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: saving ? null : (v) => selectedOrigin = v,
                          decoration: const InputDecoration(
                            labelText: 'Endereço de Origem',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Selecione a origem' : null,
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AbsorbPointer(
                        absorbing: saving,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedDestination,
                          items: _clubs
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c['id'].toString(),
                                  child: Text(
                                    c['name'].toString(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: saving
                              ? null
                              : (v) => selectedDestination = v,
                          decoration: const InputDecoration(
                            labelText: 'Clube de Destino',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Selecione o destino' : null,
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AbsorbPointer(
                        absorbing: saving,
                        child: TextFormField(
                          controller: protocolNumber,
                          decoration: const InputDecoration(
                            labelText: 'Número do Protocolo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: saving
                            ? null
                            : () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  initialDate: issuedAt ?? now,
                                );
                                if (picked != null) {
                                  setModalState(() => issuedAt = picked);
                                }
                              },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: selectedStatus == 'approved'
                                ? 'Data de Emissão *'
                                : 'Data de Emissão',
                            border: const OutlineInputBorder(),
                            enabledBorder: (selectedStatus == 'approved' && issuedAt == null)
                                ? const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                                  )
                                : null,
                          ),
                          child: Text(
                            issuedAt == null
                                ? 'Selecionar data'
                                : _formatDate(issuedAt),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: saving
                            ? null
                            : () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  initialDate: expiresAt ?? now,
                                );
                                if (picked != null) {
                                  setModalState(() => expiresAt = picked);
                                }
                              },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: (selectedStatus != 'draft' && selectedStatus != 'submitted')
                                ? 'Data de Validade *'
                                : 'Data de Validade',
                            border: const OutlineInputBorder(),
                            enabledBorder: (selectedStatus != 'draft' && 
                                           selectedStatus != 'submitted' && 
                                           expiresAt == null)
                                ? const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                                  )
                                : null,
                          ),
                          child: Text(
                            expiresAt == null
                                ? 'Selecionar data'
                                : _formatDate(expiresAt),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AbsorbPointer(
                        absorbing: saving,
                        child: TextFormField(
                          controller: notes,
                          decoration: const InputDecoration(
                            labelText: 'Observações',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
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
                                              'Documento da GTe',
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
                                                setModalState(() => selectedGtePdf = result.files.first);
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
                                                  selectedGtePdf = PlatformFile(
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
                                          if (selectedGtePdf != null || existing?['gte_url']?.toString().isNotEmpty == true)
                                            ListTile(
                                              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                              title: const Text('Remover anexo', style: TextStyle(color: Colors.redAccent)),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                setModalState(() {
                                                  selectedGtePdf = null;
                                                  gteRemoved = true;
                                                });
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                        icon: Icon(
                          selectedGtePdf != null && ['jpg', 'jpeg', 'png', 'webp'].contains(selectedGtePdf!.name.split('.').last.toLowerCase())
                              ? Icons.image
                              : Icons.file_present,
                          color: Colors.blueAccent,
                        ),
                        label: Text(
                          selectedGtePdf != null
                              ? 'Documento selecionado: ${selectedGtePdf?.name}'
                              : (existing?['gte_url']?.toString().isNotEmpty ==
                                        true
                                    ? 'Substituir arquivo existente'
                                    : 'Anexar documento da GTe'),
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                 if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }

                                if (selectedStatus == 'approved') {
                                  if (issuedAt == null || expiresAt == null) {
                                    _showMessage(
                                      'Para o status Aprovada, as datas de Emissão e Validade são obrigatórias',
                                    );
                                    return;
                                  }
                                } else if (selectedStatus != 'draft' &&
                                    selectedStatus != 'submitted') {
                                  if (expiresAt == null) {
                                    _showMessage(
                                      'Informe a Data de Validade para este status',
                                    );
                                    return;
                                  }
                                }
                                setModalState(() => saving = true);
                                 try {
                                  final gteId = existing?['id'] ?? const Uuid().v4();
                                  final payload = {
                                    'id': gteId,
                                    'firearm_id': selectedFirearm,
                                    'profile_address_id': selectedOrigin,
                                    'destination_club_id': selectedDestination,
                                    'protocol_number':
                                        protocolNumber.text.trim().isEmpty
                                        ? null
                                        : protocolNumber.text.trim(),
                                    'issued_at': issuedAt?.toIso8601String().split('T').first,
                                    'expires_at': expiresAt?.toIso8601String().split('T').first,
                                    'status': selectedStatus,
                                    'notes': notes.text.trim().isEmpty
                                        ? null
                                        : notes.text.trim(),
                                  };

                                  if (selectedGtePdf != null) {
                                    final ext = selectedGtePdf!.extension ?? selectedGtePdf!.name.split('.').last;
                                    final tempDir = Directory.systemTemp;
                                    final fileName = 'gte_${DateTime.now().millisecondsSinceEpoch}.$ext';
                                    final tempFile = File('${tempDir.path}/$fileName');
                                    
                                    if (selectedGtePdf!.bytes != null) {
                                      await tempFile.writeAsBytes(selectedGtePdf!.bytes!);
                                    } else if (selectedGtePdf!.path != null) {
                                      await File(selectedGtePdf!.path!).copy(tempFile.path);
                                    }

                                    final uploadedPath = await ApiService.uploadFile(tempFile, 'gte-documents');
                                    payload['gte_url'] = uploadedPath;
                                                                    } else if (gteRemoved) {
                                    payload['gte_url'] = null;
                                  } else if (existing != null) {
                                    payload['gte_url'] = existing['gte_url'];
                                  }

                                  await ApiService.post('gtes', payload);

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _showMessage('GTe salva com sucesso');
                                    _loadData();
                                  }
                                } catch (_) {
                                  _showMessage('Não foi possível salvar a GTe.');
                                  if (context.mounted) {
                                    setModalState(() => saving = false);
                                  }
                                }

                              },
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Salvar GTe'),
                      ),
                      if (existing != null)
                        TextButton(
                          onPressed: saving
                              ? null
                              : () async {
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
                                                'Excluir Guia de Tráfego',
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
                                                  'Os seguintes dados serão removidos permanentemente:',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: colors.textSecondary,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              ...[
                                                'Registro da GTe',
                                                'Documento PDF/Anexo associado',
                                                'Histórico de validade desta guia',
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
                                                'Deseja realmente excluir esta GTe?',
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
                                  await _deleteGte(existing['id'].toString());
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: const Text(
                            'Excluir GTe',
                            style: TextStyle(color: Colors.redAccent),
                          ),
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
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
        title: const Text('Minhas GTes'),
        actions: [
          IconButton(
            onPressed: () => openGteForm(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildGteList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: colors.scaffold,
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por arma, clube ou status...',
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: colors.textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: colors.textMuted, size: 18),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: colors.inputFill,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildGteList() {
    final filtered = _getFilteredGtes();
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isEmpty
                    ? 'Nenhuma GTe cadastrada'
                    : 'Nenhuma GTe encontrada para "$_searchQuery"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => openGteForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Cadastrar GTe'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final gte = filtered[index];
        final firearmBrand = (gte['firearm_brand'] ?? '').toString();
        final firearmModel = (gte['firearm_model'] ?? '').toString();
        final firearmName = firearmBrand.isNotEmpty || firearmModel.isNotEmpty
            ? '$firearmBrand $firearmModel'
            : 'Arma não informada';

        final displayStatus = _getGteEffectiveStatus(gte);
        final expiresAtStr = gte['expires_at']?.toString();
        final expiresAt = expiresAtStr != null && expiresAtStr.isNotEmpty
            ? DateTime.tryParse(expiresAtStr)
            : null;

                return Card(
                  color: AppColors.of(context).card,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => _showGteDetails(gte),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    displayStatus,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _statusColor(
                                      displayStatus,
                                    ).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _statusTranslation(
                                    displayStatus,
                                  ).toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(displayStatus),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: AppColors.of(context).accent,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        openGteForm(existing: gte),
                                  ),
                                  if (expiresAt != null)
                                    Text(
                                      'Validade: ${_formatDate(expiresAt)}',
                                      style: TextStyle(
                                        color: _statusColor(displayStatus),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              firearmName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.of(context).textPrimary,
                              ),
                            ),
                          ),
                          if (gte['protocol_number'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Protocolo: ${gte['protocol_number']}',
                                style: TextStyle(
                                  color: AppColors.of(context).textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          if (gte['origin_street'] != null ||
                              gte['destination_club_name'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Origem',
                                          style: TextStyle(
                                            color: AppColors.of(context).textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                        Text(
                                          gte['origin_street'] != null
                                              ? '${gte['origin_street']}, ${gte['origin_number']}'
                                              : 'N/A',
                                          style: TextStyle(
                                            color: AppColors.of(context).textPrimary,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Destino',
                                          style: TextStyle(
                                            color: AppColors.of(context).textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                        Text(
                                          gte['destination_club_name']
                                                  ?.toString() ??
                                              'N/A',
                                          style: TextStyle(
                                            color: AppColors.of(context).textPrimary,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                if ((gte['gte_signed_url'] ??
                                        gte['gte_url'] ??
                                        '')
                                    .toString()
                                    .isNotEmpty)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: SizedBox(
                                        height: 40,
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF374151,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            final url = ApiService.getPublicUrl(gte['gte_url']?.toString());
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => GteViewerPage(
                                                  title:
                                                      'GTe - Protocolo ${gte['protocol_number'] ?? 'N/A'}',
                                                  url: url,
                                                  isPdf:
                                                      url
                                                          .toLowerCase()
                                                          .contains('.pdf') ||
                                                      url
                                                          .toLowerCase()
                                                          .contains('pdf'),
                                                  fileName: 'Documento da GTe',
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.picture_as_pdf,
                                            size: 16,
                                          ),
                                          label: const Text('VISUALIZAR GTE'),
                                        ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFE5E7EB,
                                        ),
                                        backgroundColor: const Color(
                                          0xFF1F2937,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF334155),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => _showGteDetails(gte),
                                      child: const Text('EXIBIR DETALHES'),
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
              },
            );
  }
}

class GteViewerPage extends StatefulWidget {
  const GteViewerPage({
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
  State<GteViewerPage> createState() => _GteViewerPageState();
}

class _GteViewerPageState extends State<GteViewerPage> {
  Future<Uint8List> _downloadPdf() async {
    final response = await http.get(Uri.parse(widget.url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      if (bytes.length < 4 ||
          bytes[0] != 0x25 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x44 ||
          bytes[3] != 0x46) {
        throw Exception(
          'O arquivo salvo está corrompido ou vazio (Assinatura %PDF não encontrada). É provável que o arquivo tenha sido gravado com 0 bytes no momento do upload. Por favor, reenvie o anexo na tela de Edição e selecione o PDF novamente.',
        );
      }
      return bytes;
    } else {
      throw Exception(
        'Falha ao baixar do servidor: HTTP ${response.statusCode}',
      );
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
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
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
                            child: Image.network(
                              widget.url,
                              fit: BoxFit.contain,
                            ),
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
