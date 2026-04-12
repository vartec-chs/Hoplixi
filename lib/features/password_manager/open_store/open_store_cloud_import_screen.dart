import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_cloud_import_state.dart';
import 'package:hoplixi/features/password_manager/open_store/providers/open_store_cloud_import_provider.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

part 'widgets/_cloud_import_body.dart';
part 'widgets/_error_banner.dart';
part 'widgets/_placeholder.dart';
part 'widgets/_remote_snapshot_card.dart';

class OpenStoreCloudImportScreen extends ConsumerStatefulWidget {
  const OpenStoreCloudImportScreen({super.key});

  @override
  ConsumerState<OpenStoreCloudImportScreen> createState() =>
      _OpenStoreCloudImportScreenState();
}

class _OpenStoreCloudImportScreenState
    extends ConsumerState<OpenStoreCloudImportScreen> {
  late final ProviderSubscription<AsyncValue<OpenStoreCloudImportState>>
  _bindingSubscription;
  bool _isBindingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _bindingSubscription = ref
        .listenManual<AsyncValue<OpenStoreCloudImportState>>(
          openStoreCloudImportProvider,
          (previous, next) {
            next.whenData((state) async {
              final pendingBinding = state.pendingImportedStoreBinding;
              final previousBinding =
                  previous?.value?.pendingImportedStoreBinding;
              if (_isBindingDialogOpen ||
                  pendingBinding == null ||
                  identical(pendingBinding, previousBinding)) {
                return;
              }

              _isBindingDialogOpen = true;
              try {
                final shouldBind = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Привязать к cloud sync'),
                    content: Text(pendingBinding.promptDescription),
                    actions: [
                      SmoothButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        label: 'Нет',
                        type: SmoothButtonType.text,
                      ),
                      SmoothButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        label: 'Привязать',
                      ),
                    ],
                  ),
                );

                final didBind = await ref
                    .read(openStoreCloudImportProvider.notifier)
                    .resolvePendingImportedStoreBinding(
                      bind: shouldBind == true,
                    );
                if (!mounted) {
                  return;
                }

                if (didBind) {
                  Toaster.success(
                    context: context,
                    title: 'Cloud Sync',
                    description: 'Локальная копия привязана к облачному store.',
                  );
                }
              } finally {
                _isBindingDialogOpen = false;
              }
            });
          },
        );
  }

  @override
  void dispose() {
    _bindingSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(openStoreCloudImportProvider);
    final notifier = ref.read(openStoreCloudImportProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Импорт из Cloud Sync'),
        leading: BackButton(
          onPressed: () => {
            if (context.canPop())
              {context.pop()}
            else
              {context.go(AppRoutesPaths.openStore)},
          },
        ),
        actions: [
          IconButton(
            onPressed: asyncState.isLoading
                ? null
                : () async => notifier.reloadCloudOptions(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: asyncState.when(
        data: (state) => _CloudImportBody(state: state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Не удалось открыть экран импорта',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
