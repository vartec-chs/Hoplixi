import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/icon_packs/models/icon_pack_summary.dart';
import 'package:hoplixi/features/icon_packs/picker/widgets/icon_pack_picker_empty_states.dart';
import 'package:hoplixi/features/icon_packs/picker/widgets/icon_pack_picker_icon_page.dart';
import 'package:hoplixi/features/icon_packs/picker/widgets/icon_pack_picker_pack_page.dart';
import 'package:hoplixi/features/icon_packs/providers/icon_packs_provider.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

Future<String?> showIconPackPickerModal(
  BuildContext context,
  WidgetRef ref, {
  String? initialIconKey,
}) async {
  final service = ref.read(iconPackCatalogServiceProvider);
  final packs = await service.listPacks();
  final selectedPack = ValueNotifier<IconPackSummary?>(null);
  final previewColor = ValueNotifier<Color?>(null);
  final sanitizedInitialKey = initialIconKey?.trim().isEmpty == true
      ? null
      : initialIconKey?.trim();

  try {
    return await WoltModalSheet.show<String>(
      context: context,
      barrierDismissible: true,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (modalContext) {
        final modalHeight = MediaQuery.of(modalContext).size.height * 0.74;

        return [
          WoltModalSheetPage(
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            isTopBarLayerAlwaysVisible: true,
            topBarTitle: Text(
              'Выберите пак',
              style: Theme.of(modalContext).textTheme.titleMedium,
            ),
            leadingNavBarWidget: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                tooltip: 'Закрыть',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(modalContext).pop(),
              ),
            ),
            child: SizedBox(
              height: modalHeight,
              child: IconPackPickerPackPage(
                packs: packs,
                initialIconKey: sanitizedInitialKey,
                selectedPack: selectedPack,
                onPackSelected: (pack) {
                  selectedPack.value = pack;
                },
              ),
            ),
          ),
          WoltModalSheetPage(
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            isTopBarLayerAlwaysVisible: true,
            topBarTitle: ValueListenableBuilder<IconPackSummary?>(
              valueListenable: selectedPack,
              builder: (context, pack, _) {
                final title = pack?.displayName ?? 'Иконки пака';
                return Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            leadingNavBarWidget: Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  tooltip: 'Назад',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => WoltModalSheet.of(context).showPrevious(),
                ),
              ),
            ),
            trailingNavBarWidget: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Закрыть',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(modalContext).pop(),
              ),
            ),
            child: SizedBox(
              height: modalHeight,
              child: ValueListenableBuilder<IconPackSummary?>(
                valueListenable: selectedPack,
                builder: (context, pack, _) {
                  if (pack == null) {
                    return const IconPackPickerEmptySelection();
                  }

                  return IconPackPickerIconPage(
                    key: ValueKey(pack.packKey),
                    pack: pack,
                    previewColor: previewColor,
                    initialIconKey: sanitizedInitialKey,
                    onIconSelected: (iconKey) {
                      Navigator.of(modalContext).pop(iconKey);
                    },
                  );
                },
              ),
            ),
          ),
        ];
      },
    );
  } finally {
    selectedPack.dispose();
    previewColor.dispose();
  }
}
