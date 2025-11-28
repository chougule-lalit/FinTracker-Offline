import 'package:finance_tracker_offline/features/stats/models/date_filter_type.dart';
import 'package:finance_tracker_offline/features/stats/providers/date_filter_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DateFilterControls extends ConsumerWidget {
  const DateFilterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(dateFilterProvider);
    final notifier = ref.read(dateFilterProvider.notifier);

    String dateText = _getDateText(filterState);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Filter Type Dropdown
          DropdownButton<DateFilterType>(
            value: filterState.type,
            underline: Container(), // Remove underline
            onChanged: (DateFilterType? newValue) {
              if (newValue != null) {
                notifier.setFilterType(newValue);
              }
            },
            items: DateFilterType.values.map((DateFilterType type) {
              return DropdownMenuItem<DateFilterType>(
                value: type,
                child: Text(type.label),
              );
            }).toList(),
          ),
          
          const Spacer(),

          // Navigator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: filterState.type == DateFilterType.custom
                    ? null
                    : () => notifier.previous(),
              ),
              InkWell(
                onTap: filterState.type == DateFilterType.custom
                    ? () => _pickDateRange(context, notifier, filterState)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    dateText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: filterState.type == DateFilterType.custom
                    ? null
                    : () => notifier.next(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDateText(DateFilterState state) {
    switch (state.type) {
      case DateFilterType.monthly:
        return DateFormat('MMMM yyyy').format(state.referenceDate);
      case DateFilterType.yearly:
        return DateFormat('yyyy').format(state.referenceDate);
      case DateFilterType.weekly:
        final start = state.startDate;
        final end = state.endDate;
        if (start.month == end.month) {
          return '${DateFormat('MMM d').format(start)} - ${DateFormat('d').format(end)}';
        } else {
          return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
        }
      case DateFilterType.custom:
        final start = state.customStart;
        final end = state.customEnd;
        if (start == null || end == null) {
          return 'Select Range';
        }
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
    }
  }

  Future<void> _pickDateRange(
      BuildContext context, DateFilter notifier, DateFilterState state) async {
    final initialDateRange = state.customStart != null && state.customEnd != null
        ? DateTimeRange(start: state.customStart!, end: state.customEnd!)
        : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initialDateRange,
    );

    if (picked != null) {
      notifier.setCustomRange(picked.start, picked.end);
    }
  }
}
