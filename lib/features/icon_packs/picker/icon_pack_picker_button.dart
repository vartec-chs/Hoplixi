import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/features/icon_packs/picker/icon_pack_picker_modal.dart';
import 'package:hoplixi/features/icon_packs/providers/icon_packs_provider.dart';

class IconPackPickerButton extends ConsumerStatefulWidget {
  const IconPackPickerButton({
    super.key,
    this.selectedIconKey,
    required this.onIconSelected,
    this.onBeforeOpenPicker,
    this.size = 120,
    this.hintText,
  });

  final String? selectedIconKey;
  final ValueChanged<String?> onIconSelected;
  final Future<bool> Function(BuildContext context)? onBeforeOpenPicker;
  final double size;
  final String? hintText;

  @override
  ConsumerState<IconPackPickerButton> createState() =>
      _IconPackPickerButtonState();
}

class _IconPackPickerButtonState extends ConsumerState<IconPackPickerButton> {
  String? _svgContent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedIconKey != null) {
      _loadIcon(widget.selectedIconKey!);
    }
  }

  @override
  void didUpdateWidget(covariant IconPackPickerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIconKey != widget.selectedIconKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final selectedIconKey = widget.selectedIconKey;
        if (selectedIconKey == null) {
          setState(() {
            _svgContent = null;
            _isLoading = false;
          });
          return;
        }

        _loadIcon(selectedIconKey);
      });
    }
  }

  Future<void> _loadIcon(String iconKey) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(iconPackCatalogServiceProvider);
      final svg = await service.readSvgByKey(iconKey);

      if (!mounted) {
        return;
      }

      setState(() {
        _svgContent = svg;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _svgContent = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _openPicker() async {
    final canOpen = await widget.onBeforeOpenPicker?.call(context) ?? true;
    if (!canOpen || !mounted) {
      return;
    }

    final selectedKey = await showIconPackPickerModal(
      context,
      ref,
      initialIconKey: widget.selectedIconKey,
    );

    if (selectedKey == null || !mounted) {
      return;
    }

    widget.onIconSelected(selectedKey);
    await _loadIcon(selectedKey);
  }

  void _clearIcon() {
    setState(() {
      _svgContent = null;
    });
    widget.onIconSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: _openPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: _buildContent(context),
          ),
        ),
        if (_svgContent != null && !_isLoading)
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Tooltip(
                message: 'Удалить иконку',
                child: InkWell(
                  onTap: _clearIcon,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_svgContent != null && _svgContent!.trim().isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SvgPicture.string(
          _svgContent!,
          fit: BoxFit.contain,
          placeholderBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          widget.hintText ?? 'Выберите иконку',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
