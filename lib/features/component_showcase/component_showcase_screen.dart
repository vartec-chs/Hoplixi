import 'package:flutter/material.dart';
import 'package:hoplixi/features/component_showcase/screens/button_showcase_screen.dart';
import 'package:hoplixi/features/component_showcase/screens/document_scanner_showcase_screen.dart';
import 'package:hoplixi/features/component_showcase/screens/expandable_fab_screen.dart';
import 'package:hoplixi/features/component_showcase/screens/modal_sheet_showcase_screen.dart';
import 'package:hoplixi/features/component_showcase/screens/notification_showcase_screen.dart';
import 'package:hoplixi/features/component_showcase/screens/qr_scanner_showcase_screen.dart';
import 'package:hoplixi/features/component_showcase/screens/slider_button_showcase_screen.dart';
import 'package:hoplixi/features/component_showcase/screens/text_field_showcase_screen.dart';
import 'package:hoplixi/features/component_showcase/screens/universal_modal_showcase_screen.dart';

/// Основной экран для демонстрации всех кастомных компонентов
class ComponentShowcaseScreen extends StatefulWidget {
  const ComponentShowcaseScreen({super.key});

  @override
  State<ComponentShowcaseScreen> createState() =>
      _ComponentShowcaseScreenState();
}

class _ComponentShowcaseScreenState extends State<ComponentShowcaseScreen> {
  int _selectedIndex = 0;

  final List<ShowcaseItem> _showcaseItems = [
    ShowcaseItem(
      title: 'Buttons',
      icon: Icons.smart_button,
      screen: const ButtonShowcaseScreen(),
    ),
    ShowcaseItem(
      title: 'Text Fields',
      icon: Icons.text_fields,
      screen: const TextFieldShowcaseScreen(),
    ),
    ShowcaseItem(
      title: 'Slider Buttons',
      icon: Icons.swipe,
      screen: const SliderButtonShowcaseScreen(),
    ),
    ShowcaseItem(
      title: 'Modal Sheets',
      icon: Icons.layers,
      screen: const ModalSheetShowcaseScreen(),
    ),
    ShowcaseItem(
      title: 'Notifications',
      icon: Icons.notifications,
      screen: const NotificationShowcaseScreen(),
    ),
    ShowcaseItem(
      title: 'Universal Modal',
      icon: Icons.dashboard,
      screen: const UniversalModalShowcaseScreen(),
    ),
    ShowcaseItem(
      title: 'Expandable FAB',
      icon: Icons.add_circle,
      screen: const ExpandableFabScreen(),
    ),
    ShowcaseItem(
      title: 'QR Scanners',
      icon: Icons.qr_code_scanner,
      screen: const QrScannerShowcaseScreen(),
    ),
    ShowcaseItem(
      title: 'Document Scanner',
      icon: Icons.document_scanner,
      screen: const DocumentScannerShowcaseScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Component Showcase'),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Sidebar навигация
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: _showcaseItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.icon),
                    label: Text(item.title),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Основной контент
          Expanded(child: _showcaseItems[_selectedIndex].screen),
        ],
      ),
    );
  }
}

/// Модель элемента showcase
class ShowcaseItem {
  final String title;
  final IconData icon;
  final Widget screen;

  ShowcaseItem({required this.title, required this.icon, required this.screen});
}
