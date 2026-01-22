import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/otp_picker/models/otp_picker_models.dart';
import 'package:hoplixi/features/password_manager/otp_picker/providers/otp_picker_providers.dart';
import 'package:hoplixi/features/password_manager/otp_picker/widgets/otp_list_tile.dart';
import 'package:hoplixi/main_store/models/dto/otp_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно выбора нескольких OTP
Future<OtpPickerMultiResult?> showOtpPickerMultiModal(
  BuildContext context,
  WidgetRef ref, {
  String? excludeOtpId,
  List<String>? initialSelectedIds,
}) async {
  // Сбрасываем состояние перед показом
  ref.read(otpPickerFilterProvider.notifier).reset();
  ref.invalidate(otpPickerDataProvider);

  // Загружаем начальные данные с исключением OTP
  await ref.read(otpPickerDataProvider.notifier).loadInitial(excludeOtpId);

  if (!context.mounted) return null;

  return await WoltModalSheet.show<OtpPickerMultiResult>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (context) => [
      _buildOtpPickerMultiPage(
        context,
        ref,
        initialSelectedIds: initialSelectedIds,
      ),
    ],
  );
}

/// Построить страницу модального окна
WoltModalSheetPage _buildOtpPickerMultiPage(
  BuildContext context,
  WidgetRef ref, {
  List<String>? initialSelectedIds,
}) {
  return WoltModalSheetPage(
    hasSabGradient: false,
    topBarTitle: Text(
      'Выбрать OTP',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    isTopBarLayerAlwaysVisible: true,
    trailingNavBarWidget: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    ),
    child: _OtpPickerMultiContent(initialSelectedIds: initialSelectedIds),
  );
}

/// Контент модального окна для множественного выбора
class _OtpPickerMultiContent extends ConsumerStatefulWidget {
  final List<String>? initialSelectedIds;

  const _OtpPickerMultiContent({this.initialSelectedIds});

  @override
  ConsumerState<_OtpPickerMultiContent> createState() =>
      _OtpPickerMultiContentState();
}

class _OtpPickerMultiContentState
    extends ConsumerState<_OtpPickerMultiContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedOtpIds = {};
  final Map<String, String> _selectedOtpTitles = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialSelectedIds != null) {
      _selectedOtpIds.addAll(widget.initialSelectedIds!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(otpPickerDataProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    ref.read(otpPickerFilterProvider.notifier).updateQuery(value);
    final currentData = ref.read(otpPickerDataProvider);
    ref
        .read(otpPickerDataProvider.notifier)
        .loadInitial(currentData.excludeOtpId);
  }

  void _toggleOtpSelection(OtpCardDto otp) {
    setState(() {
      if (_selectedOtpIds.contains(otp.id)) {
        _selectedOtpIds.remove(otp.id);
        _selectedOtpTitles.remove(otp.id);
      } else {
        _selectedOtpIds.add(otp.id);
        _selectedOtpTitles[otp.id] =
            otp.issuer ?? otp.accountName ?? 'Без названия';
      }
    });
  }

  void _onConfirm() {
    final results = _selectedOtpIds
        .map(
          (id) => OtpPickerResult(id: id, name: _selectedOtpTitles[id] ?? ''),
        )
        .toList();

    Navigator.of(context).pop(OtpPickerMultiResult(otps: results));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(otpPickerDataProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Поле поиска
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Поиск',
              hintText: 'Введите название сервиса или аккаунта',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Индикатор выбранных OTP
        if (_selectedOtpIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Выбрано: ${_selectedOtpIds.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 1),

        // Список OTP
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: data.otps.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('OTP не найдены'),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: data.otps.length + (data.isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == data.otps.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final otp = data.otps[index] as OtpCardDto;
                      final isSelected = _selectedOtpIds.contains(otp.id);

                      return OtpListTile(
                        otp: otp,
                        onTap: () => _toggleOtpSelection(otp),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleOtpSelection(otp),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Кнопки действий
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: SmoothButton(
                  label: 'Отмена',
                  onPressed: () => Navigator.of(context).pop(),
                  type: SmoothButtonType.outlined,
                  variant: SmoothButtonVariant.normal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SmoothButton(
                  label: 'Выбрать (${_selectedOtpIds.length})',
                  onPressed: _selectedOtpIds.isEmpty ? null : _onConfirm,
                  type: SmoothButtonType.filled,
                  variant: SmoothButtonVariant.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
