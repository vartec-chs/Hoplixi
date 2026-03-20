import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';

String historyActionLabel(BuildContext context, String action) {
  final l10n = context.t.history;
  switch (action) {
    case 'modified':
      return l10n.action_modified;
    case 'deleted':
      return l10n.action_deleted;
    case 'created':
      return l10n.action_created;
    default:
      return action;
  }
}

String historyActionFilterLabel(
  BuildContext context,
  HistoryActionFilter filter,
) {
  final l10n = context.t.history;
  switch (filter) {
    case HistoryActionFilter.all:
      return l10n.filter_all_actions;
    case HistoryActionFilter.modified:
      return l10n.action_modified;
    case HistoryActionFilter.deleted:
      return l10n.action_deleted;
  }
}

String historyDatePresetLabel(BuildContext context, HistoryDatePreset preset) {
  final l10n = context.t.history;
  switch (preset) {
    case HistoryDatePreset.all:
      return l10n.filter_all_time;
    case HistoryDatePreset.last7Days:
      return l10n.filter_last7_days;
    case HistoryDatePreset.last30Days:
      return l10n.filter_last30_days;
  }
}

String historyCompareLabel(
  BuildContext context,
  HistoryCompareTargetKind kind,
) {
  final l10n = context.t.history;
  switch (kind) {
    case HistoryCompareTargetKind.newerRevision:
      return l10n.compare_to_newer_revision;
    case HistoryCompareTargetKind.currentLive:
      return l10n.compare_to_current;
    case HistoryCompareTargetKind.deletedState:
      return l10n.compare_to_deleted;
  }
}

String historyChangeLabel(BuildContext context, HistoryFieldChangeType type) {
  final l10n = context.t.history;
  switch (type) {
    case HistoryFieldChangeType.added:
      return l10n.change_added;
    case HistoryFieldChangeType.removed:
      return l10n.change_removed;
    case HistoryFieldChangeType.changed:
      return l10n.change_changed;
  }
}

String historyFormatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}
