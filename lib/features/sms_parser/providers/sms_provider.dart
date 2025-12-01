import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:finance_tracker_offline/features/sms_parser/services/sms_parser_service.dart';

final smsSyncProvider = FutureProvider<int>((ref) async {
  final smsQuery = SmsQuery();

  // 1. Request Permission
  var permission = await Permission.sms.status;
  if (permission.isDenied) {
    permission = await Permission.sms.request();
  }

  if (!permission.isGranted) {
    throw Exception('SMS permission denied');
  }

  // 2. Fetch all messages (removed count limit)
  final messages = await smsQuery.querySms(
    kinds: [SmsQueryKind.inbox],
    // count: 50, // Removed limit
  );

  final smsParser = SmsParserService();
  final List<SmsMessage> filteredMessages = [];

  // 3. Filter
  for (final message in messages) {
    final body = message.body ?? '';
    
    // Basic keyword filter to avoid parsing everything
    final lowerBody = body.toLowerCase();
    if (!lowerBody.contains('bank') &&
        !lowerBody.contains('debit') &&
        !lowerBody.contains('credit') &&
        !lowerBody.contains('upi') &&
        !lowerBody.contains('spent') &&
        !lowerBody.contains('txn') &&
        !lowerBody.contains('acct')) {
      continue;
    }
    
    filteredMessages.add(message);
  }

  // 4. Batch Sync
  final newTransactionsCount = await smsParser.syncBatchMessages(filteredMessages);

  return newTransactionsCount;
});
