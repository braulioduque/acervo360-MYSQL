import 'dart:io';
import 'package:acervo360/pages/addresses_screen.dart';
import 'package:acervo360/pages/change_password_screen.dart';
import 'package:acervo360/pages/privacy_policy_screen.dart';
import 'package:acervo360/pages/terms_of_use_screen.dart';
import 'package:acervo360/pages/welcome_screen.dart';
import 'package:acervo360/services/biometric_service.dart';
import 'package:acervo360/services/theme_service.dart';
import 'package:acervo360/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path/path.dart' as p;

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const List<String> _crCategories = [
    'Caçador',
    'Atirador',
    'Colecionador',
  ];
  static const _avatarBucket = 'profile-avatars';
  final Map<String, Map<String, dynamic>> _addressesByType = {};
  final _profileFormKey = GlobalKey<FormState>();
  final _crFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _crController = TextEditingController();
  final _crValidityController = TextEditingController();
  final _phoneController = TextEditingController();
  final Set<String> _crCategoriesSelected = {};
  final _avatarController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  DateTime? _crValidUntil;
  String? _avatarPreviewUrl;
  String? _crSignedUrl;
  Uint8List? _selectedCrBytes;
  String? _selectedCrExt;
  String? _selectedCrName;

  String? _userId;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    _userId = await ApiService.getUserId();
    _userEmail = await ApiService.getUserEmail();
    await _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _crController.dispose();
    _crValidityController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDateBr(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  DateTime? _parseIsoDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String? _validateCrValidity(String? value) {
    if (_crValidUntil == null) {
      return 'Informe a validade do CR';
    }
    return null;
  }



  String? _validateCpf(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }

    // Rejeita sequências repetidas (111.111.111-11 etc.)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
      return 'CPF inválido';
    }

    // Valida 1º dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(digits[i]) * (10 - i);
    }
    int remainder = (sum * 10) % 11;
    if (remainder == 10 || remainder == 11) remainder = 0;
    if (remainder != int.parse(digits[9])) return 'CPF inválido';

    // Valida 2º dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(digits[i]) * (11 - i);
    }
    remainder = (sum * 10) % 11;
    if (remainder == 10 || remainder == 11) remainder = 0;
    if (remainder != int.parse(digits[10])) return 'CPF inválido';

    return null;
  }

  String? _extractAvatarPathFromUrl(String value) {
    final marker = '/profile-avatars/';
    final markerIdx = value.indexOf(marker);
    if (markerIdx < 0) {
      return null;
    }

    final pathWithQuery = value.substring(markerIdx + marker.length);
    final path = pathWithQuery.split('?').first;
    if (path.isEmpty) {
      return null;
    }

    return Uri.decodeComponent(path);
  }

  String _normalizeAvatarStorageValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (!trimmed.startsWith('http')) {
      return trimmed;
    }

    return _extractAvatarPathFromUrl(trimmed) ?? trimmed;
  }

  String? get _avatarValueForStorage {
    final normalized = _normalizeAvatarStorageValue(_avatarController.text);
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> _setAvatarValue(String value) async {
    final normalized = _normalizeAvatarStorageValue(value);
    _avatarController.text = normalized;

    if (normalized.isEmpty) {
      if (!mounted) return;
      setState(() => _avatarPreviewUrl = null);
      return;
    }

    if (normalized.startsWith('http')) {
      if (!mounted) return;
      setState(() => _avatarPreviewUrl = normalized);
      return;
    }

    try {
      final publicUrl = ApiService.getPublicUrl(normalized);
      if (!mounted) return;
      setState(() => _avatarPreviewUrl = publicUrl);
    } catch (_) {
      if (!mounted) return;
      setState(() => _avatarPreviewUrl = null);
    }
  }

  Future<void> _loadProfile() async {
    if (_userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMyProfile();

      if (!mounted) return;

      if (data != null) {
        _nameController.text = (data['full_name'] ?? '').toString();
        _cpfController.text = (data['cpf'] ?? '').toString();
        _phoneController.text = (data['phone'] ?? '').toString();
        _crController.text = (data['cr_number'] ?? '').toString();
        _crValidUntil = _parseIsoDate(
          (data['cr_valid_until'] ?? '').toString(),
        );
        _crValidityController.text = _crValidUntil == null
            ? ''
            : _formatDateBr(_crValidUntil!);
        _crCategoriesSelected.clear();
        final categories = data['cr_categories'];
        if (categories is List) {
          for (final item in categories) {
            final value = item?.toString();
            if (value != null && _crCategories.contains(value)) {
              _crCategoriesSelected.add(value);
            }
          }
        }
        await _setAvatarValue((data['avatar_url'] ?? '').toString());

        final crUrl = (data['cr_url'] ?? '').toString().trim();
        if (crUrl.isNotEmpty) {
          _crSignedUrl = ApiService.getPublicUrl(crUrl);
        } else {
          _crSignedUrl = null;
        }

        await _loadAddresses();
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erro ao carregar perfil: $e');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Erro ao carregar perfil.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final data = await ApiService.get('profile_addresses/me');

      _addressesByType.clear();
      for (final row in data as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final type = (map['address_type'] ?? '').toString();
        if (type.isNotEmpty) _addressesByType[type] = map;
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível carregar endereços.');
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
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
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Alterar avatar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: colors.accent),
                title: Text('Escolher da galeria', style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatarFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: colors.accent),
                title: Text('Tirar foto com a câmera', style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatarFromCamera();
                },
              ),
              if (_avatarPreviewUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remover avatar', style: TextStyle(color: Colors.redAccent)),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = AppColors.of(context);
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text('Remover avatar', style: TextStyle(color: colors.textPrimary)),
          content: Text('Deseja realmente remover sua foto de perfil?', style: TextStyle(color: colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: colors.textMuted)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isUploadingAvatar = true);
    try {
      // O backend já exclui o arquivo físico ao receber avatar_url: null no upsert
      await ApiService.updateProfile({
        'avatar_url': null,
      });

      await _setAvatarValue('');
      if (mounted) _showMessage('Avatar removido com sucesso.');
    } catch (e) {
      if (mounted) _showMessage('Erro ao remover avatar: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _pickAvatarFromGallery() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final selected = result.files.first;
    final bytes = selected.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showMessage('Não foi possível ler o arquivo selecionado.');
      return;
    }
    final ext = (selected.extension ?? 'jpg').toLowerCase();
    await _uploadAvatarBytes(bytes, ext);
  }

  Future<void> _pickAvatarFromCamera() async {
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
      if (bytes.isEmpty) {
        _showMessage('Não foi possível ler a foto capturada.');
        return;
      }
      final ext = photo.path.split('.').last.toLowerCase();
      await _uploadAvatarBytes(bytes, ext);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Não foi possível acessar a câmera.');
    }
  }

  Future<void> _uploadAvatarBytes(Uint8List bytes, String extension) async {
    if (_userId == null) {
      _showMessage('Sessão expirada. Faça login novamente.');
      return;
    }

    setState(() => _isUploadingAvatar = true);
    try {
      final tempFile = File(p.join(Directory.systemTemp.path, 'temp_avatar.$extension'));
      await tempFile.writeAsBytes(bytes);

      final remotePath = await ApiService.uploadFile(tempFile, _avatarBucket);
      await _setAvatarValue(remotePath);

      // Atualiza o perfil com a nova URL do avatar
      await ApiService.updateProfile({
        'avatar_url': remotePath,
      });

      if (!mounted) return;
      _showMessage('Avatar atualizado com sucesso.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erro ao enviar avatar: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<bool> _saveProfile({GlobalKey<FormState>? formKey}) async {
    if (_userId == null) {
      _showMessage('Sessão expirada. Faça login novamente.');
      return false;
    }

    final key = formKey ?? _profileFormKey;
    if (!(key.currentState?.validate() ?? false)) {
      return false;
    }

    setState(() => _isSaving = true);
    try {
      final cpfDigits = _cpfController.text.replaceAll(RegExp(r'\D'), '');

      final payload = {
        'full_name': _nameController.text.trim(),
        'cpf': cpfDigits.isEmpty ? null : cpfDigits,
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'cr_number': _crController.text.trim().isEmpty
            ? null
            : _crController.text.trim(),
        'cr_categories': _crCategoriesSelected.isEmpty
            ? null
            : _crCategoriesSelected.toList(),
        'cr_valid_until': _crValidUntil?.toIso8601String().split('T').first,
        'avatar_url': _avatarValueForStorage,
        'cr_url': await _uploadCrIfSelected(_userId!),
      };

      await ApiService.updateProfile(payload);

      if (!mounted) return false;
      _showMessage('Dados atualizados com sucesso.');
      return true;
    } catch (e) {
      if (!mounted) return false;
      _showMessage('Erro ao salvar perfil: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    return false;
  }

  Future<String?> _uploadCrIfSelected(String userId) async {
    if (_selectedCrBytes == null) {
      final data = await ApiService.getMyProfile();
      return data['cr_url']?.toString();
    }

    final bytes = _selectedCrBytes!;
    final ext = _selectedCrExt ?? 'pdf';
    
    final tempFile = File(p.join(Directory.systemTemp.path, 'temp_cr.$ext'));
    await tempFile.writeAsBytes(bytes);

    final path = await ApiService.uploadFile(tempFile, 'cr-documents');
    return path;
  }

  void _pickCrSourceChooser(Function setModalState) {
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
                  'Documento do CR',
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
                    final selected = result.files.first;
                    if (selected.bytes != null) {
                      setModalState(() {
                        _selectedCrBytes = selected.bytes;
                        _selectedCrExt = selected.extension?.toLowerCase() ?? 'pdf';
                        _selectedCrName = selected.name;
                      });
                    }
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
                    final ext = photo.path.split('.').last.toLowerCase();
                    setModalState(() {
                      _selectedCrBytes = bytes;
                      _selectedCrExt = ext;
                      _selectedCrName = photo.name;
                    });
                  } catch (e) {
                    if (mounted) _showMessage('Não foi possível acessar a câmera.');
                  }
                },
              ),
              if (_selectedCrBytes != null || _crSignedUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remover documento', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeCrDocument(setModalState);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeCrDocument(Function setModalState) async {
    if (_userId == null) return;
    try {
      await ApiService.updateProfile({'cr_url': null});
      setModalState(() {
        _selectedCrBytes = null;
        _selectedCrExt = null;
        _selectedCrName = null;
        _crSignedUrl = null;
      });
      if (mounted) _showMessage('Documento do CR removido com sucesso.');
    } catch (e) {
      if (mounted) _showMessage('Não foi possível remover o documento do CR: $e');
    }
  }


  Future<void> _deleteAccountTotally() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() => _isSaving = true);
    try {
      await ApiService.post('auth/delete-account', {});
      await ApiService.logout();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomePage()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) _showMessage('Erro ao excluir conta: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final colors = AppColors.of(context);
    return await showDialog<bool>(
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
                        color: Colors.red.withOpacity(0.1),
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
                      'Excluir conta permanentemente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Esta ação é DEFINITIVA e NÃO poderá ser desfeita.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Todos os seus dados serão removidos permanentemente, incluindo:',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      'Perfil e dados pessoais',
                      'Avatar do perfil',
                      'Documento do CR',
                      'Todos os armamentos e seus avatares',
                      'Todos os documentos CRAF',
                      'Todas as GTEs e seus documentos',
                      'Todos os clubes e seus logos',
                      'Endereços cadastrados',
                      'Dados de assinatura',
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
                      'Deseja realmente excluir sua conta e todos os seus dados?',
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
                              'Excluir Tudo',
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
        ) ??
        false;
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  void _openChangePasswordScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
    );
  }

  Future<void> _openAddressesPage({String? type}) async {
    // If trying to open secondary address directly, check if primary exists
    if (type == 'secondary' && _addressesByType['primary'] == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('Atenção'),
            ],
          ),
          content: const Text(
            'Para cadastrar um endereço secundário, é necessário primeiro cadastrar o endereço principal.',
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

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressesPage(initialType: type),
      ),
    );
    _loadProfile();
  }

  void _openPersonalDataSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final colors = AppColors.of(context);
            final phoneFormatter = MaskTextInputFormatter(
              mask: '(##) #####-####',
              filter: {"#": RegExp(r'[0-9]')},
              initialText: _phoneController.text,
            );
            final cpfFormatter = MaskTextInputFormatter(
              mask: '###.###.###-##',
              filter: {"#": RegExp(r'[0-9]')},
              initialText: _cpfController.text,
            );
            final inputTextStyle = TextStyle(
              color: colors.textPrimary,
            );
            final labelStyle = TextStyle(color: colors.textSecondary);
            final fillColor = colors.inputFill;

            InputDecoration inputDecoration(String label) {
              return InputDecoration(
                labelText: label,
                labelStyle: labelStyle,
                filled: true,
                fillColor: fillColor,
                border: const OutlineInputBorder(),
              );
            }

            return SafeArea(
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: _profileFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Dados Pessoais',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          style: inputTextStyle,
                          decoration: inputDecoration('Nome completo'),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'Informe o nome completo'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          validator: _validateCpf,
                          inputFormatters: [
                            cpfFormatter,
                          ],
                          style: inputTextStyle,
                          decoration: inputDecoration('CPF'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _userEmail ?? 'Sem e-mail',
                          readOnly: true,
                          style: inputTextStyle,
                          decoration: inputDecoration('E-mail'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: inputTextStyle,
                          inputFormatters: [
                            phoneFormatter,
                          ],
                          decoration: inputDecoration('Telefone'),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'Informe o telefone'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _openAddressesPage,
                            icon: const Icon(Icons.location_on_outlined),
                            label: const Text(
                              'Gerenciar Endereços (Principal e Secundário)',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    setModalState(() {}); // Provoca rebuild para mostrar spinner
                                    final saved = await _saveProfile(
                                      formKey: _profileFormKey,
                                    );
                                    if (saved && context.mounted) {
                                      Navigator.pop(context);
                                    } else {
                                      setModalState(() {}); // Provoca rebuild para habilitar botão se falhar
                                    }
                                  },
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Salvar dados'),
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

  void _openCrInfoDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = AppColors.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: _crFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Documentação do CR',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _crController,
                          decoration: const InputDecoration(
                            labelText: 'Número do CR',
                            hintText: '000.000.000-00',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o número do CR'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _crValidityController,
                          readOnly: true,
                          validator: _validateCrValidity,
                          onTap: () async {
                            final now = DateTime.now();
                            final initial = _crValidUntil ?? DateTime(now.year + 1, now.month, now.day);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );

                            if (picked == null) return;

                            setModalState(() {
                              _crValidUntil = picked;
                              _crValidityController.text = _formatDateBr(picked);
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Validade do CR',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_month_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Categorias do CR',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FormField<Set<String>>(
                          initialValue: _crCategoriesSelected,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Selecione ao menos uma categoria do CR'
                              : null,
                          builder: (fieldState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ..._crCategories.map(
                                  (cat) => CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(cat),
                                    value: _crCategoriesSelected.contains(cat),
                                    onChanged: (checked) {
                                      setModalState(() {
                                        if (checked == true) {
                                          _crCategoriesSelected.add(cat);
                                        } else {
                                          _crCategoriesSelected.remove(cat);
                                        }
                                        fieldState.didChange(_crCategoriesSelected);
                                      });
                                    },
                                  ),
                                ),
                                if (fieldState.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      fieldState.errorText!,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Documento do CR',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _pickCrSourceChooser(setModalState);
                                },
                                icon: const Icon(Icons.upload_file),
                                label: Text(
                                  (_selectedCrBytes != null || _crSignedUrl != null)
                                      ? 'Alterar arquivo'
                                      : 'Anexar arquivo / foto',
                                ),
                              ),
                            ),
                            if (_crSignedUrl != null || _selectedCrBytes != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  if (_selectedCrBytes != null) {
                                    final bool isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(_selectedCrExt);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CrViewerPage(
                                          title: 'Certificado de Registro (Preview)',
                                          url: '',
                                          bytes: _selectedCrBytes,
                                          isImage: isImage,
                                        ),
                                      ),
                                    );
                                  } else if (_crSignedUrl != null) {
                                    // Parse extension from signed url if possible
                                    final lUrl = _crSignedUrl!.toLowerCase();
                                    final bool isImage = lUrl.contains('.jpg') || lUrl.contains('.jpeg') || lUrl.contains('.png') || lUrl.contains('.webp');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CrViewerPage(
                                          title: 'Certificado de Registro',
                                          url: _crSignedUrl!,
                                          isImage: isImage,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.visibility,
                                  color: Colors.blueAccent,
                                ),
                                tooltip: 'Visualizar CR',
                              ),
                            ],
                          ],
                        ),
                        if (_selectedCrName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Arquivo: $_selectedCrName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    if (_crFormKey.currentState?.validate() ?? false) {
                                      final saved = await _saveProfile(
                                        formKey: _crFormKey,
                                      );
                                      if (saved && context.mounted) {
                                        Navigator.pop(context);
                                        _loadProfile();
                                      }
                                    }
                                  },
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Salvar documentação'),
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

  void _openSecuritySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = AppColors.of(context);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Toggle Biometria ──
                    FutureBuilder<List<bool>>(
                      future: Future.wait([
                        BiometricService.isDeviceSupported(),
                        BiometricService.isBiometricEnabled(),
                      ]),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final isSupported = snapshot.data![0];
                        final isEnabled = snapshot.data![1];

                        if (!isSupported) return const SizedBox.shrink();

                        return SwitchListTile(
                          secondary: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.fingerprint_rounded,
                              color: colors.accent,
                            ),
                          ),
                          title: Text(
                            'Login por biometria',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            isEnabled ? 'Ativado' : 'Desativado',
                            style: TextStyle(
                              color: colors.textSecondary,
                            ),
                          ),
                          value: isEnabled,
                          activeThumbColor: const Color(0xFF3B82F6),
                          onChanged: (value) async {
                            if (value) {
                              // Solicitar senha para ativar
                              final password = await _showPasswordConfirmDialog();
                              if (password == null || password.isEmpty) return;

                              final email = _userEmail;
                              if (email == null) {
                                _showMessage('Sessão expirada.');
                                return;
                              }

                              await BiometricService.enableBiometric(email, password);
                              setSheetState(() {});
                              if (mounted) _showMessage('Biometria ativada!');
                            } else {
                              await BiometricService.disableBiometric();
                              setSheetState(() {});
                              if (mounted) _showMessage('Biometria desativada.');
                            }
                          },
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 12, endIndent: 12),
                    ListTile(
                      leading: const Icon(Icons.password_outlined),
                      title: const Text('Trocar senha'),
                      onTap: () {
                        Navigator.pop(context);
                        _openChangePasswordScreen();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Excluir conta totalmente',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _deleteAccountTotally();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showPasswordConfirmDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        final colors = AppColors.of(context);
        return AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirme sua senha',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Para ativar a biometria, informe sua senha atual.',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Sua senha',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 
                      : colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF334155) // Lighter than card background
                    : colors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: colors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accent,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      );
      },
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = _avatarPreviewUrl;

    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2563EB), width: 3),
      ),
      child: ClipOval(
        child: avatarUrl == null || avatarUrl.trim().isEmpty
            ? Container(
                color: const Color(0xFFE2E8F0),
                child: const Icon(
                  Icons.person,
                  size: 52,
                  color: Color(0xFF64748B),
                ),
              )
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(
                    Icons.person,
                    size: 52,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
      ),
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colors = AppColors.of(context);
        return Dialog(
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
                        Icons.support_agent_rounded,
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
                        'Central de Ajuda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Para suporte, dúvidas ou informações adicionais, nossa equipe está à disposição.',
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
                                    'WhatsApp de Suporte',
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
                          onPressed: () => Navigator.pop(context),
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
        );
      },
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.textSecondary),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textMuted,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title) {
    final colors = AppColors.of(context);
    return Text(
      title,
      style: TextStyle(
        color: colors.textMuted,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _userEmail ?? 'Sem e-mail';
    final fullName = _nameController.text.trim().isEmpty
        ? 'USUARIO'
        : _nameController.text.trim().toUpperCase();
    final crNumber = _crController.text.trim().isEmpty
        ? 'Não informado'
        : _crController.text.trim();
    final crCategoryLabel = _crCategoriesSelected.isEmpty
        ? 'Categorias não informadas'
        : _crCategoriesSelected.join(', ');
    final isCrValid =
        _crValidUntil != null &&
        !_crValidUntil!.isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        );

    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildAvatar(),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: InkWell(
                              onTap: _isUploadingAvatar
                                  ? null
                                  : _showAvatarSourceChooser,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.scaffold,
                                    width: 2,
                                  ),
                                ),
                                child: _isUploadingAvatar
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
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
                    const SizedBox(height: 18),
                    Text(
                      fullName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Categoria: $crCategoryLabel | CR: $crNumber',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userEmail,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isCrValid
                              ? const Color(0xFF0A3F2E)
                              : const Color(0xFF3A1F27),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          isCrValid ? 'CR VALIDO' : 'CR VENCIDO / SEM VALIDADE',
                          style: TextStyle(
                            color: isCrValid
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFFFCA5A5),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle('MINHA CONTA'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.cardBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuTile(
                            icon: Icons.person_outline,
                            iconBg: const Color(0xFF0F1E38),
                            iconColor: const Color(0xFF60A5FA),
                            title: 'Dados Pessoais e Endereços',
                            subtitle: 'Nome, CPF, e-mail, telefone e endereços',
                            onTap: _openPersonalDataSheet,
                          ),
                          const Divider(height: 1, indent: 12, endIndent: 12),
                          _buildMenuTile(
                            icon: Icons.shield_outlined,
                            iconBg: const Color(0xFF0C2D25),
                            iconColor: const Color(0xFF34D399),
                            title: 'Documentação do CR',
                            subtitle: 'Número, validade, categorias',
                            onTap: _openCrInfoDialog,
                          ),
                          const Divider(height: 1, indent: 12, endIndent: 12),
                          _buildMenuTile(
                            icon: Icons.lock_outline,
                            iconBg: const Color(0xFF24204B),
                            iconColor: const Color(0xFFA5B4FC),
                            title: 'Segurança e Senha',
                            subtitle: 'Trocar senha, biometria, excluir conta',
                            onTap: _openSecuritySheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildSectionTitle('APARÊNCIA'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.cardBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        secondary: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            ThemeService.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: ThemeService.isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B),
                          ),
                        ),
                        title: Text(
                          'Modo Escuro',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          ThemeService.isDark ? 'Tema escuro ativado' : 'Tema claro ativado',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        value: ThemeService.isDark,
                        activeThumbColor: colors.accent,
                        onChanged: (_) {
                          ThemeService.toggle();
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildSectionTitle('SUPORTE'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.cardBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuTile(
                            icon: Icons.help_outline,
                            iconBg: const Color(0xFF334155),
                            iconColor: const Color(0xFFCBD5E1),
                            title: 'Central de Ajuda',
                            subtitle: 'Dúvidas frequentes, contato',
                            onTap: _showHelpSupportDialog,
                          ),
                          const Divider(height: 1, indent: 12, endIndent: 12),
                          _buildMenuTile(
                            icon: Icons.description_outlined,
                            iconBg: const Color(0xFF334155),
                            iconColor: const Color(0xFF94A3B8),
                            title: 'Termos de Uso',
                            subtitle: 'Regras e diretrizes da plataforma',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TermsOfUsePage(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 12, endIndent: 12),
                          _buildMenuTile(
                            icon: Icons.privacy_tip_outlined,
                            iconBg: const Color(0xFF1E293B),
                            iconColor: const Color(0xFF94A3B8),
                            title: 'Política de Privacidade',
                            subtitle: 'Termos de uso e dados',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 56,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3A1F27),
                          foregroundColor: const Color(0xFFFCA5A5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isSaving ? null : _logout,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded),
                            SizedBox(width: 10),
                            Text(
                              'Sair da Conta',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _isSaving ? null : _deleteAccountTotally,
                      child: Text(
                        'Excluir conta totalmente',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ACERVO 360 - PRE-RELEASE V1.0.3',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textMuted,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }
}

class CrViewerPage extends StatefulWidget {
  const CrViewerPage({
    super.key,
    required this.title,
    required this.url,
    this.bytes,
    this.isImage = false,
  });

  final String title;
  final String url;
  final Uint8List? bytes;
  final bool isImage;

  @override
  State<CrViewerPage> createState() => _CrViewerPageState();
}

class _CrViewerPageState extends State<CrViewerPage> {
  Future<Uint8List> _downloadDocument() async {
    final response = await http.get(Uri.parse(widget.url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      if (!widget.isImage) {
        if (bytes.length < 4 || bytes[0] != 0x25 || bytes[1] != 0x50 || bytes[2] != 0x44 || bytes[3] != 0x46) {
          throw Exception('O arquivo não é um PDF válido.');
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
      appBar: AppBar(title: Text(widget.title)),
      body: widget.bytes != null
          ? (widget.isImage
              ? Center(child: InteractiveViewer(child: Image.memory(widget.bytes!)))
              : SfPdfViewer.memory(widget.bytes!))
          : FutureBuilder<Uint8List>(
              future: _downloadDocument(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Erro: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }
                if (snapshot.hasData) {
                  return widget.isImage
                      ? Center(child: InteractiveViewer(child: Image.memory(snapshot.data!)))
                      : SfPdfViewer.memory(snapshot.data!);
                }
                return const Center(child: Text('Nenhum dado encontrado.'));
              },
            ),
    );
  }
}
