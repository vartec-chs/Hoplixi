import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/icon_packs/picker/icon_pack_picker_button.dart';
import 'package:hoplixi/features/icon_packs/picker/icon_pack_picker_modal.dart';
import 'package:hoplixi/shared/ui/button.dart';

class IconPackPickerShowcaseScreen extends ConsumerStatefulWidget {
  const IconPackPickerShowcaseScreen({super.key});

  @override
  ConsumerState<IconPackPickerShowcaseScreen> createState() =>
      _IconPackPickerShowcaseScreenState();
}

class _IconPackPickerShowcaseScreenState
    extends ConsumerState<IconPackPickerShowcaseScreen> {
  String? _selectedIconKey;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSection(
          context,
          title: 'Icon Pack Picker',
          children: [
            Text(
              'Демо для file-backed SVG picker. Сначала импортируйте хотя бы один пак на экране "Паки иконок", затем выберите иконку через Wolt modal sheet.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выбранный ключ',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _selectedIconKey ?? 'Иконка пока не выбрана',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Modal API',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _openModalPicker,
                  icon: const Icon(Icons.layers_outlined),
                  label: const Text('Открыть picker'),
                ),
                OutlinedButton.icon(
                  onPressed: _selectedIconKey == null
                      ? null
                      : () {
                          setState(() {
                            _selectedIconKey = null;
                          });
                        },
                  icon: const Icon(Icons.clear),
                  label: const Text('Очистить'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Picker Button',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconPackPickerButton(
                  selectedIconKey: _selectedIconKey,
                  onIconSelected: (iconKey) {
                    setState(() {
                      _selectedIconKey = iconKey;
                    });
                  },
                  hintText: 'Пак иконок',
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Поведение',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажатие открывает двухшаговый picker: выбор пака, затем выбор SVG-иконки. Если иконка уже выбрана, кнопка показывает её превью и позволяет очистить значение.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Current Value',
          children: [
            SmoothButton(
              label: _selectedIconKey ?? 'Значение пустое',
              type: SmoothButtonType.tonal,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openModalPicker() async {
    final selectedIconKey = await showIconPackPickerModal(
      context,
      ref,
      initialIconKey: _selectedIconKey,
    );

    if (!mounted || selectedIconKey == null) {
      return;
    }

    setState(() {
      _selectedIconKey = selectedIconKey;
    });
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
