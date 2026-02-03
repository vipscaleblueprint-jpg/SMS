import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/events.dart';
import '../../providers/events_provider.dart';
import '../modals/delete_confirmation_dialog.dart';

class EventsList extends ConsumerStatefulWidget {
  final Function(Event)? onTap;
  final Function(Event)? onEdit;
  // onDelete is now handled internally via bulk or single delete action
  final Function(Event)?
  onDelete; // Keep for backward compatibility if needed, or remove

  const EventsList({super.key, this.onTap, this.onEdit, this.onDelete});

  @override
  ConsumerState<EventsList> createState() => _EventsListState();
}

class _EventsListState extends ConsumerState<EventsList> {
  final TextEditingController _searchController = TextEditingController();

  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode(int? initialId) {
    setState(() {
      if (_isSelectionMode) {
        _isSelectionMode = false;
        _selectedIds.clear();
      } else {
        _isSelectionMode = true;
        if (initialId != null) {
          _selectedIds.add(initialId);
        }
      }
    });
  }

  void _toggleItemSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final idsToDelete = _selectedIds.toList();
    if (idsToDelete.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteConfirmationDialog(
        title: 'Delete ${idsToDelete.length} Events?',
        message:
            'Are you sure you want to delete the selected events? This action cannot be undone.',
      ),
    );

    if (confirm == true) {
      await ref.read(eventsProvider.notifier).deleteEvents(idsToDelete);
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Events deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);

    final search = _searchController.text.toLowerCase();
    final filteredEvents = events
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

        // Toolbar / Search
        if (_isSelectionMode)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFFBB03B).withOpacity(0.1),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _toggleSelectionMode(null),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedIds.length} Selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelected,
                ),
              ],
            ),
          )
        else
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Checkbox(
                    value:
                        _selectedIds.isNotEmpty &&
                        _selectedIds.length == filteredEvents.length,
                    onChanged: (val) {
                      if (val == true) {
                        setState(() {
                          // Filter out null IDs just in case, though they shouldn't be null
                          _selectedIds.addAll(
                            filteredEvents
                                .where((e) => e.id != null)
                                .map((e) => e.id!),
                          );
                        });
                      } else {
                        setState(() {
                          _selectedIds.clear();
                        });
                      }
                    },
                  ),
                ),

              const Expanded(
                flex: 2,
                child: Text(
                  'Title',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              if (!_isSelectionMode)
                const Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: 48.0,
                    ), // Space for delete icon
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                const Expanded(
                  flex: 3,
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

              final isSelected =
                  event.id != null && _selectedIds.contains(event.id);

              return InkWell(
                onTap: () {
                  if (_isSelectionMode) {
                    if (event.id != null) _toggleItemSelection(event.id!);
                  } else if (widget.onTap != null) {
                    widget.onTap!(event);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode && event.id != null) {
                    _toggleSelectionMode(event.id!);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFBB03B).withOpacity(0.05)
                        : null,
                    // borderRadius: BorderRadius.circular(8), // List view items usually not rounded unless card
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 4.0,
                  ),
                  child: Row(
                    children: [
                      if (_isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Checkbox(
                            value: isSelected,
                            activeColor: const Color(0xFFFBB03B),
                            onChanged: (val) {
                              if (event.id != null)
                                _toggleItemSelection(event.id!);
                            },
                          ),
                        ),

                      Expanded(
                        flex: 2, // Width weight for Title
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3, // Width weight for Date
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateString,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (!_isSelectionMode)
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (widget.onEdit != null)
                                        widget.onEdit!(event);
                                    },
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      if (widget.onDelete != null)
                                        widget.onDelete!(event);
                                    },
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
                ),
              );
            },
          ),
      ],
    );
  }
}
