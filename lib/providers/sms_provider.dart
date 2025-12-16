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

  // Update all SMS for an event to draft (when event is unpublished)
  // or restore to pending (when event is published)
  Future<void> updateEventSmsStatuses(int eventId, bool isPublished) async {
    final smsList = await SmsDbHelper().getSmsByEventId(eventId);
    for (final sms in smsList) {
      // Only update if there's a schedule_time (don't touch actual drafts)
      if (sms.schedule_time != null) {
        final updatedSms = Sms(
          id: sms.id,
          message: sms.message,
          contact_id: sms.contact_id,
          phone_number: sms.phone_number,
          sender_number: sms.sender_number,
          status: isPublished ? SmsStatus.pending : SmsStatus.draft,
          sentTimeStamps: sms.sentTimeStamps,
          schedule_time: sms.schedule_time, // Keep the schedule time
          event_id: sms.event_id,
        );
        await SmsDbHelper().updateSms(updatedSms);
      }
    }
    await loadSms();
  }
}

final eventSmsProvider = FutureProvider.family<List<Sms>, int>((
  ref,
  eventId,
) async {
  return await SmsDbHelper().getSmsByEventId(eventId);
});
