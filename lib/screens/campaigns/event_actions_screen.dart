import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../send/add_sms_screen.dart';
import '../../providers/sms_provider.dart';
import '../../providers/events_provider.dart';
import '../../models/sms.dart';
import '../../models/events.dart';

class EventActionsScreen extends ConsumerStatefulWidget {
  final int eventId;
  final String eventTitle;
  final String eventDate;

  const EventActionsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
  });

  @override
  ConsumerState<EventActionsScreen> createState() => _EventActionsScreenState();
}

class _EventActionsScreenState extends ConsumerState<EventActionsScreen> {
  bool _isActionsEnabled = true;
  Event? _currentEvent;

  @override
  void initState() {
    super.initState();
    _loadEventStatus();
  }

  Future<void> _loadEventStatus() async {
    // Find the current event from the events list
    final events = ref.read(eventsProvider);
    final event = events.firstWhere(
      (e) => e.id == widget.eventId,
      orElse: () => Event(
        id: widget.eventId,
        name: widget.eventTitle,
        date: DateTime.now(),
        status: EventStatus.draft,
      ),
    );
    setState(() {
      _currentEvent = event;
      _isActionsEnabled = event.status == EventStatus.activate;
    });
  }

  Future<void> _toggleEventStatus(bool value) async {
    if (_currentEvent == null) return;

    // Update event status
    final updatedEvent = Event(
      id: _currentEvent!.id,
      name: _currentEvent!.name,
      date: _currentEvent!.date,
      status: value ? EventStatus.activate : EventStatus.draft,
      recipients: _currentEvent!.recipients,
    );

    await ref.read(eventsProvider.notifier).updateEvent(updatedEvent);

    // Update all SMS statuses for this event
    await ref
        .read(smsProvider.notifier)
        .updateEventSmsStatuses(
          widget.eventId,
          value, // isPublished
        );

    // Refresh SMS list
    ref.invalidate(eventSmsProvider(widget.eventId));

    setState(() {
      _currentEvent = updatedEvent;
      _isActionsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final smsListAsync = ref.watch(eventSmsProvider(widget.eventId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.eventTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBB03B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Event Actions Header with Toggle
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Event Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: _isActionsEnabled,
                                onChanged: _toggleEventStatus,
                                activeColor: Colors.white,
                                activeTrackColor: const Color(0xFFFBB03B),
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                        // Event Date
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.eventDate, // Using formatted date
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // SMS List
                  smsListAsync.when(
                    data: (smsList) {
                      // Sort by date ideally
                      final sortedList = List<Sms>.from(smsList);
                      sortedList.sort(
                        (a, b) => (a.schedule_time ?? DateTime(2100)).compareTo(
                          b.schedule_time ?? DateTime(2100),
                        ),
                      );

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedList.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        itemBuilder: (context, index) {
                          final sms = sortedList[index];
                          // Determine title "SMS #1", "SMS #2"...
                          // Or "FINAL SMS CTA" if it's the last one?
                          // The screenshot implies a specific 'Final' type.
                          // Without that data, I'll assume the last one is "Final" if we have logic,
                          // or just use indices.
                          // Let's us indices for now and assume the user names them or we hardcode "Final" for the last one if > 1?
                          // The prompt says "SMS #1", "SMS #2", "FINAL SMS CTA".
                          // I'll leave it as "SMS #${index + 1}" for now unless I spot a flag.

                          String title = "SMS #${index + 1}";
                          // Heuristic: If message contains "Final" or it's the last one?
                          // No, safe to stick to numbering or use message snippet if available?
                          // Design shows titles. I'll stick to numbering.

                          return _buildSmsItem(
                            sms,
                            title,
                            index == sortedList.length - 1 &&
                                sortedList.length > 2,
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) =>
                        Center(child: Text('Error loading SMS: $err')),
                  ),

                  // Add SMS Button (Inside Card, at bottom)
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  InkWell(
                    onTap: () {
                      DateTime? parsedEventDate;
                      try {
                        parsedEventDate = DateFormat(
                          'MMM dd, yyyy hh:mm a',
                        ).parse(widget.eventDate);
                      } catch (_) {}

                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) => AddSmsScreen(
                                eventTitle: widget.eventTitle,
                                eventId: widget.eventId,
                                eventDate: parsedEventDate,
                              ),
                            ),
                          )
                          .then((_) {
                            // ignore: unused_result
                            ref.refresh(eventSmsProvider(widget.eventId));
                          });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Text(
                            '+ Add SMS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmsItem(Sms sms, String title, bool isFinal) {
    // Format date directly from sms data
    final dateStr = sms.schedule_time != null
        ? DateFormat('MMMM dd, yyyy hh:mm a').format(sms.schedule_time!)
        : (sms.sentTimeStamps != null
              ? DateFormat('MMMM dd, yyyy hh:mm a').format(sms.sentTimeStamps!)
              : 'Draft');

    final bool isDraft = sms.status == SmsStatus.draft;

    // Decoration for Non-Draft items (Card style)
    final BoxDecoration? decoration = !isDraft
        ? BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          )
        : null;

    final EdgeInsets margin = !isDraft
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    final EdgeInsets padding = !isDraft
        ? const EdgeInsets.all(16)
        : const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ); // Less padding for drafts

    // Checkmark Color Logic
    final Color checkColor = _isActionsEnabled
        ? const Color(0xFFFBB03B) // Yellow if Published
        : Colors.grey; // Grey if Not Published

    return InkWell(
      onTap: () async {
        DateTime? parsedEventDate;
        try {
          parsedEventDate = DateFormat(
            'MMM dd, yyyy hh:mm a',
          ).parse(widget.eventDate);
        } catch (_) {}

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddSmsScreen(
              eventTitle: widget.eventTitle,
              eventId: widget.eventId,
              eventDate: parsedEventDate,
              smsToEdit: sms,
            ),
          ),
        );
        if (mounted) {
          // ignore: unused_result
          ref.refresh(eventSmsProvider(widget.eventId));
        }
      },
      child: Container(
        margin: margin,
        padding: padding,
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.eventTitle, // Use Event Title as per screenshot
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                // Status Indicator - Displayed for ALL items but logic varies?
                // Screenshot shows checkmark even for item 3 and 1. Item 2 (Draft) has no checkmark.
                // So if !isDraft, show checkmark.
                if (!isDraft)
                  Icon(Icons.check_circle, color: checkColor, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            // Divider only for Card items (non-draft)
            if (!isDraft) ...[
              Divider(color: Colors.grey[100], height: 1),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isDraft ? Colors.grey[700] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDraft ? Colors.grey[700] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
