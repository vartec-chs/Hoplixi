# Shared UI Components (`lib/shared/ui/`)

This document is the source of truth for reusable UI components located in
`lib/shared/ui/`.

## Rules

- Prefer these components over ad-hoc local UI implementations.
- Keep visual and behavior consistency across features.
- `universal_modal.dart` is legacy and should not be used in new code.

## Components by File

### `button.dart`

- `SmoothButton`
- Enums: `SmoothButtonType`, `SmoothButtonSize`, `SmoothButtonIconPosition`,
  `SmoothButtonVariant`
- Use for primary/secondary button actions instead of raw Material buttons.

### `copy_to_clipboard_button.dart`

- `CopyToClipboardIconButton`
- `CopySmoothButton`
- Use for copy-to-clipboard actions with local success state (check icon).

### `modal_sheet_close_button.dart`

- `ModalSheetCloseButton`
- Use as default close action in modal/sheet headers.

### `confirmation_bottom_modal.dart`

- `ConfirmationBottomModal`
- Use for action confirmations in a bottom-positioned rectangular modal with
  fixed external spacing (12px left/right/bottom).
- Supports optional `title`, `description`, custom `body` (including `Slider`),
  and optional confirm/decline actions.

### `notification_card.dart`

- `NotificationCard`
- `ErrorNotificationCard`, `SuccessNotificationCard`, `InfoNotificationCard`,
  `WarningNotificationCard`
- Enum: `NotificationType`
- Use for inline notifications and status feedback blocks.

### `password_generator_widget.dart`

- `PasswordGeneratorWidget`
- Use when a full password generator UI is needed (length, charset, copy,
  strength visualization, optional submit callback).

### `password_strength_indicator.dart`

- `PasswordStrengthIndicator`
- Use to display password strength score and semantic status label.

### `slider_button.dart`

- `SliderButton`
- `SliderButtonTheme`, `SliderButtonThemeData`, `SliderButtonThemes`
- Enums: `SliderButtonType`, `SliderButtonVariant`,
  `SliderButtonCompletionAnimation`
- Use for confirmation-style gestures (confirm/delete/unlock/send).

### `text_field.dart`

- `primaryInputDecoration`
- `PrimaryTextField`
- `PrimaryTextFormField`
- `PasswordField`
- `CustomOutlineInputBorder`
- Use for all app text input styling and consistent field behavior.

### `type_chip.dart`

- `TypeChip`
- Use for selectable filter/type chips with focus and keyboard support.

### `universal_modal.dart` (legacy)

- `UniversalModal`
- `UniversalModalContent`
- Status: do not use in new code. Prefer `WoltModalSheet` or native Flutter
  dialogs according to feature requirements.
