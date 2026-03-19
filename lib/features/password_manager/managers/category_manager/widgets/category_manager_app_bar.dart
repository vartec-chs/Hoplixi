import 'package:flutter/material.dart';

class CategoryManagerAppBar extends StatelessWidget {
  const CategoryManagerAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      title: Text('Категории'),
    );
  }
}
