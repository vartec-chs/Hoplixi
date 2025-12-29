import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/forms/bank_card_form/screens/bank_card_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/file_form/screens/file_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/screens/note_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/otp_form/screens/otp_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/password_form/screens/password_form_screen.dart';

/// Виджет-обертка для создания/редактирования сущностей
/// Возвращает соответствующий экран формы в зависимости от типа сущности
class EntityAddEdit extends StatelessWidget {
  const EntityAddEdit({
    super.key,
    required this.entity,
    required this.isEdit,
    this.id,
  });

  /// Тип сущности
  final EntityType entity;

  /// Режим редактирования (true) или создания (false)
  final bool isEdit;

  /// ID сущности для редактирования (null для режима создания)
  final String? id;

  @override
  Widget build(BuildContext context) {
    switch (entity) {
      case EntityType.password:
        return PasswordFormScreen(passwordId: id);
      case EntityType.note:
        return NoteFormScreen(noteId: id);
      case EntityType.bankCard:
        return BankCardFormScreen(bankCardId: id);
      case EntityType.file:
        return FileFormScreen(fileId: id);
      case EntityType.otp:
        return OtpFormScreen(otpId: id);
    }
  }
}
