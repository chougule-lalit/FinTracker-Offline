import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/receipt_service.dart';

part 'receipt_provider.g.dart';

@riverpod
ReceiptService receiptService(Ref ref) {
  return ReceiptService();
}
