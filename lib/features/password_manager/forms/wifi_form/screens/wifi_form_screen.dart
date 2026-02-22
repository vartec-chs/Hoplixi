import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class WifiFormScreen extends ConsumerStatefulWidget {
  const WifiFormScreen({super.key, this.wifiId});

  final String? wifiId;

  bool get isEdit => wifiId != null;

  @override
  ConsumerState<WifiFormScreen> createState() => _WifiFormScreenState();
}

class _WifiFormScreenState extends ConsumerState<WifiFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _securityController = TextEditingController();
  final _eapMethodController = TextEditingController();
  final _usernameController = TextEditingController();
  final _identityController = TextEditingController();
  final _domainController = TextEditingController();
  final _bssidController = TextEditingController();
  final _priorityController = TextEditingController();
  final _notesController = TextEditingController();
  final _qrPayloadController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _hidden = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(wifiDaoProvider.future);
      final row = await dao.getById(widget.wifiId!);
      if (row == null) return;
      final item = row.$1;
      final wifi = row.$2;

      _nameController.text = item.name;
      _ssidController.text = wifi.ssid;
      _passwordController.text = wifi.password ?? '';
      _securityController.text = wifi.security ?? '';
      _eapMethodController.text = wifi.eapMethod ?? '';
      _usernameController.text = wifi.username ?? '';
      _identityController.text = wifi.identity ?? '';
      _domainController.text = wifi.domain ?? '';
      _bssidController.text = wifi.lastConnectedBssid ?? '';
      _priorityController.text = wifi.priority?.toString() ?? '';
      _notesController.text = wifi.notes ?? '';
      _qrPayloadController.text = wifi.qrCodePayload ?? '';
      _descriptionController.text = item.description ?? '';
      _hidden = wifi.hidden;
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _securityController.dispose();
    _eapMethodController.dispose();
    _usernameController.dispose();
    _identityController.dispose();
    _domainController.dispose();
    _bssidController.dispose();
    _priorityController.dispose();
    _notesController.dispose();
    _qrPayloadController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      Toaster.error(title: 'Проверьте поля формы');
      return;
    }

    setState(() => _loading = true);
    try {
      final dao = await ref.read(wifiDaoProvider.future);

      String? clean(TextEditingController controller) {
        final value = controller.text.trim();
        return value.isEmpty ? null : value;
      }

      final name = _nameController.text.trim();
      final ssid = _ssidController.text.trim();
      final priority = int.tryParse(_priorityController.text.trim());

      if (widget.isEdit) {
        await dao.updateWifi(
          widget.wifiId!,
          UpdateWifiDto(
            name: name,
            ssid: ssid,
            password: clean(_passwordController),
            security: clean(_securityController),
            hidden: _hidden,
            eapMethod: clean(_eapMethodController),
            username: clean(_usernameController),
            identity: clean(_identityController),
            domain: clean(_domainController),
            lastConnectedBssid: clean(_bssidController),
            priority: priority,
            notes: clean(_notesController),
            qrCodePayload: clean(_qrPayloadController),
            description: clean(_descriptionController),
          ),
        );
      } else {
        await dao.createWifi(
          CreateWifiDto(
            name: name,
            ssid: ssid,
            password: clean(_passwordController),
            security: clean(_securityController),
            hidden: _hidden,
            eapMethod: clean(_eapMethodController),
            username: clean(_usernameController),
            identity: clean(_identityController),
            domain: clean(_domainController),
            lastConnectedBssid: clean(_bssidController),
            priority: priority,
            notes: clean(_notesController),
            qrCodePayload: clean(_qrPayloadController),
            description: clean(_descriptionController),
          ),
        );
      }

      Toaster.success(title: widget.isEdit ? 'Wi-Fi обновлен' : 'Wi-Fi создан');
      if (mounted) context.pop();
    } catch (e) {
      Toaster.error(title: 'Ошибка сохранения', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Редактировать Wi-Fi' : 'Новая Wi-Fi сеть'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Название'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Название обязательно'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ssidController,
                    decoration: const InputDecoration(labelText: 'SSID'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'SSID обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _securityController,
                    decoration: const InputDecoration(labelText: 'Security'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _eapMethodController,
                    decoration: const InputDecoration(labelText: 'EAP method'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _identityController,
                    decoration: const InputDecoration(labelText: 'Identity'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _domainController,
                    decoration: const InputDecoration(labelText: 'Domain'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bssidController,
                    decoration: const InputDecoration(
                      labelText: 'Last connected BSSID',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priorityController,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _qrPayloadController,
                    decoration: const InputDecoration(labelText: 'QR payload'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Описание'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  SwitchListTile(
                    value: _hidden,
                    onChanged: (v) => setState(() => _hidden = v),
                    title: const Text('Скрытая сеть'),
                  ),
                ],
              ),
            ),
    );
  }
}
