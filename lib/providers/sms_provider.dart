import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sms.dart';
import '../utils/db/sms_db_helper.dart';
import '../services/sms_service.dart';
import 'contacts_provider.dart';

final smsProvider = NotifierProvider<SmsNotifier, List<Sms>>(SmsNotifier.new);

class SmsNotifier extends Notifier<List<Sms>> {
  @override
  List<Sms> build() {
    loadSms();
    return [];
  }

  Future<void> loadSms() async {
    final dbSmsList = await SmsDbHelper().getSmsList();

    // Fetch system SMS
    List<Sms> systemSmsList = [];
    try {
      final systemMessages = await SmsService().getSentMessages();
      // ref is available in Notifier
      // Use read here. Note: If contacts aren't loaded yet, this might be empty.
      final contacts = ref.read(contactsProvider);

      systemSmsList = systemMessages.map((msg) {
        final phoneNumber = msg.address ?? '';
        // Basic normalization for matching
        final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');

        // Find matching contact
        final contact = contacts.cast<dynamic>().firstWhere(
          (c) => c.phone.replaceAll(RegExp(r'\s+'), '') == normalizedPhone,
          orElse: () => null,
        );

        return Sms(
          // id is null for system messages not in our DB
          message: msg.body ?? '',
          phone_number: phoneNumber,
          contact_id: contact?.contact_id,
          status: SmsStatus.sent,
          sentTimeStamps: DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0),
        );
      }).toList();
    } catch (e) {
      print('Error loading system SMS: $e');
    }

    // Merge and sort
    final allSms = [...dbSmsList, ...systemSmsList];
    allSms.sort((a, b) {
      final tA = a.sentTimeStamps ?? a.schedule_time ?? DateTime(0);
      final tB = b.sentTimeStamps ?? b.schedule_time ?? DateTime(0);
      return tB.compareTo(tA);
    });

    state = allSms;
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
          recurrence: sms.recurrence,
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
