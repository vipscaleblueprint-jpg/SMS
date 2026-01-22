import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/master_sequence.dart';
import '../utils/db/scheduled_db_helper.dart';

class SequenceService {
  final ScheduledDbHelper _db = ScheduledDbHelper();

  Future<void> _ensureWelcomeSequenceExists() async {
    final sequences = await _db.getMasterSequences();
    final hasWelcome = sequences.any(
      (s) => s.title == 'Welcome Message' || s.tagId == 'new',
    );

    if (!hasWelcome) {
      debugPrint('🌱 Seeding default Welcome Message sequence...');
      // Note: We'll use 'new' as the tagId initially,
      // but WelcomeMessageScreen will later update it to the actual tag ID.
      // Actually, it's better to just leave it as 'new' for now if we don't have the tag list.
      // But wait, checkTriggers uses tag.id == seq.tagId.
      // So we NEED the actual ID.

      // We can't easily access the TagsProvider here since this is a plain class.
      // However, we can just look for a tag named 'new' in the database directly or use a known constant.
      // For now, let's just seed without the tagId if we can't find it, or just use 'new'.
      // If we use 'new', checkTriggers will fail because it compares IDs.

      final seqId = await _db.insertMasterSequence(
        MasterSequence(title: 'Welcome Message', tagId: 'new'),
      );

      await _db.insertSequenceMessage(
        SequenceMessage(
          sequenceId: seqId,
          title: 'Welcome SMS',
          message:
              'Welcome and thank you for connecting with us!\n\n'
              'We\'re pleased to have you as part of our contact list. By joining us, you\'ll receive relevant updates, insights, and information about our products, services, and industry developments that we believe will be valuable to you.\n\n'
              'Our goal is to keep you informed, supported, and up to date with content that helps you make confident, informed decisions. From time to time, we may also share important announcements, resources, or opportunities tailored to your interests.\n\n'
              'If you have any questions or would like to learn more about how we can support your business, please don\'t hesitate to reach out. We look forward to building a productive and successful relationship with you.\n\n'
              'Warm regards,\n'
              'VIP SCALE',
          delayDays: 0,
        ),
      );
    }

    // Safety Cleanup: Deactivate old "Onboarding sequence" (ID 1) if it exists and is active
    try {
      final onboarding = sequences
          .where((s) => s.id == 1 && s.title.contains('Onboarding'))
          .firstOrNull;
      if (onboarding != null && onboarding.isActive) {
        debugPrint(
          '🧹 Deactivating redundant "Onboarding sequence" to prevent duplicates.',
        );
        await _db.updateMasterSequence(
          MasterSequence(
            id: 1,
            title: onboarding.title,
            tagId: onboarding.tagId,
            isActive: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deactivating old sequence: $e');
    }
  }

  /// Checks if a contact should be subscribed to any active sequences based on their tags.
  Future<void> checkTriggers(Contact contact) async {
    await _ensureWelcomeSequenceExists();
    debugPrint(
      '🔔 Checking sequence triggers for contact: ${contact.first_name}',
    );
    final activeSequences = await _db.getMasterSequences();

    debugPrint('Found ${activeSequences.length} total sequences.');
    for (var s in activeSequences) {
      debugPrint(
        'Sequence: ${s.title}, ID: ${s.id}, Active: ${s.isActive}, TagID: ${s.tagId}',
      );
    }

    // Filter active sequences that match any of the contact's tags
    final matchingSequences = activeSequences
        .where(
          (seq) =>
              seq.isActive &&
              contact.tags.any((tag) {
                // 1. Exact ID match (Preferred)
                if (tag.id == seq.tagId) return true;

                // 2. Robust fallback for "Welcome Message":
                // If the sequence is named "Welcome Message" and the contact has "new" tag, treat as match.
                // This handles cases where tag IDs might have changed or been seeded differently.
                final isWelcomeSeq =
                    (seq.title == 'Welcome Message' || seq.tagId == 'new');
                final hasNewTag = tag.name.toLowerCase() == 'new';

                if (isWelcomeSeq && hasNewTag) {
                  debugPrint(
                    '✅ Robust Match: "Welcome Message" sequence matched to contact "${contact.first_name}" via "new" tag name.',
                  );
                  return true;
                }

                return false;
              }),
        )
        .toList();

    if (matchingSequences.isEmpty) {
      debugPrint(
        'No matching active sequences for this contact tags: ${contact.tags.map((t) => t.name).toList()}',
      );
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

      // Robust check: Is the contact still tagged for this sequence?
      bool hasMatchingTag = contact.tags.any((t) => t.id == sequence.tagId);

      // Robust fallback for "Welcome Message"
      if (!hasMatchingTag) {
        final isWelcomeSeq =
            (sequence.title == 'Welcome Message' || sequence.tagId == 'new');
        if (isWelcomeSeq) {
          hasMatchingTag = contact.tags.any(
            (t) => t.name.toLowerCase() == 'new',
          );
        }
      }

      // If sequence not found or tag is missing from contact, unsubscribe
      if (sequence.id == null || !hasMatchingTag) {
        debugPrint(
          '❌ Unsubscribing contact ${contact.contact_id} from sequence ${sequence.title}',
        );
        await _db.deleteSubscription(contact.contact_id, sub.sequenceId);
      }
    }
  }
}
