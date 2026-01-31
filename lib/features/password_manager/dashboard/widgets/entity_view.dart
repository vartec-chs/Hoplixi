import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/forms/bank_card_form/screens/bank_card_view_screen.dart';
import 'package:hoplixi/features/password_manager/forms/document_form/screens/document_view_screen.dart';
import 'package:hoplixi/features/password_manager/forms/file_form/screens/file_view_screen.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/screens/note_view_screen.dart';
import 'package:hoplixi/features/password_manager/forms/otp_form/screens/otp_view_screen.dart';
import 'package:hoplixi/features/password_manager/forms/password_form/screens/password_view_screen.dart';

/// Виджет-обертка для просмотра сущностей
/// Возвращает соответствующий экран просмотра в зависимости от типа сущности
class EntityView extends StatelessWidget {
  const EntityView({super.key, required this.entity, required this.id});

  /// Тип сущности
  final EntityType entity;

  /// ID сущности для просмотра
  final String id;

  @override
  Widget build(BuildContext context) {
    switch (entity) {
      case EntityType.password:
        return PasswordViewScreen(passwordId: id);
      case EntityType.note:
        return NoteViewScreen(noteId: id);
      case EntityType.bankCard:
        return BankCardViewScreen(bankCardId: id);
      case EntityType.file:
        return FileViewScreen(fileId: id);
      case EntityType.otp:
        return OtpViewScreen(otpId: id);
      case EntityType.document:
        return DocumentViewScreen(documentId: id);
    }
  }
}
