import 'package:flutter/material.dart';

// =============================================================================
// Animation Durations
// =============================================================================

/// Длительность анимации панели
const Duration kPanelAnimationDuration = Duration(milliseconds: 280);

/// Длительность fade анимации
const Duration kFadeAnimationDuration = Duration(milliseconds: 250);

/// Длительность scale анимации
const Duration kScaleAnimationDuration = Duration(milliseconds: 200);

/// Длительность opacity анимации
const Duration kOpacityAnimationDuration = Duration(milliseconds: 200);

/// Длительность анимации segment indicator
const Duration kSegmentIndicatorDuration = Duration(milliseconds: 300);

// =============================================================================
// Layout Dimensions
// =============================================================================

/// Ширина NavigationRail
const double kRailWidth = 80.0;

/// Ширина левой панели фильтрации
const double kLeftPanelWidth = 260.0;

/// Ширина разделителя
const double kDividerWidth = 2.0;

/// Высота нижней навигации
const double kBottomNavHeight = 70.0;

/// Ширина пространства для FAB
const double kFabSpaceWidth = 40.0;

/// Радиус индикатора навигации
const double kIndicatorBorderRadius = 16.0;

/// Радиус границы нижней навигации
const double kBottomNavBorderRadius = 12.0;

/// Размер шрифта нижней навигации
const double kBottomNavFontSize = 12.0;

/// Отступ нижней навигации
const double kBottomNavSpacing = 4.0;

/// Горизонтальный отступ нижней навигации
const double kBottomNavPaddingHorizontal = 8.0;

/// Вертикальный отступ нижней навигации
const double kBottomNavPaddingVertical = 4.0;

/// Отступ от notch
const double kBottomNavNotchMargin = 8.0;

// =============================================================================
// Floating Bottom Navigation Dimensions
// =============================================================================

/// Горизонтальный отступ плавающей навигации
const double kFloatingNavMarginHorizontal = 12.0;

/// Нижний отступ плавающей навигации
const double kFloatingNavMarginBottom = 24.0;

/// Радиус границы плавающей панели
const double kFloatingNavBarBorderRadius = 28.0;

/// Высота плавающей навигационной панели
const double kFloatingNavBarHeight = 64.0;

/// Радиус размытия тени плавающей навигации
const double kFloatingNavShadowBlurRadius = 20.0;

/// Прозрачность тени плавающей навигации
const double kFloatingNavShadowOpacity = 0.12;

/// Смещение тени по Y
const double kFloatingNavShadowOffsetY = 4.0;

/// Радиус элемента плавающей навигации
const double kFloatingNavItemBorderRadius = 16.0;

/// Горизонтальный отступ элемента
const double kFloatingNavItemPaddingH = 8.0;

/// Вертикальный отступ элемента
const double kFloatingNavItemPaddingV = 6.0;

/// Размер иконки в плавающей навигации
const double kFloatingNavIconSize = 22.0;

/// Размер шрифта метки
const double kFloatingNavLabelFontSize = 10.0;

/// Отступ метки
const double kFloatingNavLabelSpacing = 2.0;

/// Смещение FAB от низа
const double kFloatingNavFabBottomOffset = 12.0;

// =============================================================================
// Animation Values
// =============================================================================

/// Масштаб центра при открытой панели
const double kCenterScaleWhenPanelOpen = 0.92;

/// Масштаб центра при полноэкранном режиме
const double kCenterScaleWhenFullCenter = 0.96;

/// Начальный масштаб панели
const double kPanelZoomBegin = 0.85;

/// Конечный масштаб панели
const double kPanelZoomEnd = 1.0;

/// Начальное значение fade
const double kFadeBegin = 0.0;

/// Конечное значение fade
const double kFadeEnd = 1.0;

/// Начальный масштаб full-center
const double kFullCenterScaleBegin = 0.92;

/// Смещение масштаба full-center
const double kFullCenterScaleOffset = 0.08;

// =============================================================================
// Segment Indicator
// =============================================================================

/// Вертикальный отступ segment indicator
const double kSegmentIndicatorVerticalPadding = 6.0;

/// Горизонтальный отступ segment indicator
const double kSegmentIndicatorHorizontalPadding = 6.0;

// =============================================================================
// Animation Intervals
// =============================================================================

/// Начало интервала fade анимации
const double kFadeAnimationIntervalStart = 0.1;

/// Конец интервала fade анимации
const double kFadeAnimationIntervalEnd = 0.4;

// =============================================================================
// Path Segments
// =============================================================================

/// Минимальное количество сегментов для отображения панели
const int kMinPathSegmentsForPanel = 3;

/// Количество сегментов для entity
const int kPathSegmentsForEntity = 2;

// =============================================================================
// Navigation Indices
// =============================================================================

/// Индекс пункта "Главная"
const int kHomeIndex = 0;

/// Индекс пункта "Категории"
const int kCategoriesIndex = 1;

/// Индекс пункта "Теги"
const int kTagsIndex = 2;

/// Индекс пункта "Иконки"
const int kIconsIndex = 3;

/// Индекс пункта "Граф"
const int kGraphIndex = 4;

// =============================================================================
// Navigation Destinations
// =============================================================================

/// Базовые destinations для NavigationRail
const List<NavigationRailDestination> kBaseDestinations = [
  NavigationRailDestination(icon: Icon(Icons.home), label: Text('Главная')),
  NavigationRailDestination(
    icon: Icon(Icons.category),
    label: Text('Категории'),
  ),
  NavigationRailDestination(icon: Icon(Icons.tag), label: Text('Теги')),
  NavigationRailDestination(icon: Icon(Icons.image), label: Text('Иконки')),
];

/// Destination для графа (только для notes)
const NavigationRailDestination kGraphDestination = NavigationRailDestination(
  icon: Icon(Icons.bubble_chart),
  label: Text('Граф'),
);

// =============================================================================
// Actions
// =============================================================================

/// Действия панели справа и нижнего меню
const List<String> kDashboardActions = ['categories', 'tags', 'icons'];
