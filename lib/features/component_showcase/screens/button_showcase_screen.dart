import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/button.dart';

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
          title: 'Button Variants',
          children: [
            SmoothButton(
              label: 'Normal Filled',
              variant: SmoothButtonVariant.normal,
              type: SmoothButtonType.filled,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Error Filled',
              variant: SmoothButtonVariant.error,
              type: SmoothButtonType.filled,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Warning Filled',
              variant: SmoothButtonVariant.warning,
              type: SmoothButtonType.filled,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Info Filled',
              variant: SmoothButtonVariant.info,
              type: SmoothButtonType.filled,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Success Filled',
              variant: SmoothButtonVariant.success,
              type: SmoothButtonType.filled,
              onPressed: () {},
            ),
            const SizedBox(height: 24),
            Text(
              'Tonal Variants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Error Tonal',
              variant: SmoothButtonVariant.error,
              type: SmoothButtonType.tonal,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Warning Tonal',
              variant: SmoothButtonVariant.warning,
              type: SmoothButtonType.tonal,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Success Tonal',
              variant: SmoothButtonVariant.success,
              type: SmoothButtonType.tonal,
              onPressed: () {},
            ),
            const SizedBox(height: 24),
            Text(
              'Outlined Variants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Error Outlined',
              variant: SmoothButtonVariant.error,
              type: SmoothButtonType.outlined,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Success Outlined',
              variant: SmoothButtonVariant.success,
              type: SmoothButtonType.outlined,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Error Dashed',
              variant: SmoothButtonVariant.error,
              type: SmoothButtonType.dashed,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Success Dashed',
              variant: SmoothButtonVariant.success,
              type: SmoothButtonType.dashed,
              onPressed: () {},
            ),
            const SizedBox(height: 24),
            Text(
              'Text Variants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Error Text',
              variant: SmoothButtonVariant.error,
              type: SmoothButtonType.text,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Success Text',
              variant: SmoothButtonVariant.success,
              type: SmoothButtonType.text,
              onPressed: () {},
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
}
