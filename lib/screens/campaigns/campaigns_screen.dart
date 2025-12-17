import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/events.dart';
import '../../providers/events_provider.dart';
import '../welcome_message_screen.dart';
import 'event_actions_screen.dart';
import '../home/settings_screen.dart';
import '../../widgets/modals/campaign_dialog.dart';
import '../../widgets/list/events_list.dart';

class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});

  @override
  ConsumerState<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends ConsumerState<CampaignsScreen> {
  final GlobalKey _profileKey = GlobalKey();

  void _showProfileMenu() async {
    final RenderBox button =
        _profileKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset(0, button.size.height)),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      items: [
        const PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    ).then((value) {
      if (value == 'logout') {
        // Navigate back to login screen
        Navigator.of(context).pushReplacementNamed('/');
      } else if (value == 'settings') {
        // Navigate to settings screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
      }
    });
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => CampaignDialog(
        onSave: (title, dateString, recipients) {
          // Parse date string back to DateTime if needed, or assume CampaignDialog returns formatted string
          // CampaignDialog returns formatted string currently. We need to parse it or change CampaignDialog to return DateTime.
          // For now, let's try to parse the format "MMM dd, yyyy hh:mm a"

          DateTime date;
          try {
            date = DateFormat("MMM dd, yyyy hh:mm a").parse(dateString);
          } catch (e) {
            date = DateTime.now();
          }

          final newEvent = Event(
            name: title,
            date: date,
            status: EventStatus.draft,
            recipients: recipients,
          );
          ref.read(eventsProvider.notifier).addEvent(newEvent);
        },
      ),
    );
  }

  void _showDeleteEventDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Delete this Event?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    const TextSpan(
                      text: 'Are you sure you want to delete the ',
                    ),
                    TextSpan(
                      text: '${event.name} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: 'Event?\n\n'),
                    const TextSpan(
                      text:
                          'Deleting this event will result in the following actions that you may want to consider before moving forward.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (event.id != null) {
                        ref
                            .read(eventsProvider.notifier)
                            .deleteEvent(event.id!);
                      }
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Delete event',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditEventDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => CampaignDialog(
        event: event,
        onSave: (title, dateString, recipients) {
          DateTime date;
          try {
            date = DateFormat("MMM dd, yyyy hh:mm a").parse(dateString);
          } catch (e) {
            date = DateTime.now();
          }

          final updatedEvent = Event(
            id: event.id,
            name: title,
            date: date,
            status: event.status, // Preserve status
            recipients: recipients,
          );
          ref.read(eventsProvider.notifier).updateEvent(updatedEvent);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Profile
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    key: _profileKey,
                    onTap: _showProfileMenu,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFFBB03B),
                            radius: 16,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Antony John',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Events Title and Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Events',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _showAddEventDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBB03B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Add Event',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Welcome Message Card
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const WelcomeMessageScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome Message',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Send Welcome Message to new\nimported contacts',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.rotate(
                              angle: -0.5, // Tilted paper plane
                              child: const Icon(
                                Icons.send,
                                color: Colors.grey,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    EventsList(
                      onDelete: _showDeleteEventDialog,
                      onEdit: _showEditEventDialog,
                      onTap: (event) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EventActionsScreen(
                              eventId: event.id!,
                              eventTitle: event.name,
                              eventDate: DateFormat(
                                'MMM dd, yyyy hh:mm a',
                              ).format(event.date),
                            ),
                          ),
                        );
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
