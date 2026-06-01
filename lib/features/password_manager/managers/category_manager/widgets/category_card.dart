import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/category_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/icon_dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/icons/icon_refs.dart';
import 'package:hoplixi/shared/widgets/icon_ref_preview.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rawColor = Color(0xFF000000 | widget.category.color);
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
                    mainAxisSize: MainAxisSize.min,
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

                      const SizedBox(height: 18),

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

                      // Информация о типе (заглушка или удалена)
                      Row(
                        children: [
                          const Spacer(),
                          // Можно добавить счетчик элементов если будет реализован
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
        child: widget.category.iconRefId != null
            ? IconRefPreview(
                iconRef: IconRefDto(
                  id: widget.category.iconRefId,
                  iconSourceType: IconSourceType
                      .pack, // Заглушка, нужно грузить реальный IconRef
                ),
                fallbackIcon: Icons.folder,
                size: 26,
                color: baseColor,
              )
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
}
