# Hoplixi - Менеджер Паролей 🔐

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](https://www.rust-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

> **Hoplixi** - это современный, безопасный и удобный менеджер паролей для
> хранения, генерации и управления вашими учетными данными. Защитите свои
> онлайн-аккаунты с помощью мощного шифрования и интуитивного интерфейса.

<img src="assets/logo/logo.png" width="200" alt="Hoplixi Logo" />

## ✨ Особенности

### 🔒 Безопасность

- **Военное шифрование**: AES-256 и SQLCipher для защиты баз данных
- **Шифрование файлов**: Все прикрепленные файлы и документы надежно шифруются
  алгоритмом XChaCha20 перед сохранением на накопитель
- **Биометрическая аутентификация**: Поддержка Touch ID / Face ID / Windows
  Hello
- **Локальное хранение**: Все данные хранятся исключительно локально на вашем
  устройстве
- **Мастер-пароль**: Дополнительный и главный уровень защиты вашего хранилища

### 🗂 Поддерживаемые типы данных

Hoplixi — это не просто менеджер паролей, а полноценное защищенное хранилище для
любых конфиденциальных данных:

- 🔑 **Учетные данные**: Пароли, OTP-коды (2FA), Коды восстановления
- 💳 **Финансы**: Банковские карты, Криптокошельки
- 📄 **Документы и файлы**: Заметки, Документы, Зашифрованные файлы
- 💻 **Разработка и IT**: API-ключи, SSH-ключи, Сертификаты, Лицензионные ключи
- 👤 **Личное**: Контакты, Личностные данные (паспорт), Wi-Fi сети

### 🕰 Система истории (Версионирование)

Каждое изменение ваших данных бережно сохраняется благодаря встроенной системе
истории:

- **Полный аудит**: Отслеживание всех операций (создание, изменение, удаление)
  для каждой записи.
- **Снапшоты данных**: Сохранение предыдущих состояний полей (например, старых
  паролей или прошлых версий заметок).
- **Безопасность от ошибок**: Возможность в любой момент просмотреть историю
  изменений и восстановить случайно измененные данные.

### 🚀 Функциональность

- **Генерация паролей**: Создание сильных, уникальных паролей
- **Автозаполнение**: Быстрое заполнение форм в браузерах и приложениях (пока не
  реализовано)
- **Категоризация**: Организация записей по категориям и тегам
- **Поиск**: Мгновенный поиск по всем сохраненным данным
- **Импорт/Экспорт**: Поддержка различных форматов обмена данными

### 📱 Кроссплатформенность

- **Android** и **iOS**: Мобильные приложения
- **Windows**, **Linux** и **macOS**: Десктопные версии

### 🔧 Дополнительные возможности

- **OTP Генератор**: Встроенный генератор одноразовых паролей (2FA)
- **QR-сканер**: Сканирование QR-кодов для быстрого добавления аккаунтов
- **Облачное синхронизирование**: Синхронизация между устройствами (в планах)
- **Виджеты**: Быстрый доступ к паролям с главного экрана
- **Темная тема**: Поддержка светлой и темной темы оформления (в будущем -
  кастомные темы)

## 📸 Скриншоты

- Главный экран приложения
  <img src="screenshots/main_screen.png" width="500" alt="Hoplixi Screenshot" />

- Дашборд (ПК)
  <img src="screenshots/dashboard_pc.png" width="800" alt="Hoplixi Dashboard PC" />

- Дашборд (ПК, режим редактирования)
  <img src="screenshots/dashboard_pc_edit_mode.png" width="800" alt="Hoplixi Dashboard PC Edit Mode" />

- Дашборд (мобильный)
  <img src="screenshots/dashboard_mobile.png" width="500" alt="Hoplixi Dashboard Mobile" />

- Дашборд (мобильный, режим редактирования)
  <img src="screenshots/dashboard_mobile_edit_mode.png" width="500" alt="Hoplixi Dashboard Mobile Edit Mode" />

## 🛠 Установка и запуск

### Предварительные требования

- [Flutter SDK](https://flutter.dev/docs/get-started/install) рекомендуется
  версия 3.10+
- [Rust](https://www.rust-lang.org/tools/install) для разработки и сборки
- [Dart SDK](https://dart.dev/get-dart) для мобильной разработки: Android Studio
  / Xcode

### Клонирование репозитория

```bash
git clone https://github.com/vartec-chs/Hoplixi
cd Hoplixi
```

### Установка зависимостей

```bash
flutter pub get
```

### Генерация кода

```bash
dart run build_runner build --delete-conflicting-outputs
```

`or is on Windows`

```bash
build_runner.bat
```

### Запуск приложения (dev mode)

#### Android

```bash
flutter run -d android
```

#### iOS

```bash
flutter run -d ios
```

#### Windows

```bash
flutter run -d windows
```

#### Linux

```bash
flutter run -d linux
```

#### macOS

```bash
flutter run -d macos
```

## 📖 Использование

### Первый запуск

1. Установите мастер-пароль при первом запуске
2. Настройте биометрическую аутентификацию (рекомендуется)
3. Добавьте свои первые учетные данные

### Добавление нового пароля

1. Нажмите кнопку "Создать" на главном экране
2. Выберите категорию или создайте новую
3. Введите данные аккаунта
4. Используйте генератор паролей для создания сильного пароля
5. Сохраните изменения

### Генерация OTP

1. Перейдите в раздел "OTP Генератор"
2. Отсканируйте QR-код или введите секретный ключ вручную
3. Используйте сгенерированные коды для двухфакторной аутентификации

## 🏗 Архитектура

Hoplixi построен с использованием современных технологий:

- **Flutter**: Кроссплатформенный UI фреймворк
- **Riverpod**: Управление состоянием
- **Drift**: ORM для работы с базой данных
- **SQLCipher**: Шифрование базы данных
- **Freezed**: Генерация иммутабельных моделей
- **Go Router**: Навигация между экранами
- **Rust**: Для оптимизации криптографических операций и т.п (в будущем)

### Структура проекта

```
lib/
├── app.dart                 # Главный виджет приложения
├── main.dart               # Точка входа
├── core/                   # Базовые сервисы и утилиты
│   ├── logger/            # Логирование
│   ├── services/          # Бизнес-логика
│   ├── theme/             # Темизация
│   └── utils/             # Утилиты
├── features/              # Функциональные модули
│   ├── home/              # Главный экран
│   ├── password_manager/  # Управление паролями
│   ├── settings/          # Настройки
│   └── ...
├── main_store/            # База данных и модели
├── routing/               # Навигация
└── shared/                # Общие компоненты
```

## 🔧 Разработка

### Структура стора

```
store_name/
├── store_name.hplxdb
├── attachments_decrypted/
└── attachments/
```

- attachments folder for encrypt files
- attachments_decrypted temporary decrypt files

### Окружения (Flavors)

Проект использует пакет `flutter_flavorizr` для управления окружениями.
Настройки описаны в файле `flavorizr.yaml`. Доступно два окружения:

- **dev**: Для разработки (имя приложения "Hoplixi Dev", bundleId
  `com.hiplixi.app.dev`)
- **prod**: Для релиза (имя приложения "Hoplixi", bundleId `com.hiplixi.app`)

Для генерации настроек окружений используется команда:

```bash
flutter pub run flutter_flavorizr
```

### Сборка для релиза

Для удобной сборки релизных версий в проекте предусмотрен скрипт
`build_prod.bat`. Он позволяет выбрать платформу и автоматически выполняет
необходимые команды, включая инкремент номера сборки (через `cider`) для
Android.

Запуск скрипта сборки:

```bash
build_prod.bat
```

#### Генерация Keystore для Android

Для подписи Android APK необходим keystore. Проект включает скрипты для
генерации debug и production keystore.

**Генерация debug keystore:**

```bash
android\create_debug_keystore.bat
```

Этот скрипт создаст `android/app/debug.keystore` с предустановленными
параметрами для отладки.

**Генерация production keystore:**

```bash
android\create_keystore.bat
```

Этот скрипт создаст `upload-keystore.jks` в папке `android`. Вам будет
предложено ввести информацию для сертификата (имя, организация и т.д.).
**Обязательно сделайте резервную копию этого файла и храните его в безопасном
месте!**

После генерации keystore, убедитесь, что файл `android/key.properties` содержит
правильные пути и пароли:

```
storePassword=ваш_пароль
keyPassword=ваш_пароль
keyAlias=upload
storeFile=../upload-keystore.jks
```

#### Ручная сборка Android APK (Prod)

```bash
flutter build apk --flavor prod --release
```

#### Ручная сборка iOS

```bash
flutter build ios --flavor prod --release
```

#### Ручная сборка Windows

Для сборки Windows версии используется утилита `fastforge`:

```bash
fastforge package --platform windows --targets exe
```

Или стандартными средствами Flutter:

```bash
flutter build windows --release
```

### Тестирование

```bash
flutter test
```

### Анализ кода

```bash
flutter analyze
```

### Форматирование

```bash
dart format .
```

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие Hoplixi! Вот как вы можете помочь:

1. **Fork** репозиторий
2. Создайте **feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit** изменения (`git commit -m 'Add some AmazingFeature'`)
4. **Push** в ветку (`git push origin feature/AmazingFeature`)
5. Откройте **Pull Request**

### Руководство по контрибьютингу

- Следуйте [Effective Dart](https://dart.dev/effective-dart) гайдлайнам
- Используйте [Flutter lints](https://pub.dev/packages/flutter_lints)
- Пишите тесты для нового функционала
- Обновляйте документацию при внесении изменений

## 💭 Планы после релиза

В планах на будущее:

- **Переписывание на Rust**: Переписать основную логику приложения на Rust для
  повышения производительности, безопасности и эффективности работы с памятью
- **Новые функции**: Auto-Type, Cloud Sync, Расширения для браузеров, LocalSend
  и многое другое
- **Улучшение UX**: Оптимизация интерфейса и добавление новых тем оформления и
  возможностей кастомизации

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Подробности в файле
[LICENSE](LICENSE).

## 🙏 Благодарности

- [Flutter](https://flutter.dev/) - за отличный фреймворк
- [Lucide Icons](https://lucide.dev/) - за красивые иконки
- [Riverpod](https://riverpod.dev/) - за управление состоянием
- [Drift](https://drift.simonbinder.eu/) - за удобную работу с базой данных
- [SQLCipher](https://www.zetetic.net/sqlcipher/) - за надежное шифрование
  данных
- [Rust](https://www.rust-lang.org/) - за мощный язык программирования для
  сложных задач
- Сообществу Flutter за поддержку и вдохновение

## 📞 Контакты

- **Автор**: [Кирилл](https://github.com/vartec-chs)
- **Email**: misticmvm@gmail.com
- **Telegram**: [@VartecCHS](https://t.me/VartecCHS)
- **Issues**: [GitHub Issues](https://github.com/vartec-chs/hoplixi/issues)

---

<p align="center">
  <b>Hoplixi</b> - Ваш надежный страж цифровой безопасности! 🛡️
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/vartec-chs/hoplixi?style=social" alt="Stars">
  <img src="https://img.shields.io/github/forks/vartec-chs/hoplixi?style=social" alt="Forks">
  <img src="https://img.shields.io/github/watchers/vartec-chs/hoplixi?style=social" alt="Watchers">
</p>
