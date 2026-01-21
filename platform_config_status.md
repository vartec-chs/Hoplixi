# Статус платформенных конфигураций для зависимостей

Этот файл отслеживает статус платформенных изменений для зависимостей в
`pubspec.yaml`. Галочки (✅) указывают на библиотеки, требующие платформенных
изменений, которые уже выполнены.

## Библиотеки, требующие платформенных изменений (выполнены ✅)

- **permission_handler**: Добавлены разрешения в `AndroidManifest.xml` (CAMERA,
  LOCATION, STORAGE, BIOMETRIC). Все ключи описания разрешений в `Info.plist`
  для iOS. Макросы разрешений в `Podfile`.
- **flutter_secure_storage**: `android:allowBackup="false"` в
  `AndroidManifest.xml`. `keychain-access-groups` в entitlements для iOS.
- **local_auth**: `MainActivity` изменен на `FlutterFragmentActivity`, добавлено
  разрешение `USE_BIOMETRIC`, тема `Theme.AppCompat.DayNight` в `styles.xml`.
  Ключ `NSFaceIDUsageDescription` в `Info.plist`.
- **image_picker**: Ключи `NSPhotoLibraryUsageDescription`,
  `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` в `Info.plist`. Код
  `retrieveLostData()` в `main.dart` для Android. Entitlement
  `com.apple.security.files.user-selected.read-only` для macOS.
- **mobile_scanner**: Ключ `NSCameraUsageDescription` в `Info.plist`.
  `dev.steenbakker.mobile_scanner.useUnbundled=true` в `gradle.properties`.
- **screen_protector**: Переопределение `onWindowFocusChanged` в
  `MainActivity.kt` для Android.
- **device_info_plus**: Entitlement
  `com.apple.developer.device-information.user-assigned-device-name` в
  entitlements для iOS.
- **open_file**: FileProvider конфигурация в `AndroidManifest.xml` с
  `tools:replace` для разрешения конфликтов. Файл `res/xml/filepaths.xml`
  создан. Entitlement `com.apple.security.files.user-selected.read-only` для
  macOS.
- **file_picker**: `use_frameworks!` в `Podfile`. Ключи `UIBackgroundModes`,
  `NSAppleMusicUsageDescription`, `UISupportsDocumentBrowser`,
  `LSSupportsOpeningDocumentsInPlace` в `Info.plist`. Entitlement
  `com.apple.security.files.user-selected.read-only` для macOS.

## Библиотеки, не требующие платформенных изменений

- flex_color_scheme
- package_info_plus
- device_info_plus (частично выполнено, см. выше)
- archive
- uuid
- crypto
- pointycastle
- smooth_page_indicator
- synchronized
- cupertino_icons
- flutter_riverpod
- riverpod
- freezed
- freezed_annotation
- freezed_lint
- json_annotation
- sqlcipher_flutter_libs
- drift
- google_fonts
- font_awesome_flutter
- go_router
- toastification
- flutter_svg
- tray_manager
- shared_preferences
- hive_ce
- hive_ce_flutter
- animations
- path
- path_provider
- flutter_dotenv
- get_it
- flutter_launcher_icons
- result_dart
- universal_platform
- logger
- intl
- window_manager
- animated_text_kit
- animated_theme_switcher
- wolt_modal_sheet
- dotted_border
- infinite_scroll_pagination
- pinput
- flutter_colorpicker
- image
- flutter_expandable_fab
- sliver_tools
- flutter_resizable_container
- flutter_credit_card
- flutter_quill
- otp
- zxing2
- image_cropper
- crop_image
- pasteboard
- cryptography
- mime
- watcher
- protobuf
- lucide_icons_flutter
- flutter_graph_view
- file_crypto (локальный)
- cloud_storage_all (локальный)
- build_config

## Примечания

- Все изменения применены на основе документации на январь 2026 года.
- Для Android: изменения в `AndroidManifest.xml`, `MainActivity.kt`,
  `build.gradle.kts`, `styles.xml`, `gradle.properties`.
- Для iOS: изменения в `Info.plist`, `DebugProfile.entitlements`,
  `Release.entitlements`.
- Для macOS/Windows/Linux: изменения в entitlements или другие файлы, где
  применимо.
- Рекомендуется пересобрать приложение после изменений:
  `flutter clean && flutter pub get && flutter run`.
