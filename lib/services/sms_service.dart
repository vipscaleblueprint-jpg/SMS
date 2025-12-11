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
}
