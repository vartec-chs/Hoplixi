import 'package:flutter/material.dart';
import 'package:hoplixi/app/widgets/app_runtime_wrapper.dart';

class App extends StatelessWidget {
  const App({super.key, this.filePath});

  final String? filePath;

  @override
  Widget build(BuildContext context) {
    return AppRuntimeWrapper(filePath: filePath);
  }
}
