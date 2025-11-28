import 'package:finance_tracker_offline/features/stats/models/date_filter_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'date_filter_provider.g.dart';

class DateFilterState {
  final DateFilterType type;
  final DateTime referenceDate;
  final DateTime? customStart;
  final DateTime? customEnd;

  DateFilterState({
    required this.type,
    required this.referenceDate,
    this.customStart,
    this.customEnd,
  });

  DateFilterState copyWith({
    DateFilterType? type,
    DateTime? referenceDate,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return DateFilterState(
      type: type ?? this.type,
      referenceDate: referenceDate ?? this.referenceDate,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }

  DateTime get startDate {
    switch (type) {
      case DateFilterType.monthly:
        return DateTime(referenceDate.year, referenceDate.month, 1);
      case DateFilterType.weekly:
        // Find Monday of the current week
        // weekday: 1 = Mon, 7 = Sun
        final diff = referenceDate.weekday - 1;
        final start = referenceDate.subtract(Duration(days: diff));
        return DateTime(start.year, start.month, start.day);
      case DateFilterType.yearly:
        return DateTime(referenceDate.year, 1, 1);
      case DateFilterType.custom:
        return customStart ?? DateTime.now();
    }
  }

  DateTime get endDate {
    switch (type) {
      case DateFilterType.monthly:
        // Last day of month: First day of next month - 1 microsecond
        return DateTime(referenceDate.year, referenceDate.month + 1, 1)
            .subtract(const Duration(microseconds: 1));
      case DateFilterType.weekly:
        // End of Sunday
        final start = startDate;
        return start
            .add(const Duration(days: 7))
            .subtract(const Duration(microseconds: 1));
      case DateFilterType.yearly:
        return DateTime(referenceDate.year + 1, 1, 1)
            .subtract(const Duration(microseconds: 1));
      case DateFilterType.custom:
        return customEnd ?? DateTime.now();
    }
  }
}

@riverpod
class DateFilter extends _$DateFilter {
  @override
  DateFilterState build() {
    return DateFilterState(
      type: DateFilterType.monthly,
      referenceDate: DateTime.now(),
    );
  }

  void setFilterType(DateFilterType type) {
    state = state.copyWith(type: type);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      type: DateFilterType.custom,
      customStart: start,
      customEnd: end,
    );
  }

  void next() {
    if (state.type == DateFilterType.custom) return;

    DateTime newDate;
    switch (state.type) {
      case DateFilterType.monthly:
        newDate = DateTime(
            state.referenceDate.year, state.referenceDate.month + 1, state.referenceDate.day);
        break;
      case DateFilterType.weekly:
        newDate = state.referenceDate.add(const Duration(days: 7));
        break;
      case DateFilterType.yearly:
        newDate = DateTime(
            state.referenceDate.year + 1, state.referenceDate.month, state.referenceDate.day);
        break;
      default:
        return;
    }
    state = state.copyWith(referenceDate: newDate);
  }

  void previous() {
    if (state.type == DateFilterType.custom) return;

    DateTime newDate;
    switch (state.type) {
      case DateFilterType.monthly:
        newDate = DateTime(
            state.referenceDate.year, state.referenceDate.month - 1, state.referenceDate.day);
        break;
      case DateFilterType.weekly:
        newDate = state.referenceDate.subtract(const Duration(days: 7));
        break;
      case DateFilterType.yearly:
        newDate = DateTime(
            state.referenceDate.year - 1, state.referenceDate.month, state.referenceDate.day);
        break;
      default:
        return;
    }
    state = state.copyWith(referenceDate: newDate);
  }
}
