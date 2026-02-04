import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/scheduled_sms.dart';
import '../utils/db/contact_db_helper.dart';
import '../utils/db/scheduled_db_helper.dart';
import '../utils/db/sms_db_helper.dart';
import '../utils/db/event_db_helper.dart';
import 'dart:convert';
import '../models/events.dart';
import '../utils/scheduling_utils.dart';
import '../models/sms.dart' as sms_model;
import 'sms_service.dart';
import '../utils/db/user_db_helper.dart';

@pragma('vm:entry-point')
Future<void> dispatcher() async {
  final now = DateTime.now();
  debugPrint('⏰ Background check at $now');

  final dbHelper = ScheduledDbHelper();
  final oneTimeDbHelper = SmsDbHelper();
  final contactDb = ContactDbHelper.instance;
  final userDb = UserDbHelper();

  try {
    // 0. Fetch User Profile for sender name resolution
    String? senderName;
    final user = await userDb.getUser();
    if (user != null) {
      senderName = user.name;
    }
    debugPrint('👤 Sender Name for this run: $senderName');

    // 1. Process Campaign Messages (Recurring)
    final dueMessages = await dbHelper.getDueMessages(now);
    debugPrint('Due Campaign Messages count: ${dueMessages.length}');
    if (dueMessages.isNotEmpty) {
      final smsService = SmsService();
      for (final msg in dueMessages) {
        await SchedulingService.processMessage(
          msg,
          dbHelper,
          contactDb,
          smsService,
          senderName: senderName,
        );
      }
    }

    // 2. Process One-Time Scheduled Messages (SendScreen)
    final dueOneTime = await oneTimeDbHelper.getDueOneTimeMessages(now);
    debugPrint('Due One-Time Messages count: ${dueOneTime.length}');
    if (dueOneTime.isNotEmpty) {
      final smsService = SmsService();
      for (final msg in dueOneTime) {
        await SchedulingService.processOneTimeMessage(
          msg,
          oneTimeDbHelper,
          smsService,
          senderName: senderName,
        );
      }
    }
    // 3. Process Event Messages (Broadcasts)
    final dueEvents = await oneTimeDbHelper.getDueEventMessages(now);
    debugPrint('Due Event Template Messages count: ${dueEvents.length}');
    if (dueEvents.isNotEmpty) {
      final smsService = SmsService();
      final eventDb = EventDbHelper();
      for (final msg in dueEvents) {
        await SchedulingService.processEventTemplate(
          msg,
          oneTimeDbHelper,
          eventDb,
          contactDb,
          smsService,
          senderName: senderName,
        );
      }
    }

    // 4. Process Master Sequences (Drip)
    await SchedulingService.processSequences(
      dbHelper,
      contactDb,
      SmsService(),
      senderName: senderName,
    );
  } catch (e) {
    debugPrint('❌ Error in background dispatcher: $e');
  }
}

