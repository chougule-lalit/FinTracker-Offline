class AddTransactionState {
  final double? amount;
  final String description;
  final int? categoryId;
  final bool isLoading;
  final String? error;

  const AddTransactionState({
    this.amount,
    this.description = '',
    this.categoryId,
    this.isLoading = false,
    this.error,
  });

  AddTransactionState copyWith({
    double? amount,
    String? description,
    int? categoryId,
    bool? isLoading,
    String? error,
  }) {
    return AddTransactionState(
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
