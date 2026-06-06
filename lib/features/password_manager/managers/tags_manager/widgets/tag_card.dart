import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/tag_dto.dart';

/// Современная карточка тега с градиентным фоном и анимациями.
///
/// Поддерживает кастомные цвета и показывает количество элементов.
class TagCard extends StatefulWidget {
  final TagCardDto tag;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TagCard({
    super.key,
    required this.tag,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TagCard> createState() => _TagCardState();
}

class _TagCardState extends State<TagCard> with SingleTickerProviderStateMixin {
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
    final rawColor = Color(0xFF000000 | widget.tag.color);
    final isDark = theme.brightness == Brightness.dark;

    // Корректируем цвет для контрастности
    final baseColor = _adjustColorForContrast(rawColor, isDark);

    // Создаем градиентные цвета на основе базового цвета
    // Используем непрозрачный фон для хорошей видимости на любом фоне
    final cardBackground = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLowest;
    final gradientStart = Color.alphaBlend(
      baseColor.withValues(alpha: isDark ? 0.3 : 0.15),
      cardBackground,
    );
    final gradientMiddle = Color.alphaBlend(
      baseColor.withValues(alpha: isDark ? 0.15 : 0.08),
      cardBackground,
    );
    final gradientEnd = cardBackground;

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
              borderRadius: BorderRadius.circular(16),
              color: cardBackground,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gradientStart, gradientMiddle, gradientEnd],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.2)
                      : baseColor.withValues(alpha: _isHovered ? 0.15 : 0.08),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: Offset(0, _isHovered ? 6 : 3),
                  spreadRadius: _isHovered ? 1 : 0,
                ),
                // Мягкое свечение в цвете карточки
                if (_isHovered)
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onTap,
                splashColor: baseColor.withValues(alpha: 0.15),
                highlightColor: baseColor.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Иконка тега
                      _buildTagIcon(baseColor, isDark),
                      const SizedBox(width: 14),

                      // Название и информация
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Название тега
                            Text(
                              widget.tag.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Информация о типе удалена т.к. нет в новом DTO
                          ],
                        ),
                      ),

                      // Меню действий
                      _buildPopupMenu(colorScheme),
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

  Widget _buildTagIcon(Color baseColor, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: isDark ? 0.35 : 0.25),
            baseColor.withValues(alpha: isDark ? 0.2 : 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: baseColor.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.label_rounded, color: baseColor, size: 24),
      ),
    );
  }

  Widget _buildPopupMenu(ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        size: 20,
      ),
      splashRadius: 18,
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
