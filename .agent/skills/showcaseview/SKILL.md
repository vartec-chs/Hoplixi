---
name: showcaseview
description: Use this skill when implementing in-app onboarding, guided product tours, feature discovery, tooltip walkthroughs, highlighted UI targets, multi-step tutorials, skip/next/previous controls, accessibility-enabled showcases, auto-scroll tours, scoped showcase configurations, or custom showcase tooltips in Flutter apps with the showcaseview package. Keywords: Flutter, showcaseview, ShowcaseView, Showcase, Showcase.withWidget, guided tour, onboarding, tutorial overlay, tooltip, highlight widget, GlobalKey, autoPlay, autoScroll, scope, Riverpod, post frame callback.
---

# ShowcaseView Flutter Skill

Use this skill when an agent needs to add, refactor, debug, or review guided onboarding/tutorial overlays in a Flutter app using the `showcaseview` package.

Package import:

```dart
import 'package:showcaseview/showcaseview.dart';
```

Dependency example:

```yaml
dependencies:
  showcaseview: ^5.0.0
```

> Check the currently installed version in `pubspec.yaml` / `pubspec.lock` before generating code. APIs in this skill are based on the newer `ShowcaseView.register()` style API.

---

## Core Concepts

`showcaseview` highlights one or more widgets and displays tooltip content around them.

Main pieces:

- `ShowcaseView.register(...)` — registers global or scoped showcase configuration.
- `ShowcaseView.get()` — gets the default showcase controller.
- `ShowcaseView.get(scope: 'profile')` — gets a scoped showcase controller.
- `Showcase(...)` — wraps a target widget with default tooltip UI.
- `Showcase.withWidget(...)` — wraps a target widget with a fully custom tooltip widget.
- `GlobalKey` — identifies each showcase target.
- `startShowCase([...])` — starts a sequence of target keys.
- `next()`, `previous()`, `dismiss()` — controls the running showcase.
- `unregister()` — removes showcase configuration when no longer needed.

---

## Basic Implementation Pattern

Use this pattern for a normal screen-level tutorial.

```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _addKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    ShowcaseView.register();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([_menuKey, _addKey]);
    });
  }

  @override
  void dispose() {
    ShowcaseView.get().unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Showcase(
          key: _menuKey,
          title: 'Menu',
          description: 'Open the navigation menu.',
          child: const Icon(Icons.menu),
        ),
        title: const Text('Showcase Example'),
      ),
      floatingActionButton: Showcase(
        key: _addKey,
        title: 'Add',
        description: 'Create a new item.',
        child: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
      body: const Center(
        child: Text('Content'),
      ),
    );
  }
}
```

Important rules:

- Register before starting a showcase.
- Start showcase after first frame with `WidgetsBinding.instance.addPostFrameCallback`.
- Check `mounted` before starting from async/post-frame code.
- Unregister in `dispose` for screen-specific registrations.
- Keep `GlobalKey`s as state fields, not local variables inside `build`.

---

## Global Configuration Pattern

Use this when the whole app should share one style and behavior.

```dart
ShowcaseView.register(
  autoPlayDelay: const Duration(seconds: 3),
  semanticEnable: true,
  globalFloatingActionWidget: (showcaseContext) => FloatingActionWidget(
    left: 16,
    bottom: 16,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () => ShowcaseView.get().dismiss(),
        child: const Text('Skip'),
      ),
    ),
  ),
  globalTooltipActionConfig: const TooltipActionConfig(
    position: TooltipActionPosition.inside,
    alignment: MainAxisAlignment.spaceBetween,
    actionGap: 20,
  ),
  globalTooltipActions: [
    TooltipActionButton(
      type: TooltipDefaultActionType.previous,
      hideActionWidgetForShowcase: [_firstKey],
    ),
    TooltipActionButton(
      type: TooltipDefaultActionType.next,
      hideActionWidgetForShowcase: [_lastKey],
    ),
  ],
);
```

Use `semanticEnable: true` when accessibility support is important.

---

## Starting a Showcase

### From a button

```dart
ElevatedButton(
  onPressed: () {
    ShowcaseView.get().startShowCase([_oneKey, _twoKey, _threeKey]);
  },
  child: const Text('Start tutorial'),
)
```

### On screen load

```dart
@override
void initState() {
  super.initState();

  ShowcaseView.register();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    ShowcaseView.get().startShowCase([_oneKey, _twoKey, _threeKey]);
  });
}
```

