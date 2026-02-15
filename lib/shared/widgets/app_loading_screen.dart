import 'package:flutter/material.dart';

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}
