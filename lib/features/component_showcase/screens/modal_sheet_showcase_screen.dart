import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Экран для демонстрации Wolt Modal Sheet
class ModalSheetShowcaseScreen extends StatefulWidget {
  const ModalSheetShowcaseScreen({super.key});

  @override
  State<ModalSheetShowcaseScreen> createState() =>
      _ModalSheetShowcaseScreenState();
}

class _ModalSheetShowcaseScreenState extends State<ModalSheetShowcaseScreen> {
  String _lastAction = 'No action yet';

  void _updateAction(String action) {
    setState(() => _lastAction = action);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Result display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Last action: $_lastAction',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 24),

        _buildSection(
          context,
          title: 'Basic Modal',
          children: [
            FilledButton(
              onPressed: () => _showBasicModal(context),
              child: const Text('Show Basic Modal'),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildSection(
          context,
          title: 'Multi-Page Modal',
          children: [
            FilledButton(
              onPressed: () => _showMultiPageModal(context),
              child: const Text('Show Multi-Page Modal'),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildSection(
          context,
          title: 'Modal with Form',
          children: [
            FilledButton(
              onPressed: () => _showFormModal(context),
              child: const Text('Show Form Modal'),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildSection(
          context,
          title: 'Modal with Top Bar',
          children: [
            FilledButton(
              onPressed: () => _showModalWithTopBar(context),
              child: const Text('Show Modal with Top Bar'),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildSection(
          context,
          title: 'Modal with Hero Image',
          children: [
            FilledButton(
              onPressed: () => _showModalWithHero(context),
              child: const Text('Show Modal with Hero'),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildSection(
          context,
          title: 'Modal with Long Text',
          children: [
            FilledButton(
              onPressed: () =>
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showModalWithLongText(context);
                  }),
              child: const Text('Show Long Text Modal'),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  // Basic single page modal
  void _showBasicModal(BuildContext context) {
    WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          // backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          surfaceTintColor: Colors.transparent,
          child: Builder(
            builder: (context) {
              // ref.watch(themeProvider);
              return Container(
                // Применяем цвет фона из текущей темы
                // color: Theme.of(context).colorScheme.surfaceContainerLow,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Modal',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This is a simple modal sheet with basic content. '
                      'You can dismiss it by dragging down or tapping outside.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _updateAction('Modal dismissed');
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _updateAction('Basic modal action confirmed');
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Multi-page modal with navigation
  void _showMultiPageModal(BuildContext context) {
    WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        // Page 1
        WoltModalSheetPage(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Text(
            'Page 1 of 3',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          isTopBarLayerAlwaysVisible: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.looks_one, size: 48),
                const SizedBox(height: 16),
                Text(
                  'First Step',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is the first page. Navigate to the next page to continue.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      WoltModalSheet.of(context).showNext();
                      _updateAction('Navigated to page 2');
                    },
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Page 2
        WoltModalSheetPage(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Text(
            'Page 2 of 3',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => WoltModalSheet.of(context).showPrevious(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.looks_two, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Second Step',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Middle page. You can go back or proceed to the final step.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          WoltModalSheet.of(context).showPrevious();
                          _updateAction('Navigated back to page 1');
                        },
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          WoltModalSheet.of(context).showNext();
                          _updateAction('Navigated to page 3');
                        },
                        child: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Page 3
        WoltModalSheetPage(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Text(
            'Page 3 of 3',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => WoltModalSheet.of(context).showPrevious(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.looks_3, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Final Step',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is the final page. Complete the flow or go back.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          WoltModalSheet.of(context).showPrevious();
                          _updateAction('Navigated back to page 2');
                        },
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _updateAction('Multi-page flow completed');
                        },
                        child: const Text('Complete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Modal with form
  void _showFormModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phone = '';
    String company = '';
    String country = '';
    String message = '';
    bool subscribe = false;

    WoltModalSheet.show(
      context: context,
      barrierDismissible: true,

      pageListBuilder: (context) {
        final theme = Theme.of(context);
        return [
          WoltModalSheetPage(
            // backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            topBarTitle: Builder(
              builder: (context) {
                return Text('Contact Form', style: theme.textTheme.titleMedium);
              },
            ),
            isTopBarLayerAlwaysVisible: true,
            child: Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fill in your details',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Name is required';
                          return null;
                        },
                        onSaved: (value) => name = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Email is required';
                          }
                          if (!value!.contains('@')) return 'Invalid email';
                          return null;
                        },
                        onSaved: (value) => email = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Phone is required';
                          }
                          return null;
                        },
                        onSaved: (value) => phone = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Company',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Company is required';
                          }
                          return null;
                        },
                        onSaved: (value) => company = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.public),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Country is required';
                          }
                          return null;
                        },
                        onSaved: (value) => country = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Message is required';
                          }
                          return null;
                        },
                        onSaved: (value) => message = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Subscribe to newsletter'),
                        value: subscribe,
                        onChanged: (value) {
                          subscribe = value ?? false;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _updateAction('Form cancelled');
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                Navigator.of(context).pop();
                                _updateAction(
                                  'Form submitted: $name, $email, $phone, $company, $country, Message: $message, subscribe: $subscribe',
                                );
                              }
                            },
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ];
      },
    );
  }

  // Modal with top bar customization
  void _showModalWithTopBar(BuildContext context) {
    WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Text(
            'Custom Top Bar',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          trailingNavBarWidget: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _updateAction('Menu button pressed');
            },
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Bar Customization',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This modal demonstrates a custom top bar with title, '
                  'leading close button, and trailing menu button.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _updateAction('Settings tapped'),
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _updateAction('About tapped'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Modal with hero image
  void _showModalWithHero(BuildContext context) {
    WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          heroImage: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 80, color: Colors.white),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modal with Hero Image',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This modal showcases a hero image at the top. '
                  'Perfect for product details, image previews, or featured content.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateAction('Hero modal action performed');
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Got it'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Modal with long text content using SliverWoltModalSheetPage
  void _showModalWithLongText(BuildContext context) {
    WoltModalSheet.show(
      context: context,
      modalTypeBuilder: (_) =>
          const WoltDialogType(), // или WoltBottomSheetType()

      pageListBuilder: (context) => [
        SliverWoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: const Text('Long Text Content'),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          mainContentSliversBuilder: (context) => [
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Terms and Conditions'),
                    const SizedBox(height: 16),
                    const Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                      'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                      'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\n'
                      'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
                      'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\n'
                      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, '
                      'totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.\n\n'
                      'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.\n\n'
                      'Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, '
                      'sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _updateAction('Long text modal declined');
                          },
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _updateAction('Long text modal accepted');
                          },
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Добавляем bottom safe area
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ],
    );
  }
}
