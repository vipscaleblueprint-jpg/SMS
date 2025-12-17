import 'package:flutter/material.dart';
import '../list/dropdown-contacts.dart';
import '../../models/events.dart';
import 'dart:convert';

class CampaignDialog extends StatefulWidget {
  final Function(String title, String date, String recipients) onSave;

  final Event? event;

  const CampaignDialog({super.key, required this.onSave, this.event});

  @override
  State<CampaignDialog> createState() => _CampaignDialogState();
}

class _CampaignDialogState extends State<CampaignDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final TextEditingController _recipientsController = TextEditingController();
  final FocusNode _recipientsFocusNode = FocusNode();

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

      final date = widget.event!.date;
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour == 0 || date.hour == 12 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour < 12 ? 'AM' : 'PM';

      _dateController.text = "$month $day, $year";
      _timeController.text =
          "${hour.toString().padLeft(2, '0')}:$minute $period";

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
          // Fallback or ignore if parsing fails
          print('Error parsing recipients: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();

    _recipientsController.dispose();
    _recipientsFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000), // Allow past dates
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFBB03B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    setState(() {
      _selectedDate = date;

      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      final year = date.year;

      _dateController.text = "$month $day, $year";
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFBB03B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      _selectedTime = time;

      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';

      _timeController.text =
          "${hour.toString().padLeft(2, '0')}:$minute $period";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event == null ? 'Create an event' : 'Edit event',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Title Field
            const Text(
              'Title',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Event Starts Fields
            const Text(
              'Event Starts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                // Date Picker
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        hintText: 'Date',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Time Picker
                GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        hintText: 'Time',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        suffixIcon: Icon(
                          Icons.access_time,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recipients Field
            const Text(
              'Recipients',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownContacts(
              controller: _recipientsController,
              focusNode: _recipientsFocusNode,
              selectedContactIds: _selectedContactIds,
              selectedTagIds: _selectedTagIds,
              hintText: 'Search tags',
              showContacts: false,
              onContactSelected: (contact) {
                // Should be unreachable if showContacts is false, but safe to implement
                // or ignore. For now, we update state just in case.
                setState(() {
                  if (_selectedContactIds.contains(contact.contact_id)) {
                    _selectedContactIds.remove(contact.contact_id);
                  } else {
                    _selectedContactIds.add(contact.contact_id);
                  }
                });
              },
              onTagSelected: (tag) {
                setState(() {
                  if (_selectedTagIds.contains(tag.id)) {
                    _selectedTagIds.remove(tag.id);
                  } else {
                    _selectedTagIds.add(tag.id);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isNotEmpty &&
                        _dateController.text.isNotEmpty &&
                        _timeController.text.isNotEmpty) {
                      final recipientsData = {
                        'contacts': _selectedContactIds.toList(),
                        'tags': _selectedTagIds.toList(),
                      };

                      // Combine Date and Time
                      final combinedDateString =
                          "${_dateController.text} ${_timeController.text}";

                      widget.onSave(
                        _titleController.text,
                        combinedDateString,
                        jsonEncode(recipientsData),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBB03B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
