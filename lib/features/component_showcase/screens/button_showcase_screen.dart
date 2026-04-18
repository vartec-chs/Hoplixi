import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/copy_to_clipboard_button.dart';

/// Экран для демонстрации кнопок
class ButtonShowcaseScreen extends StatelessWidget {
  const ButtonShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSection(
          context,
          title: 'Button Types',
          children: [
            SmoothButton(
              label: 'Filled Button',
              type: SmoothButtonType.filled,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Tonal Button',
              type: SmoothButtonType.tonal,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Outlined Button',
              type: SmoothButtonType.outlined,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Dashed Button',
              type: SmoothButtonType.dashed,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Text Button',
              type: SmoothButtonType.text,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Button Sizes',
          children: [
            SmoothButton(
              label: 'Small',
              size: SmoothButtonSize.small,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Medium',
              size: SmoothButtonSize.medium,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Large',
              size: SmoothButtonSize.large,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'With Icons',
          children: [
            SmoothButton(
              label: 'Icon Start',
              icon: const Icon(Icons.add),
              iconPosition: SmoothButtonIconPosition.start,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Icon End',
              icon: const Icon(Icons.arrow_forward),
              iconPosition: SmoothButtonIconPosition.end,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'States',
          children: [
            SmoothButton(label: 'Loading', loading: true, onPressed: () {}),
            const SizedBox(height: 12),
            const SmoothButton(label: 'Disabled', onPressed: null),
            const SizedBox(height: 12),
            SmoothButton(label: 'Bold Text', bold: true, onPressed: () {}),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Copy To Clipboard',
          children: [
            const Row(
              children: [
                Text('Icon copy button'),
                SizedBox(width: 8),
                CopyToClipboardIconButton(
                  text: 'Hoplixi clipboard demo text',
                  tooltip: 'Копировать демо-текст',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const CopySmoothButton(
              text: 'Hoplixi clipboard demo text',
              label: 'Копировать через SmoothButton',
              copiedLabel: 'Скопировано',
              type: SmoothButtonType.tonal,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Button Variants',
          children: [
            Text(
              'Filled Variants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Normal Filled',
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.normal,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Error Filled',
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.error,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Warning Filled',
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.warning,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Info Filled',
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.info,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Success Filled',
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.success,
            ),
            const SizedBox(height: 24),
            Text(
              'Tonal Variants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Error Tonal',
              type: SmoothButtonType.tonal,
              variant: SmoothButtonVariant.error,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Warning Tonal',
              type: SmoothButtonType.tonal,
              variant: SmoothButtonVariant.warning,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Success Tonal',
              type: SmoothButtonType.tonal,
              variant: SmoothButtonVariant.success,
            ),
            const SizedBox(height: 24),
            Text(
              'Outlined Variants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Error Outlined',
              type: SmoothButtonType.outlined,
              variant: SmoothButtonVariant.error,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Success Outlined',
              type: SmoothButtonType.outlined,
              variant: SmoothButtonVariant.success,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Error Dashed',
              type: SmoothButtonType.dashed,
              variant: SmoothButtonVariant.error,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Success Dashed',
              type: SmoothButtonType.dashed,
              variant: SmoothButtonVariant.success,
            ),
            const SizedBox(height: 24),
            Text(
              'Text Variants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Error Text',
              type: SmoothButtonType.text,
              variant: SmoothButtonVariant.error,
            ),
            const SizedBox(height: 12),
            _buildVariantStateDemo(
              context,
              title: 'Success Text',
              type: SmoothButtonType.text,
              variant: SmoothButtonVariant.success,
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
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

  Widget _buildVariantStateDemo(
    BuildContext context, {
    required String title,
    required SmoothButtonType type,
    required SmoothButtonVariant variant,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStateButton(
              label: 'Default',
              type: type,
              variant: variant,
              onPressed: () {},
            ),
            _buildStateButton(
              label: 'Disabled',
              type: type,
              variant: variant,
              onPressed: null,
            ),
            _buildStateButton(
              label: 'Loading',
              type: type,
              variant: variant,
              onPressed: () {},
              loading: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateButton({
    required String label,
    required SmoothButtonType type,
    required SmoothButtonVariant variant,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: 170,
      child: SmoothButton(
        label: label,
        type: type,
        variant: variant,
        loading: loading,
        isFullWidth: true,
        onPressed: onPressed,
      ),
    );
  }
}
