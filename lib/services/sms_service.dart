import 'package:another_telephony/telephony.dart' hide SmsStatus;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/contact.dart';
import '../models/sms.dart';
import '../utils/db/sms_db_helper.dart';

class SmsService {
  Telephony get _telephony => Telephony.instance;

  Future<bool?> requestPermissions() async {
    final sms = await Permission.sms.request();
    final phone = await Permission.phone.request();
    return sms.isGranted && phone.isGranted;
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
    int? id,
    String? contactId,
    String? batchId,
    int? batchTotal,
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
          id: id,
          contact_id: contactId,
          phone_number: address,
          message: message,
          status: status,
          sentTimeStamps: status == SmsStatus.sent ? DateTime.now() : null,
          batchId: batchId,
          batchTotal: batchTotal,
        );

        if (id != null) {
          await SmsDbHelper().updateSms(sms);
        } else {
          await SmsDbHelper().insertSms(sms);
        }
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
    final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';
    final batchTotal = recipients.length;
    for (final recipient in recipients) {
      if (recipient.trim().isEmpty) continue;

      try {
        await sendSms(
          address: recipient,
          message: message,
          batchId: batchId,
          batchTotal: batchTotal,
        );
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
    final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';
    final batchTotal = contacts.length;
    for (final contact in contacts) {
      // Reuse sendFlexibleSms logic for substitution and sending
      try {
        await sendFlexibleSms(
          contact: contact,
          message: message,
          instant: instant,
          scheduledTime: scheduledTime,
          simSlot: simSlot,
          batchId: batchId,
          batchTotal: batchTotal,
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
    String? batchId,
    int? batchTotal,
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
          batchId: batchId,
          batchTotal: batchTotal,
        );
      } else if (simSlot == 2) {
        await sendSms(
          address: contact.phone,
          message: finalMessage,
          contactId: contact.contact_id,
          batchId: batchId,
          batchTotal: batchTotal,
        );
      }
    } else if (scheduledTime != null) {
      debugPrint('⏰ DB-Scheduling SMS to ${contact.phone} for $scheduledTime');
      try {
        final delay = scheduledTime.difference(DateTime.now());
        if (delay.isNegative) {
          debugPrint('Scheduled time is in the past. Sending immediately.');
          await sendSms(
            address: contact.phone,
            message: finalMessage,
            contactId: contact.contact_id,
          );
          return;
        }

        // Save to Database as Pending for SchedulingService to pick up
        try {
          final sms = Sms(
            contact_id: contact.contact_id,
            phone_number: contact.phone,
            message: finalMessage,
            status: SmsStatus.pending,
            schedule_time: scheduledTime,
            batchId: batchId,
            batchTotal: batchTotal,
          );
          await SmsDbHelper().insertSms(sms);
          debugPrint(
            '✅ SMS saved to DB for scheduling: ${contact.name} (${contact.phone}) at $scheduledTime',
          );
        } catch (dbError) {
          debugPrint('Error saving scheduled SMS to database: $dbError');
          rethrow;
        }
      } catch (e) {
        debugPrint('❌ Failed to schedule SMS in DB: $e');
        rethrow;
      }
    } else {
      debugPrint('⚠️ No scheduled time provided for non‑instant send');
    }
  }
}
