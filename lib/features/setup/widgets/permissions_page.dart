import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/setup/providers/setup_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:permission_handler/permission_handler.dart';

/// Страница запроса разрешений
class PermissionsPage extends ConsumerStatefulWidget {
  const PermissionsPage({super.key});

  @override
  ConsumerState<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends ConsumerState<PermissionsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final setupState = ref.watch(setupProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 100),

            // Заголовок
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.tertiary.withOpacity(0.8),
                            colorScheme.tertiary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.tertiary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        size: 48,
                        color: colorScheme.onTertiary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Разрешения',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Для полноценной работы приложения\n'
                      'нам нужны следующие разрешения',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Список разрешений
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildPermissionsList(context, setupState),
              ),
            ),

            const SizedBox(height: 24),

            // Кнопка запросить все
            if (!setupState.allPermissionsGranted)
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SmoothButton(
                    label: 'Разрешить все',
                    onPressed: setupState.isLoading
                        ? null
                        : () {
                            ref
                                .read(setupProvider.notifier)
                                .requestAllPermissions();
                          },
                    type: SmoothButtonType.filled,
                    isFullWidth: true,
                    loading: setupState.isLoading,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                  ),
                ),
              ),

            if (setupState.allPermissionsGranted)
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Все разрешения получены!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsList(BuildContext context, SetupState setupState) {
    final permissions = SetupNotifier.requiredPermissions;

    return Column(
      children: permissions.map((permission) {
        final status = setupState.permissionStatuses[permission];
        final isGranted = status?.isGranted ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PermissionTile(
            permission: permission,
            isGranted: isGranted,
            onRequest: () {
              ref.read(setupProvider.notifier).requestPermission(permission);
            },
          ),
        );
      }).toList(),
    );
  }
}

/// Плитка разрешения
class _PermissionTile extends StatelessWidget {
  final Permission permission;
  final bool isGranted;
  final VoidCallback onRequest;

  const _PermissionTile({
    required this.permission,
    required this.isGranted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final info = _getPermissionInfo(permission);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted
            ? Colors.green.withOpacity(0.1)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? Colors.green.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Иконка
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.shade100
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              info.$1,
              color: isGranted
                  ? Colors.green.shade700
                  : colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.$2,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  info.$3,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Статус / Кнопка
          if (isGranted)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 18),
            )
          else
            SmoothButton(
              label: 'Разрешить',
              onPressed: onRequest,
              type: SmoothButtonType.tonal,
              size: SmoothButtonSize.small,
            ),
        ],
      ),
    );
  }

  (IconData, String, String) _getPermissionInfo(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return (
          Icons.camera_alt_outlined,
          'Камера',
          'Для сканирования QR-кодов',
        );
      case Permission.storage:
        return (
          Icons.folder_outlined,
          'Хранилище',
          'Для резервного копирования',
        );
      case Permission.photos:
        return (
          Icons.photo_library_outlined,
          'Фотографии',
          'Для выбора изображений',
        );
      case Permission.manageExternalStorage:
        return (
          Icons.sd_storage_outlined,
          'Управление хранилищем',
          'Для расширенного доступа к файлам',
        );
      default:
        return (
          Icons.settings_outlined,
          permission.toString(),
          'Системное разрешение',
        );
    }
  }
}
