import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

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
        note.item.name,
        style: Theme.of(context).textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: note.item.description != null
          ? Text(
              note.item.description!,
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
          (note.item.isFavorite
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
