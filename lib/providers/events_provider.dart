import 'package:flutter_riverpod/legacy.dart';
import '../models/events.dart';
import '../utils/db/event_db_helper.dart';

final eventsProvider = StateNotifierProvider<EventsNotifier, List<Event>>((
  ref,
) {
  return EventsNotifier();
});

class EventsNotifier extends StateNotifier<List<Event>> {
  EventsNotifier() : super([]) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    final events = await EventDbHelper().getEvents();
    state = events.reversed.toList(); // Show newest first
  }

  Future<void> addEvent(Event event) async {
    await EventDbHelper().insertEvent(event);
    await loadEvents();
  }

  Future<void> updateEvent(Event event) async {
    await EventDbHelper().updateEvent(event);
    await loadEvents();
  }

  Future<void> deleteEvent(int id) async {
    await EventDbHelper().deleteEvent(id);
    await loadEvents();
  }
}
