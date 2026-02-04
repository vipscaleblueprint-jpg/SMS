import 'package:flutter/material.dart'; // Trigger re-compile
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/sms.dart';
import '../../providers/sms_provider.dart';
import '../../widgets/variable_text_editor.dart';
import '../../widgets/modals/delete_confirmation_dialog.dart';

class AddSmsScreen extends ConsumerStatefulWidget {
  final String eventTitle;
  final int? eventId;
  final DateTime? eventDate;
  final Sms? smsToEdit; // Added for editing

  const AddSmsScreen({
    super.key,
    required this.eventTitle,
    this.eventId,
    this.eventDate,
    this.smsToEdit,
  });

  @override
  ConsumerState<AddSmsScreen> createState() => _AddSmsScreenState();
}

class _AddSmsScreenState extends ConsumerState<AddSmsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController(
    text:
        "Subject: Thanks, your spot is saved!\n\n{{first_name}}\n\nThanks for registering for [your webinar name]!\nHere are the details of when we're starting:\nTime: {{ event_time | date: \"%B %d, %Y %I:%M%p (%Z)\" }}\n\nThe webinar link will be emailed to you on the day of the event :)\n\nHere's what I'll be covering in the webinar:\n[insert a numbered list or bullet points of the topics you'll be talking about in the live stream]\n\nTalk soon,\n{{your_name}}",
  );

  bool _isDropdownOpen = false;
  String _selectedTimeOrientation = 'Draft'; // Default to Draft
  final List<String> _timeOptions = [
    'Draft',
    'Specific Date and Time',
    'Before the event',
    'At the time of event',
    'After the event',
  ];

  DateTime? _selectedDateTime;

  // Relative Time State
  final TextEditingController _relativeTimeValueController =
      TextEditingController();
  String _relativeTimeUnit = 'days';
  final List<String> _relativeTimeOptions = [
    'minutes',
    'hours',
    'days',
    'weeks',
    'months',
  ];
  bool _isRelativeUnitDropdownOpen = false;

  final FocusNode _bodyFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode(); // Add new FocusNode

  @override
  void initState() {
    super.initState();
    _relativeTimeValueController.addListener(() {
      setState(() {});
    });

    // Add listener to rebuild UI on focus change
    _titleFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.smsToEdit != null) {
      _titleController.text = widget.smsToEdit!.title ?? '';
      _bodyController.text = widget.smsToEdit!.message;

      // Determine orientation
      if (widget.smsToEdit!.status == SmsStatus.draft) {
        _selectedTimeOrientation = 'Draft';
      } else if (widget.smsToEdit!.schedule_time != null) {
        // Checking exact match might be tricky with microseconds, but let's try or default to specific
        if (widget.eventDate != null) {
          final diff = widget.smsToEdit!.schedule_time!.difference(
            widget.eventDate!,
          );

          if (diff.inSeconds == 0) {
            _selectedTimeOrientation = 'At the time of event';
          } else {
            // Check for relative match
            final isAfter = !diff.isNegative;
            final absDiff = diff.abs();

            String? bestUnit;
            int? bestValue;

            if (absDiff.inMinutes > 0 && absDiff.inSeconds % 60 == 0) {
              // Try to find the largest clean unit
              if (absDiff.inDays > 0 && absDiff.inHours % 24 == 0) {
                if (absDiff.inDays % 30 == 0) {
                  bestUnit = 'months';
                  bestValue = absDiff.inDays ~/ 30;
                } else if (absDiff.inDays % 7 == 0) {
                  bestUnit = 'weeks';
                  bestValue = absDiff.inDays ~/ 7;
                } else {
                  bestUnit = 'days';
                  bestValue = absDiff.inDays;
                }
              } else if (absDiff.inHours > 0 && absDiff.inMinutes % 60 == 0) {
                bestUnit = 'hours';
                bestValue = absDiff.inHours;
              } else {
                bestUnit = 'minutes';
                bestValue = absDiff.inMinutes;
              }
            }

            if (bestUnit != null && bestValue != null) {
              _selectedTimeOrientation = isAfter
                  ? 'After the event'
                  : 'Before the event';
              _relativeTimeUnit = bestUnit;
              _relativeTimeValueController.text = bestValue.toString();
            } else {
              // Fallback to specific if no clean relative mapping found
              _selectedTimeOrientation = 'Specific Date and Time';
              _selectedDateTime = widget.smsToEdit!.schedule_time;
            }
          }
        } else {
          // No event date to compare against
          _selectedTimeOrientation = 'Specific Date and Time';
          _selectedDateTime = widget.smsToEdit!.schedule_time;
        }
      } else {
        // Fallback
        _selectedTimeOrientation = 'Draft';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _relativeTimeValueController.dispose();
    _bodyFocusNode.dispose();
    _titleFocusNode.dispose(); // Dispose new node
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: Color(0xFFFFF0D6),
              headerForegroundColor: Colors.black,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.white,
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFBB03B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
              surfaceContainerHigh:
                  Colors.white, // For M3 TimePicker background potentially
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now(),
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: const TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteColor: Color(0xFFFFF0D6), // Light orange for input
                dayPeriodColor: Color(0xFFFFF0D6), // Light orange for AM/PM
                dialHandColor: Color(0xFFFBB03B),
                dialBackgroundColor: Colors.white,
              ),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFBB03B),
                onPrimary: Colors.white,
                onSurface: Colors.black,
                surface: Colors.white,
                surfaceContainerHigh: Colors.white,
                surfaceContainerHighest: Colors.white,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  DateTime _calculateRelativeTime(DateTime base, {required bool isBefore}) {
    int value = int.tryParse(_relativeTimeValueController.text) ?? 0;
    Duration duration;
    switch (_relativeTimeUnit) {
      case 'minutes':
        duration = Duration(minutes: value);
        break;
      case 'hours':
        duration = Duration(hours: value);
        break;
      case 'weeks':
        duration = Duration(days: value * 7);
        break;
      case 'months':
        duration = Duration(days: value * 30);
        break;
      case 'days':
      default:
        duration = Duration(days: value);
    }
    return isBefore ? base.subtract(duration) : base.add(duration);
  }

  DateTime? get _calculatedDate {
    if (_selectedTimeOrientation == 'Draft') {
      return null;
    } else if (_selectedTimeOrientation == 'Specific Date and Time') {
      return _selectedDateTime;
    } else if (_selectedTimeOrientation == 'At the time of event') {
      return widget.eventDate;
    } else if (_selectedTimeOrientation == 'Before the event') {
      if (widget.eventDate != null) {
        return _calculateRelativeTime(widget.eventDate!, isBefore: true);
      }
    } else if (_selectedTimeOrientation == 'After the event') {
      if (widget.eventDate != null) {
        return _calculateRelativeTime(widget.eventDate!, isBefore: false);
      }
    }
    return null;
  }

  Future<void> _saveSms() async {
    final finalScheduleTime = _calculatedDate;

    final sms = Sms(
      id: widget.smsToEdit?.id, // Preserve ID if editing
      title: _titleController.text,
      message: _bodyController.text,
      event_id: widget.eventId,
      status: finalScheduleTime == null ? SmsStatus.draft : SmsStatus.pending,
      contact_id: widget.smsToEdit?.contact_id,
      phone_number: widget.smsToEdit?.phone_number,
      sender_number: widget.smsToEdit?.sender_number,
      schedule_time: finalScheduleTime,
    );

    if (widget.smsToEdit != null) {
      await ref.read(smsProvider.notifier).updateSms(sms);
    } else {
      await ref.read(smsProvider.notifier).addSms(sms);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteSms() async {
    if (widget.smsToEdit?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const DeleteConfirmationDialog(
        title: 'Delete SMS?',
        message: 'Are you sure you want to delete this message?',
      ),
    );

    if (confirm == true) {
      await ref.read(smsProvider.notifier).deleteSms(widget.smsToEdit!.id!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Campaign Message',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.smsToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteSms,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: _saveSms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBB03B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  widget.smsToEdit != null ? 'Update' : 'Save',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode, // Attach focus node
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter title',
                        hintStyle: TextStyle(
                          color: const Color(
                            0xFFB3B3B3,
                          ).withOpacity(_titleFocusNode.hasFocus ? 0.5 : 1.0),
                        ), // Conditional opacity
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // When Section
                  const Text(
                    'When',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDropdownOpen = !_isDropdownOpen;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: _isDropdownOpen
                            ? const BorderRadius.vertical(
                                top: Radius.circular(12),
                              )
                            : BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedTimeOrientation,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isDropdownOpen)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Column(
                        children: _timeOptions.map((option) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTimeOrientation = option;
                                _isDropdownOpen = false;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // CONDITIONAL RENDER: Specific Date
                  if (_selectedTimeOrientation == 'Specific Date and Time')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: InkWell(
                        onTap: _pickDateTime,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _selectedDateTime != null
                                ? DateFormat(
                                    'yyyy-MM-dd hh:mm a',
                                  ).format(_selectedDateTime!)
                                : 'Select Date and Time',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedDateTime != null
                                  ? Colors.black87
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // CONDITIONAL RENDER: Relative Time (Before/After)
                  if (_selectedTimeOrientation == 'Before the event' ||
                      _selectedTimeOrientation == 'After the event')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Can be up to 90 days before or after the event and must be in the future.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Number Input
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _relativeTimeValueController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Unit Dropdown
                              Expanded(
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isRelativeUnitDropdownOpen =
                                              !_isRelativeUnitDropdownOpen;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              _isRelativeUnitDropdownOpen
                                              ? const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                )
                                              : BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _relativeTimeUnit,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Icon(
                                              _isRelativeUnitDropdownOpen
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: Colors.grey[600],
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_isRelativeUnitDropdownOpen)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                bottom: Radius.circular(12),
                                              ),
                                          border: Border(
                                            left: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                            right: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                            bottom: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: _relativeTimeOptions.map((
                                            option,
                                          ) {
                                            return InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _relativeTimeUnit = option;
                                                  _isRelativeUnitDropdownOpen =
                                                      false;
                                                });
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 16,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(
                                                      color:
                                                          Colors.grey.shade200,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  option,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (_calculatedDate != null &&
                      (_selectedTimeOrientation == 'Before the event' ||
                          _selectedTimeOrientation == 'After the event'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                      child: Text(
                        'Scheduled for: ${DateFormat('MMMM dd, yyyy hh:mm a').format(_calculatedDate!)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),

                  // Body SMS Section
                  VariableTextEditor(
                    label: 'Body SMS',
                    controller: _bodyController,
                    focusNode: _bodyFocusNode,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
