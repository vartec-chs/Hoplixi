import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/provider/archive_provider.dart';
import 'package:hoplixi/main_store/services/archive_service.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

Future<void> showStoreArchiveImportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String archivePath,
}) async {
  final password = await showDialog<String?>(
    context: context,
    builder: (context) => ImportStoreArchiveDialog(archivePath: archivePath),
  );

  if (password == null) {
    return;
  }

  final archiveService = ref.read(archiveServiceProvider);
  final storagesPath = await AppPaths.appStoragesPath;
  final result = await archiveService.unarchiveStore(
    archivePath,
    password: password.isEmpty ? null : password,
    basePath: storagesPath,
  );

  result.fold(
    (extractedPath) {
      Toaster.success(
        title: 'Хранилище импортировано',
        description: 'Распаковано в $extractedPath',
      );
    },
    (error) {
      Toaster.error(
        title: 'Ошибка импорта',
        description: error.message,
      );
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
        ],
      ),
      actions: [
        SmoothButton(
          onPressed: () => Navigator.pop(context, null),
          label: 'Нет',
          type: .text,
        ),
        SmoothButton(
          onPressed: () => Navigator.pop(context, _passwordController.text.trim()),
          label: 'Импортировать',
          type: .filled,
        ),
      ],
    );
  }
}
