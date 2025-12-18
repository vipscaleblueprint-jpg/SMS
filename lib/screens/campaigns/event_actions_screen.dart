import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'add_sms_screen.dart';
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

    DateTime? eventDateTime;
    try {
      eventDateTime = DateFormat(
        'MMM dd, yyyy hh:mm a',
      ).parse(widget.eventDate);
    } catch (e) {
      eventDateTime = DateTime.now();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
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
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event Actions Header with Toggle (Includes Date)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
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
                          Switch(
                            value: _isActionsEnabled,
                            onChanged: _toggleEventStatus,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFFFBB03B),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Date Row inside the gray box
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.eventDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Action List Items
                smsListAsync.when(
                  data: (smsList) {
                    // Sort all SMS by schedule_time
                    final sortedList = List<Sms>.from(smsList);
                    final now = DateTime.now();
                    sortedList.sort((a, b) {
                      final isDraftA =
                          a.status == SmsStatus.draft &&
                          a.schedule_time == null;
                      final isDraftB =
                          b.status == SmsStatus.draft &&
                          b.schedule_time == null;

                      // 1. Drafts > Not Draft
                      if (isDraftA && !isDraftB) return -1;
                      if (!isDraftA && isDraftB) return 1;

                      if (isDraftA && isDraftB) {
                        return (b.id ?? 0).compareTo(a.id ?? 0);
                      }

                      // 2. Event date closer to date now > event date
                      final dateA = a.schedule_time ?? a.sentTimeStamps;
                      final dateB = b.schedule_time ?? b.sentTimeStamps;

                      if (dateA == null && dateB == null) return 0;
                      if (dateA == null) return 1;
                      if (dateB == null) return -1;

                      final diffA = dateA.difference(now).abs();
                      final diffB = dateB.difference(now).abs();

                      int cmp = diffA.compareTo(diffB);
                      if (cmp != 0) return cmp;

                      return dateA.compareTo(dateB);
                    });

                    if (sortedList.isEmpty) {
                      return const SizedBox(height: 0);
                    }

                    return ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      children: sortedList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final sms = entry.value;
                        final isLast = index == sortedList.length - 1;

                        bool nextIsDraft = false;
                        if (!isLast) {
                          final nextSms = sortedList[index + 1];
                          nextIsDraft =
                              nextSms.status == SmsStatus.draft &&
                              nextSms.schedule_time == null;
                        }

                        bool prevIsDraft = false;
                        if (index > 0) {
                          final prevSms = sortedList[index - 1];
                          prevIsDraft =
                              prevSms.status == SmsStatus.draft &&
                              prevSms.schedule_time == null;
                        }

                        return _buildSmsItem(
                          sms,
                          index,
                          isLast,
                          nextIsDraft,
                          prevIsDraft,
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),

                // Add SMS Button removed from here
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          DateTime? parsedEventDate;
          try {
            parsedEventDate = DateFormat(
              'MMM dd, yyyy hh:mm a',
            ).parse(widget.eventDate);
          } catch (e) {
            // print or handle error if needed
          }

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
                // Refreshes handled by provider watcher usually if invalidated, but explicit refresh ensures it
                void _ = ref.refresh(eventSmsProvider(widget.eventId));
              });
        },
        backgroundColor: const Color(0xFFFBB03B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEventCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.eventDate,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Icon(
            Icons.check_circle,
            color: _isActionsEnabled ? const Color(0xFFFBB03B) : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSmsItem(
    Sms sms,
    int index,
    bool isLast,
    bool nextIsDraft,
    bool prevIsDraft,
  ) {
    // Format date directly from sms data
    final dateStr = sms.schedule_time != null
        ? DateFormat('MMMM dd, yyyy hh:mm a').format(sms.schedule_time!)
        : (sms.sentTimeStamps != null
              ? DateFormat('MMMM dd, yyyy hh:mm a').format(sms.sentTimeStamps!)
              : 'Draft');

    // Determining styles based on status
    // Treat as "Draft" only if there is no schedule time.
    // Scheduled items (even if set to 'draft' status when event is paused) should appear as cards with checkmarks.
    final isDraft = sms.status == SmsStatus.draft && sms.schedule_time == null;

    // Container Decoration
    final decoration = isDraft
        ? const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          )
        : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          );

    // Margin/Padding - drafts have minimal spacing, pending/sent have card padding
    final margin = isDraft
        ? const EdgeInsets.all(0)
        : EdgeInsets.only(
            top: (index == 0 || prevIsDraft) ? 16 : 8,
            left: 16,
            right: 16,
            bottom: (isLast || nextIsDraft) ? 16 : 8,
          );

    final padding = isDraft
        ? const EdgeInsets.only(top: 16, left: 32, right: 32, bottom: 16)
        : const EdgeInsets.all(16);

    return InkWell(
      onTap: () async {
        // Navigate to Edit Screen (AddSmsScreen with existing SMS)
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
                Expanded(
                  child: Text(
                    sms.title?.isNotEmpty == true ? sms.title! : 'Untitled SMS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                // Status Check Icon - only show for pending/sent, not draft
                if (!isDraft)
                  Icon(
                    Icons.check_circle,
                    color: sms.status == SmsStatus.sent
                        ? const Color(0xFFFBB03B)
                        : Colors.grey,
                    // Original logic for reference:
                    // color: _isActionsEnabled ? const Color(0xFFFBB03B) : Colors.grey,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
