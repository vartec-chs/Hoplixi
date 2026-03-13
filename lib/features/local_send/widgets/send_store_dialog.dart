import 'package:flutter/material.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/main_store/models/store_folder_info.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class SendStoreDialogResult {
  final StoreFolderInfo store;
  final String? archivePassword;

  const SendStoreDialogResult({
    required this.store,
    required this.archivePassword,
  });
}

class SendStoreDialog extends StatefulWidget {
  const SendStoreDialog({super.key});

  @override
  State<SendStoreDialog> createState() => _SendStoreDialogState();
}

class _SendStoreDialogState extends State<SendStoreDialog> {
  late final TextEditingController _passwordController;
  List<StoreFolderInfo> _stores = const <StoreFolderInfo>[];
  bool _isLoading = true;
  String? _loadError;
  StoreFolderInfo? _selectedStore;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _loadStores();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    try {
      final stores = await AppPaths.getAllStorageFolders();
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _selectedStore = stores.isNotEmpty ? stores.first : null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedStore = _selectedStore;

    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      title: const Text('Отправить хранилище'),
      content: SizedBox(
        width: 440,
        child: _buildContent(context, textTheme, selectedStore),
      ),
      actions: [
        SmoothButton(
          onPressed: () => Navigator.pop(context),
          label: 'Отмена',
          type: .text,
        ),
        SmoothButton(
          onPressed: selectedStore == null
              ? null
              : () {
                  Navigator.pop(
                    context,
                    SendStoreDialogResult(
                      store: selectedStore,
                      archivePassword: _passwordController.text.trim().isEmpty
                          ? null
                          : _passwordController.text.trim(),
                    ),
                  );
                },
          label: 'Отправить ZIP',
          type: .filled,
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    TextTheme textTheme,
    StoreFolderInfo? selectedStore,
  ) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Text('Не удалось загрузить список хранилищ: $_loadError');
    }

    if (_stores.isEmpty || selectedStore == null) {
      return const Text(
        'Нет доступных хранилищ для отправки. Сначала создайте или импортируйте хранилище.',
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Хранилище будет заархивировано и отправлено как ZIP-файл.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<StoreFolderInfo>(
          value: selectedStore,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Хранилище',
            hintText: 'Выберите хранилище',
          ),
          items: _stores.map((store) {
            return DropdownMenuItem<StoreFolderInfo>(
              value: store,
              child: Text(store.storeName),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedStore = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _StorePreviewCard(store: selectedStore),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Пароль ZIP (опционально)',
            hintText: 'Оставьте пустым для отправки без пароля',
          ),
        ),
      ],
    );
  }
}

class _StorePreviewCard extends StatelessWidget {
  final StoreFolderInfo store;

  const _StorePreviewCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lastModified = store.lastModified.toLocal();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.storeName,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Размер: ${store.sizeFormatted}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Изменено: ${lastModified.day.toString().padLeft(2, '0')}.'
            '${lastModified.month.toString().padLeft(2, '0')}.'
            '${lastModified.year} '
            '${lastModified.hour.toString().padLeft(2, '0')}:'
            '${lastModified.minute.toString().padLeft(2, '0')}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            store.folderPath,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
