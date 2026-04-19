import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:acervo360/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:acervo360/theme/app_theme.dart';
import 'package:acervo360/pages/dashboard_screen.dart';

class HabitualitiesPage extends StatefulWidget {
  const HabitualitiesPage({super.key});

  @override
  State<HabitualitiesPage> createState() => _HabitualitiesPageState();
}

class _HabitualitiesPageState extends State<HabitualitiesPage> {
  bool _loading = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _habitualities = [];
  List<Map<String, dynamic>> _firearms = [];
  List<String> _modalities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        ApiService.get('habitualities'),
        ApiService.get('firearms'),
        ApiService.get('habituality_modalities'), // Note: adjust backend if missing
      ]);

      if (mounted) {
        setState(() {
          _habitualities = (results[0] as List).cast<Map<String, dynamic>>();
          _firearms = (results[1] as List).cast<Map<String, dynamic>>();
          _modalities = (results[2] as List).map((e) => e['name'].toString()).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading habitualities: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteHabituality(String id) async {
    final colors = AppColors.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Excluir Habitualidade', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'Tem certeza que deseja remover este registro? Esta ação é permanente e todos os dados vinculados, incluindo anexos, serão excluídos.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCELAR', style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.delete('habitualities', id);
      _loadData();
      _showMessage('Registro removido com sucesso.');
    } catch (e) {
      debugPrint('Error deleting habituality: $e');
      _showMessage('Erro ao excluir habitualidade.');
    }
  }

  void _openForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HabitualityForm(
        item: item,
        firearms: _firearms,
        modalities: _modalities,
        onSaved: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DashboardPage()),
            );
          },
        ),
        title: const Text('Habitualidades'),
        backgroundColor: colors.scaffold,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_circle_outline),
            color: colors.accent,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(colors),
                Expanded(
                  child: _buildList(colors),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar(AppColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: colors.scaffold,
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por tipo, modalidade ou local...',
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: colors.textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: colors.textMuted, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          filled: true,
          fillColor: colors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.accent.withOpacity(0.5), width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildList(AppColors colors) {
    if (_habitualities.isEmpty) {
      return _buildEmptyState(colors);
    }

    final filtered = _habitualities.where((h) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      
      final type = (h['type'] ?? '').toString().toLowerCase();
      final modality = (h['modality'] ?? '').toString().toLowerCase();
      final location = (h['location_name'] ?? '').toString().toLowerCase();
      final event = (h['event_name'] ?? '').toString().toLowerCase();
      
      final firearm = h['firearms'] as Map<String, dynamic>?;
      final firearmDesc = firearm != null 
          ? '${firearm['brand']} ${firearm['model']}'.toLowerCase()
          : '';

      return type.contains(query) ||
          modality.contains(query) ||
          location.contains(query) ||
          event.contains(query) ||
          firearmDesc.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: colors.textMuted.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Nenhum resultado para "$_searchQuery"', style: TextStyle(color: colors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final habit = filtered[index];
        return _HabitualityCard(
          habit: habit,
          onView: () => _viewHabituality(habit),
          onEdit: () => _openForm(habit),
          onDelete: () => _deleteHabituality(habit['id']),
        );
      },
    );
  }

  void _viewHabituality(Map<String, dynamic> habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HabitualityDetailModal(habit: habit),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 80, color: colors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Nenhuma habitualidade registrada.',
            style: TextStyle(color: colors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Registrar agora'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitualityCard extends StatelessWidget {
  final Map<String, dynamic> habit;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HabitualityCard({
    required this.habit,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final date = DateTime.parse(habit['date_realization']);
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    
    final firearm = habit['firearms'];
    final firearmDesc = habit['equipment_source'] == 'Própria'
        ? (firearm != null ? '${firearm['brand']} ${firearm['model']}' : 'Arma própria')
        : '${habit['third_party_brand']} (${habit['third_party_caliber']})';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      habit['type'].toUpperCase(),
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit_outlined, size: 20, color: colors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                habit['type'] == 'Treino' 
                    ? habit['modality'] 
                    : (habit['event_name'] ?? habit['modality']),
                style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      habit['location_name'] ?? 'Local não informado',
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'EQUIPAMENTO',
                              style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• $formattedDate',
                              style: TextStyle(color: colors.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          firearmDesc,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'DISPAROS',
                        style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${habit['shot_count']}',
                        style: TextStyle(color: colors.accent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitualityForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> firearms;
  final List<String> modalities;
  final VoidCallback onSaved;

  const _HabitualityForm({
    this.item,
    required this.firearms,
    required this.modalities,
    required this.onSaved,
  });

  @override
  State<_HabitualityForm> createState() => _HabitualityFormState();
}

class _HabitualityFormState extends State<_HabitualityForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late String _type;
  final _eventNameController = TextEditingController();
  late String _modality;
  final _modalityOtherController = TextEditingController();
  
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  
  final _locationController = TextEditingController();
  String? _selectedClubId;
  
  late String _equipmentSource;
  String? _selectedFirearmId;
  
  String? _ammoSource;
  final _shotCountController = TextEditingController();
  
  // Third party fields
  String _thirdPartyType = 'Sigma';
  final _thirdPartyBrandController = TextEditingController();
  String _thirdPartySpecies = 'Pistola';
  String _thirdPartyCaliberType = 'Restrito';
  final _thirdPartyCaliberController = TextEditingController();
  final _bookPageController = TextEditingController();

  File? _attachmentFile;
  String? _currentAttachmentUrl;
  bool _attachmentRemoved = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    
    _type = item?['type'] ?? 'Treino';
    _eventNameController.text = item?['event_name'] ?? '';
    _modality = item?['modality'] ?? (widget.modalities.isNotEmpty ? widget.modalities.first : 'IPSC');
    _modalityOtherController.text = item?['modality_other'] ?? '';
    
    _date = item != null ? DateTime.parse(item['date_realization']) : null;
    _startTime = item != null ? _parseTime(item['start_time']) : null;
    _endTime = item != null ? _parseTime(item['end_time']) : null;
    
    _locationController.text = item?['location_name'] ?? '';
    _selectedClubId = item?['club_id'];
    
    _equipmentSource = item?['equipment_source'] ?? 'Própria';
    _selectedFirearmId = item?['firearm_id'];
    
    _ammoSource = item?['ammo_source'];
    _shotCountController.text = item?['shot_count']?.toString() ?? '';
    
    _thirdPartyType = item?['third_party_type'] ?? 'Sigma';
    _thirdPartyBrandController.text = item?['third_party_brand'] ?? '';
    _thirdPartySpecies = item?['third_party_species'] ?? 'Pistola';
    _thirdPartyCaliberType = item?['third_party_caliber_type'] ?? 'Restrito';
    _thirdPartyCaliberController.text = item?['third_party_caliber'] ?? '';
    _bookPageController.text = item?['book_page'] ?? '';
    
    _currentAttachmentUrl = item?['attachment_url'];
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _pickAttachment() async {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      useRootNavigator: true,
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
                  'Comprovante da Habitualidade',
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
                  );
                  if (result != null && result.files.single.path != null) {
                    setState(() => _attachmentFile = File(result.files.single.path!));
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
                    setState(() {
                      _attachmentFile = File(photo.path);
                      _attachmentRemoved = false;
                    });
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível acessar a câmera.')));
                  }
                },
              ),
              if (_attachmentFile != null || _currentAttachmentUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remover anexo', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _attachmentFile = null;
                      _currentAttachmentUrl = null;
                      _attachmentRemoved = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);

    try {
      String? attachmentUrl = _currentAttachmentUrl;
      
      if (_attachmentFile != null) {
        attachmentUrl = await ApiService.uploadFile(_attachmentFile!, 'habitualities');
      } else if (_attachmentRemoved) {
        attachmentUrl = null;
      }

      if (_date == null || _startTime == null || _endTime == null) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe data e horários.')));
        return;
      }

      if (_ammoSource == null) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o tipo de munição.')));
        return;
      }

      if (_equipmentSource == 'Própria' && _selectedFirearmId == null) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma arma.')));
        return;
      }

      if (_locationController.text.isEmpty) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o Clube ou Local.')));
        return;
      }

      final data = {
        'type': _type,
        'event_name': (_type == 'Competição' || _type == 'Curso') ? _eventNameController.text : null,
        'modality': _modality,
        'modality_other': _modality == 'Outros' ? _modalityOtherController.text : null,
        'date_realization': DateFormat('yyyy-MM-dd').format(_date!),
        'start_time': _formatTimeOfDay(_startTime!),
        'end_time': _formatTimeOfDay(_endTime!),
        'location_name': _locationController.text,
        'club_id': _selectedClubId,
        'equipment_source': _equipmentSource,
        'firearm_id': _equipmentSource == 'Própria' ? _selectedFirearmId : null,
        'ammo_source': _ammoSource,
        'shot_count': int.tryParse(_shotCountController.text) ?? 0,
        'book_page': _bookPageController.text.trim().isEmpty ? null : _bookPageController.text.trim(),
        'attachment_url': attachmentUrl,
      };

      if (_equipmentSource == 'Terceiros') {
        data.addAll({
          'third_party_type': _thirdPartyType,
          'third_party_brand': _thirdPartyBrandController.text,
          'third_party_species': _thirdPartySpecies,
          'third_party_caliber_type': _thirdPartyCaliberType,
          'third_party_caliber': _thirdPartyCaliberController.text,
        });
      }

      await ApiService.post('habitualities', {
        if (widget.item != null) 'id': widget.item!['id'],
        ...data,
      });

      widget.onSaved();
    } catch (e) {
      debugPrint('Error saving habituality: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar habitualidade.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final safePadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.scaffold,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding + safePadding),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colors),
              const SizedBox(height: 24),
              
              _sectionTitle(colors, 'INFORMAÇÕES GERAIS'),
              _buildTypeSelector(colors),
              if (_type != 'Treino') ...[
                const SizedBox(height: 16),
                _buildTextField(
                  colors: colors,
                  controller: _eventNameController,
                  label: _type == 'Competição' ? 'Nome da Competição' : 'Nome do Curso',
                  hint: 'Ex: Pan-Americano 2024',
                ),
              ],
              
              const SizedBox(height: 16),
              _buildModalitySelector(colors),
              if (_modality == 'Outros') ...[
                const SizedBox(height: 16),
                _buildTextField(
                  colors: colors,
                  controller: _modalityOtherController,
                  label: 'Outra Modalidade',
                  hint: 'Digite a modalidade',
                ),
              ],
              
              const SizedBox(height: 24),
              _sectionTitle(colors, 'DATA E HORÁRIO'),
              Row(
                children: [
                  Expanded(child: _buildDatePicker(colors)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTimePicker(colors, 'Início', _startTime, _pickStartTime)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimePicker(colors, 'Término', _endTime, _pickEndTime)),
                ],
              ),
              
              const SizedBox(height: 16),
              _buildClubAutocomplete(colors),
              
              const SizedBox(height: 24),
              _sectionTitle(colors, 'EQUIPAMENTO / MUNIÇÃO'),
              _buildEquipmentSourceSelector(colors),
              
              if (_equipmentSource == 'Própria') ...[
                const SizedBox(height: 16),
                _buildFirearmSelector(colors),
              ] else ...[
                const SizedBox(height: 16),
                _buildThirdPartySection(colors),
              ],
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildAmmoSelector(colors)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildShotCountField(colors)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildBookPageField(colors)),
                ],
              ),
              
              const SizedBox(height: 24),
              _sectionTitle(colors, 'ANEXO (OPCIONAL)'),
              _buildAttachmentPicker(colors),
              
              const SizedBox(height: 32),
              _buildSubmitButton(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.item == null ? 'Nova Habitualidade' : 'Editar Habitualidade',
          style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: colors.textMuted),
        ),
      ],
    );
  }

  Widget _sectionTitle(AppColors colors, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTypeSelector(AppColors colors) {
    final options = ['Treino', 'Competição', 'Curso'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = _type == opt;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _type = opt),
                child: Container(
                  margin: EdgeInsets.only(right: opt == options.last ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accent : colors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? colors.accent : colors.cardBorder),
                  ),
                  child: Center(
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: isSelected ? Colors.white : colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModalitySelector(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modalidade', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.modalities.contains(_modality) ? _modality : null,
              isExpanded: true,
              dropdownColor: colors.card,
              style: TextStyle(color: colors.textPrimary),
              items: widget.modalities.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _modality = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(AppColors colors) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: _date == null ? colors.textMuted : colors.accent),
            const SizedBox(width: 12),
            Text(
              _date != null ? DateFormat('dd/MM/yyyy').format(_date!) : 'Selecionar Data',
              style: TextStyle(color: _date != null ? colors.textPrimary : colors.textMuted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(AppColors colors, String label, TimeOfDay? time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colors.textMuted, fontSize: 10)),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: time == null ? colors.textMuted : colors.accent),
                const SizedBox(width: 8),
                Text(
                  time != null 
                    ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                    : '--:--',
                  style: TextStyle(color: time != null ? colors.textPrimary : colors.textMuted, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubAutocomplete(AppColors colors) {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) return const [];
        try {
          final res = await ApiService.get('clubs/search', queryParams: {'query': textEditingValue.text});
          return (res as List).cast<Map<String, dynamic>>();
        } catch (_) {
          return const [];
        }
      },
      displayStringForOption: (option) => option['name'],
      onSelected: (option) {
        setState(() {
          _selectedClubId = option['id'];
          _locationController.text = option['name'];
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (_locationController.text.isNotEmpty && controller.text.isEmpty) {
          controller.text = _locationController.text;
        }
        return _buildTextField(
          colors: colors,
          controller: controller,
          focusNode: focusNode,
          label: 'Clube / Local',
          hint: 'Comece a digitar...',
          onChanged: (val) {
             _locationController.text = val;
             _selectedClubId = null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: colors.card,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 48,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => Divider(color: colors.cardBorder, height: 1),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option['name'], style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text('${option['city'] ?? ''} ${option['state'] ?? ''}'.trim(), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEquipmentSourceSelector(AppColors colors) {
    return Row(
      children: ['Própria', 'Terceiros'].map((opt) {
        final isSelected = _equipmentSource == opt;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _equipmentSource = opt),
            child: Container(
              margin: EdgeInsets.only(right: opt == 'Própria' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accent : colors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? colors.accent : colors.cardBorder),
              ),
              child: Center(
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFirearmSelector(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selecione sua Arma', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFirearmId,
              isExpanded: true,
              dropdownColor: colors.card,
              hint: Text('Selecione uma arma', style: TextStyle(color: colors.textMuted)),
              style: TextStyle(color: colors.textPrimary),
              items: widget.firearms.map((f) {
                return DropdownMenuItem(
                  value: f['id'].toString(),
                  child: Text('${f['brand']} ${f['model']} (${f['caliber']})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedFirearmId = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThirdPartySection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: ['Sigma', 'Sinarm'].map((opt) {
            final isSelected = _thirdPartyType == opt;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _thirdPartyType = opt),
                child: Container(
                  margin: EdgeInsets.only(right: opt == 'Sigma' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accent.withOpacity(0.2) : colors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? colors.accent : colors.cardBorder),
                  ),
                  child: Center(
                    child: Text(opt, style: TextStyle(color: isSelected ? colors.accent : colors.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildTextField(colors: colors, controller: _thirdPartyBrandController, label: 'Marca', hint: 'Ex: Taurus'),
        const SizedBox(height: 16),
        _buildDropdown(
          colors: colors,
          label: 'Espécie',
          value: _thirdPartySpecies,
          items: ['Pistola', 'Revolver', 'Espingarda', 'Carabina / Fuzil', 'Rifle / Fuzil', 'Outros'],
          onChanged: (val) => setState(() => _thirdPartySpecies = val!),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                colors: colors,
                label: 'Tipo Calibre',
                value: _thirdPartyCaliberType,
                items: ['Restrito', 'Permitido'],
                onChanged: (val) => setState(() => _thirdPartyCaliberType = val!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(colors: colors, controller: _thirdPartyCaliberController, label: 'Calibre', hint: 'Ex: 9mm'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmmoSelector(AppColors colors) {
    return _buildDropdown(
      colors: colors,
      label: 'Munição',
      value: _ammoSource,
      hint: 'Selecionar',
      items: ['Própria', 'Terceirizada'],
      onChanged: (val) => setState(() => _ammoSource = val!),
    );
  }

  Widget _buildShotCountField(AppColors colors) {
    return _buildTextField(
      colors: colors,
      controller: _shotCountController,
      label: 'Disparos',
      hint: 'Ex: 50',
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildBookPageField(AppColors colors) {
    return _buildTextField(
      colors: colors,
      controller: _bookPageController,
      label: 'Livro/Folha',
      hint: 'Ex: 123/45',
      required: false,
    );
  }

  Widget _buildAttachmentPicker(AppColors colors) {
    return GestureDetector(
      onTap: _pickAttachment,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.cardBorder, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(Icons.attach_file, color: colors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _attachmentFile != null 
                    ? _attachmentFile!.path.split('/').last 
                    : (_currentAttachmentUrl != null ? 'Arquivo anexado' : 'Anexar Foto ou Arquivo'),
                style: TextStyle(color: _attachmentFile != null || _currentAttachmentUrl != null ? colors.textPrimary : colors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_attachmentFile != null || _currentAttachmentUrl != null)
              Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AppColors colors) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _saving
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(widget.item == null ? 'REGISTRAR' : 'ATUALIZAR', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildTextField({
    required AppColors colors,
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    bool required = true,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey(label),
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted),
            fillColor: colors.card,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (val) {
            if (required && (val == null || val.isEmpty)) return 'Obrigatório';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required AppColors colors,
    required String label,
    String? value,
    String? hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value != null && items.contains(value) ? value : null,
              hint: hint != null ? Text(hint, style: TextStyle(color: colors.textMuted)) : null,
              isExpanded: true,
              dropdownColor: colors.card,
              style: TextStyle(color: colors.textPrimary),
              items: items.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitualityDetailModal extends StatelessWidget {
  final Map<String, dynamic> habit;

  const _HabitualityDetailModal({required this.habit});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final date = DateTime.parse(habit['date_realization']);
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    
    final firearm = habit['firearms'];
    final firearmDesc = habit['equipment_source'] == 'Própria'
        ? (firearm != null ? '${firearm['brand']} ${firearm['model']}' : 'Arma própria')
        : '${habit['third_party_brand']} (${habit['third_party_caliber']})';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.scaffold,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: colors.cardBorder, borderRadius: BorderRadius.circular(2)),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Detalhes do Registro', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    _statusBadge(colors, habit['type']),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                if (habit['event_name'] != null)
                  _detailItem(colors, 'EVENTO', habit['event_name'], Icons.event),
                
                _detailItem(colors, 'MODALIDADE', habit['modality'] + (habit['modality_other'] != null ? ': ${habit['modality_other']}' : ''), Icons.workspace_premium),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _detailItem(colors, 'DATA', formattedDate, Icons.calendar_today)),
                    Expanded(child: _detailItem(colors, 'HORÁRIO', '${habit['start_time']} - ${habit['end_time']}', Icons.access_time)),
                  ],
                ),
                
                const SizedBox(height: 16),
                _detailItem(colors, 'LOCAL', habit['location_name'], Icons.location_on),
                
                const SizedBox(height: 24),
                _divider(colors),
                const SizedBox(height: 24),
                
                _detailItem(colors, 'EQUIPAMENTO', firearmDesc, Icons.inventory_2),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _detailItem(colors, 'MUNIÇÃO', habit['ammo_source'], Icons.security)),
                    Expanded(child: _detailItem(colors, 'DISPAROS', '${habit['shot_count']} un.', Icons.gps_fixed)),
                  ],
                ),
                
                if (habit['book_page'] != null && habit['book_page'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _detailItem(colors, 'LIVRO FOLHA', habit['book_page'].toString(), Icons.menu_book),
                ],

                const SizedBox(height: 32),
                _buildAttachmentSection(context, colors),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(AppColors colors, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(type, style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _detailItem(AppColors colors, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Expanded(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider(AppColors colors) {
    return Divider(color: colors.cardBorder, thickness: 1);
  }

  Widget _buildAttachmentSection(BuildContext context, AppColors colors) {
    final url = habit['attachment_url'] as String?;
    if (url == null || url.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.no_photography_outlined, color: colors.textMuted),
            const SizedBox(width: 12),
            Text('Sem comprovante anexado', style: TextStyle(color: colors.textMuted)),
          ],
        ),
      );
    }

    final isPdf = url.toLowerCase().endsWith('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COMPROVANTE', style: TextStyle(color: colors.textSecondary, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _openAttachment(context, url),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: colors.accent, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPdf ? 'Visualizar PDF' : 'Visualizar Foto',
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      Text('Clique para abrir o arquivo', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new, color: colors.accent, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAttachment(BuildContext context, String path) async {
    final publicUrl = ApiService.getPublicUrl(path);
    
    final isPdf = path.toLowerCase().endsWith('.pdf');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitualityViewerPage(
          title: isPdf ? 'Visualizar PDF' : 'Visualizar Foto',
          url: publicUrl,
          isPdf: isPdf,
        ),
      ),
    );
  }
}

class HabitualityViewerPage extends StatefulWidget {
  final String title;
  final String url;
  final bool isPdf;

  const HabitualityViewerPage({
    super.key,
    required this.title,
    required this.url,
    required this.isPdf,
  });

  @override
  State<HabitualityViewerPage> createState() => _HabitualityViewerPageState();
}

class _HabitualityViewerPageState extends State<HabitualityViewerPage> {
  Future<Uint8List> _downloadFile() async {
    final response = await http.get(Uri.parse(widget.url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      if (widget.isPdf) {
        if (bytes.length < 4 ||
            bytes[0] != 0x25 ||
            bytes[1] != 0x50 ||
            bytes[2] != 0x44 ||
            bytes[3] != 0x46) {
          throw Exception(
              'O arquivo PDF está corrompido ou vazio. Por favor, reenvie o anexo.');
        }
      }
      return bytes;
    } else {
      throw Exception('Falha ao baixar do servidor: HTTP ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: widget.isPdf
            ? FutureBuilder<Uint8List>(
                future: _downloadFile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(color: Colors.white);
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Erro ao carregar documento:\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
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
                child: Image.network(
                  widget.url,
                  loadingBuilder: (ctx, child, loading) {
                    if (loading == null) return child;
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                  errorBuilder: (ctx, error, stack) => const Text(
                    'Erro ao carregar imagem',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
      ),
    );
  }
}