### After animations or delayed layout

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  ShowcaseView.get().startShowCase(
    [_oneKey, _twoKey, _threeKey],
    delay: const Duration(milliseconds: 500),
  );
});
```

Use a delay when:

- the target is inside an entrance animation;
- a page transition is still running;
- a list/grid is still building;
- target size/position may be unstable on the first frame.

---

## Custom Tooltip with `Showcase.withWidget`

Use this when the default title/description tooltip is not enough.

```dart
Showcase.withWidget(
  key: _customKey,
  height: 100,
  width: 220,
  targetShapeBorder: const CircleBorder(),
  container: DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Custom Tooltip',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'This is a custom showcase tooltip.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  ),
  child: const Icon(Icons.star),
)
```

Prefer `Showcase.withWidget` for branded onboarding, complex layout, illustrations, or custom action rows.

---

## Tooltip Actions

Use `tooltipActions` for per-target controls.

```dart
Showcase(
  key: _actionKey,
  title: 'Actions',
  description: 'This step has custom navigation actions.',
  tooltipActions: const [
    TooltipActionButton(
      type: TooltipActionButtonType.previous,
      name: 'Previous',
    ),
    TooltipActionButton(
      type: TooltipActionButtonType.next,
      name: 'Next',
    ),
    TooltipActionButton(
      type: TooltipActionButtonType.skip,
      name: 'Skip',
    ),
  ],
  tooltipActionConfig: const TooltipActionConfig(
    alignment: MainAxisAlignment.spaceEvenly,
    position: TooltipActionPosition.outside,
  ),
  child: MyWidget(),
)
```

For app-wide actions, prefer `globalTooltipActions` in `ShowcaseView.register(...)`.

---

## Styling Pattern

```dart
Showcase(
  key: _styleKey,
  title: 'Styled Showcase',
  description: 'This showcase has custom styling.',
  titleTextStyle: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
  descTextStyle: const TextStyle(
    fontSize: 16,
  ),
  tooltipBackgroundColor: Colors.black87,
  targetPadding: const EdgeInsets.all(8),
  targetBorderRadius: BorderRadius.circular(8),
  tooltipBorderRadius: BorderRadius.circular(16),
  child: MyWidget(),
)
```

Use `targetPadding` and `targetBorderRadius` to make highlights feel less cramped.

---

## Auto Play

Use when the tour should advance automatically.

```dart
ShowcaseView.register(
  autoPlay: true,
  autoPlayDelay: const Duration(seconds: 3),
  enableAutoPlayLock: true,
);
```

Good for passive demos. Avoid forcing auto-play for important onboarding if the user needs time to read.

---

## Auto Scroll

Use when targets may be outside the current viewport.

```dart
ShowcaseView.register(
  enableAutoScroll: true,
  scrollDuration: const Duration(milliseconds: 500),
);
```

Limitations:

- Auto-scroll does not work with multi-showcase.
- The target widget must already be attached to the widget tree.
- Lazy builders like `ListView.builder` may not have built the target yet.

For lazy lists, manually scroll first in `onStart`.

```dart
final ScrollController _controller = ScrollController();

ShowcaseView.register(
  onStart: (index, key) {
    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) return;
        _controller.jumpTo(1000);
      });
    }
  },
);
```

```dart
ListView.builder(
  controller: _controller,
  itemCount: 100,
  itemBuilder: (context, index) {
    return ListTile(title: Text('Item $index'));
  },
)
```

---

## Multi-Showcase

Use the same key for multiple `Showcase` widgets when several targets should be displayed simultaneously.

```dart
final GlobalKey _multiKey = GlobalKey();

Showcase(
  key: _multiKey,
  title: 'First Widget',
  description: 'This is the first widget.',
  child: const Icon(Icons.star),
),

