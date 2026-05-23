---
name: dart-slang-i18n
description:
  "Use this skill whenever the user asks to add translations ('добавь перевод'),
  localize text, or manage internationalization (i18n) using the `slang` package
  with `.i18n.arb` files. It handles modular translations (namespaces), string
  formatting, plurals, linked translations, and running code generation."
---

# Slang i18n (Modular ARB Workflow)

This project uses the `slang` package for type-safe internationalization,
configured to use `.i18n.arb` files with **namespaces** (modules) enabled.

## Possibilities

```dart
final t = Translations.of(context); // there is also a static getter without context

String a = t.mainScreen.title;                         // simple use case
String b = t.game.end.highscore(score: 32.6);          // with parameters
String c = t.$wip('Password Forgotten');               // fast prototyping
String d = t.items(n: 2);                              // with pluralization
String e = t.greet(name: 'Tom', context: Gender.male); // with custom context
String f = t.greet(today: DateTime.now());             // with L10n
String g = t.intro.step[4];                            // with index
String h = t.error.type['WARNING'];                    // with dynamic key
String i = t['mainScreen.title'];                      // with fully dynamic key
TextSpan j = t.greet(name: TextSpan(text: 'Tom'));     // with RichText

PageData page0 = t.onboarding.pages[0];                // with interfaces
PageData page1 = t.onboarding.pages[1];
String k = page1.title; // type-safe call
```

## Commands

```bash
dart run slang                               # generate dart file
dart run slang analyze                       # unused and missing translations
dart run slang normalize                     # sort translations according to base locale
dart run slang configure                     # automatically update CFBundleLocalizations
dart run slang edit move loginPage authPage  # move or rename translations
dart run slang migrate arb src.arb dest.json # migrate arb to json
```

## File Structure and Namespaces (Modules)

Translations are split into modules to keep them organized. The naming
convention for these files is `<namespace>_<locale>.i18n.arb` or they are
organized in directories (e.g., `lib/i18n/<namespace>_<locale>.i18n.arb` or
`lib/i18n/en/<namespace>.i18n.arb`).

If you are told to add a translation to the "auth" module, look for or create
files like:

- `auth_en.i18n.arb`
- `auth_ru.i18n.arb`

If no module is specified, ask the user or look for a generic module (like
`common`, `core`, or `_default` for the root namespace).

## Workflow

1. **Locate the correct module file**: Find the `.i18n.arb` file corresponding
   to the requested module and locale.
2. **Add translations**: Insert your keys. Keys in ARB must be flat (no nested
   objects).
3. **Generate code**: ALWAYS run the code generator after editing translation
   files to update `strings.g.dart`.
   ```bash
   dart run slang
   ```
4. **Use in code**: Import the generated file. Access the translation via the
   namespace:
   ```dart
   final text = t.auth.login_success; // t.<namespace>.<key>
   ```

## File Types

`slang` supports multiple input formats, but this skill is optimized for
`.i18n.arb`.

- `*.i18n.arb`: best fit for Flutter projects using ARB-style localization.
- `*.i18n.json`: also supported, but this skill should prefer ARB when the user
  explicitly asks for it.
- `*.i18n.yaml` and `*.i18n.csv`: supported by `slang`, but only use them if the
  repository already uses those formats.

When the user says "добавь перевод", default to ARB files unless the repo or the
prompt clearly points to another format.

## String Interpolation

ARB uses braces interpolation. Keep variable names stable and match the
generated Dart signature.

- **Example in ARB**: `"login_greet": "Welcome {name}"`
- **Usage in Dart**: `t.auth.login_greet(name: 'Alice')`

Prefer braces for all placeholder values, including numbers and dates when the
key is meant to stay type-safe.

## RichText

Add `(rich)` to the key when one translation needs inline styling or clickable
segments.

- **Example in ARB**:
  ```json
  {
  	"myText(rich)": "Welcome {name}. Please tap {tapHere(here)}!"
  }
  ```
- **Usage in Dart**:
  ```dart
  Text.rich(t.moduleName.myText(
    name: 'Alice',
    tapHere: (text) => TextSpan(text: text),
  ))
  ```

Use RichText only when the content actually needs mixed styling or interactive
spans. Otherwise keep the translation plain.

## Lists

Lists are fully supported. No extra configuration is needed. You can also put
lists or maps inside lists when the translation data calls for it.

- **Example in ARB**:
  ```json
  {
  	"niceList": [
  		"hello",
  		"nice",
  		["first item in nested list", "second item in nested list"],
  		{
  			"wow": "WOW!",
  			"ok": "OK!"
  		},
  		{
  			"a map entry": "access via key",
  			"another entry": "access via second key"
  		}
  	]
  }
  ```
- **Usage in Dart**:
  ```dart
  String a = t.niceList[1];
  String b = t.niceList[2][0];
  String c = t.niceList[3].ok;
  String d = t.niceList[4]['a map entry'];
  ```

