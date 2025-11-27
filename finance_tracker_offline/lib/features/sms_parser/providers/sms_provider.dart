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

  // 2. Fetch last 50 messages
  final messages = await smsQuery.querySms(
    kinds: [SmsQueryKind.inbox],
    count: 50,
  );

  int newTransactionsCount = 0;
  final smsParser = SmsParserService();

  // 3. Filter & Parse
  for (final message in messages) {
    final body = message.body ?? '';
    final address = message.address ?? 'Unknown';
    final date = message.date?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;

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

    final transaction = await smsParser.parseAndSaveSms(body, date, address);

    if (transaction != null) {
      newTransactionsCount++;
    }
  }

  return newTransactionsCount;
});
