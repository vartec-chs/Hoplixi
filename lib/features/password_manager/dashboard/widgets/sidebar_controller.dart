import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout.dart';

/// Пример кнопки для закрытия sidebar из любого места приложения
class CloseSidebarButton extends StatelessWidget {
  final String? label;
  final IconData? icon;

  const CloseSidebarButton({super.key, this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon ?? Icons.close),
      tooltip: label ?? 'Закрыть',
      onPressed: () {
        // Безопасно закрываем sidebar через статическую ссылку
        DashboardLayout.currentState?.closeSidebar();
      },
    );
  }
}

/// Пример кнопки для переключения состояния sidebar
class ToggleSidebarButton extends StatelessWidget {
  const ToggleSidebarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Переключить sidebar',
      onPressed: () {
        DashboardLayout.currentState?.toggleSidebar();
      },
    );
  }
}

/// Пример виджета, который показывает состояние sidebar
class SidebarStatusIndicator extends StatefulWidget {
  const SidebarStatusIndicator({super.key});

  @override
  State<SidebarStatusIndicator> createState() => _SidebarStatusIndicatorState();
}

class _SidebarStatusIndicatorState extends State<SidebarStatusIndicator> {
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _checkSidebarStatus();
  }

  void _checkSidebarStatus() {
    final state = DashboardLayout.currentState;
    if (state != null) {
      setState(() {
        _isSidebarOpen = state.isSidebarOpen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isSidebarOpen ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _isSidebarOpen ? 'Sidebar открыт' : 'Sidebar закрыт',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

/// @Deprecated Расширение для типа State, оставлено для обратной совместимости
/// Используйте DashboardLayout.currentState вместо этого
extension DashboardLayoutStateExtension on State<StatefulWidget> {
  /// Проверяет, является ли этот State экземпляром DashboardLayoutState
  bool get isDashboardLayoutState => this is DashboardLayoutState;

  /// Приводит к DashboardLayoutState, если возможно
  DashboardLayoutState? get asDashboardLayoutState {
    return this is DashboardLayoutState ? this as DashboardLayoutState : null;
  }
}

/// Хелпер класс для удобной работы с sidebar
class SidebarController {
  /// Закрывает sidebar, если он доступен
  static void close() {
    DashboardLayout.currentState?.closeSidebar();
  }

  /// Открывает sidebar, если он доступен
  static void open() {
    DashboardLayout.currentState?.openSidebar();
  }

  /// Переключает состояние sidebar
  static void toggle() {
    DashboardLayout.currentState?.toggleSidebar();
  }

  /// Проверяет, открыт ли sidebar
  static bool get isOpen {
    return DashboardLayout.currentState?.isSidebarOpen ?? false;
  }

  /// Проверяет, доступен ли sidebar
  static bool get isAvailable {
    return DashboardLayout.currentState != null;
  }
}
