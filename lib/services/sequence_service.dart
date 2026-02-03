import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/master_sequence.dart';
import '../models/tag.dart';
import '../utils/db/scheduled_db_helper.dart';
import '../utils/db/tags_db_helper.dart';

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

  /// Ensures the "Welcome Sequence" exists and is tied to the 'new' tag.
  Future<void> initializeWelcomeSequence() async {
    debugPrint('🚀 Initializing Welcome Sequence...');
    try {
      final tagsDb = TagsDbHelper.instance;

      // 1. Get or create 'new' tag
      var newTag = await tagsDb.getTagByName('new');
      if (newTag == null) {
        debugPrint('Creating "new" tag...');
        newTag = Tag(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'new',
          created: DateTime.now(),
        );
        await tagsDb.insertTag(newTag);
      }

      // 2. Get or create Master Sequence
      final sequences = await _db.getMasterSequences();
      var welcomeSeq = sequences.firstWhere(
        (s) => s.title == 'Welcome Sequence' || s.tagId == newTag!.id,
        orElse: () => MasterSequence(title: '', tagId: '', isActive: false),
      );

      int seqId;
      if (welcomeSeq.id == null) {
        debugPrint('Creating "Welcome Sequence"...');
        welcomeSeq = MasterSequence(
          title: 'Welcome Sequence',
          tagId: newTag.id,
          isActive: true,
        );
        seqId = await _db.insertMasterSequence(welcomeSeq);
      } else {
        seqId = welcomeSeq.id!;
      }

      // 3. Ensure the welcome message exists and is correct
      const welcomeText =
          'Welcome and thank you for connecting with us!\n\n'
          'We\'re pleased to have you as part of our contact list. By joining us, you\'ll receive relevant updates, insights, and information about our products, services, and industry developments that we believe will be valuable to you.\n\n'
          'Our goal is to keep you informed, supported, and up to date with content that helps you make confident, informed decisions. From time to time, we may also share important announcements, resources, or opportunities tailored to your interests.\n\n'
          'If you have any questions or would like to learn more about how we can support your business, please don\'t hesitate to reach out. We look forward to building a productive and successful relationship with you.\n\n'
          'Warm regards,\n'
          'VIP SCALE';

      final messages = await _db.getSequenceMessages(seqId);
      if (messages.isEmpty) {
        debugPrint('Creating initial welcome message...');
        final welcomeMsg = SequenceMessage(
          sequenceId: seqId,
          title: 'Welcome Message',
          message: welcomeText,
          delayDays: 0,
        );
        await _db.insertSequenceMessage(welcomeMsg);
      } else if (messages.first.message.trim().length < 50) {
        // If message is too short (likely a placeholder), update it
        debugPrint('Updating short placeholder welcome message...');
        final existing = messages.first;
        final updated = SequenceMessage(
          id: existing.id,
          sequenceId: existing.sequenceId,
          title: existing.title,
          message: welcomeText,
          delayDays: existing.delayDays,
        );

        final dbInstance = await _db.database;
        await dbInstance.update(
          'sequence_messages',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      }
      debugPrint('✅ Welcome Sequence initialized.');
    } catch (e) {
      debugPrint('❌ Failed to initialize welcome sequence: $e');
    }
  }
}
