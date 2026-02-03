import 'package:another_telephony/telephony.dart' hide SmsStatus;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/contact.dart';
import '../models/sms.dart';
import '../utils/db/sms_db_helper.dart';

class SmsService {
  Telephony? _telephonyInstance;
  Telephony get _telephony => _telephonyInstance ??= Telephony.instance;

  Future<bool?> requestPermissions() async {
    final status = await [
      Permission.sms,
      Permission.phone,
      Permission.contacts,
      Permission.notification,
    ].request();

    return status[Permission.sms]?.isGranted == true &&
        status[Permission.phone]?.isGranted == true;
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
    // 1. Proactive Permission Guard
    // The background service (SchedulingService) calls this.
    // If permission is missing, another_telephony might try to request it on the main thread,
    // causing "IllegalStateException: Reply already submitted" crash.
    final isGranted = await Permission.sms.isGranted;
    if (!isGranted) {
      debugPrint('❌ SMS Permission NOT GRANTED. Aborting send to $address');
      _saveSmsStatus(
        id,
        contactId,
        address,
        message,
        SmsStatus.failed,
        batchId,
        batchTotal,
      );
      return;
    }

    SmsStatus status = SmsStatus.pending;
    try {
      debugPrint(
        '📱 SmsService: Calling _telephony.sendSms to $address (len: ${message.length})...',
      );
      // Some versions of telephony use isMultipart for long messages
      await _telephony.sendSms(
        to: address,
        message: message,
        isMultipart: true, // Handle messages > 160 characters
        statusListener: (status) {
          debugPrint('📡 Telephony status for $address: $status');
        },
      );
      debugPrint('✅ SmsService: _telephony.sendSms RETURNED for $address');
      status = SmsStatus.sent;
      debugPrint('✅ SMS status: SENT to $address');
    } catch (e) {
      status = SmsStatus.failed;
      debugPrint('❌ Failed to send SMS to $address: $e');
    } finally {
      await _saveSmsStatus(
        id,
        contactId,
        address,
        message,
        status,
        batchId,
        batchTotal,
      );
    }
  }

  Future<void> _saveSmsStatus(
    int? id,
    String? contactId,
    String address,
    String message,
    SmsStatus status,
    String? batchId,
    int? batchTotal,
  ) async {
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
      debugPrint('❌ Error saving SMS to database: $dbError');
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
    Map<String, String>? additionalTags,
  }) async {
    debugPrint(
      '🔵 sendFlexibleSms called - instant: $instant, scheduledTime: $scheduledTime',
    );

    // 1. Strip "Subject: " if present at the start (common in copy-pasted templates)
    String finalMessage = message;
    if (finalMessage.toLowerCase().startsWith('subject:')) {
      final lines = finalMessage.split('\n');
      if (lines.isNotEmpty) {
        // Remove the first line if it contains the subject
        final firstLine = lines.first;
        if (firstLine.toLowerCase().startsWith('subject:')) {
          finalMessage = lines.skip(1).join('\n').trim();
        }
      }
    }

    // 2. Perform variable substitution (Case-insensitive, space-insensitive)
    finalMessage = finalMessage
        .replaceAll(
          RegExp(r'\{\{\s*first_name\s*\}\}', caseSensitive: false),
          contact.first_name,
        )
        .replaceAll(
          RegExp(r'\{\{\s*last_name\s*\}\}', caseSensitive: false),
          contact.last_name,
        )
        .replaceAll(
          RegExp(r'\{\{\s*name\s*\}\}', caseSensitive: false),
          contact.name,
        )
        .replaceAll(
          RegExp(r'\{\{\s*email\s*\}\}', caseSensitive: false),
          contact.email ?? '',
        );

    // 3. Handle additional tags
    if (additionalTags != null) {
      additionalTags.forEach((key, value) {
        // Handle date filters if the value is a date string
        // Regex to match {{ key | date: "format" }} or just {{ key }}
        final dateRegex = RegExp(
          '\\{\\{\\s*$key\\s*\\|\\s*date:\\s*[\"\'](.*?)[\"\']\\s*\\}\\}',
        );
        final simpleRegex = RegExp('\\{\\{\\s*$key\\s*\\}\\}');

        final dateMatches = dateRegex.allMatches(finalMessage);
        if (dateMatches.isNotEmpty) {
          try {
            final dt = DateTime.tryParse(value);
            if (dt != null) {
              for (final match in dateMatches) {
                final liquidFormat = match.group(1) ?? '';
                final formattedDate = _formatLiquidDate(dt, liquidFormat);
                finalMessage = finalMessage.replaceFirst(
                  match.group(0)!,
                  formattedDate,
                );
              }
            }
          } catch (e) {
            debugPrint('Error formatting date for tag $key: $e');
          }
        }

        // Final simple replacement for non-filtered tags
        finalMessage = finalMessage.replaceAll(simpleRegex, value);
      });
    }

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

  String _formatLiquidDate(DateTime dt, String format) {
    if (format.isEmpty) return dt.toString();

    // Simple conversion from Liquid/strftime to intl DateFormat
    String pattern = format
        .replaceAll('%B', 'MMMM')
        .replaceAll('%b', 'MMM')
        .replaceAll('%d', 'dd')
        .replaceAll('%Y', 'yyyy')
        .replaceAll('%y', 'yy')
        .replaceAll('%I', 'hh')
        .replaceAll('%H', 'HH')
        .replaceAll('%M', 'mm')
        .replaceAll('%S', 'ss')
        .replaceAll('%k', 'H')
        .replaceAll('%l', 'h')
        .replaceAll('%p', 'a')
        .replaceAll('%P', 'a')
        .replaceAll('%Z', 'v');

    try {
      return DateFormat(pattern).format(dt);
    } catch (e) {
      debugPrint('DateFormat error: $e');
      return dt.toString();
    }
  }
}
