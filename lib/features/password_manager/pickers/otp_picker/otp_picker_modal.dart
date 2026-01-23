import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/otp_picker/models/otp_picker_models.dart';
import 'package:hoplixi/features/password_manager/pickers/otp_picker/providers/otp_picker_providers.dart';
import 'package:hoplixi/features/password_manager/pickers/otp_picker/widgets/otp_list_tile.dart';
import 'package:hoplixi/main_store/models/dto/otp_dto.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно выбора OTP
Future<OtpPickerResult?> showOtpPickerModal(
  BuildContext context,
  WidgetRef ref, {
  String? excludeOtpId,
}) async {
  // Сбрасываем состояние перед показом
  ref.read(otpPickerFilterProvider.notifier).reset();
  ref.invalidate(otpPickerDataProvider);

  // Загружаем начальные данные с исключением OTP
  await ref.read(otpPickerDataProvider.notifier).loadInitial(excludeOtpId);

  if (!context.mounted) return null;

  return await WoltModalSheet.show<OtpPickerResult>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (context) => [_buildOtpPickerPage(context, ref)],
  );
}

/// Построить страницу модального окна
WoltModalSheetPage _buildOtpPickerPage(BuildContext context, WidgetRef ref) {
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
    child: const _OtpPickerContent(),
  );
}

/// Контент модального окна
class _OtpPickerContent extends ConsumerStatefulWidget {
  const _OtpPickerContent();

  @override
  ConsumerState<_OtpPickerContent> createState() => _OtpPickerContentState();
}

class _OtpPickerContentState extends ConsumerState<_OtpPickerContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  void _onOtpSelected(OtpCardDto otp) {
    final name = otp.issuer ?? otp.accountName ?? 'Без названия';
    Navigator.of(context).pop(OtpPickerResult(id: otp.id, name: name));
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
                      return OtpListTile(
                        otp: otp,
                        onTap: () => _onOtpSelected(otp),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
