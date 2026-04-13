import 'package:flutter/material.dart';

void syncTextController({
  required TextEditingController controller,
  required String oldValue,
  required String newValue,
}) {
  if (oldValue == newValue) {
    return;
  }

  if (controller.text != oldValue) {
    return;
  }

  controller.value = controller.value.copyWith(
    text: newValue,
    selection: TextSelection.collapsed(offset: newValue.length),
    composing: TextRange.empty,
  );
}