@pragma('vm:entry-point')
class SchedulingService {
  static const int _alarmId = 1000;

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    await start();
  }

  static Future<void> start() async {
    await AndroidAlarmManager.periodic(
      const Duration(minutes: 1),
      _alarmId,
      dispatcher,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
    debugPrint('🚀 Scheduling Service started (periodic check every 1 min)');
  }

  static Future<void> processOneTimeMessage(
    sms_model.Sms msg,
    SmsDbHelper dbHelper,
    SmsService smsService, {
    String? senderName,
  }) async {
    debugPrint('Processing One-Time: ${msg.id} for ${msg.phone_number}');
    if (msg.phone_number == null) {
      debugPrint(
        '⚠️ Missing phone number for message ${msg.id}. Marking as failed.',
      );
      final failedSms = sms_model.Sms(
        id: msg.id,
        title: msg.title,
        message: msg.message,
        contact_id: msg.contact_id,
        phone_number: null,
        status: sms_model.SmsStatus.failed,
        schedule_time: msg.schedule_time,
      );
      await dbHelper.updateSms(failedSms);
      return;
    }

    try {
      // Send the SMS
      await smsService.sendSms(
        address: msg.phone_number!,
        message: msg.message,
        id: msg.id, // Pass ID to update existing record
        contactId: msg.contact_id,
        // Proactively resolve your_name here if needed, but sendSms also calls flexible send eventually?
        // Wait, sendSms in SmsService DOES NOT call flexibleSend. It sends RAW.
        // We should use flexible send if we want variable resolution for one-time messages too,
        // BUT traditionally one-time messages are already resolved in the UI.
        // Let's check SendScreen.
      );
      // Removed redundant updateSms call as sendSms now handles it.
    } catch (e) {
      debugPrint('❌ Error processing one-time message ${msg.id}: $e');
      // Removed redundant updateSms call as sendSms now handles it via internal finally block.
    }
  }

  static Future<void> processMessage(
    ScheduledSms msg,
    ScheduledDbHelper dbHelper,
    ContactDbHelper contactDb,
    SmsService smsService, {
    String? senderName,
  }) async {
    debugPrint('Processing: ${msg.title}');

    try {
      // 1. Resolve Recipients
      Set<String> contactIds = msg.contactIds;
      Set<String> tagIds = msg.tagIds;

      if (contactIds.isEmpty && tagIds.isEmpty) {
        // Inherit from group
        final group = await dbHelper.getGroupById(msg.groupId);
        if (group != null) {
          contactIds = group.contactIds;
          tagIds = group.tagIds;
        }
      }

      if (contactIds.isEmpty && tagIds.isEmpty) {
        debugPrint('⚠️ No recipients found for message ${msg.id}. Skipping.');
        // Maybe mark as failed or just wait for user to fix
        return;
      }

      // 2. Fetch Contacts
      final Set<Contact> targetContacts = {};

      if (contactIds.isNotEmpty) {
        final contacts = await contactDb.getContactsByIds(contactIds.toList());
        targetContacts.addAll(contacts);
      }

      if (tagIds.isNotEmpty) {
        final contacts = await contactDb.getContactsByTagIds(tagIds.toList());
        targetContacts.addAll(contacts);
      }

      if (targetContacts.isEmpty) {
        debugPrint('⚠️ Resolved recipients resulted in 0 contacts. Skipping.');
        return;
      }

      // 3. Send SMS (Loop through contacts)
      debugPrint('Sending to ${targetContacts.length} contacts...');
      final batchId =
          'campaign_${msg.id}_${DateTime.now().millisecondsSinceEpoch}';
      final batchTotal = targetContacts.length;

      for (final contact in targetContacts) {
        try {
          // Use SmsService's flexible send logic
          await smsService.sendFlexibleSms(
            contact: contact,
            message: msg.message,
            instant: true,
            batchId: batchId,
            batchTotal: batchTotal,
            senderName: senderName,
          );
        } catch (e) {
          debugPrint('Failed to send to ${contact.phone}: $e');
        }
      }

      // 4. Update Message Status / Calculate Next Run
      DateTime? nextRun;
      final originalTime = msg.scheduledTime;
      final hour = originalTime?.hour ?? 9;
      final minute = originalTime?.minute ?? 0;

      if (msg.frequency == 'Monthly' && msg.scheduledDay != null) {
        nextRun = SchedulingUtils.getNextMonthlyDate(
          msg.scheduledDay!,
          DateTime.now(),
          hour: hour,
          minute: minute,
        );
      } else if (msg.frequency == 'Weekly' && msg.scheduledDay != null) {
        nextRun = SchedulingUtils.getNextWeeklyDate(
          msg.scheduledDay!,
          DateTime.now(),
          hour: hour,
          minute: minute,
        );
      }

      final updatedMessage = ScheduledSms(
        id: msg.id,
        groupId: msg.groupId,
        title: msg.title,
        frequency: msg.frequency,
        scheduledDay: msg.scheduledDay,
        message: msg.message,
        isActive: msg.isActive,
        status: nextRun != null ? 'pending' : 'sent',
        scheduledTime: nextRun,
        contactIds: msg.contactIds,
        tagIds: msg.tagIds,
      );

      await dbHelper.updateMessage(updatedMessage);
      debugPrint('✅ Message ${msg.id} processed. Next run: $nextRun');
    } catch (e) {
      debugPrint('❌ Error processing message ${msg.id}: $e');
    }
  }

  static Future<void> processSequences(
    ScheduledDbHelper dbHelper,
    ContactDbHelper contactDb,
    SmsService smsService, {
    String? senderName,
  }) async {
    debugPrint('Processing Master Sequences...');
    try {
      final subscriptions = await dbHelper.getSubscriptions();
      debugPrint(
        'Found ${subscriptions.length} active sequence subscriptions.',
      );
      final now = DateTime.now();

      for (final sub in subscriptions) {
        debugPrint(
          'Checking subscription ${sub.id} (Sequence ${sub.sequenceId}) for contact ${sub.contactId}',
        );
        // Find messages for this sequence
        final messages = await dbHelper.getSequenceMessages(sub.sequenceId);
        debugPrint(
          'Sequence ${sub.sequenceId} has ${messages.length} messages.',
        );

        for (final msg in messages) {
          final dueAt = sub.subscribedAt.add(Duration(days: msg.delayDays));
          final isDue = now.isAfter(dueAt);
          debugPrint(
            '-- Message "${msg.title}" (Delay: ${msg.delayDays} days) - Due at: $dueAt - IsDue: $isDue',
          );

          if (isDue) {
            // Check if already sent
            final alreadySent = await dbHelper.hasSentSequenceMessage(
              sub.id!,
              msg.id!,
            );

            if (!alreadySent) {
              debugPrint(
                '🚀 Sending drip message: ${msg.title} to contact ${sub.contactId}',
              );
              debugPrint('Attempting to resolve contact ${sub.contactId}...');

              // Resolve contact
              final contacts = await contactDb.getContactsByIds([
                sub.contactId,
              ]);
              debugPrint('Resolved contacts: ${contacts.length}');

              if (contacts.isEmpty) {
                debugPrint(
                  '⚠️ Contact ${sub.contactId} no longer exists. Deleting ghost subscription.',
                );
                await dbHelper.deleteSubscription(
                  sub.contactId,
                  sub.sequenceId,
                );
                // Break out of this sequence of messages for a non-existent contact
                break;
              }

              final contact = contacts.first;
              debugPrint(
                'Contact found: ${contact.name}, Phone: ${contact.phone}. Calling sendFlexibleSms...',
              );

              try {
                await smsService.sendFlexibleSms(
                  contact: contact,
                  message: msg.message,
                  instant: true,
                  senderName: senderName,
                );

                // Log as sent
                await dbHelper.insertSequenceLog(sub.id!, msg.id!);
                debugPrint('✅ Drip message ${msg.id} logged as sent.');
              } catch (e) {
                debugPrint('Failed to send drip to ${contact.phone}: $e');
              }
            } else {
              debugPrint(
                'ℹ️ Message "${msg.title}" already sent to contact ${sub.contactId}. Skipping.',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing sequences: $e');
    }
  }

  static Future<void> processEventTemplate(
    sms_model.Sms msg,
    SmsDbHelper dbHelper,
    EventDbHelper eventDb,
    ContactDbHelper contactDb,
    SmsService smsService, {
    String? senderName,
  }) async {
    debugPrint(
      'Processing Event Broadcast: ${msg.title} (Event: ${msg.event_id})',
    );

    if (msg.event_id == null) return;

    try {
      // 1. Resolve Event
      final event = await eventDb.getEventById(msg.event_id!);
      if (event == null) {
        debugPrint(
          '⚠️ Event ${msg.event_id} not found. Marking message as failed.',
        );
        final failedSms = sms_model.Sms(
          id: msg.id,
          title: msg.title,
          message: msg.message,
          event_id: msg.event_id,
          status: sms_model.SmsStatus.failed,
          schedule_time: msg.schedule_time,
        );
        await dbHelper.updateSms(failedSms);
        return;
      }

      // 2. Resolve Recipients
      final Set<Contact> targetContacts = {};
      if (event.recipients != null) {
        try {
          final decoded = jsonDecode(event.recipients!) as Map<String, dynamic>;

          if (decoded.containsKey('contacts')) {
            final contactIds = List<String>.from(decoded['contacts']);
            if (contactIds.isNotEmpty) {
              final contacts = await contactDb.getContactsByIds(contactIds);
              targetContacts.addAll(contacts);
            }
          }

          if (decoded.containsKey('tags')) {
            final tagIds = List<String>.from(decoded['tags']);
            if (tagIds.isNotEmpty) {
              final contacts = await contactDb.getContactsByTagIds(tagIds);
              debugPrint(
                'Resolved ${contacts.length} contacts from tags: $tagIds',
              );
              targetContacts.addAll(contacts);
            }
          }
        } catch (e) {
          debugPrint('❌ Error parsing event recipients: $e');
        }
      }

      if (targetContacts.isEmpty) {
        debugPrint(
          '⚠️ No recipients resolved for event ${event.id}. Marking template as sent (nothing to do).',
        );
        final completedSms = sms_model.Sms(
          id: msg.id,
          title: msg.title,
          message: msg.message,
          event_id: msg.event_id,
          status: sms_model
              .SmsStatus
              .sent, // We mark as sent to stop it re-triggering
          schedule_time: msg.schedule_time,
        );
        await dbHelper.updateSms(completedSms);
        return;
      }

      // 3. Broadcast SMS
      debugPrint('Broadcasting to ${targetContacts.length} contacts...');
      for (final contact in targetContacts) {
        try {
          await smsService.sendFlexibleSms(
            contact: contact,
            message: msg.message,
            instant: true,
            batchId:
                'event_${msg.id}_${DateTime.now().millisecondsSinceEpoch}', // Group these messages in history
            additionalTags: {'event_time': event.date.toIso8601String()},
            senderName: senderName,
          );
        } catch (e) {
          debugPrint('Failed to send to ${contact.phone}: $e');
        }
      }

      // 4. Update Template Status
      final sentSms = sms_model.Sms(
        id: msg.id,
        title: msg.title,
        message: msg.message,
        event_id: msg.event_id,
        status: sms_model.SmsStatus.sent,
        schedule_time: msg.schedule_time,
        sentTimeStamps: DateTime.now(),
      );
      await dbHelper.updateSms(sentSms);
      debugPrint('✅ Event Broadcast ${msg.id} completed.');
    } catch (e) {
      debugPrint('❌ Error processing event broadcast ${msg.id}: $e');
    }
  }
}