Showcase(
  key: _multiKey,
  title: 'Second Widget',
  description: 'This is the second widget.',
  child: const Icon(Icons.favorite),
),
```

Caveats:

- Auto-scroll does not work with multi-showcase.
- Common settings such as barrier tap and colors are taken from the first initialized showcase.
- Use multi-showcase sparingly; it can overwhelm users.

---

## Scoped Configuration

Use scopes when different app modules need different showcase configurations.

Register default configuration:

```dart
ShowcaseView.register(
  semanticEnable: true,
);
```

Register a module-specific configuration:

```dart
ShowcaseView.register(
  scope: 'profile',
  autoPlay: true,
  autoPlayDelay: const Duration(seconds: 2),
);
```

Start a scoped showcase:

```dart
ShowcaseView.get(scope: 'profile').startShowCase([
  _profileHeaderKey,
  _profileEditKey,
]);
```

Assign widgets explicitly to a scope:

```dart
Showcase(
  key: _profileHeaderKey,
  scope: 'profile',
  title: 'Profile',
  description: 'Your profile information.',
  child: const Icon(Icons.person),
)
```

Unregister scoped config when it is no longer needed:

```dart
ShowcaseView.get(scope: 'profile').unregister();
```

If multiple scopes are registered with the same name, the last registration wins.

---

## Control Methods

```dart
ShowcaseView.get().next();
ShowcaseView.get().previous();
ShowcaseView.get().dismiss();
```

Use these from:

- custom tooltip buttons;
- global floating skip button;
- keyboard shortcuts on desktop;
- onboarding state managers.

---

## Event Callbacks

Register lifecycle callbacks globally or per scope.

```dart
ShowcaseView.register(
  onStart: (index, key) {
    debugPrint('Started showcase step $index');
  },
  onComplete: (index, key) {
    debugPrint('Completed showcase step $index');
  },
  onFinish: () {
    debugPrint('Showcase finished');
  },
  onDismiss: (reason) {
    debugPrint('Showcase dismissed: $reason');
  },
);
```

Use callbacks to:

- persist “tutorial completed” state;
- send analytics events;
- unlock dependent UI;
- scroll or prepare content before a target step;
- clean up temporary state.

---

## Dynamic Callbacks

Use dynamic callbacks when widgets deeper in the tree need to listen to showcase events.

```dart
void onStepStarted(int index, GlobalKey key) {
  debugPrint('Step $index started');
}

ShowcaseView.get().addOnstartCallback(onStepStarted);
ShowcaseView.get().removeOnstartCallback(onStepStarted);
```

Other dynamic callback APIs:

```dart
ShowcaseView.get().addOnCompleteCallback((index, key) {});
ShowcaseView.get().addOnFinishCallback(() {});
ShowcaseView.get().addOnDismissCallback((reason) {});
```

Scoped example:

```dart
ShowcaseView.get(scope: 'profile').addOnFinishCallback(() {
  debugPrint('Profile tour finished');
});
```

Always remove callbacks if they are tied to a widget lifecycle and may outlive the widget.

---

## Riverpod Integration Pattern

For apps using Riverpod, avoid putting `GlobalKey` objects in long-lived global providers unless the keys truly belong to app-level UI. Usually, keys belong to the widget `State`, while completed/seen flags belong to providers or persistent storage.

Example state provider:

```dart
final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('home_tour_seen') ?? false;
});
```

Start showcase after provider resolves and UI is built:

```dart
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _addKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    ShowcaseView.register(
      onFinish: _markTourSeen,
      onDismiss: (_) => _markTourSeen(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final seen = await ref.read(onboardingSeenProvider.future);
      if (!mounted || seen) return;

      ShowcaseView.get().startShowCase([_menuKey, _addKey]);
    });
  }

  Future<void> _markTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_tour_seen', true);
    ref.invalidate(onboardingSeenProvider);
  }

  @override
  void dispose() {
    ShowcaseView.get().unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Showcase(
          key: _menuKey,
          title: 'Menu',
          description: 'Open navigation.',
          child: const Icon(Icons.menu),
        ),
      ),
      floatingActionButton: Showcase(
        key: _addKey,
        title: 'Create',
        description: 'Create a new item.',
        child: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

Riverpod guidance:

- Do not mutate providers directly inside `build` to start a showcase.
- Use `initState`, `ref.listen`, or post-frame callbacks for side effects.
- Store durable “seen/completed” state in storage-backed providers.
- Keep showcase controller calls near UI layer because they depend on widget lifecycle and layout.

---

## Clean Architecture Guidance

Recommended responsibility split:

- Widget layer: owns `GlobalKey`s, wraps widgets with `Showcase`, starts the visual tour.
- Application/use case layer: decides whether a tour should be shown.
- Storage/repository layer: persists completed/skipped tutorial flags.
- Analytics layer: receives events from `onStart`, `onComplete`, `onFinish`, `onDismiss`.

Avoid placing package-specific calls like `ShowcaseView.get().startShowCase(...)` in repositories or domain services.

---

## Common Pitfalls

### Starting too early

Bad:

```dart
@override
void initState() {
  super.initState();
  ShowcaseView.get().startShowCase([_key]);
}
```

Better:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  ShowcaseView.get().startShowCase([_key]);
});
```

### Creating keys inside `build`

Bad:

```dart
@override
Widget build(BuildContext context) {
  final key = GlobalKey();
  return Showcase(key: key, child: child);
}
```

Better:

```dart
final GlobalKey _key = GlobalKey();
```

### Forgetting to unregister

If configuration is screen-specific, call:

```dart
@override
void dispose() {
  ShowcaseView.get().unregister();
  super.dispose();
}
```

For scoped configuration:

```dart
ShowcaseView.get(scope: 'profile').unregister();
```

### Lazy list target is not mounted

Auto-scroll can only scroll to widgets already attached to the widget tree. For `ListView.builder`, scroll manually to a position where the target gets built, then start or continue the showcase.

### Multiple scopes confusion

If using scopes, make sure both controller and widgets use the same scope:

```dart
Showcase(
  key: _key,
  scope: 'profile',
  title: 'Profile',
  description: 'Profile info.',
  child: child,
)

