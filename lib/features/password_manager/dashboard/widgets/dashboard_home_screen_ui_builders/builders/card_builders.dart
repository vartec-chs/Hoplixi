part of 'dashboard_home_builders.dart';

Widget _buildDashboardListCardFor({
  required BuildContext context,
  required WidgetRef ref,
  required EntityType type,
  required BaseCardDto item,
  required DashboardCardCallbacks callbacks,
  required bool isBulkMode,
  required bool isSelected,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
  required void Function(String id) onOpenView,
  bool isDismissible = true,
}) {
  final noCorrectType = Text(
    'No correct type for $type',
    style: const TextStyle(color: Colors.red),
  );

  final location = GoRouterState.of(context).uri.toString();

  Widget card;
  switch (type) {
    case EntityType.password:
      if (item is! PasswordCardDto) return noCorrectType;
      card = PasswordListCard(
        password: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.password,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.password,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.note:
      if (item is! NoteCardDto) return noCorrectType;
      card = NoteListCard(
        note: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.note,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.note,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.bankCard:
      if (item is! BankCardCardDto) return noCorrectType;
      card = BankCardListCard(
        bankCard: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () => {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.bankCard,
                item.id,
              ))
            {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.bankCard,
                  item.id,
                ),
              ),
            },
        },
      );
      break;
    case EntityType.file:
      if (item is! FileCardDto) return noCorrectType;
      card = FileListCard(
        file: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onDecrypt: () => showFileDecryptModal(context, item),
        onOpenHistory: () => {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.file,
                item.id,
              ))
            {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.file,
                  item.id,
                ),
              ),
            },
        },
      );
      break;
    case EntityType.otp:
      if (item is! OtpCardDto) return noCorrectType;
      card = TotpListCard(
        otp: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () => {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.otp,
                item.id,
              ))
            {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.otp,
                  item.id,
                ),
              ),
            },
        },
      );
      break;
    case EntityType.document:
      if (item is! DocumentCardDto) return noCorrectType;
      card = DocumentListCard(
        document: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onDecrypt: () => showDocumentDecryptModal(context, item),
        onOpenHistory: () => {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.document,
                item.id,
              ))
            {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.document,
                  item.id,
                ),
              ),
            },
        },
      );
      break;
    case EntityType.apiKey:
      if (item is! ApiKeyCardDto) return noCorrectType;
      card = ApiKeyListCard(
        apiKey: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.apiKey,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.apiKey,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.contact:
      if (item is! ContactCardDto) return noCorrectType;
      card = ContactListCard(
        contact: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.contact,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.contact,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.sshKey:
      if (item is! SshKeyCardDto) return noCorrectType;
      card = SshKeyListCard(
        sshKey: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.sshKey,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.sshKey,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.certificate:
      if (item is! CertificateCardDto) return noCorrectType;
      card = CertificateListCard(
        certificate: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.certificate,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.certificate,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.cryptoWallet:
      if (item is! CryptoWalletCardDto) return noCorrectType;
      card = CryptoWalletListCard(
        wallet: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.cryptoWallet,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.cryptoWallet,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.wifi:
      if (item is! WifiCardDto) return noCorrectType;
      card = WifiListCard(
        wifi: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.wifi,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.wifi,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.identity:
      if (item is! IdentityCardDto) return noCorrectType;
      card = IdentityListCard(
        identity: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.identity,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.identity,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.licenseKey:
      if (item is! LicenseKeyCardDto) return noCorrectType;
      card = LicenseKeyListCard(
        license: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.licenseKey,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.licenseKey,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.recoveryCodes:
      if (item is! RecoveryCodesCardDto) return noCorrectType;
      card = RecoveryCodesListCard(
        recoveryCodes: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.recoveryCodes,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.recoveryCodes,
                item.id,
              ),
            );
          }
        },
      );
      break;
    case EntityType.loyaltyCard:
      if (item is! LoyaltyCardCardDto) return noCorrectType;
      card = LoyaltyCardListCard(
        loyaltyCard: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
        onOpenHistory: () {
          if (location !=
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.loyaltyCard,
                item.id,
              )) {
            context.push(
              AppRoutesPaths.dashboardHistoryWithParams(
                EntityType.loyaltyCard,
                item.id,
              ),
            );
          }
        },
      );
      break;
  }

  final wrappedCard = _wrapDashboardInteractiveCard(
    context: context,
    child: card,
    itemId: item.id,
    isBulkMode: isBulkMode,
    isSelected: isSelected,
    onItemTap: onItemTap,
    onItemLongPress: onItemLongPress,
  );

  if (!isDismissible) return wrappedCard;

  return _buildDashboardDismissible(
    context: context,
    ref: ref,
    child: wrappedCard,
    item: item,
    type: type,
    callbacks: callbacks,
  );
}

Widget _buildDashboardDismissible({
  required BuildContext context,
  required WidgetRef ref,
  required Widget child,
  required BaseCardDto item,
  required EntityType type,
  required DashboardCardCallbacks callbacks,
}) {
  final isDeleted = item.isDeleted;

  return Dismissible(
    key: ValueKey(item.id),
    direction: DismissDirection.horizontal,
    background: Container(
      decoration: BoxDecoration(
        color: isDeleted
            ? Colors.green
            : (item.isArchived ? Colors.orangeAccent : Colors.blueAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: Icon(
        isDeleted
            ? Icons.restore
            : (item.isArchived ? Icons.unarchive : Icons.edit),
        color: Colors.white,
      ),
    ),
    secondaryBackground: Container(
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerRight,
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (direction) async {
      if (direction == DismissDirection.startToEnd) {
        if (isDeleted) {
          callbacks.onRestore(item.id);
          return false;
        } else if (item.isArchived) {
          callbacks.onToggleArchive(item.id);
          return false;
        }

        if (item is PasswordCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.password,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is BankCardCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.bankCard,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is NoteCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.note,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is OtpCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.otp,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is FileCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.file,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is DocumentCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.document,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is ApiKeyCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.apiKey,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is ContactCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.contact,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is SshKeyCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.sshKey,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is CertificateCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.certificate,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is CryptoWalletCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.cryptoWallet,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is WifiCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.wifi,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is IdentityCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.identity,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is LicenseKeyCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.licenseKey,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is RecoveryCodesCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.recoveryCodes,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        } else if (item is LoyaltyCardCardDto) {
          final path = AppRoutesPaths.dashboardEntityEdit(
            EntityType.loyaltyCard,
            item.id,
          );
          if (GoRouter.of(context).state.matchedLocation != path) {
            context.push(path);
          }
        }

        return false;
      } else {
        String itemName = 'неизвестный элемент';
        if (item is PasswordCardDto) {
          itemName = item.name;
        } else if (item is BankCardCardDto) {
          itemName = item.name;
        } else if (item is NoteCardDto) {
          itemName = item.title;
        } else if (item is OtpCardDto) {
          itemName = item.accountName ?? 'OTP';
        } else if (item is FileCardDto) {
          itemName = item.name;
        } else if (item is DocumentCardDto) {
          itemName = item.title ?? 'Документ';
        } else if (item is ApiKeyCardDto) {
          itemName = item.name;
        } else if (item is ContactCardDto) {
          itemName = item.name;
        } else if (item is SshKeyCardDto) {
          itemName = item.name;
        } else if (item is CertificateCardDto) {
          itemName = item.name;
        } else if (item is CryptoWalletCardDto) {
          itemName = item.name;
        } else if (item is WifiCardDto) {
          itemName = item.name;
        } else if (item is IdentityCardDto) {
          itemName = item.name;
        } else if (item is LicenseKeyCardDto) {
          itemName = item.name;
        } else if (item is RecoveryCodesCardDto) {
          itemName = item.name;
        } else if (item is LoyaltyCardCardDto) {
          itemName = item.name;
        }

        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Удалить?'),
            content: Text("Вы уверены, что хотите удалить '$itemName'?"),
            actions: [
              SmoothButton(
                type: SmoothButtonType.text,
                onPressed: () => Navigator.pop(dialogContext, false),
                label: 'Отмена',
              ),
              SmoothButton(
                type: SmoothButtonType.filled,
                variant: SmoothButtonVariant.error,
                onPressed: () => Navigator.pop(dialogContext, true),
                label: 'Удалить',
              ),
            ],
          ),
        );
        return shouldDelete ?? false;
      }
    },
    onDismissed: (_) {
      callbacks.onLocalRemove(item.id);
      callbacks.onDelete(item.id, item.isDeleted);
    },
    child: child,
  );
}

Widget _buildDashboardGridCardFor({
  required BuildContext context,
  required WidgetRef ref,
  required EntityType type,
  required BaseCardDto item,
  required DashboardCardCallbacks callbacks,
  required bool isBulkMode,
  required bool isSelected,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
  required void Function(String id) onOpenView,
}) {
  final noCorrectType = Text(
    'No correct type for $type',
    style: const TextStyle(color: Colors.red),
  );

  Widget card;
  switch (type) {
    case EntityType.password:
      if (item is! PasswordCardDto) return noCorrectType;
      card = PasswordGridCard(
        password: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.note:
      if (item is! NoteCardDto) return noCorrectType;
      card = NoteGridCard(
        note: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.bankCard:
      if (item is! BankCardCardDto) return noCorrectType;
      card = BankCardGridCard(
        bankCard: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.file:
      if (item is! FileCardDto) return noCorrectType;
      card = FileGridCard(
        file: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onDecrypt: () => showFileDecryptModal(context, item),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.otp:
      if (item is! OtpCardDto) return noCorrectType;
      card = TotpGridCard(
        otp: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.document:
      if (item is! DocumentCardDto) return noCorrectType;
      card = DocumentGridCard(
        document: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onDecrypt: () => showDocumentDecryptModal(context, item),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.apiKey:
      if (item is! ApiKeyCardDto) return noCorrectType;
      card = ApiKeyGridCard(
        apiKey: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.contact:
      if (item is! ContactCardDto) return noCorrectType;
      card = ContactGridCard(
        contact: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.sshKey:
      if (item is! SshKeyCardDto) return noCorrectType;
      card = SshKeyGridCard(
        sshKey: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.certificate:
      if (item is! CertificateCardDto) return noCorrectType;
      card = CertificateGridCard(
        certificate: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.cryptoWallet:
      if (item is! CryptoWalletCardDto) return noCorrectType;
      card = CryptoWalletGridCard(
        wallet: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.wifi:
      if (item is! WifiCardDto) return noCorrectType;
      card = WifiGridCard(
        wifi: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.identity:
      if (item is! IdentityCardDto) return noCorrectType;
      card = IdentityGridCard(
        identity: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.licenseKey:
      if (item is! LicenseKeyCardDto) return noCorrectType;
      card = LicenseKeyGridCard(
        license: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.recoveryCodes:
      if (item is! RecoveryCodesCardDto) return noCorrectType;
      card = RecoveryCodesGridCard(
        recoveryCodes: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
    case EntityType.loyaltyCard:
      if (item is! LoyaltyCardCardDto) return noCorrectType;
      card = LoyaltyCardGridCard(
        loyaltyCard: item,
        onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
        onTogglePin: () => callbacks.onTogglePin(item.id),
        onToggleArchive: () => callbacks.onToggleArchive(item.id),
        onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
        onRestore: () => callbacks.onRestore(item.id),
        onOpenView: () => onOpenView(item.id),
      );
      break;
  }

  return _wrapDashboardInteractiveCard(
    context: context,
    child: card,
    itemId: item.id,
    isBulkMode: isBulkMode,
    isSelected: isSelected,
    onItemTap: onItemTap,
    onItemLongPress: onItemLongPress,
  );
}
