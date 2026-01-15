import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/scheduled_sms.dart';
import '../utils/db/contact_db_helper.dart';
import '../utils/db/scheduled_db_helper.dart';
import '../utils/scheduling_utils.dart';
import 'sms_service.dart';

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

  @pragma('vm:entry-point')
  static void dispatcher() async {
    final now = DateTime.now();
    debugPrint('⏰ Background check at $now');

    final dbHelper = ScheduledDbHelper();
    final contactDb = ContactDbHelper.instance;
    final smsService = SmsService();

    try {
      final dueMessages = await dbHelper.getDueMessages(now);
      if (dueMessages.isEmpty) {
        debugPrint('No due messages found.');
        return;
      }

      debugPrint('Found ${dueMessages.length} due messages.');

      for (final msg in dueMessages) {
        await _processMessage(msg, dbHelper, contactDb, smsService);
      }
    } catch (e) {
      debugPrint('❌ Error in background dispatcher: $e');
    }
  }

  static Future<void> _processMessage(
    ScheduledSms msg,
    ScheduledDbHelper dbHelper,
    ContactDbHelper contactDb,
    SmsService smsService,
  ) async {
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
      for (final contact in targetContacts) {
        try {
          // Use SmsService's flexible send logic
          await smsService.sendFlexibleSms(
            contact: contact,
            message: msg.message,
            instant:
                true, // Background send is technically "instant" once triggered
          );
        } catch (e) {
          debugPrint('Failed to send to ${contact.phone}: $e');
        }
      }

      // 4. Update Message Status / Calculate Next Run
      DateTime? nextRun;
      if (msg.frequency == 'Monthly' && msg.scheduledDay != null) {
        nextRun = SchedulingUtils.getNextMonthlyDate(
          msg.scheduledDay!,
          DateTime.now(),
        );
      } else if (msg.frequency == 'Weekly' && msg.scheduledDay != null) {
        nextRun = SchedulingUtils.getNextWeeklyDate(
          msg.scheduledDay!,
          DateTime.now(),
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
}
