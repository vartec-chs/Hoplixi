import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/migration/otp/otp_extractor.dart';
import 'package:hoplixi/features/password_manager/migration/otp/providers/import_otp_notifier.dart';
import 'package:hoplixi/features/password_manager/migration/otp/widgets/otp_import_list_item.dart';
import 'package:hoplixi/features/qr_scanner/widgets/qr_scanner_widget.dart';
import 'package:hoplixi/shared/ui/slider_button.dart';

class ImportOtpScreen extends ConsumerWidget {
  const ImportOtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importOtpProvider);
    final notifier = ref.read(importOtpProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Импорт OTP'),
        actions: [
          if (state.importedOtps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: notifier.selectAll,
              tooltip: 'Выбрать все',
            ),
          if (state.importedOtps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.deselect),
              onPressed: notifier.deselectAll,
              tooltip: 'Снять выделение',
            ),
        ],
        leading: const FormCloseButton(),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (state.importedOtps.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Начать импорт OTP',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Отсканируйте QR-код или выберите изображение, чтобы начать',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        QrScannerWidget(
                          title: 'Импорт OTP',
                          subtitle: 'Выберите способ сканирования QR-кода',
                          onResult: (data) async {
                            await notifier.importOtp(
                              Uint8List.fromList(data.codeUnits),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.importedOtps.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final otp = state.importedOtps[index];
                    final isSelected = state.selectedIndices.contains(index);
                    final isExpanded = state.expandedIndices.contains(index);

                    // Calculate current code for preview
                    String currentCode = '------';
                    try {
                      // We need raw secret for totp generation.
                      // OtpData has secretBase32.
                      // We can decode it.
                      final secret = base32Decode(otp.secretBase32);
                      currentCode = totp(
                        secret,
                        digits: otp.digits,
                        algo: otp.algorithm,
                      );
                    } catch (_) {}

                    return OtpImportListItem(
                      otp: otp,
                      isSelected: isSelected,
                      isExpanded: isExpanded,
                      onToggleSelection: () => notifier.toggleSelection(index),
                      onToggleExpanded: () => notifier.toggleExpanded(index),
                      currentCode: currentCode,
                      remainingSeconds: state.remainingSeconds,
                    );
                  },
                ),
              ),
            if (state.importedOtps.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${state.selectedIndices.length} выбрано',
                          style: theme.textTheme.titleMedium,
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await showQrScannerDialog(
                              context: context,
                              title: 'Сканировать еще один QR',
                            );
                            if (result != null) {
                              await notifier.importOtp(
                                Uint8List.fromList(result.codeUnits),
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить еще'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderButton(
                      text: 'Сохранить выбранные OTP',
                      type: SliderButtonType.confirm,
                      onSlideCompleteAsync: () async {
                        try {
                          await notifier.saveSelectedOtps();
                          if (context.mounted) {
                            Toaster.success(
                              title: 'Успех',
                              description: 'Выбранные OTP успешно сохранены',
                            );
                            if (state.importedOtps.isEmpty) {
                              context.pop();
                            }
                          }
                        } catch (e) {
                          Toaster.error(
                            title: 'Ошибка',
                            description:
                                'Не удалось сохранить выбранные OTP: $e',
                          );
                        }
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
