import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/confirmation_bottom_modal.dart';

/// Showcase экран для демонстрации ConfirmationBottomModal.
class ConfirmationBottomModalShowcaseScreen extends StatefulWidget {
  const ConfirmationBottomModalShowcaseScreen({super.key});

  @override
  State<ConfirmationBottomModalShowcaseScreen> createState() =>
      _ConfirmationBottomModalShowcaseScreenState();
}

class _ConfirmationBottomModalShowcaseScreenState
    extends State<ConfirmationBottomModalShowcaseScreen> {
  String _lastResult = 'Нет результата';

  void _setResult(bool? result) {
    setState(() {
      _lastResult = switch (result) {
        true => 'Подтверждено (true)',
        false => 'Отклонено (false)',
        null => 'Закрыто без действия (null)',
      };
    });
  }

  Future<void> _showBasicConfirmation(BuildContext context) async {
    final result = await ConfirmationBottomModal.show(
      context: context,
      title: 'Подтвердите действие',
      description: 'Эта модалка открывается внизу и имеет отступы 12px.',
      confirmButtonLabel: 'Согласиться',
      declineButtonLabel: 'Отклонить',
    );
    if (!mounted) return;
    _setResult(result);
  }

  Future<void> _showWithSlider(BuildContext context) async {
    var sliderValue = 35.0;

    final result = await ConfirmationBottomModal.show(
      context: context,
      title: 'Настройка параметра',
      description: 'В body можно передать любой виджет, например Slider.',
      confirmButtonLabel: 'Применить',
      declineButtonLabel: 'Отмена',
      body: StatefulBuilder(
        builder: (context, setLocalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Значение: ${sliderValue.toStringAsFixed(0)}'),
              Slider(
                value: sliderValue,
                min: 0,
                max: 100,
                divisions: 100,
                label: sliderValue.toStringAsFixed(0),
                onChanged: (value) {
                  setLocalState(() {
                    sliderValue = value;
                  });
                },
              ),
            ],
          );
        },
      ),
      onConfirmPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Подтверждено со значением ${sliderValue.toStringAsFixed(0)}',
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    _setResult(result);
  }

  Future<void> _showWithoutActions(BuildContext context) async {
    final result = await ConfirmationBottomModal.show(
      context: context,
      title: 'Информационная модалка',
      description: 'Кнопки можно отключить полностью.',
      confirmButtonLabel: null,
      declineButtonLabel: null,
      body: const Text('Закройте модалку тапом по затемнению.'),
    );
    if (!mounted) return;
    _setResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ConfirmationBottomModal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Последний результат: $_lastResult',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => _showBasicConfirmation(context),
          child: const Text('Показать базовое подтверждение'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () => _showWithSlider(context),
          child: const Text('Показать модалку со слайдером'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _showWithoutActions(context),
          child: const Text('Показать без кнопок действий'),
        ),
      ],
    );
  }
}
