import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/import/keepass/providers/keepass_import_provider.dart';
import 'package:hoplixi/features/password_manager/import/keepass/widgets/keepass_import_navigation_bar.dart';
import 'package:hoplixi/features/password_manager/import/keepass/widgets/keepass_import_step_content.dart';
import 'package:hoplixi/features/password_manager/import/keepass/widgets/keepass_import_step_header.dart';

class KeepassImportScreen extends ConsumerStatefulWidget {
  const KeepassImportScreen({super.key});

  @override
  ConsumerState<KeepassImportScreen> createState() =>
      _KeepassImportScreenState();
}

class _KeepassImportScreenState extends ConsumerState<KeepassImportScreen> {
  late final TextEditingController _passwordController;
  var _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<KeepassImportState>(keepassImportProvider, (previous, next) {
      if (previous?.message == next.message || next.message == null) {
        return;
      }

      if (next.isSuccess) {
        Toaster.success(title: 'KeePass', description: next.message!);
      } else {
        Toaster.error(title: 'KeePass', description: next.message!);
      }
    });

    final state = ref.watch(keepassImportProvider);
    final notifier = ref.read(keepassImportProvider.notifier);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final shouldConstrainBody = screenWidth > 600;

    final bodyContent = SafeArea(
      child: Column(
        children: [
          KeepassImportStepHeader(state: state, notifier: notifier),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: KeepassImportStepContent(
                    state: state,
                    notifier: notifier,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    onTogglePasswordVisibility: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          KeepassImportNavigationBar(state: state, notifier: notifier),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Импорт KeePass'),
        leading: const FormCloseButton(),
      ),
      body: shouldConstrainBody
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.35),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: bodyContent,
                    ),
                  ),
                ),
              ),
            )
          : bodyContent,
    );
  }
}
