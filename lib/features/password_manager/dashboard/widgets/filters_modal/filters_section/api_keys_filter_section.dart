import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/api_key/api_key_items.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class ApiKeysFilterSection extends StatefulWidget {
  final ApiKeyFilter filter;
  final Function(ApiKeyFilter) onFilterChanged;

  const ApiKeysFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<ApiKeysFilterSection> createState() => _ApiKeysFilterSectionState();
}

class _ApiKeysFilterSectionState extends State<ApiKeysFilterSection> {
  late TextEditingController _nameController;
  late TextEditingController _serviceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name);
    _serviceController = TextEditingController(text: widget.filter.service);
  }

  @override
  void didUpdateWidget(ApiKeysFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _nameController,
      oldValue: oldWidget.filter.name ?? '',
      newValue: widget.filter.name ?? '',
    );
    syncTextController(
      controller: _serviceController,
      oldValue: oldWidget.filter.service ?? '',
      newValue: widget.filter.service ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  void _updateFilter(ApiKeyFilter Function(ApiKeyFilter) updater) {
    widget.onFilterChanged(updater(widget.filter));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.vpn_key, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры API ключей',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasApiKeysSpecificFilters())
                TextButton.icon(
                  onPressed: _clearApiKeysFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Сбросить'),
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Текстовые фильтры
        _buildTextFilters(),

        const Divider(height: 1),

        // Типы токенов
        _buildTokenTypeSection(),

        const Divider(height: 1),

        // Окружения
        _buildEnvironmentSection(),

        const Divider(height: 1),

        // Статусные фильтры
        _buildStatusFilters(),

        const Divider(height: 1),

        // Сортировка
        _buildSortingSection(),
      ],
    );
  }

  // ============================================================================
  // Текстовые фильтры
  // ============================================================================

  Widget _buildTextFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Поиск',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Название
          TextField(
            controller: _nameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Название',
              hintText: 'Введите название ключа...',
              prefixIcon: const Icon(Icons.title),
              suffixIcon: _nameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _nameController.clear();
                        _updateFilter((f) => f.copyWith(name: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(name: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Сервис
          TextField(
            controller: _serviceController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Сервис',
              hintText: 'Введите название сервиса (GitHub, OpenAI)...',
              prefixIcon: const Icon(Icons.cloud_outlined),
              suffixIcon: _serviceController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _serviceController.clear();
                        _updateFilter((f) => f.copyWith(service: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(service: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Типы токенов
  // ============================================================================

  Widget _buildTokenTypeSection() {
    return ExpansionTile(
      leading: const Icon(Icons.category),
      title: const Text('Тип токена'),
      initiallyExpanded: widget.filter.tokenType != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ApiKeyTokenType.values.map((type) {
              return ChoiceChip(
                label: Text(type.name.toUpperCase()),
                selected: widget.filter.tokenType == type,
                onSelected: (selected) {
                  _updateFilter(
                    (f) => f.copyWith(tokenType: selected ? type : null),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Окружения
  // ============================================================================

  Widget _buildEnvironmentSection() {
    return ExpansionTile(
      leading: const Icon(Icons.settings_input_component),
      title: const Text('Окружение'),
      initiallyExpanded: widget.filter.environment != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ApiKeyEnvironment.values.map((env) {
              return ChoiceChip(
                label: Text(env.name.toUpperCase()),
                selected: widget.filter.environment == env,
                onSelected: (selected) {
                  _updateFilter(
                    (f) => f.copyWith(environment: selected ? env : null),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Статусные фильтры
  // ============================================================================

  Widget _buildStatusFilters() {
    return ExpansionTile(
      leading: const Icon(Icons.check_circle_outline),
      title: const Text('Наличие полей и статус'),
      initiallyExpanded: _hasActiveStatusFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'Отозван',
                value: widget.filter.isRevoked,
                icon: Icons.cancel_outlined,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(isRevoked: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Срок действия',
                value: widget.filter.hasExpiration,
                icon: Icons.event,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasExpiration: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Владелец',
                value: widget.filter.hasOwner,
                icon: Icons.person,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasOwner: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Base URL',
                value: widget.filter.hasBaseUrl,
                icon: Icons.link,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasBaseUrl: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Разрешения (Scopes)',
                value: widget.filter.hasScopes,
                icon: Icons.security,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasScopes: value));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTriStateCheckbox({
    required String label,
    required bool? value,
    required IconData icon,
    required void Function(bool?) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        // Cycle: null -> true -> false -> null
        if (value == null) {
          onChanged(true);
        } else if (value == true) {
          onChanged(false);
        } else {
          onChanged(null);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: value != null
                ? colorScheme.primary.withOpacity(0.5)
                : colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: value == true
              ? colorScheme.primary.withOpacity(0.1)
              : value == false
              ? colorScheme.error.withOpacity(0.1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: value == true
                  ? colorScheme.primary
                  : value == false
                  ? colorScheme.error
                  : colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: value != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            if (value != null)
              Icon(
                value ? Icons.check : Icons.close,
                size: 18,
                color: value ? colorScheme.primary : colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveStatusFilters() {
    return widget.filter.isRevoked != null ||
        widget.filter.hasExpiration != null ||
        widget.filter.hasOwner != null ||
        widget.filter.hasBaseUrl != null ||
        widget.filter.hasScopes != null;
  }

  // ============================================================================
  // Сортировка
  // ============================================================================

  Widget _buildSortingSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сортировка',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip(
                label: 'По названию',
                field: ApiKeySortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По сервису',
                field: ApiKeySortField.service,
                icon: Icons.cloud_outlined,
              ),
              _buildSortChip(
                label: 'По типу',
                field: ApiKeySortField.tokenType,
                icon: Icons.category,
              ),
              _buildSortChip(
                label: 'По окружению',
                field: ApiKeySortField.environment,
                icon: Icons.settings_input_component,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: ApiKeySortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: ApiKeySortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: ApiKeySortField.lastUsedAt,
                icon: Icons.access_time,
              ),
            ],
          ),
          if (widget.filter.sortField != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _updateFilter((f) => f.copyWith(sortField: null));
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Сбросить сортировку'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required ApiKeySortField field,
    required IconData icon,
  }) {
    final isSelected = widget.filter.sortField == field;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? colorScheme.onSecondaryContainer : null,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        _updateFilter((f) => f.copyWith(sortField: selected ? field : null));
      },
      selectedColor: colorScheme.secondaryContainer,
      checkmarkColor: colorScheme.onSecondaryContainer,
    );
  }

  // ============================================================================
  // Вспомогательные методы
  // ============================================================================

  bool _hasApiKeysSpecificFilters() {
    return widget.filter.name != null ||
        widget.filter.service != null ||
        widget.filter.tokenType != null ||
        widget.filter.environment != null ||
        widget.filter.isRevoked != null ||
        widget.filter.hasExpiration != null ||
        widget.filter.hasOwner != null ||
        widget.filter.hasBaseUrl != null ||
        widget.filter.hasScopes != null ||
        widget.filter.sortField != null;
  }

  void _clearApiKeysFilters() {
    _nameController.clear();
    _serviceController.clear();

    _updateFilter(
      (f) => f.copyWith(
        name: null,
        service: null,
        tokenType: null,
        environment: null,
        isRevoked: null,
        hasExpiration: null,
        hasOwner: null,
        hasBaseUrl: null,
        hasScopes: null,
        sortField: null,
      ),
    );
  }
}
