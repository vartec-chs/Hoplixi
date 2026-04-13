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
- fix(password_manager): исправлен сброс текста при вводе в фильтрах
  `lib/features/password_manager/dashboard/widgets/dashboard_home/filter_sections`
  за счет безопасной синхронизации `TextEditingController` в `didUpdateWidget`
- fix(local_send): большие текстовые сообщения теперь отправляются через
  `WebRtcTransferService` чанками по control-channel вместо одного большого
  JSON-сообщения, чтобы не забивать буфер DataChannel и не подвешивать систему
- chore(security): проверено, что в модуле qr_scanner не логируются
  отсканированные данные; в логах остаются только служебные события и формат
  кода
- fix(security): в otp_form_provider удалено логирование данных из сканирования
  (сырой OTP URI и issuer) при обработке QR-кода
- feat(logs_viewer): добавлено копирование конкретной записи лога по долгому
  нажатию на карточку
- improve(logs_viewer): переработан UX фильтрации (чипы уровней, dropdown по
  тегам, корректная очистка/синхронизация поисковой строки)
- improve(logs_viewer): поиск расширен по полям stack trace и additionalData,
  фильтр по тегу и поиск сделаны более устойчивыми к регистру/пробелам
- improve(logs_viewer): обновлен UI карточки лога (новая визуальная иерархия
  уровня/тегов, встроенная кнопка копирования, анимированное раскрытие деталей и
  форматирование дополнительных данных)
