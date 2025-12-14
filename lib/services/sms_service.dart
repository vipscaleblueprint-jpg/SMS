import 'package:another_telephony/telephony.dart';

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
}
