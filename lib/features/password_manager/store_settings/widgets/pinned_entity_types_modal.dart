import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/pinned_entity_types_provider.dart';
import 'package:hoplixi/features/password_manager/store_settings/widgets/pinned_entity_types_selector.dart';
import 'package:hoplixi/main_db/config/store_settings_keys.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать отдельную модалку для настройки закреплённых типов сущностей.
Future<bool?> showPinnedEntityTypesModal(BuildContext context) {
  return WoltModalSheet.show<bool>(
    context: context,
    barrierDismissible: true,
    useSafeArea: true,
    useRootNavigator: true,
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Builder(
            builder: (context) {
              return Text(
                'Типы записей в навигации',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              );
            },
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ModalSheetCloseButton(
              onPressed: () => Navigator.of(modalContext).pop(false),
            ),
          ),
          child: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.all(12.0),
              child: _PinnedEntityTypesModalContent(
                onSaved: () => Navigator.of(modalContext).pop(true),
              ),
            ),
          ),
        ),
      ];
    },
  );
}

class _PinnedEntityTypesModalContent extends ConsumerStatefulWidget {
  final VoidCallback onSaved;

  const _PinnedEntityTypesModalContent({required this.onSaved});

  @override
  ConsumerState<_PinnedEntityTypesModalContent> createState() =>
      _PinnedEntityTypesModalContentState();
}

class _PinnedEntityTypesModalContentState
    extends ConsumerState<_PinnedEntityTypesModalContent> {
  static const String _logTag = 'PinnedEntityTypesModal';

  List<String> _selectedEntityTypeIds = const [];
  List<String> _initialEntityTypeIds = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPinnedEntityTypes();
  }

  Future<void> _loadPinnedEntityTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dao = await ref.read(storeSettingsDaoProvider.future);
      final raw = await dao.getSetting(StoreSettingsKeys.pinnedEntityTypes);
      final ids = _parsePinnedEntityTypes(raw);

      if (!mounted) return;
      setState(() {
        _selectedEntityTypeIds = ids;
        _initialEntityTypeIds = ids;
        _isLoading = false;
      });
    } catch (e, s) {
      logError(
        'Failed to load pinned entity types: $e',
        stackTrace: s,
        tag: _logTag,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось загрузить типы записей';
      });
    }
  }

  Future<void> _savePinnedEntityTypes() async {
    if (_isLoading || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final dao = await ref.read(storeSettingsDaoProvider.future);
      final normalizedIds = _normalizePinnedEntityTypes(
        _selectedEntityTypeIds,
      );

      if (!_listEquals(normalizedIds, _initialEntityTypeIds)) {
        await dao.setSetting(
          StoreSettingsKeys.pinnedEntityTypes,
          jsonEncode(normalizedIds),
        );
        ref.invalidate(pinnedEntityTypesProvider);
      }

      if (!mounted) return;

      Toaster.success(
        title: 'Успешно',
        description: 'Типы записей в навигации сохранены',
      );
      widget.onSaved();
    } catch (e, s) {
      logError(
        'Failed to save pinned entity types: $e',
        stackTrace: s,
        tag: _logTag,
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Не удалось сохранить типы записей';
      });
    }
  }

  void _updatePinnedEntityTypes(List<String> ids) {
    setState(() {
      _selectedEntityTypeIds = ids;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            NotificationCard(
              type: NotificationType.error,
              text: _errorMessage!,
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Повторить',
              type: SmoothButtonType.outlined,
              onPressed: _isSaving ? null : _loadPinnedEntityTypes,
              isFullWidth: true,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Закрыть',
              type: SmoothButtonType.text,
              onPressed: () => Navigator.of(context).pop(false),
              isFullWidth: true,
            ),
          ] else ...[
            Text(
              'Выберите типы, которые будут отображаться в выпадающем списке. '
              'Если ничего не отмечено, в навигации доступны все типы.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            PinnedEntityTypesSelector(
              selectedEntityTypeIds: _selectedEntityTypeIds,
              enabled: !_isSaving,
              onChanged: _updatePinnedEntityTypes,
            ),
            const SizedBox(height: 20),
            SmoothButton(
              label: 'Сохранить',
              loading: _isSaving,
              onPressed: _savePinnedEntityTypes,
              isFullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  static List<String> _parsePinnedEntityTypes(String? raw) {
    if (raw == null || raw.isEmpty) return const [];

    try {
      final ids = (jsonDecode(raw) as List).cast<String>();
      return _normalizePinnedEntityTypes(ids);
    } catch (_) {
      return const [];
    }
  }

  static List<String> _normalizePinnedEntityTypes(List<String> ids) {
    final selected = ids.toSet();
    final allIds = EntityType.allTypes.map((type) => type.id).toSet();

    if (selected.isEmpty || selected.containsAll(allIds)) {
      return const [];
    }

    return EntityType.allTypes
        .map((type) => type.id)
        .where(selected.contains)
        .toList();
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}