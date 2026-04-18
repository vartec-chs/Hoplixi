import 'package:flutter/material.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_pack_summary.dart';
import 'package:hoplixi/features/custom_icon_packs/picker/widgets/icon_pack_picker_empty_states.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class IconPackPickerPackPage extends StatefulWidget {
  const IconPackPickerPackPage({
    super.key,
    required this.packs,
    required this.selectedPack,
    required this.onPackSelected,
    this.initialIconKey,
  });

  final List<IconPackSummary> packs;
  final ValueNotifier<IconPackSummary?> selectedPack;
  final ValueChanged<IconPackSummary> onPackSelected;
  final String? initialIconKey;

  @override
  State<IconPackPickerPackPage> createState() => _IconPackPickerPackPageState();
}

class _IconPackPickerPackPageState extends State<IconPackPickerPackPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Поиск пака',
              hintText: 'Введите название или ключ пака',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Очистить поиск',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (value) {
              setState(() {
                _query = value.trim().toLowerCase();
              });
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildPacksBody(context)),
      ],
    );
  }

  Widget _buildPacksBody(BuildContext context) {
    final filteredPacks = widget.packs.where(_matchesPackQuery).toList();
    _syncInitialPackSelection(widget.packs);

    if (widget.packs.isEmpty) {
      return const IconPackPickerEmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Паки иконок не найдены',
        description:
            'Сначала импортируйте хотя бы один SVG-пак на экране управления паками.',
      );
    }

    if (filteredPacks.isEmpty) {
      return const IconPackPickerEmptyState(
        icon: Icons.search_off_outlined,
        title: 'Ничего не найдено',
        description: 'Попробуйте изменить поисковый запрос.',
      );
    }

    return ValueListenableBuilder<IconPackSummary?>(
      valueListenable: widget.selectedPack,
      builder: (context, selected, _) {
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filteredPacks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final pack = filteredPacks[index];
            final isSelected = selected?.packKey == pack.packKey;

            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: isSelected ? 0 : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  widget.onPackSelected(pack);
                  WoltModalSheet.of(context).showNext();
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.folder_copy_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pack.displayName,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pack.iconCount} SVG · ${pack.packKey}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Источник: ${pack.sourceArchiveName}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _matchesPackQuery(IconPackSummary pack) {
    if (_query.isEmpty) {
      return true;
    }

    return pack.displayName.toLowerCase().contains(_query) ||
        pack.packKey.toLowerCase().contains(_query) ||
        pack.sourceArchiveName.toLowerCase().contains(_query);
  }

  void _syncInitialPackSelection(List<IconPackSummary> packs) {
    final initialPackKey = _extractPackKey(widget.initialIconKey);
    if (initialPackKey == null || widget.selectedPack.value != null) {
      return;
    }

    for (final pack in packs) {
      if (pack.packKey == initialPackKey) {
        widget.selectedPack.value = pack;
        break;
      }
    }
  }

  static String? _extractPackKey(String? iconKey) {
    if (iconKey == null || !iconKey.contains('/')) {
      return null;
    }
    return iconKey.split('/').first;
  }
}
