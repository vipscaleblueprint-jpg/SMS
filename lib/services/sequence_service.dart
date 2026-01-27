import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/master_sequence.dart';
import '../utils/db/scheduled_db_helper.dart';

class SequenceService {
  final ScheduledDbHelper _db = ScheduledDbHelper();

  /// Checks if a contact should be subscribed to any active sequences based on their tags.
  Future<void> checkTriggers(Contact contact) async {
    debugPrint(
      '🔔 Checking sequence triggers for contact: ${contact.first_name}',
    );
    final activeSequences = await _db.getMasterSequences();

    // Filter active sequences that match any of the contact's tags
    final matchingSequences = activeSequences.where(
      (seq) => seq.isActive && contact.tags.any((tag) => tag.id == seq.tagId),
    );

    if (matchingSequences.isEmpty) {
      debugPrint('No matching active sequences for this contact tags.');
      return;
    }

    final existingSubscriptions = await _db.getSubscriptions();

    for (final sequence in matchingSequences) {
      // Check if already subscribed
      final alreadySubscribed = existingSubscriptions.any(
        (sub) =>
            sub.contactId == contact.contact_id &&
            sub.sequenceId == sequence.id,
      );

      if (!alreadySubscribed) {
        debugPrint(
          '✅ Subscribing contact ${contact.contact_id} to sequence ${sequence.title}',
        );
        final subscription = SequenceSubscription(
          contactId: contact.contact_id,
          sequenceId: sequence.id!,
          subscribedAt: DateTime.now(),
        );
        await _db.insertSubscription(subscription);
      } else {
        debugPrint('Contact already subscribed to sequence ${sequence.title}');
      }
    }
  }

  /// Removes subscriptions for a sequence when a tag is removed from a contact.
  /// This is optional depending on requirements, but for "email subscription" style,
  /// usually if you untag they stop getting messages.
  Future<void> syncSubscriptions(Contact contact) async {
    // 1. Check triggers for new tags
    await checkTriggers(contact);

    // 2. Remove subscriptions if the tag is no longer present
    final allSubscriptions = await _db.getSubscriptions();
    final contactSubs = allSubscriptions.where(
      (s) => s.contactId == contact.contact_id,
    );

    final activeSequences = await _db.getMasterSequences();

    for (final sub in contactSubs) {
      final sequence = activeSequences.firstWhere(
        (s) => s.id == sub.sequenceId,
        orElse: () => MasterSequence(title: '', tagId: '', isActive: false),
      );

      // If sequence not found or tag is missing from contact, unsubscribe
      if (sequence.id == null ||
          !contact.tags.any((t) => t.id == sequence.tagId)) {
        debugPrint(
          '❌ Unsubscribing contact ${contact.contact_id} from sequence ${sequence.title}',
        );
        await _db.deleteSubscription(contact.contact_id, sub.sequenceId);
      }
    }

    // 3. Inspect status
    await inspectContact(contact);
  }

  /// Troubleshooting utility to inspect a contact's sequence state
  Future<void> inspectContact(Contact contact) async {
    debugPrint('\n--- INSPECTING CONTACT: ${contact.first_name} ---');
    debugPrint('Tags: ${contact.tags.map((t) => t.name).join(', ')}');

    final subs = await _db.getSubscriptions();
    final contactSubs = subs.where((s) => s.contactId == contact.contact_id);

    debugPrint('Active Subscriptions: ${contactSubs.length}');
    for (final sub in contactSubs) {
      debugPrint(
        ' - Seq ID: ${sub.sequenceId} (Subscribed: ${sub.subscribedAt})',
      );

      // Calculate due messages
      final messages = await _db.getSequenceMessages(sub.sequenceId);
      for (final msg in messages) {
        final dueDate = sub.subscribedAt.add(Duration(days: msg.delayDays));
        final isDue = DateTime.now().isAfter(dueDate);
        debugPrint(
          '   -> Msg: "${msg.message.length > 20 ? msg.message.substring(0, 20) : msg.message}..." Due: $dueDate (${isDue ? "READY" : "WAITING"})',
        );
      }
    }
    debugPrint('--- END INSPECTION ---\n');
  }
}
