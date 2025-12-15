import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/sms.dart';
import '../utils/db/sms_db_helper.dart';

final smsProvider = StateNotifierProvider<SmsNotifier, List<Sms>>((ref) {
  return SmsNotifier();
});

class SmsNotifier extends StateNotifier<List<Sms>> {
  SmsNotifier() : super([]) {
    loadSms();
  }

  Future<void> loadSms() async {
    final smsList = await SmsDbHelper().getSmsList();
    state = smsList;
  }

  Future<void> addSms(Sms sms) async {
    await SmsDbHelper().insertSms(sms);
    await loadSms();
  }

  Future<void> updateSms(Sms sms) async {
    await SmsDbHelper().updateSms(sms);
    await loadSms();
  }

  Future<void> deleteSms(int id) async {
    await SmsDbHelper().deleteSms(id);
    await loadSms();
  }
}

final eventSmsProvider = FutureProvider.family<List<Sms>, int>((
  ref,
  eventId,
) async {
  return await SmsDbHelper().getSmsByEventId(eventId);
});
