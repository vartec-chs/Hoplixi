part of '../open_store_cloud_import_screen.dart';

class _RemoteSnapshotCard extends StatelessWidget {
  const _RemoteSnapshotCard({
    required this.entry,
    required this.provider,
    required this.accountLabel,
    required this.isDownloading,
    required this.isDeleting,
    required this.onDownload,
    required this.onDelete,
  });

  final CloudManifestStoreEntry entry;
  final CloudSyncProvider provider;
  final String accountLabel;
  final bool isDownloading;
  final bool isDeleting;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final updatedAt = entry.updatedAt.toLocal();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Icon(provider.metadata.icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.storeName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${provider.metadata.displayName} · $accountLabel'),
                  const SizedBox(height: 4),
                  Text('Revision: ${entry.revision}'),
                  Text(
                    'Updated: ${updatedAt.day.toString().padLeft(2, '0')}.${updatedAt.month.toString().padLeft(2, '0')}.${updatedAt.year} '
                    '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SmoothButton(
                  label: 'Скачать',
                  onPressed: isDownloading || isDeleting ? null : onDownload,
                  loading: isDownloading,
                  icon: const Icon(Icons.download_outlined),
                  size: SmoothButtonSize.small,
                ),
                const SizedBox(height: 8),
                if (isDeleting)
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Удалить snapshot из облака',
                    onPressed: isDownloading ? null : onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