## Maps

Maps are useful when you want string-keyed access rather than a plain class
shape. This is a good fit for categories, dynamic labels, and keyed lookups.

- **Example in ARB**:
  ```json
  {
  	"error(map)": {
  		"warning": "Warning",
  		"critical": "Critical"
  	}
  }
  ```
- **Usage in Dart**:
  ```dart
  final warning = t.error['warning'];
  ```

Use maps when the set of keys is naturally string-driven and you want access by
name instead of a fixed class member. If the project prefers a global config,
the same idea can be declared through the `maps:` section in `slang.yaml`.

## Dynamic Keys

Dynamic keys let you access translations with a string path when the exact key
is not known at compile time.

- **Example**:
  ```dart
  final title = t['mainScreen.title'];
  final item = t['myPath.anotherPath.3'];
  final greeting = t['myPath.anotherPath'](name: 'Tom');
  ```

Use dynamic keys for prototyping, data-driven UIs, or places where the full key
path is assembled at runtime. Prefer normal typed access when the path is known
ahead of time.

## Changing Locale

Use the built-in locale helpers when the skill needs to explain switching the
current language or wiring translations into the app lifecycle.

- `LocaleSettings.setLocale` for type-safe locale changes.
- `LocaleSettings.setLocaleRaw` when you only have a string tag.
- `LocaleSettings.useDeviceLocale` when you want the app to follow the device.

If the app uses `TranslationProvider`, wire `MaterialApp.locale` to
`TranslationProvider.of(context).flutterLocale` so Flutter widgets and built-in
UI strings stay in sync.

## Advanced Features

Slang also supports plurals, linked translations, and custom contexts. Use them
when the text itself needs grammatical variation or reuse.

- **Linked translations**: use `@:path.to.otherKey` to reuse another string.
- **Plurals**: use plural forms or ICU-style plural syntax when the value needs
  singular/plural branching.

### Custom Contexts / Enums

Use custom contexts when the same translation needs different variants for
different enum values, such as male/female wording or other domain-specific
cases.

- **Example in ARB**:
  ```json
  {
  	"greet(context=GenderContext)": {
  		"male": "Hello Mr {name}",
  		"female": "Hello Ms {name}"
  	}
  }
  ```
- **Generated enum**:
  ```dart
  enum GenderContext {
    male,
    female,
  }
  ```
- **Usage in Dart**:
  ```dart
  String a = t.greet(name: 'Maria', context: GenderContext.female);
  ```

If not all variants need unique text, collapse them to save space:

- **Collapsed example in ARB**:
  ```json
  {
  	"greet(context=GenderContext)": {
  		"male,female": "Hello {name}"
  	}
  }
  ```

The parameter name defaults to `context`, but you can rename it:

- **Example in ARB**:
  ```json
  {
  	"greet(context=GenderContext, param=gender)": {
  		"male": "Hello Mr",
  		"female": "Hello Ms"
  	}
  }
  ```
- **Usage in Dart**:
  ```dart
  String a = t.greet(gender: GenderContext.female);
  ```

You can also set the default parameter globally:

- **Config**:
  ```yaml
  contexts:
    GenderContext:
      default_parameter: gender
  ```

If you already have an enum in the app, import it instead of generating a new
one:

- **Config**:
  ```yaml
  imports:
    - 'package:my_package/path_to_enum.dart'
  contexts:
    UserType:
      generate_enum: false
  ```

There is also a global `generate_enum` option for all contexts:

- **Config**:
  ```yaml
  imports:
    - 'package:my_package/path_to_enum.dart'
  generate_enum: false
  ```

### Typed Parameters

Parameters are typed as `Object` by default, but you can make them explicit when
the translation should enforce a specific type.

- **Example in ARB**:
  ```json
  {
  	"greet": "Hello {name: String}, you are {age: int} years old"
  }
  ```

Use typed parameters when the translation is part of a stricter UI contract and
you want the generated Dart signature to reflect the expected data types.

## Usage Example

**auth_en.i18n.arb**

```json
{
	"@@locale": "en",
	"login_success": "Login successful!",
	"login_greet": "Welcome {name}"
}
```

**Dart Code**

```dart
import 'package:your_app/i18n/strings.g.dart';

// Access translation from the "auth" namespace
final successMsg = t.auth.login_success;
final greeting = t.auth.login_greet(name: 'Alice');
```

## Important Notes

- ARB is best for flat translation keys. If the project needs deeply nested
  objects, complex lists, or maps, prefer JSON/YAML unless the existing repo
  already uses ARB successfully for that structure.
- Generated Dart access may depend on `key_case`. For example, `login_success`
  can become `loginSuccess` if `key_case: camel` is enabled.
- After editing translations, run `dart run slang`. If shell access is not
  available, explicitly tell the user to run it.
- After generation, run `dart run slang analyze` or `dart analyze` to catch
  missing keys and generated API errors.
