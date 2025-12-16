import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';
import '../models/contact.dart';

@pragma('vm:entry-point')
void sendScheduledSms(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final String? address = prefs.getString('sms_${id}_address');
  final String? message = prefs.getString('sms_${id}_message');

  if (address != null && message != null) {
    final Telephony telephony = Telephony.instance;
    try {
      await telephony.sendSms(to: address, message: message);
      print('Background SMS sent to $address (Alarm ID: $id)');
      // Cleanup
      await prefs.remove('sms_${id}_address');
      await prefs.remove('sms_${id}_message');
    } catch (e) {
      print('Failed to send background SMS: $e');
    }
  } else {
    print('No SMS data found for Alarm ID: $id');
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

  Future<void> sendSms({
    required String address,
    required String message,
  }) async {
    await _telephony.sendSms(to: address, message: message);
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

  /// Sends an SMS with options for scheduling and SIM selection.
  ///
  /// [contact] is the phone number.
  /// [instant] if true, sends immediately.
  /// [scheduledTime] if provided and [instant] is false, schedules the message (implementation depends on scheduling mechanism).
  /// [simSlot] 1 for SIM 1, 2 for SIM 2. Note: SIM selection depends on platform support.
  /// Sends an SMS with options for scheduling and SIM selection.
  ///
  /// [contact] is the Contact object containing details for variable substitution.
  /// [instant] if true, sends immediately.
  /// [scheduledTime] if provided and [instant] is false, schedules the message.
  /// [simSlot] 1 for SIM 1, 2 for SIM 2.
  Future<void> sendFlexibleSms({
    required Contact contact,
    required String message,
    bool instant = true,
    DateTime? scheduledTime,
    int simSlot = 1,
  }) async {
    // Perform variable substitution
    String finalMessage = message
        .replaceAll('{{first_name}}', contact.first_name)
        .replaceAll('{{last_name}}', contact.last_name)
        .replaceAll('{{name}}', contact.name)
        .replaceAll('{{email}}', contact.email ?? '');

    if (instant) {
      if (simSlot == 1) {
        await sendSms(address: contact.phone, message: finalMessage);
      } else if (simSlot == 2) {
        await sendSms(address: contact.phone, message: finalMessage);
      }
    } else if (scheduledTime != null) {
      try {
        final delay = scheduledTime.difference(DateTime.now());
        if (delay.isNegative) {
          print('Scheduled time is in the past. Sending immediately.');
          await sendSms(address: contact.phone, message: finalMessage);
          return;
        }

        // Generate a unique ID (within 32-bit int range)
        final int id = DateTime.now().millisecondsSinceEpoch % 0x7FFFFFFF;

        // Save data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sms_${id}_address', contact.phone);
        await prefs.setString('sms_${id}_message', finalMessage);

        await AndroidAlarmManager.oneShot(
          delay,
          id,
          sendScheduledSms,
          exact: true,
          wakeup: true,
        );

        print(
          '✅ SMS scheduled for ${contact.name} (${contact.phone}) at $scheduledTime (in ${delay.inMinutes} mins) [Alarm ID: $id]: "$finalMessage"',
        );
      } catch (e) {
        print('❌ Failed to schedule SMS: $e');
        rethrow;
      }
    } else {
      print('⚠️ No scheduled time provided for non‑instant send');
    }
  }
}
