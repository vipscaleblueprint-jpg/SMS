import 'package:flutter/foundation.dart';
import '../utils/db/scheduled_db_helper.dart';

class DbInspector {
  static Future<void> inspect() async {
    final db = ScheduledDbHelper();

    debugPrint('--- DB INSPECTION ---');

    final sequences = await db.getMasterSequences();
    debugPrint('MASTER SEQUENCES: ${sequences.length}');
    for (var s in sequences) {
      debugPrint(
        'ID: ${s.id}, Title: ${s.title}, TagID: ${s.tagId}, Active: ${s.isActive}',
      );
      final messages = await db.getSequenceMessages(s.id!);
      debugPrint('  Messages: ${messages.length}');
      for (var m in messages) {
        debugPrint(
          '    - [MSG ID: ${m.id}] [${m.delayDays}d] ${m.title}: ${m.message.substring(0, m.message.length > 20 ? 20 : m.message.length)}...',
        );
      }
    }

    final subs = await db.getSubscriptions();
    debugPrint('SUBSCRIPTIONS: ${subs.length}');
    for (var sub in subs) {
      debugPrint(
        '  ID: ${sub.id}, Contact: ${sub.contactId}, Sequence: ${sub.sequenceId}, SubscribedAt: ${sub.subscribedAt}',
      );
    }

    debugPrint('--- END INSPECTION ---');
  }
}
