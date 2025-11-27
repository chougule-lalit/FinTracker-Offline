// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_transaction_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddTransactionNotifier)
const addTransactionProvider = AddTransactionNotifierProvider._();

final class AddTransactionNotifierProvider
    extends $NotifierProvider<AddTransactionNotifier, AddTransactionState> {
  const AddTransactionNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'addTransactionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$addTransactionNotifierHash();

  @$internal
  @override
  AddTransactionNotifier create() => AddTransactionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddTransactionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddTransactionState>(value),
    );
  }
}

String _$addTransactionNotifierHash() =>
    r'7fb0b0252df39d4f2a472514718949fd633fe3e4';

abstract class _$AddTransactionNotifier extends $Notifier<AddTransactionState> {
  AddTransactionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AddTransactionState, AddTransactionState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AddTransactionState, AddTransactionState>,
        AddTransactionState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
