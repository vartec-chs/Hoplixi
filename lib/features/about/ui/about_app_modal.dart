import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> showAppAboutModal(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final info = snapshot.data;
                final appName = (info?.appName.isNotEmpty ?? false)
                    ? info!.appName
                    : 'Hoplixi';
                final version = info?.version ?? '-';
                final buildNumber = info?.buildNumber ?? '-';
                final packageName = info?.packageName ?? '-';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'О приложении',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AboutInfoRow(label: 'Название', value: appName),
                    _AboutInfoRow(
                      label: 'Версия',
                      value:
                          '$version ${buildNumber.isNotEmpty ? '($buildNumber)' : ''}',
                    ),
                    _AboutInfoRow(label: 'Пакет', value: packageName),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SmoothButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            context.push(AppRoutesPaths.aboutLicenses);
                          },
                          label: 'Лицензии',
                          type: SmoothButtonType.outlined,
                        ),
                        const SizedBox(width: 8),
                        SmoothButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          label: 'Закрыть',
                          type: SmoothButtonType.filled,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

class _AboutInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
