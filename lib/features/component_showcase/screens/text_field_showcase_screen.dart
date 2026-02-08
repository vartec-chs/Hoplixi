import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Экран для демонстрации текстовых полей
class TextFieldShowcaseScreen extends StatefulWidget {
  const TextFieldShowcaseScreen({super.key});

  @override
  State<TextFieldShowcaseScreen> createState() =>
      _TextFieldShowcaseScreenState();
}

class _TextFieldShowcaseScreenState extends State<TextFieldShowcaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _multilineController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _multilineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSection(
          context,
          title: 'Basic Text Fields',
          children: [
            PrimaryTextField(
              label: 'Simple Text Field',
              controller: _textController,
              hintText: 'Enter some text',
            ),
            const SizedBox(height: 16),
            const PrimaryTextField(
              label: 'With Prefix Icon',
              prefixIcon: Icon(Icons.person),
              hintText: 'Username',
            ),
            const SizedBox(height: 16),
            const PrimaryTextField(
              label: 'With Suffix Icon',
              suffixIcon: Icon(Icons.clear),
              hintText: 'Search',
            ),
            const SizedBox(height: 16),
            PrimaryTextField(
              label: 'Read Only',
              readOnly: true,
              controller: TextEditingController(text: 'Cannot edit this'),
            ),
            const SizedBox(height: 16),
            const PrimaryTextField(
              label: 'Disabled',
              enabled: false,
              hintText: 'This field is disabled',
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Text Form Fields',
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  PrimaryTextFormField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                    helperText: 'Enter your email address',
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    label: 'Password',
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Form is valid!')),
                          );
                        }
                      },
                      child: const Text('Validate Form'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Multiline',
          children: [
            PrimaryTextField(
              label: 'Multiline Text',
              controller: _multilineController,
              maxLines: 5,
              minLines: 3,
              hintText: 'Enter multiple lines of text...',
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Special Types',
          children: [
            const PrimaryTextField(
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
              prefixIcon: Icon(Icons.phone),
              hintText: '+1 234 567 8900',
            ),
            const SizedBox(height: 16),
            const PrimaryTextField(
              label: 'Number',
              keyboardType: TextInputType.number,
              prefixIcon: Icon(Icons.numbers),
              hintText: '123456',
            ),
            const SizedBox(height: 16),
            PrimaryTextField(
              label: 'Date',
              readOnly: true,
              suffixIcon: const Icon(Icons.calendar_today),
              hintText: 'Select date',
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected: ${date.toString()}')),
                  );
                }
              },
            ),
          ],
        ),
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
}
