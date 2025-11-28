enum DateFilterType {
  monthly,
  weekly,
  yearly,
  custom;

  String get label {
    switch (this) {
      case DateFilterType.monthly:
        return 'Monthly';
      case DateFilterType.weekly:
        return 'Weekly';
      case DateFilterType.yearly:
        return 'Yearly';
      case DateFilterType.custom:
        return 'Custom';
    }
  }
}
