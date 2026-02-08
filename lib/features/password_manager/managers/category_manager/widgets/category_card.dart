import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';

/// Современная карточка категории с градиентным фоном и анимациями.
///
/// Поддерживает кастомные цвета, иконки и показывает количество элементов.
class CategoryCard extends StatefulWidget {
  final CategoryCardDto category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return Theme.of(context).colorScheme.primary;
    }
    final colorValue = int.tryParse(colorHex.replaceFirst('#', ''), radix: 16);
    return colorValue != null
        ? Color(0xFF000000 | colorValue)
        : Theme.of(context).colorScheme.primary;
  }

  /// Корректирует цвет для обеспечения контрастности на текущем фоне.
  /// Светлые цвета затемняются на светлом фоне, тёмные осветляются на тёмном.
  Color _adjustColorForContrast(Color color, bool isDark) {
    final luminance = color.computeLuminance();

    if (isDark) {
      // На тёмном фоне: если цвет слишком тёмный — осветляем
      if (luminance < 0.2) {
        return Color.lerp(color, Colors.white, 0.4)!;
      }
      return color;
    } else {
      // На светлом фоне: если цвет слишком светлый — затемняем
      if (luminance > 0.7) {
        return Color.lerp(color, Colors.black, 0.35)!;
      }
      return color;
    }
  }

  String _getTypeDisplayName(String type) {
    return switch (type) {
      'notes' => 'Заметки',
      'password' => 'Пароли',
      'totp' => 'TOTP',
      'bankCard' => 'Карты',
      'files' => 'Файлы',
      'mixed' => 'Смешанный',
      _ => type,
    };
  }

  IconData _getTypeIcon(String type) {
    return switch (type) {
      'notes' => Icons.note_alt_outlined,
      'password' => Icons.lock_outline,
      'totp' => Icons.qr_code_2,
      'bankCard' => Icons.credit_card,
      'files' => Icons.folder_outlined,
      'mixed' => Icons.layers_outlined,
      _ => Icons.category_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rawColor = _parseColor(widget.category.color);
    final isDark = theme.brightness == Brightness.dark;

    // Корректируем цвет для контрастности
    final baseColor = _adjustColorForContrast(rawColor, isDark);

    // Создаем градиентные цвета на основе базового цвета
    // Используем непрозрачный фон для хорошей видимости на любом фоне
    final cardBackground = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLowest;
    final gradientStart = Color.alphaBlend(
      baseColor.withOpacity(isDark ? 0.35 : 0.2),
      cardBackground,
    );
    final gradientEnd = Color.alphaBlend(
      baseColor.withOpacity(isDark ? 0.15 : 0.08),
      cardBackground,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: cardBackground,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gradientStart, gradientEnd],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(_isHovered ? 0.4 : 0.25)
                      : baseColor.withOpacity(_isHovered ? 0.2 : 0.1),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
                // Мягкое свечение в цвете карточки
                BoxShadow(
                  color: baseColor.withOpacity(_isHovered ? 0.15 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onTap,
                splashColor: baseColor.withOpacity(0.2),
                highlightColor: baseColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Верхняя часть: иконка и меню
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Иконка категории
                          _buildIconContainer(baseColor, isDark),
                          const Spacer(),
                          // Меню действий
                          _buildPopupMenu(colorScheme),
                        ],
                      ),

                      const Spacer(),

                      // Название категории
                      Text(
                        widget.category.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Тип и количество элементов
                      Row(
                        children: [
                          // Тип категории с иконкой
                          _buildTypeBadge(baseColor, isDark),
                          const Spacer(),
                          // Счетчик элементов
                          _buildItemsCounter(colorScheme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(Color baseColor, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: baseColor.withOpacity(isDark ? 0.3 : 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: baseColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: widget.category.iconId != null
            ? Icon(Icons.folder, color: baseColor, size: 26)
            : Text(
                widget.category.name.isNotEmpty
                    ? widget.category.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: baseColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _buildPopupMenu(ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        size: 20,
      ),
      splashRadius: 20,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Редактировать'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
              const SizedBox(width: 12),
              Text('Удалить', style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          widget.onEdit?.call();
        } else if (value == 'delete') {
          widget.onDelete?.call();
        }
      },
    );
  }

  Widget _buildTypeBadge(Color baseColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getTypeIcon(widget.category.type), size: 14, color: baseColor),
          const SizedBox(width: 5),
          Text(
            _getTypeDisplayName(widget.category.type),
            style: TextStyle(
              color: baseColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCounter(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.layers_outlined,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.category.itemsCount}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
