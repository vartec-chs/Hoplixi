import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/providers/discovery_provider.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';
import 'package:hoplixi/features/local_send/utils/platform_icons.dart';
import 'package:hoplixi/features/local_send/widgets/device_card.dart';

class DeviceListSection extends ConsumerStatefulWidget {
  const DeviceListSection({super.key});

  @override
  ConsumerState<DeviceListSection> createState() => _DeviceListSectionState();
}

class _DeviceListSectionState extends ConsumerState<DeviceListSection>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _searchController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _searchController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final devicesAsync = ref.watch(discoveryProvider);
    final deviceName = ref.watch(localDeviceName);
    final platform = ref.watch(localDevicePlatform);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточка своего устройства.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getPlatformIcon(platform),
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Это устройство',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) =>
                    Opacity(opacity: _pulseAnimation.value, child: child),
                child: Icon(
                  Icons.wifi_tethering,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Устройства',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              devicesAsync.when(
                data: (devices) => Text(
                  '${devices.length} найдено',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, _) => Text(
                  'Ошибка',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Нажмите на устройство, чтобы подключиться',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          devicesAsync.when(
            data: (devices) => devices.isEmpty
                ? _buildEmptyPlaceholder(
                    icon: Icons.search,
                    text: 'Поиск устройств в сети...',
                  )
                : _buildDevicesGrid(devices),
            loading: () => _buildEmptyPlaceholder(
              icon: Icons.search,
              text: 'Поиск устройств...',
            ),
            error: (e, _) => _buildEmptyPlaceholder(
              icon: Icons.error_outline,
              text: 'Ошибка: $e',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder({
    required IconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon == Icons.search
              ? AnimatedBuilder(
                  animation: _searchController,
                  builder: (_, child) => SlideTransition(
                    position: AlwaysStoppedAnimation(
                      Offset(
                        sin(_searchController.value * 2 * pi) * 0.1,
                        sin(_searchController.value * 4 * pi) * 0.1,
                      ),
                    ),
                    child: child,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : Icon(icon, size: 40, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesGrid(List<DeviceInfo> devices) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    if (isSmallScreen) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: devices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final device = devices[index];
          return DeviceCard(
            device: device,
            onTap: () {
              ref.read(transferProvider.notifier).connectToDevice(device);
            },
          );
        },
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return DeviceCard(
          device: device,
          onTap: () {
            ref.read(transferProvider.notifier).connectToDevice(device);
          },
        );
      },
    );
  }
}
