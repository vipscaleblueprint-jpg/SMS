import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../providers/tags_provider.dart';
import '../../models/tag.dart';
import '../../widgets/modals/select_tags_dialog.dart';
import '../../models/events.dart';
import '../../widgets/modals/tag_contacts_dialog.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/events_provider.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  final Event? event;

  const CreateCampaignScreen({super.key, this.event});

  @override
  ConsumerState<CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // State for DropdownContacts
  final Set<String> _selectedContactIds = {};
  final Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.name;
      _selectedDate = widget.event!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.event!.date);

      _updateDateTimeText();

      if (widget.event!.recipients != null) {
        try {
          final decoded =
              jsonDecode(widget.event!.recipients!) as Map<String, dynamic>;
          if (decoded.containsKey('contacts')) {
            _selectedContactIds.addAll(List<String>.from(decoded['contacts']));
          }
          if (decoded.containsKey('tags')) {
            _selectedTagIds.addAll(List<String>.from(decoded['tags']));
          }
        } catch (e) {
          debugPrint('Error parsing recipients: $e');
        }
      }
    }
  }

  void _updateDateTimeText() {
    if (_selectedDate != null && _selectedTime != null) {
      final date = _selectedDate!;
      final time = _selectedTime!;

      final year = date.year;
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');

      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';

      _dateTimeController.text = "$year-$month-$day $hour:$minute $period";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: Colors.white,
              headerForegroundColor: Colors.black,
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFBB03B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: Color(0xFFFFF0D6),
              dayPeriodColor: Color(0xFFFFF0D6),
              dialHandColor: Color(0xFFFBB03B),
              dialBackgroundColor: Colors.white,
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFBB03B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
      _updateDateTimeText();
    });
  }

  void _saveCampaign() {
    if (_titleController.text.isNotEmpty &&
        _dateTimeController.text.isNotEmpty) {
      final recipientsData = {
        'contacts': _selectedContactIds.toList(),
        'tags': _selectedTagIds.toList(),
      };

      // Create or Update logic moved here
      // Logic from CampaignsScreen._showAddEventDialog closure:
      // CampaignDialog passed back (title, dateString, recipients)

      // We need to match the logic:
      // Try to parse the dateString using "MMM dd, yyyy hh:mm a" OR use existing _selectedDate/_selectedTime
      // The old dialog returned a formatted string.
      // Here, we have the DateTime objects directly available (_selectedDate, _selectedTime).
      // Let's use them to construct the final DateTime.

      DateTime finalDate;
      if (_selectedDate != null && _selectedTime != null) {
        finalDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      } else {
        // Fallback (shouldn't happen if validation passes)
        finalDate = DateTime.now();
      }

      final recipientsJson = jsonEncode(recipientsData);

      if (widget.event == null) {
        // Add
        final newEvent = Event(
          name: _titleController.text,
          date: finalDate,
          status: EventStatus.draft,
          recipients: recipientsJson,
        );
        ref.read(eventsProvider.notifier).addEvent(newEvent);
      } else {
        // Update
        final updatedEvent = Event(
          id: widget.event!.id,
          name: _titleController.text,
          date: finalDate,
          status: widget.event!.status,
          recipients: recipientsJson,
        );
        ref.read(eventsProvider.notifier).updateEvent(updatedEvent);
      }

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Title and Date')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Add Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    const Text(
                      'Title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        fillColor: Colors.grey.shade100,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFBB03B),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Event Starts Field
                    const Text(
                      'Campaign Starts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dateTimeController,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Select Date & Time',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            suffixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.grey,
                              size: 18,
                            ),
                            fillColor: Colors.grey.shade100,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Selected Tags List
                    if (_selectedTagIds.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: ref
                            .watch(tagsProvider)
                            .where((tag) => _selectedTagIds.contains(tag.id))
                            .map((tag) {
                              return GestureDetector(
                                onLongPress: () async {
                                  final allContacts = ref.read(
                                    contactsProvider,
                                  );
                                  final resultIds =
                                      await showDialog<List<String>>(
                                        context: context,
                                        builder: (context) => TagContactsDialog(
                                          tag: tag,
                                          allContacts: allContacts,
                                        ),
                                      );

                                  if (resultIds != null) {
                                    setState(() {
                                      _selectedTagIds.remove(tag.id);
                                      _selectedContactIds.addAll(resultIds);
                                    });
                                  }
                                },
                                child: Chip(
                                  label: Text(
                                    tag.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.black54,
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedTagIds.remove(tag.id);
                                    });
                                  },
                                  backgroundColor: Colors.grey.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide.none,
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              );
                            })
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    GestureDetector(
                      onTap: () async {
                        final initialTags = ref
                            .read(tagsProvider)
                            .where((t) => _selectedTagIds.contains(t.id))
                            .toList();

                        final List<Tag>? result = await showDialog<List<Tag>>(
                          context: context,
                          builder: (context) => SelectTagsDialog(
                            initialSelectedTags: initialTags,
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            _selectedTagIds.clear();
                            _selectedTagIds.addAll(result.map((t) => t.id));
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Search tags',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            fillColor: Colors.grey.shade100,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFFBB03B),
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button (Full Width)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveCampaign,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBB03B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Add Event',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
