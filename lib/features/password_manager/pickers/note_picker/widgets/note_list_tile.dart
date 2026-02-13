import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';

/// Элемент списка заметок
class NoteListTile extends StatelessWidget {
  final NoteCardDto note;
  final VoidCallback onTap;
  final Widget? trailing;

  const NoteListTile({
    super.key,
    required this.note,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        note.title,
        style: Theme.of(context).textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: note.description != null
          ? Text(
              note.description!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.note,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      trailing:
          trailing ??
          (note.isFavorite
              ? Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                )
              : null),
      onTap: onTap,
    );
  }
}
