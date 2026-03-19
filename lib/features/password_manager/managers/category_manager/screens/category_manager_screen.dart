import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/providers/category_tree_provider.dart';
import 'package:hoplixi/routing/paths.dart';

import '../widgets/category_manager_app_bar.dart';
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

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(categoryTreeProvider.notifier).loadMoreRoots();
    }
  }

  void _refresh() {
    ref.read(categoryTreeProvider.notifier).refresh();
  }

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 700.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const CategoryManagerAppBar(),
          CategoryTreeView(entity: widget.entity, onRefresh: _refresh),
        ],
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
