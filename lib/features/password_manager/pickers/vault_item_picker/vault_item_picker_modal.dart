import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/models/dto/linked_vault_item_card_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

Future<LinkedVaultItemCardDto?> showVaultItemPickerModal(
  BuildContext context,
  WidgetRef ref, {
  String? excludeItemId,
}) async {
  if (!context.mounted) return null;

  return WoltModalSheet.show<LinkedVaultItemCardDto>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (context) => [
      WoltModalSheetPage(
        hasSabGradient: false,
        isTopBarLayerAlwaysVisible: true,
        topBarTitle: Text(
          'Выбрать объект',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        trailingNavBarWidget: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        child: _VaultItemPickerContent(excludeItemId: excludeItemId),
      ),
    ],
  );
}

class _VaultItemPickerContent extends ConsumerStatefulWidget {
  const _VaultItemPickerContent({this.excludeItemId});

  final String? excludeItemId;

  @override
  ConsumerState<_VaultItemPickerContent> createState() =>
      _VaultItemPickerContentState();
}

class _VaultItemPickerContentState
    extends ConsumerState<_VaultItemPickerContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Поиск',
              hintText: 'Введите название объекта',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: FutureBuilder<List<LinkedVaultItemCardDto>>(
              future: _loadItems(query),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Объекты не найдены'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final entityType = item.vaultItemType.toEntityType();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Icon(
                          entityType.icon,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.description?.isNotEmpty == true
                            ? '${entityType.label} · ${item.description}'
                            : entityType.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<List<LinkedVaultItemCardDto>> _loadItems(String query) async {
    final dao = await ref.read(vaultItemDaoProvider.future);
    return dao.searchLinkableItems(
      query: query,
      excludeItemId: widget.excludeItemId,
    );
  }
}
