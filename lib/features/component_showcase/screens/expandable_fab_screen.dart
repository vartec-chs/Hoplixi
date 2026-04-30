import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/fab/expandable_fab.dart';

class ExpandableFabScreen extends StatefulWidget {
  const ExpandableFabScreen({super.key});

  @override
  State<ExpandableFabScreen> createState() => _ExpandableFabScreenState();
}

class _ExpandableFabScreenState extends State<ExpandableFabScreen> {
  FABExpandDirection _direction = FABExpandDirection.up;

  final List<FABActionData> _actions = [
    FABActionData(
      icon: Icons.mail,
      label: 'Отправить письмо',
      onPressed: () => debugPrint('Action: Mail'),
    ),
    FABActionData(
      icon: Icons.phone,
      label: 'Позвонить',
      onPressed: () => debugPrint('Action: Phone'),
    ),
    FABActionData(
      icon: Icons.share,
      label: 'Поделиться',
      onPressed: () => debugPrint('Action: Share'),
    ),
    FABActionData(
      icon: Icons.edit,
      label: 'Редактировать',
      onPressed: () => debugPrint('Action: Edit'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expandable FAB Demo'),
        actions: [
          IconButton(
            icon: Icon(
              _direction == FABExpandDirection.up
                  ? Icons.arrow_upward
                  : Icons.arrow_forward,
            ),
            tooltip: 'Переключить режим',
            onPressed: () {
              setState(() {
                _direction = _direction == FABExpandDirection.up
                    ? FABExpandDirection.rightDown
                    : FABExpandDirection.up;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Нажмите на FAB', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Режим: ${_direction == FABExpandDirection.up ? "Вверх" : "Вправо-Вниз"}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ExpandableFAB(
        direction: _direction,
        spacing: 56,
        actions: _actions,
        onStateChanged: (isOpen) {
          debugPrint('FAB is ${isOpen ? "open" : "closed"}');
        },
      ),
    );
  }
}
