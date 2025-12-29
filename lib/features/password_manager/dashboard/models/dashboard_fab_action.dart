// import 'package:flutter/material.dart';
// import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
// import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';
// import 'package:hoplixi/routing/paths.dart';

// /// Тип цветовой схемы для FAB action
// enum FabActionColorType {
//   /// Primary container цвета темы
//   primary,

//   /// Secondary container цвета темы
//   secondary,

//   /// Tertiary container цвета темы
//   tertiary,
// }

// /// Callback для проверки видимости FAB action
// typedef FabActionVisibilityCallback =
//     bool Function(BuildContext context, EntityType? entityType);

// /// Определение действий FAB для Dashboard.
// ///
// /// Каждое действие содержит всю информацию для отображения в ExpandableFAB.
// /// Поддерживает динамические labels на основе текущего EntityType.
// ///
// /// Для добавления нового действия:
// /// 1. Добавить новое значение в enum
// /// 2. Настроить icon, labelBuilder, pathBuilder
// /// 3. Опционально настроить isVisible для условного отображения
// enum DashboardFabAction {
//   /// Создать тег
//   createTag(icon: Icons.local_offer, colorType: FabActionColorType.secondary),

//   /// Создать категорию
//   createCategory(icon: Icons.folder, colorType: FabActionColorType.secondary),

//   /// Создать иконку
//   createIcon(icon: Icons.image, colorType: FabActionColorType.secondary),

//   /// Импортировать OTP коды
//   importOtp(icon: Icons.qr_code, colorType: FabActionColorType.primary),

//   /// Миграция паролей
//   migratePasswords(icon: Icons.sync, colorType: FabActionColorType.primary),

//   /// Создать сущность (password/note/bankCard/file/otp)
//   /// Label и icon зависят от текущего EntityType
//   createEntity(
//     icon: Icons.add, // Переопределяется в getIcon()
//     colorType: FabActionColorType.primary,
//   ),

//   /// Открыть граф связей заметок
//   openNotesGraph(
//     icon: Icons.graphic_eq,
//     colorType: FabActionColorType.secondary,
//   );

//   const DashboardFabAction({required this.icon, required this.colorType});

//   /// Иконка по умолчанию
//   final IconData icon;

//   /// Тип цветовой схемы
//   final FabActionColorType colorType;

//   // ===========================================================================
//   // Dynamic Properties
//   // ===========================================================================

//   /// Получить иконку (может зависеть от EntityType)
//   IconData getIcon(EntityType? entityType) {
//     if (this == DashboardFabAction.createEntity && entityType != null) {
//       return entityType.icon;
//     }
//     return icon;
//   }

//   /// Получить label для действия
//   String getLabel(EntityType? entityType) {
//     switch (this) {
//       case DashboardFabAction.createTag:
//         return 'Создать тег';
//       case DashboardFabAction.createCategory:
//         return 'Создать категорию';
//       case DashboardFabAction.createIcon:
//         return 'Создать иконку';
//       case DashboardFabAction.importOtp:
//         return 'Импортировать OTP коды';
//       case DashboardFabAction.migratePasswords:
//         return 'Миграция паролей';
//       case DashboardFabAction.createEntity:
//         if (entityType != null) {
//           return 'Создать ${entityType.label}';
//         }
//         return 'Создать запись';
//       case DashboardFabAction.openNotesGraph:
//         return 'Граф заметок';
//     }
//   }

//   /// Получить путь для навигации
//   ///
//   /// Возвращает null если действие не требует навигации
//   String? getPath(EntityType? entityType) {
//     switch (this) {
//       case DashboardFabAction.createTag:
//         return AppRoutesPaths.dashboardTagManager;
//       case DashboardFabAction.createCategory:
//         return AppRoutesPaths.dashboardCategoryManager;
//       case DashboardFabAction.createIcon:
//         return AppRoutesPaths.dashboardIconManager;
//       case DashboardFabAction.importOtp:
//         return AppRoutesPaths.dashboardMigrateOtp;
//       case DashboardFabAction.migratePasswords:
//         return AppRoutesPaths.dashboardMigratePasswords;