ShowcaseView.get(scope: 'profile').startShowCase([_key]);
```

### Dismissing from custom widgets

Use the correct scope:

```dart
ShowcaseView.get(scope: 'profile').dismiss();
```

not:

```dart
ShowcaseView.get().dismiss();
```

when the showcase was started in the `profile` scope.

---

## Debug Checklist

When a showcase does not appear:

1. Confirm `ShowcaseView.register()` was called before `startShowCase`.
2. Confirm target widgets are wrapped with `Showcase` or `Showcase.withWidget`.
3. Confirm the same `GlobalKey` instance is used in both the widget and `startShowCase`.
4. Confirm keys are not recreated in `build`.
5. Confirm `startShowCase` runs after first frame.
6. Confirm the target widget is currently mounted and visible/attached.
7. Confirm scope names match if scoped configuration is used.
8. Confirm `unregister()` was not called before starting.
9. For scrollable/lazy content, confirm the target item has been built.
10. Check console logs from `onStart`, `onComplete`, `onFinish`, and `onDismiss`.

---

## Recommended Code Generation Defaults

When generating showcase code for a production Flutter app:

- Use `StatefulWidget` or `ConsumerStatefulWidget`.
- Define keys as `final GlobalKey` fields in `State`.
- Register in `initState`.
- Start in `addPostFrameCallback`.
- Use `mounted` checks.
- Unregister in `dispose` when registration is screen-specific.
- Use scopes for module-specific tours.
- Enable semantics when accessibility matters.
- Persist skipped/completed status outside the widget.
- Avoid auto-starting the same tutorial repeatedly.
- Avoid huge tours; prefer 3–7 steps per screen.

---

## Minimal Template

```dart
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class ExampleShowcaseScreen extends StatefulWidget {
  const ExampleShowcaseScreen({super.key});

  @override
  State<ExampleShowcaseScreen> createState() => _ExampleShowcaseScreenState();
}

class _ExampleShowcaseScreenState extends State<ExampleShowcaseScreen> {
  final GlobalKey _firstKey = GlobalKey();
  final GlobalKey _secondKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    ShowcaseView.register(
      semanticEnable: true,
      onFinish: () {
        debugPrint('Showcase finished');
      },
      onDismiss: (reason) {
        debugPrint('Showcase dismissed: $reason');
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([_firstKey, _secondKey]);
    });
  }

  @override
  void dispose() {
    ShowcaseView.get().unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Showcase(
          key: _firstKey,
          title: 'Menu',
          description: 'Open the navigation menu.',
          child: const Icon(Icons.menu),
        ),
        title: const Text('Example'),
      ),
      body: Center(
        child: Showcase(
          key: _secondKey,
          title: 'Main Action',
          description: 'This is the main content area.',
          child: const Text('Hello'),
        ),
      ),
    );
  }
}
```

---

## Agent Response Rules

When helping with `showcaseview` tasks:

1. Ask for the installed package version only if the API mismatch matters.
2. Prefer code compatible with `ShowcaseView.register()` if the project uses the new API.
3. Never recreate `GlobalKey`s inside `build`.
4. Always account for widget lifecycle and layout timing.
5. Use `addPostFrameCallback` for auto-start.
6. Use `mounted` checks after post-frame, async, or delayed code.
7. Mention auto-scroll limitations for lazy lists.
8. Use scopes when multiple independent tutorials exist.
9. Keep package-specific code in the UI/application layer, not in repositories/domain services.
10. For Riverpod apps, avoid provider mutation during widget build.
