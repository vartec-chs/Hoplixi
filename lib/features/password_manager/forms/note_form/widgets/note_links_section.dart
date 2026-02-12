import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/providers/note_form_provider.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

/// Секция для отображения связей между заметками
class NoteLinksSection extends ConsumerWidget {
  const NoteLinksSection({required this.noteId, super.key});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteLinkDaoAsync = ref.watch(noteLinkDaoProvider);
    final formState = ref.watch(noteFormProvider);

    // Показываем количество связей из стейта формы (в реальном времени)
    final currentLinksCount = formState.linkedNoteIds.length;

    return noteLinkDaoAsync.when(
      data: (dao) {
        return FutureBuilder<Map<String, dynamic>>(
          future: dao.getAllLinks(noteId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              // Показываем счетчик из стейта пока загружается
              if (currentLinksCount > 0) {
                return _buildQuickCounter(context, currentLinksCount);
              }
              return const SizedBox.shrink();
            }

            final data = snapshot.data!;
            final outgoing = data['outgoing'] as List<NoteCardDto>;
            final incoming = data['incoming'] as List<NoteCardDto>;
            final hasLinks =
                outgoing.isNotEmpty ||
                incoming.isNotEmpty ||
                currentLinksCount > 0;

            if (!hasLinks) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Нет связей с другими заметками',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            return Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.link, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Связи',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (outgoing.isNotEmpty)
                          Chip(
                            label: Text('→ ${outgoing.length}'),
                            visualDensity: VisualDensity.compact,
                          ),
                        // Показываем несохраненные изменения
                        if (currentLinksCount != outgoing.length)
                          Chip(
                            label: Text('→ $currentLinksCount*'),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            visualDensity: VisualDensity.compact,
                          ),
                        if (outgoing.isNotEmpty && incoming.isNotEmpty)
                          const SizedBox(width: 8),
                        if (incoming.isNotEmpty)
                          Chip(
                            label: Text('← ${incoming.length}'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    if (outgoing.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Исходящие (ссылки на другие заметки)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      ...outgoing.map(
                        (note) => _NoteLinkTile(
                          note: note,
                          icon: Icons.arrow_forward,
                        ),
                      ),
                    ],
                    if (incoming.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Входящие (ссылаются на эту заметку)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      ...incoming.map(
                        (note) =>
                            _NoteLinkTile(note: note, icon: Icons.arrow_back),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Ошибка загрузки ссылок')),
    );
  }

  /// Быстрый счетчик связей (пока загружается полная информация)
  Widget _buildQuickCounter(BuildContext context, int count) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.link, size: 20),
            const SizedBox(width: 8),
            Text('Связи', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Chip(
              label: Text('→ $count*'),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Text(
              'Сохраните для обновления',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteLinkTile extends StatelessWidget {
  const _NoteLinkTile({required this.note, required this.icon});

  final NoteCardDto note;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 16),
      title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: note.description != null
          ? Text(
              note.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.isFavorite)
            Icon(
              Icons.star,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          if (note.usedCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${note.usedCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16),
        ],
      ),
      onTap: () {
        context.pushNamed(
          'entity_edit',
          pathParameters: {'entity': EntityType.note.id, 'id': note.id},
        );
        //TODO: ПОД ВОПРОСОМ
      },
    );
  }
}
