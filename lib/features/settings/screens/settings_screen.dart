import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/settings/ui/settings_sections.dart';

/// Экран настроек приложения
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            // Секция внешнего вида
            AppearanceSettingsSection(),

            SizedBox(height: 8),

            // Секция общих настроек
            GeneralSettingsSection(),

            SizedBox(height: 8),

            // Секция безопасности
            SecuritySettingsSection(),

            SizedBox(height: 8),

            // Секция синхронизации
            SyncSettingsSection(),

            SizedBox(height: 8),

            // Секция резервного копирования
            BackupSettingsSection(),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
