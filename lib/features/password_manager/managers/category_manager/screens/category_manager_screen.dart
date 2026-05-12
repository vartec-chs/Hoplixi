import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/providers/category_filter_provider.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/providers/category_pagination_provider.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/providers/category_tree_provider.dart';
import 'package:hoplixi/main_db/core/old/models/filter/index.dart';
import 'package:hoplixi/routing/paths.dart';

import '../widgets/category_manager_app_bar.dart';
import '../widgets/category_manager_filtered_list_view.dart';
import '../widgets/category_tree_view.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key, required this.entity});

  final EntityType entity;

  @override
  ConsumerState<CategoryManagerScreen> createState() =>
      _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final hasActiveFilters = ref
        .read(categoryFilterProvider)
        .hasActiveConstraints;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      if (hasActiveFilters) {
        ref.read(categoryListProvider.notifier).loadMore();
      } else {
        ref.read(categoryTreeProvider.notifier).loadMoreRoots();
      }
    }
  }

  void _refresh() {
    final hasActiveFilters = ref
        .read(categoryFilterProvider)
        .hasActiveConstraints;
    if (hasActiveFilters) {
      ref.read(categoryListProvider.notifier).refresh();
    } else {
      ref.read(categoryTreeProvider.notifier).refresh();
    }
  }

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 700.0;
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = ref.watch(
      categoryFilterProvider.select((filter) => filter.hasActiveConstraints),
    );

    return Scaffold(
      body: Scrollbar(
        controller: _scrollController,
        child: CustomScrollView(
          controller: _scrollController,
          primary: false,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const CategoryManagerAppBar(),
            if (hasActiveFilters)
              CategoryManagerFilteredListView(
                entity: widget.entity,
                onRefresh: _refresh,
              )
            else
              CategoryTreeView(entity: widget.entity, onRefresh: _refresh),
          ],
        ),
      ),
      floatingActionButton: _isMobileLayout(context)
          ? FloatingActionButton(
              heroTag: 'category_add_btn',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () {
                final result = context.push<bool>(
                  AppRoutesPaths.categoryAdd(widget.entity),
                );
                result.then((added) {
                  if (added == true) {
                    _refresh();
                  }
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
