import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class ContactViewScreen extends ConsumerStatefulWidget {
  const ContactViewScreen({super.key, required this.contactId});

  final String contactId;

  @override
  ConsumerState<ContactViewScreen> createState() => _ContactViewScreenState();
}

class _ContactViewScreenState extends ConsumerState<ContactViewScreen> {
  bool _loading = true;

  String _name = '';
  String? _phone;
  String? _email;
  String? _company;
  String? _jobTitle;
  String? _address;
  String? _website;
  DateTime? _birthday;
  String? _notes;
  String? _description;
  bool _isEmergencyContact = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(contactDaoProvider.future);
      final row = await dao.getById(widget.contactId);
      if (row == null) {
        Toaster.error(title: 'Контакт не найден');
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final details = row.$2;
      setState(() {
        _name = item.name;
        _phone = details.phone;
        _email = details.email;
        _company = details.company;
        _jobTitle = details.jobTitle;
        _address = details.address;
        _website = details.website;
        _birthday = details.birthday;
        _notes = details.notes;
        _description = item.description;
        _isEmergencyContact = details.isEmergencyContact;
      });
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyValue(String? value, String label) async {
    if (value == null || value.isEmpty) {
      Toaster.warning(title: '$label не указан');
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    Toaster.success(title: '$label скопирован');
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр контакта'),
        actions: [
          IconButton(
            tooltip: 'Редактировать',
            onPressed: () => context.push(
              AppRoutesPaths.dashboardEntityEdit(
                EntityType.contact,
                widget.contactId,
              ),
            ),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(_name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                if (_company?.isNotEmpty == true)
                  Text(
                    _company!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 8),
                if (_isEmergencyContact)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.warning_amber_rounded),
                    title: Text('Экстренный контакт'),
                  ),
                if (_phone?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Телефон'),
                    subtitle: Text(_phone!),
                    trailing: IconButton(
                      onPressed: () => _copyValue(_phone, 'Телефон'),
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                if (_email?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Email'),
                    subtitle: Text(_email!),
                    trailing: IconButton(
                      onPressed: () => _copyValue(_email, 'Email'),
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                if (_jobTitle?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Должность'),
                    subtitle: Text(_jobTitle!),
                  ),
                if (_address?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Адрес'),
                    subtitle: Text(_address!),
                  ),
                if (_website?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Сайт'),
                    subtitle: Text(_website!),
                  ),
                if (_birthday != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Дата рождения'),
                    subtitle: Text(_formatDate(_birthday!)),
                  ),
                if (_notes?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Заметки'),
                    subtitle: Text(_notes!),
                  ),
                if (_description?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Описание'),
                    subtitle: Text(_description!),
                  ),
              ],
            ),
    );
  }
}
