# CHANGELOG

## 2026-04-14

- docs: в AGENT.md добавлено обязательное правило для агента фиксировать
  изменения в корневом CHANGELOG.md после любых правок
- feat(password_manager): добавлена настройка стора для управления инкрементом
  `usedCount` при копировании данных
- refactor(password_manager): логика копирования и условного `incrementUsage`
  вынесена в общий util
  `lib/features/password_manager/shared/utils/copy_usage_utils.dart`
- refactor(password_manager): карточки в
  `lib/features/password_manager/dashboard/widgets/cards` переведены на общий
  util копирования вместо локального дублирования `Clipboard.setData` и
  `incrementUsage`
- refactor(password_manager): `view_screen.dart` в
  `lib/features/password_manager/forms` с существующим `incrementUsage`
  переведены на тот же общий util
