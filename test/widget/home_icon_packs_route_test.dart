import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/home/home_screen.dart';
import 'package:hoplixi/features/home/providers/recent_database_provider.dart';
import 'package:hoplixi/features/custom_icon_packs/screens/icon_packs_screen.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/routing/routes.dart';

void main() {
  testWidgets('HomeScreen navigates to icon packs route', (tester) async {
    final router = GoRouter(
      routes: appRoutes,
      initialLocation: AppRoutesPaths.home,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentDatabaseProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Паки иконок'), findsOneWidget);

    await tester.tap(find.text('Паки иконок'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(IconPacksScreen), findsOneWidget);

    router.dispose();
  });
}
