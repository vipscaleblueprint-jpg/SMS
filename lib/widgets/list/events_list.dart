import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/events.dart';

class EventsList extends StatefulWidget {
  final List<Event> events;
  final Function(Event) onDelete;
  final Function(Event) onTap;
  final Function(Event) onEdit;

  const EventsList({
    super.key,
    required this.events,
    required this.onDelete,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<EventsList> createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = _searchController.text.toLowerCase();
    final filteredEvents = widget.events
        .where((event) => event.name.toLowerCase().contains(search))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "All" Tab
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFFFBB03B), // Yellow underline
                decorationThickness: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search events',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Header Row
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Title',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Padding(
                padding: EdgeInsets.only(
                  right: 48.0,
                ), // Space for delete icon alignment
                child: Text(
                  'Date',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Event List
        if (filteredEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No events found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final event = filteredEvents[index];
              final dateString = DateFormat(
                'MMM dd, yyyy hh:mm a',
              ).format(event.date);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2, // Width weight for Title
                      child: InkWell(
                        onTap: () => widget.onTap(event),
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3, // Width weight for Date
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => widget.onTap(event),
                            child: Text(
                              dateString,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => widget.onEdit(event),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => widget.onDelete(event),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
