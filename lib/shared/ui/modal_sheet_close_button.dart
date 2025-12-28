import 'package:flutter/material.dart';

class ModalSheetCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const ModalSheetCloseButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
}
