// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(stats)
const statsProvider = StatsFamily._();

final class StatsProvider extends $FunctionalProvider<
        AsyncValue<List<CategoryStat>>,
        List<CategoryStat>,
        Stream<List<CategoryStat>>>
    with
        $FutureModifier<List<CategoryStat>>,
        $StreamProvider<List<CategoryStat>> {
  const StatsProvider._(
      {required StatsFamily super.from,
      required TransactionType super.argument})
      : super(
          retry: null,
          name: r'statsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$statsHash();

  @override
  String toString() {
    return r'statsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CategoryStat>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<CategoryStat>> create(Ref ref) {
    final argument = this.argument as TransactionType;
    return stats(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$statsHash() => r'34e7e3871443e3071305964407df401289d27e7a';

final class StatsFamily extends $Family
    with
        $FunctionalFamilyOverride<Stream<List<CategoryStat>>, TransactionType> {
  const StatsFamily._()
      : super(
          retry: null,
          name: r'statsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  StatsProvider call(
    TransactionType type,
  ) =>
      StatsProvider._(argument: type, from: this);

  @override
  String toString() => r'statsProvider';
}
