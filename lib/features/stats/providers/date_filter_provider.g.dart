// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'date_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DateFilter)
const dateFilterProvider = DateFilterProvider._();

final class DateFilterProvider
    extends $NotifierProvider<DateFilter, DateFilterState> {
  const DateFilterProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'dateFilterProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$dateFilterHash();

  @$internal
  @override
  DateFilter create() => DateFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateFilterState>(value),
    );
  }
}

String _$dateFilterHash() => r'b97a32b924a6877a35c8397a896626cfd958f55b';

abstract class _$DateFilter extends $Notifier<DateFilterState> {
  DateFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DateFilterState, DateFilterState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<DateFilterState, DateFilterState>,
        DateFilterState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
