import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_db/old/provider/archive_provider.dart';
import 'package:hoplixi/main_db/old/services/other/archive_service.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class _ImportStoreArchiveDialogResult {
  final String? password;
  final bool replaceExistingIfNewer;

  const _ImportStoreArchiveDialogResult({
    required this.password,
    required this.replaceExistingIfNewer,
  });
}

Future<void> showStoreArchiveImportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String archivePath,
}) async {
  final importOptions = await showDialog<_ImportStoreArchiveDialogResult?>(
    context: context,
    builder: (context) => ImportStoreArchiveDialog(archivePath: archivePath),
  );

  if (importOptions == null) {
    return;
  }

  final archiveService = ref.read(archiveServiceProvider);
  final storagesPath = await AppPaths.appStoragesPath;
  final result = await archiveService.unarchiveStore(
    archivePath,
    password: importOptions.password?.isEmpty ?? true
        ? null
        : importOptions.password,
    basePath: storagesPath,
    replaceExistingIfNewer: importOptions.replaceExistingIfNewer,
  );

  result.fold(
    (extractedPath) {
      Toaster.success(
        title: 'Хранилище импортировано',
        description: 'Распаковано в $extractedPath',
      );
    },
    (error) {
      Toaster.error(title: 'Ошибка импорта', description: error.message);
    },
  );
}

class ImportStoreArchiveDialog extends StatefulWidget {
  final String archivePath;

  const ImportStoreArchiveDialog({super.key, required this.archivePath});

  @override
  State<ImportStoreArchiveDialog> createState() =>
      _ImportStoreArchiveDialogState();
}

class _ImportStoreArchiveDialogState extends State<ImportStoreArchiveDialog> {
  late final TextEditingController _passwordController;
  var _replaceExistingIfNewer = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archiveName = ArchiveService.suggestedStoreFolderName(
      widget.archivePath,
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      title: const Text('Импортировать хранилище'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Получен архив хранилища "$archiveName". Импортировать его в локальную папку хранилищ?',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Пароль ZIP (если есть)',
              hintText: 'Оставьте пустым для архива без пароля',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _replaceExistingIfNewer,
            onChanged: (value) {
              setState(() {
                _replaceExistingIfNewer = value;
              });
            },
            title: const Text('Заменять существующее хранилище'),
            subtitle: const Text(
              'Если архив новее локального хранилища с тем же store ID, старая версия будет перенесена в backups.',
            ),
          ),
        ],
      ),
      actions: [
        SmoothButton(
          onPressed: () => Navigator.pop(context, null),
          label: 'Нет',
          type: .text,
        ),
        SmoothButton(
          onPressed: () {
            Navigator.pop(
              context,
              _ImportStoreArchiveDialogResult(
                password: _passwordController.text.trim(),
                replaceExistingIfNewer: _replaceExistingIfNewer,
              ),
            );
          },
          label: 'Импортировать',
          type: .filled,
        ),
      ],
    );
  }
}