//       case DashboardFabAction.createEntity:
//         return entityType?.createPath;
//       case DashboardFabAction.openNotesGraph:
//         return AppRoutesPaths.dashboardNotesGraph;
//     }
//   }

//   /// Проверить видимость действия
//   ///
//   /// Скрывает определённые действия в зависимости от текущего EntityType:
//   /// - `importOtp` — видим только когда выбран EntityType.otp
//   /// - `migratePasswords` — видим только для EntityType.password
//   /// - `openNotesGraph` — видим только для EntityType.note
//   /// - `createEntity` — всегда видим
//   /// - остальные — всегда видимы
//   bool isVisible(BuildContext context, EntityType? entityType) {
//     switch (this) {
//       case DashboardFabAction.importOtp:
//         // Показывать импорт OTP только когда выбран тип OTP
//         return entityType == EntityType.otp;

//       case DashboardFabAction.migratePasswords:
//         // Показывать миграцию только для паролей
//         return entityType == EntityType.password;

//       case DashboardFabAction.openNotesGraph:
//         // Показывать граф заметок только для заметок
//         return entityType == EntityType.note;

//       case DashboardFabAction.createTag:
//       case DashboardFabAction.createCategory:
//       case DashboardFabAction.createIcon:
//       case DashboardFabAction.createEntity:
//         // Всегда видимы
//         return true;
//     }
//   }

//   // ===========================================================================
//   // Color Helpers
//   // ===========================================================================

//   /// Получить цвет фона из темы
//   Color getBackgroundColor(ThemeData theme) {
//     switch (colorType) {
//       case FabActionColorType.primary:
//         return theme.colorScheme.primaryContainer;
//       case FabActionColorType.secondary:
//         return theme.colorScheme.secondaryContainer;
//       case FabActionColorType.tertiary:
//         return theme.colorScheme.tertiaryContainer;
//     }
//   }

//   /// Получить цвет контента из темы
//   Color getForegroundColor(ThemeData theme) {
//     switch (colorType) {
//       case FabActionColorType.primary:
//         return theme.colorScheme.onPrimaryContainer;
//       case FabActionColorType.secondary:
//         return theme.colorScheme.onSecondaryContainer;
//       case FabActionColorType.tertiary:
//         return theme.colorScheme.onTertiaryContainer;
//     }
//   }

//   // ===========================================================================
//   // Conversion Methods
//   // ===========================================================================

//   /// Конвертировать в [FABActionData] для использования в ExpandableFAB
//   FABActionData toFABActionData({
//     required BuildContext context,
//     required VoidCallback onPressed,
//     EntityType? entityType,
//   }) {
//     final theme = Theme.of(context);

//     return FABActionData(
//       icon: getIcon(entityType),
//       label: getLabel(entityType),
//       onPressed: onPressed,
//       backgroundColor: getBackgroundColor(theme),
//       foregroundColor: getForegroundColor(theme),
//     );
//   }

//   // ===========================================================================
//   // Static Utility Methods
//   // ===========================================================================

//   /// Построить список [FABActionData] для всех видимых действий
//   ///
//   /// [context] — BuildContext для получения темы
//   /// [entityType] — текущий тип сущности для динамических labels
//   /// [onActionPressed] — callback вызываемый при нажатии на действие
//   /// [visibilityFilter] — опциональный фильтр видимости
//   static List<FABActionData> buildActions({
//     required BuildContext context,
//     required void Function(DashboardFabAction action) onActionPressed,
//     EntityType? entityType,
//     FabActionVisibilityCallback? visibilityFilter,
//   }) {
//     return DashboardFabAction.values
//         .where((action) {
//           // Применяем кастомный фильтр если передан
//           if (visibilityFilter != null) {
//             return visibilityFilter(context, entityType);
//           }
//           // Иначе используем встроенную проверку видимости
//           return action.isVisible(context, entityType);
//         })
//         .map(
//           (action) => action.toFABActionData(
//             context: context,
//             entityType: entityType,
//             onPressed: () => onActionPressed(action),
//           ),
//         )
//         .toList();
//   }

//   @override
//   String toString() => 'DashboardFabAction.$name';
// }
