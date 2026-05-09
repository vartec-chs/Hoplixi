# Action Items from \_buildActionItems

This document lists all action items defined in the `_buildActionItems` method
of `HomeScreen`.

## Action Items

| Icon                     | Label               | Description                                               | Primary | Dev Only |
| ------------------------ | ------------------- | --------------------------------------------------------- | ------- | -------- |
| `LucideIcons.folderOpen` | Открыть             | Существующее хранилище                                    | Yes     | No       |
| `LucideIcons.plus`       | Создать             | Новое хранилище                                           | No      | No       |
| `LucideIcons.key`        | Генератор           | Генерация паролей                                         | No      | No       |
| `LucideIcons.send`       | LocalSend           | Отправка данных по локальной сети в том числе и хранилища | No      | No       |
| `LucideIcons.archive`    | Архивация хранилища | Упаковать хранилище в архив или распаковать из архива     | No      | No       |
| `LucideIcons.image`      | Паки иконок         | Импорт и каталог пользовательских SVG-паков               | No      | No       |
| `LucideIcons.cloud`      | Cloud Sync          | Центр управления облачной синхронизацией и токенами.      | No      | No       |
| `LucideIcons.box`        | Component Showcase  | Тестовый экран для UI-компонентов                         | No      | Yes      |

## Notes

- Items marked as "Dev Only" are only shown when `!MainConstants.isProduction`.
- All items have showcase keys and descriptions for onboarding.

## Recent Database Card

The `RecentDatabaseCard` widget displays information about the most recently
accessed database from the history. It provides quick access to open the
database and manage cloud sync operations.

### Features

- **Database Info Display**: Shows the database name, description, file path,
  and last modified date.
- **Cloud Sync Integration**: If the database has cloud sync configured,
  displays the provider logo and allows checking for newer versions from the
  cloud.
- **Cloud Lock Handling**: Checks for cloud locks to prevent concurrent access
  from multiple devices. Shows status banners during lock checking/releasing.
- **Biometric Authentication**: If password saving is enabled and biometrics are
  configured, prompts for biometric confirmation before opening.
- **Key File Support**: Handles optional key files for additional security
  layer.
- **Password Management**: Supports saved passwords with biometric protection,
  or prompts for manual password entry.
- **Attempt Limiting**: Implements password attempt limiting to prevent
  brute-force attacks.
- **Migration Support**: Handles database migrations if needed during opening.
- **History Management**: Allows removing the database from history without
  deleting files.

### UI Display Details

The card displays the following elements in order:

1. **Header Row**:
   - Storage icon (LucideIcons.storage_rounded) in primary color
   - Title "Недавнее хранилище" in bold primary color
   - Delete button (trash icon) in error color for removing from history

2. **Database Name**:
   - Displayed as headlineSmall with bold font weight

3. **Description** (optional):
   - Shows if description exists and is not empty
   - Displayed as bodyMedium with onSurfaceVariant color
   - Limited to 2 lines with ellipsis overflow

4. **File Path**:
   - Full path to the database file
   - Displayed as bodySmall with outline color
   - Limited to 1 line with ellipsis overflow

5. **Cloud Sync Status** (if configured):
   - Container with rounded corners
   - Provider logo (20px) and text "Подключен Cloud Sync: [Provider Name]"
   - Displayed as bodySmall with onSurface color and semi-bold weight

6. **Action Buttons**:
   - **Cloud Version Check** (if cloud sync enabled):
     - Label: "Проверить и установить новую версию" or progress label
     - Outlined button with provider logo
     - Disabled during opening or checking
   - **Open Button**:
     - Label: "Открыть" or "Открытие..." during loading
     - Tonal button with folderOpen icon
     - Disabled during opening

7. **Status Banners** (conditional):
   - **Lock Checking**: "Проверяем cloud lock" with progress indicator
   - **Lock Releasing**: "Закрываем cloud-сессию" with progress indicator
   - Shows when cloud lock operations are in progress

8. **Progress Panel** (during cloud version check):
   - Displays current sync stage, step progress, title, and description

### Actions

- **Open Database**: Opens the database with appropriate authentication (saved
  password, biometrics, manual entry, key file).
- **Check Cloud Version**: Downloads and applies newer versions from cloud sync
  if available.
- **Delete from History**: Removes the entry from recent databases history.

### Security Features

- Password attempt blocking after failed attempts.
- Biometric confirmation for saved passwords.
- Key file validation by ID.
- Cloud lock enforcement to prevent data corruption.
