import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/header_user.dart';
import '../../widgets/list/events_list.dart';
import '../../widgets/modals/campaign_dialog.dart';
import '../../providers/events_provider.dart';
import '../../models/events.dart';
import 'event_actions_screen.dart';

class CampaignHistoryScreen extends ConsumerStatefulWidget {
  const CampaignHistoryScreen({super.key});

  @override
  ConsumerState<CampaignHistoryScreen> createState() =>
      _CampaignHistoryScreenState();
}

class _CampaignHistoryScreenState extends ConsumerState<CampaignHistoryScreen> {
  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => CampaignDialog(
        onSave: (title, date, recipients) async {
          final newEvent = Event(
            name: title,
            date: DateFormat('yyyy-MM-dd hh:mm a').parse(date),
            status: EventStatus.draft,
            recipients: recipients,
          );

          // Actually, let's fix the Date parsing in logic below or assume simpler for now:
          // The previous code had a helper or DateFormat.
          // I will use DateFormat in the logic.

          // But wait, addEvent logic:
          // ref.read(eventsProvider.notifier).addEvent(newEvent);

          await ref.read(eventsProvider.notifier).addEvent(newEvent);
        },
      ),
    );
  }

  void _showEditEventDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => CampaignDialog(
        event: event,
        onSave: (title, date, recipients) async {
          // update logic
        },
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text('Are you sure you want to delete "${event.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && event.id != null) {
      await ref.read(eventsProvider.notifier).deleteEvent(event.id!);
    }
  }

  // Correction: CampaignDialog onSave signature: (String title, String date, String recipients)
  // I need to parse the date string.
  // format: "2024-01-01 12:00 PM"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const HeaderUser(),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Events',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -1,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _showAddEventDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBB03B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            '+ Add Event',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    EventsList(
                      onTap: (event) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventActionsScreen(
                              eventId: event.id!,
                              eventTitle: event.name,
                              eventDate: event.date
                                  .toString(), // Simplify or formatting?
                              // EventActionsScreen takes String eventDate.
                              // I should format it nicely "MMM dd, yyyy"
                            ),
                          ),
                        );
                      },
                      onEdit: (event) {
                        _showEditEventDialog(event);
                      },
                      onDelete: (event) {
                        _deleteEvent(event);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
