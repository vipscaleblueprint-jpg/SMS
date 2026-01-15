import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart' hide SmsStatus;
import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/sms.dart';
import '../utils/db/sms_db_helper.dart';

@pragma('vm:entry-point')
void sendScheduledSms(int id) async {
  print('🔔 sendScheduledSms callback triggered! Alarm ID: $id');
  print('🔔 Current time: ${DateTime.now()}');

  final prefs = await SharedPreferences.getInstance();
  final String? address = prefs.getString('sms_${id}_address');
  final String? message = prefs.getString('sms_${id}_message');

  print('🔔 Retrieved from prefs - address: $address, message: $message');

  if (address != null && message != null) {
    final Telephony telephony = Telephony.instance;
    try {
      print('🔔 Attempting to send SMS to $address...');
      await telephony.sendSms(to: address, message: message);
      print('✅ Background SMS sent to $address (Alarm ID: $id)');
      // Cleanup
      await prefs.remove('sms_${id}_address');
      await prefs.remove('sms_${id}_message');
      print('🔔 Cleaned up SharedPreferences for alarm $id');
    } catch (e) {
      print('❌ Failed to send background SMS: $e');
    }
  } else {
    print('⚠️ No SMS data found for Alarm ID: $id');
    print('⚠️ All keys in prefs: ${prefs.getKeys()}');
  }
}

class SmsService {
  final Telephony _telephony = Telephony.instance;

  Future<bool?> requestPermissions() async {
    return await _telephony.requestPhoneAndSmsPermissions;
  }

  Future<List<SmsMessage>> getInboxMessages() async {
    return await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );
  }

  Future<List<SmsMessage>> getSentMessages() async {
    return await _telephony.getSentSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );
  }

  Future<void> sendSms({
    required String address,
    required String message,
    String? contactId,
  }) async {
    SmsStatus status = SmsStatus.pending;
    try {
      await _telephony.sendSms(to: address, message: message);
      status = SmsStatus.sent;
    } catch (e) {
      status = SmsStatus.failed;
      rethrow;
    } finally {
      // Save to database regardless of outcome
      try {
        final sms = Sms(
          contact_id: contactId,
          phone_number: address,
          message: message,
          status: status,
          sentTimeStamps: status == SmsStatus.sent ? DateTime.now() : null,
        );
        await SmsDbHelper().insertSms(sms);
      } catch (dbError) {
        print('Error saving SMS to database: $dbError');
      }
    }
  }

  /// Sends a batch of SMS messages to multiple [recipients].
  ///
  /// Returns a [Stream] that yields the number of messages sent so far.
  /// This allows the UI to show a progress bar.
  ///
  /// [delay] is an optional pause between messages to avoid spam filters or rate limits.
  Stream<int> sendBatchSms({
    required List<String> recipients,
    required String message,

    Duration delay = const Duration(milliseconds: 200),
  }) async* {
    int sentCount = 0;
    for (final recipient in recipients) {
      if (recipient.trim().isEmpty) continue;

      try {
        await sendSms(address: recipient, message: message);
        // Small delay to be safe/polite to the OS/network
        await Future.delayed(delay);
      } catch (e) {
        // Log error but continue sending to others
        // In a real app, we might want to track failed numbers
        print("Failed to send to $recipient: $e");
      }

      sentCount++;
      yield sentCount;
    }
  }

  /// Sends a batch of SMS messages using detailed [contacts] information.
  /// Allows for variable substitution in [message].
  Stream<int> sendBatchSmsWithDetails({
    required List<Contact> contacts,
    required String message,
    bool instant = true,
    DateTime? scheduledTime,
    int simSlot = 1,
    Duration delay = const Duration(milliseconds: 200),
  }) async* {
    int sentCount = 0;
    for (final contact in contacts) {
      // Reuse sendFlexibleSms logic for substitution and sending
      try {
        await sendFlexibleSms(
          contact: contact,
          message: message,
          instant: instant,
          scheduledTime: scheduledTime,
          simSlot: simSlot,
        );
        // Small delay between sends if instant
        if (instant) {
          await Future.delayed(delay);
        }
      } catch (e) {
        print("Failed to send to ${contact.phone}: $e");
      }

      sentCount++;
      yield sentCount;
    }
  }

  Future<void> sendFlexibleSms({
    required Contact contact,
    required String message,
    bool instant = true,
    DateTime? scheduledTime,
    int simSlot = 1,
  }) async {
    debugPrint(
      '🔵 sendFlexibleSms called - instant: $instant, scheduledTime: $scheduledTime',
    );

    // Perform variable substitution
    String finalMessage = message
        .replaceAll('{{first_name}}', contact.first_name)
        .replaceAll('{{last_name}}', contact.last_name)
        .replaceAll('{{name}}', contact.name)
        .replaceAll('{{email}}', contact.email ?? '');

    if (instant) {
      debugPrint('📤 Sending instant SMS to ${contact.phone}');
      if (simSlot == 1) {
        await sendSms(
          address: contact.phone,
          message: finalMessage,
          contactId: contact.contact_id,
        );
      } else if (simSlot == 2) {
        await sendSms(
          address: contact.phone,
          message: finalMessage,
          contactId: contact.contact_id,
        );
      }
    } else if (scheduledTime != null) {
      debugPrint('⏰ Scheduling SMS to ${contact.phone} for $scheduledTime');
      try {
        final delay = scheduledTime.difference(DateTime.now());
        if (delay.isNegative) {
          print('Scheduled time is in the past. Sending immediately.');
          await sendSms(
            address: contact.phone,
            message: finalMessage,
            contactId: contact.contact_id,
          );
          return;
        }

        // Generate a unique ID (within 32-bit int range)
        final int id = DateTime.now().millisecondsSinceEpoch % 0x7FFFFFFF;

        // Save data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sms_${id}_address', contact.phone);
        await prefs.setString('sms_${id}_message', finalMessage);

        // Verify data was saved
        final savedAddress = prefs.getString('sms_${id}_address');
        final savedMessage = prefs.getString('sms_${id}_message');
        debugPrint(
          '✅ Saved to SharedPreferences - address: $savedAddress, message: $savedMessage',
        );

        await AndroidAlarmManager.oneShot(
          delay,
          id,
          sendScheduledSms,
          exact: true, // CRITICAL: Changed to true for reliable execution
          wakeup: true,
        );

        debugPrint(
          '✅ AndroidAlarmManager.oneShot called with ID: $id, delay: ${delay.inMinutes} mins, EXACT: TRUE',
        );

        // Save to Database as Pending
        try {
          final sms = Sms(
            contact_id: contact.contact_id,
            phone_number: contact.phone,
            message: finalMessage,
            status: SmsStatus.pending,
            schedule_time: scheduledTime,
          );
          await SmsDbHelper().insertSms(sms);
        } catch (dbError) {
          print('Error saving scheduled SMS to database: $dbError');
        }

        print(
          '✅ SMS scheduled for ${contact.name} (${contact.phone}) at $scheduledTime (in ${delay.inMinutes} mins) [Alarm ID: $id]: "$finalMessage"',
        );
      } catch (e) {
        print('❌ Failed to schedule SMS: $e');
        try {
          final sms = Sms(
            contact_id: contact.contact_id,
            phone_number: contact.phone,
            message: finalMessage,
            status: SmsStatus.failed,
            schedule_time: scheduledTime,
          );
          await SmsDbHelper().insertSms(sms);
        } catch (dbError) {
          print('Error saving failed scheduled SMS to database: $dbError');
        }
        rethrow;
      }
    } else {
      print('⚠️ No scheduled time provided for non‑instant send');
    }
  }
}
