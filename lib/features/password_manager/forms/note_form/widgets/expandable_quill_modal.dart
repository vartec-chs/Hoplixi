import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:universal_platform/universal_platform.dart';

Future<void> showQuillEditorModal({
  required BuildContext context,
  required QuillController controller,
  String title = 'Заметки',
  Widget? toolbar,
  Future<void> Function(String url)? onLaunchUrl,
  EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  double widthFactor = 0.95,
  double heightFactor = 0.9,
}) {
  FocusScope.of(context).unfocus();
  final isDesktop = UniversalPlatform.isDesktop;
  final modal = ExpandableQuillModal(
    controller: controller,
    title: title,
    toolbar: toolbar,
    onLaunchUrl: onLaunchUrl,
    padding: padding,
    widthFactor: widthFactor,
    heightFactor: heightFactor,
  );

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Padding(
        padding: isDesktop ? const EdgeInsets.only(top: 42) : EdgeInsets.zero,
        child: modal,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class ExpandableQuillModal extends StatefulWidget {
  const ExpandableQuillModal({
    super.key,
    required this.controller,
    required this.title,
    this.toolbar,
    this.onLaunchUrl,
    this.padding = const EdgeInsets.all(12),
    this.widthFactor = 0.95,
    this.heightFactor = 0.85,
  });

  final QuillController controller;
  final String title;
  final Widget? toolbar;
  final Future<void> Function(String url)? onLaunchUrl;
  final EdgeInsetsGeometry padding;
  final double widthFactor;
  final double heightFactor;

  @override
  State<ExpandableQuillModal> createState() => _ExpandableQuillModalState();
}

class _ExpandableQuillModalState extends State<ExpandableQuillModal> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Delay the focus request to ensure the modal is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final width = math.min(size.width * widget.widthFactor, 1200.0);
    final height = math.min(size.height * widget.heightFactor, 900.0);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: SafeArea(
          child: Center(
            child: Material(
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              color: theme.colorScheme.surface,
              child: SizedBox(
                width: width,
                height: height,
                child: Column(
                  children: [
                    _ExpandableQuillModalHeader(title: widget.title),
                    const Divider(height: 1),
                    if (widget.toolbar != null) widget.toolbar!,
                    Expanded(
                      child: QuillEditor(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        config: QuillEditorConfig(
                          placeholder: 'Начните писать заметку...',
                          padding: widget.padding,
                          expands: true,
                          dialogTheme: QuillDialogTheme(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            dialogBackgroundColor: theme.colorScheme.surface,
                          ),
                          onLaunchUrl: widget.onLaunchUrl,
                          customStyles: DefaultStyles(
                            link: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableQuillModalHeader extends StatelessWidget {
  const _ExpandableQuillModalHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Закрыть',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
