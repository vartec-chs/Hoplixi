import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

import 'base_filter_provider.dart';

final contactsFilterProvider =
    NotifierProvider<ContactsFilterNotifier, ContactsFilter>(
      ContactsFilterNotifier.new,
    );

class ContactsFilterNotifier extends Notifier<ContactsFilter> {
  static const String _logTag = 'ContactsFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  ContactsFilter build() {
    ref.listen(baseFilterProvider, (_, next) {
      state = state.copyWith(base: next);
    });

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return ContactsFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilter(ContactsFilter filter) {
    _debounceTimer?.cancel();
    state = filter;
  }

  void updateFilterDebounced(ContactsFilter filter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = filter;
    });
  }

  void setName(String? name) {
    final value = name?.trim();
    logDebug('Contact filter name: $value', tag: _logTag);
    state = state.copyWith(name: value?.isEmpty == true ? null : value);
  }

  void setPhone(String? phone) {
    final value = phone?.trim();
    state = state.copyWith(phone: value?.isEmpty == true ? null : value);
  }

  void setEmail(String? email) {
    final value = email?.trim();
    state = state.copyWith(email: value?.isEmpty == true ? null : value);
  }

  void setCompany(String? company) {
    final value = company?.trim();
    state = state.copyWith(company: value?.isEmpty == true ? null : value);
  }

  void setIsEmergencyContact(bool? isEmergencyContact) {
    state = state.copyWith(isEmergencyContact: isEmergencyContact);
  }

  void setHasPhone(bool? hasPhone) {
    state = state.copyWith(hasPhone: hasPhone);
  }

  void setHasEmail(bool? hasEmail) {
    state = state.copyWith(hasEmail: hasEmail);
  }

  void setSortField(ContactsSortField? sortField) {
    state = state.copyWith(sortField: sortField);
  }
}
