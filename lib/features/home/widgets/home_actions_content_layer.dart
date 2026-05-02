import 'package:flutter/material.dart';
import 'package:hoplixi/features/home/models/action_item.dart';
import 'package:hoplixi/features/home/widgets/home_action_grid.dart';
import 'package:hoplixi/features/home/widgets/recent_database_card.dart';

class HomeActionsContentLayer extends StatelessWidget {
  const HomeActionsContentLayer({
    super.key,
    required this.top,
    required this.hasRecentDatabase,
    required this.items,
    this.showcaseScope,
  });

  final double top;
  final bool hasRecentDatabase;
  final List<ActionItem> items;
  final String? showcaseScope;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      top: top,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: SafeArea(
          top: false,
          child: hasRecentDatabase
              ? Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: RecentDatabaseCard(),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _ActionsScrollView(
                        items: items,
                        showcaseScope: showcaseScope,
                      ),
                    ),
                  ],
                )
              : _ActionsScrollView(
                  items: items,
                  showcaseScope: showcaseScope,
                ),
        ),
      ),
    );
  }
}

class _ActionsScrollView extends StatelessWidget {
  const _ActionsScrollView({required this.items, this.showcaseScope});

  final List<ActionItem> items;
  final String? showcaseScope;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: HomeActionGrid(items: items, showcaseScope: showcaseScope),
      ),
    );
  }
}
