import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/features/custom_icon_packs/providers/icon_packs_provider.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/icons/custom_icons.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/icons/icon_refs.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';

class IconRefPreview extends ConsumerStatefulWidget {
  const IconRefPreview({
    super.key,
    this.iconRef,
    required this.fallbackIcon,
    this.size = 24,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
  });

  final IconRefDto? iconRef;
  final IconData fallbackIcon;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsets padding;

  @override
  ConsumerState<IconRefPreview> createState() => _IconRefPreviewState();
}

class _IconRefPreviewState extends ConsumerState<IconRefPreview> {
  Uint8List? _dbIconData;
  String? _dbIconType;
  String? _svgContent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(covariant IconRefPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconRef != widget.iconRef) {
      _loadIcon();
    }
  }

  Future<void> _loadIcon() async {
    final iconRef = widget.iconRef;
    if (iconRef == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dbIconData = null;
        _dbIconType = null;
        _svgContent = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _dbIconData = null;
      _dbIconType = null;
      _svgContent = null;
    });

    try {
      switch (iconRef.iconSourceType) {
        case IconSourceType.custom:
          final customIconId = iconRef.customIconId;
          if (customIconId == null) {
            throw Exception('customIconId is null for custom icon');
          }
          final repos = await ref.read(vaultRepositories.future);
          final result = await repos.icon.getCustomIcon(customIconId);
          final icon = result.getOrNull()?.getOrNull();
          if (!mounted) {
            return;
          }
          setState(() {
            _dbIconData = icon?.data;
            _dbIconType = icon?.format.name;
            _isLoading = false;
          });
        case IconSourceType.pack:
          final iconValue = iconRef.iconValue;
          if (iconValue == null) {
            throw Exception('iconValue is null for pack icon');
          }
          final service = ref.read(iconPackCatalogServiceProvider);
          final svg = await service.readSvgByKey(iconValue);
          if (!mounted) {
            return;
          }
          setState(() {
            _svgContent = svg;
            _isLoading = false;
          });
        case IconSourceType.builtin:
          // TODO: handle builtin icons if needed in the future
          if (!mounted) {
            return;
          }
          setState(() {
            _isLoading = false;
          });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dbIconData = null;
        _dbIconType = null;
        _svgContent = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_isLoading) {
      child = SizedBox.square(
        dimension: widget.size,
        child: const Center(
          child: SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_svgContent != null && _svgContent!.trim().isNotEmpty) {
      child = SvgPicture.string(
        _svgContent!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        colorFilter: widget.color == null
            ? null
            : ColorFilter.mode(widget.color!, BlendMode.srcIn),
      );
    } else if (_dbIconData != null && _dbIconType != null) {
      final isSvg = _dbIconType == CustomIconFormat.svg.name;
      child = isSvg
          ? SvgPicture.memory(
              _dbIconData!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              colorFilter: widget.color == null
                  ? null
                  : ColorFilter.mode(widget.color!, BlendMode.srcIn),
            )
          : Image.memory(
              _dbIconData!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              color: widget.color,
            );
    } else {
      child = Icon(widget.fallbackIcon, size: widget.size, color: widget.color);
    }

    if (widget.backgroundColor == null && widget.borderRadius == null) {
      return Padding(padding: widget.padding, child: child);
    }

    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
      ),
      child: child,
    );
  }
}
