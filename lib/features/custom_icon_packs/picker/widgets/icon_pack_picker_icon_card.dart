import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_pack_entry.dart';
import 'package:hoplixi/features/custom_icon_packs/providers/icon_packs_provider.dart';

class IconPackPickerIconCard extends StatelessWidget {
  const IconPackPickerIconCard({
    super.key,
    required this.entry,
    required this.previewColor,
    required this.onTap,
    required this.isSelected,
  });

  final IconPackEntry entry;
  final Color? previewColor;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: entry.relativePath,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: isSelected ? 0 : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: IconPackSvgPreview(
                      iconKey: entry.key,
                      previewColor: previewColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.name,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IconPackSvgPreview extends ConsumerStatefulWidget {
  const IconPackSvgPreview({
    super.key,
    required this.iconKey,
    this.previewColor,
  });

  final String iconKey;
  final Color? previewColor;

  @override
  ConsumerState<IconPackSvgPreview> createState() => _IconPackSvgPreviewState();
}

class _IconPackSvgPreviewState extends ConsumerState<IconPackSvgPreview> {
  late Future<String?> _svgFuture;

  @override
  void initState() {
    super.initState();
    _svgFuture = _loadSvg();
  }

  @override
  void didUpdateWidget(covariant IconPackSvgPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconKey != widget.iconKey) {
      _svgFuture = _loadSvg();
    }
  }

  Future<String?> _loadSvg() {
    final service = ref.read(iconPackCatalogServiceProvider);
    return service.readSvgByKey(widget.iconKey);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _svgFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          return Icon(
            Icons.broken_image_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.error,
          );
        }

        final svg = snapshot.data;
        if (svg == null || svg.trim().isEmpty) {
          return Icon(
            Icons.broken_image_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.error,
          );
        }

        return SvgPicture.string(
          width: 42,
          height: 42,
          svg,
          fit: BoxFit.contain,
          colorFilter: widget.previewColor == null
              ? null
              : ColorFilter.mode(widget.previewColor!, BlendMode.srcIn),
          placeholderBuilder: (context) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
