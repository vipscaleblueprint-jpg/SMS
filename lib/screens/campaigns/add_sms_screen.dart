import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/sms.dart';
import '../../providers/sms_provider.dart';

class AddSmsScreen extends ConsumerStatefulWidget {
  final String eventTitle;
  final int? eventId;
  final int? groupId; // Added for groups
  final DateTime? eventDate;
  final Sms? smsToEdit; // Added for editing

  const AddSmsScreen({
    super.key,
    required this.eventTitle,
    this.eventId,
    this.groupId,
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
        "Subject: Thanks, your spot is saved!\n\n{{first_name}}\n\nThanks for registering for [your webinar name]!\nHere are the details of when we're starting:\nTime: {{ event_time | date: \"%B %d, %Y %I:%M%p (%Z)\" }}\n\nThe webinar link will be emailed to you on the day of the event :)\n\nHere's what I'll be covering in the webinar:\n[insert a numbered list or bullet points of the topics you'll be talking about in the live stream]\n\nTalk soon,\nYour Name",
  );
  final TextEditingController _messageController = TextEditingController();

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

  List<String> get _filteredTimeOptions {
    if (widget.eventId == null || widget.groupId != null) {
      return ['Monthly', 'Weekly', 'Specific Date and Time'];
    }
    return _timeOptions;
  }

  String _selectedMonthlyDay = '15th';
  String _selectedWeeklyDay = 'Monday';

  // Relative Time State
  final TextEditingController _relativeTimeValueController =
      TextEditingController();
  final TextEditingController _monthlyDayController = TextEditingController(
    text: '15',
  );
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
  final FocusNode _monthlyDayFocusNode = FocusNode();

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
        if (widget.eventDate != null &&
            widget.smsToEdit!.schedule_time!.isAtSameMomentAs(
              widget.eventDate!,
            )) {
          _selectedTimeOrientation = 'At the time of event';
        } else {
          // Default to Specific Date if we can't reverse engineer relative easily
          _selectedTimeOrientation = 'Specific Date and Time';
          _selectedDateTime = widget.smsToEdit!.schedule_time;
        }
      }

      if (widget.smsToEdit!.recurrence != null) {
        if (widget.smsToEdit!.recurrence!.startsWith('Monthly:')) {
          _selectedTimeOrientation = 'Monthly';
          _selectedMonthlyDay = widget.smsToEdit!.recurrence!.split(':')[1];
          _monthlyDayController.text = _selectedMonthlyDay;
        } else if (widget.smsToEdit!.recurrence!.startsWith('Weekly:')) {
          _selectedTimeOrientation = 'Weekly';
          _selectedWeeklyDay = widget.smsToEdit!.recurrence!.split(':')[1];
        }
      }
    } else {
      // Default for new SMS
      if (widget.eventId == null || widget.groupId != null) {
        _selectedTimeOrientation = 'Monthly';
        _monthlyDayController.text = '15';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _messageController.dispose();
    _relativeTimeValueController.dispose();
    _monthlyDayController.dispose();
    _bodyFocusNode.dispose();
    _titleFocusNode.dispose(); // Dispose new node
    _monthlyDayFocusNode.dispose();
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
    } else if (_selectedTimeOrientation == 'Monthly') {
      DateTime now = DateTime.now();
      int day = int.tryParse(_monthlyDayController.text) ?? 15;
      // Clamp day between 1 and 31
      if (day < 1) day = 1;
      if (day > 31) day = 31;

      // Ensure we don't pick a day that doesn't exist in the target month
      // (Simplified: if day > 28/29/30/31, DateTime constructor usually rolls over to next month)
      // For simplicity, we'll just use the day provided.
      DateTime target = DateTime(now.year, now.month, day, 10, 0);
      if (target.isBefore(now)) {
        // Find next month's occurrence
        int nextMonth = now.month + 1;
        int nextYear = now.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        target = DateTime(nextYear, nextMonth, day, 10, 0);
      }
      return target;
    } else if (_selectedTimeOrientation == 'Weekly') {
      DateTime now = DateTime.now();
      int targetWeekday = DateTime.monday;
      switch (_selectedWeeklyDay) {
        case 'Monday':
          targetWeekday = DateTime.monday;
          break;
        case 'Tuesday':
          targetWeekday = DateTime.tuesday;
          break;
        case 'Wednesday':
          targetWeekday = DateTime.wednesday;
          break;
        case 'Thursday':
          targetWeekday = DateTime.thursday;
          break;
        case 'Friday':
          targetWeekday = DateTime.friday;
          break;
      }

      DateTime target = DateTime(now.year, now.month, now.day, 10, 0);
      // If today is target day but time passed, or not target day, find next
      if (target.isBefore(now) || target.weekday != targetWeekday) {
        // Move to next occurrence of that weekday
        int daysToAdd = (targetWeekday - now.weekday + 7) % 7;
        if (daysToAdd == 0 && target.isBefore(now)) daysToAdd = 7;
        target = target.add(Duration(days: daysToAdd));
      }
      return target;
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
      group_id: widget.groupId ?? widget.smsToEdit?.group_id,
      status: finalScheduleTime == null ? SmsStatus.draft : SmsStatus.pending,
      contact_id: widget.smsToEdit?.contact_id,
      phone_number: widget.smsToEdit?.phone_number,
      sender_number: widget.smsToEdit?.sender_number,
      schedule_time: finalScheduleTime,
      recurrence: _selectedTimeOrientation == 'Monthly'
          ? 'Monthly:${_monthlyDayController.text}'
          : _selectedTimeOrientation == 'Weekly'
          ? 'Weekly:$_selectedWeeklyDay'
          : null,
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
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete SMS?'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
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
                  const Text(
                    'Scheduled Message',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                    'Frequency',
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
                        children: _filteredTimeOptions.map((option) {
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

                  // CONDITIONAL RENDER: Monthly
                  if (_selectedTimeOrientation == 'Monthly')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Day of the Month',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _monthlyDayController,
                              focusNode: _monthlyDayFocusNode,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Enter day (1-31)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _selectedMonthlyDay = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'The message will be sent on this day every month.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // CONDITIONAL RENDER: Weekly
                  if (_selectedTimeOrientation == 'Weekly')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Weekday',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  [
                                    'Monday',
                                    'Tuesday',
                                    'Wednesday',
                                    'Thursday',
                                    'Friday',
                                  ].map((day) {
                                    bool isSelected = _selectedWeeklyDay == day;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: ChoiceChip(
                                        label: Text(day),
                                        selected: isSelected,
                                        onSelected: (val) {
                                          if (val)
                                            setState(
                                              () => _selectedWeeklyDay = day,
                                            );
                                        },
                                        selectedColor: const Color(0xFFFBB03B),
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? const Color(0xFFFBB03B)
                                                : Colors.grey.shade300,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Body SMS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      // Add Customization Button
                      PopupMenuButton<String>(
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        onSelected: (value) {
                          String placeholder = '';
                          switch (value) {
                            case 'First Name':
                              placeholder = '{{first_name}}';
                              break;
                            case 'Last Name':
                              placeholder = '{{last_name}}';
                              break;
                            case 'Full Name':
                              placeholder = '{{full_name}}';
                              break;
                          }

                          if (placeholder.isNotEmpty) {
                            String newText =
                                "Subject: Thanks, your spot is saved!\n\n$placeholder\n\nThanks for registering for [your webinar name]!\nHere are the details of when we're starting:\nTime: {{ event_time | date: \"%B %d, %Y %I:%M%p (%Z)\" }}\n\nThe webinar link will be emailed to you on the day of the event :)\n\nHere's what I'll be covering in the webinar:\n[insert a numbered list or bullet points of the topics you'll be talking about in the live stream]\n\nTalk soon,\nYour Name";

                            _bodyController.text = newText;

                            // Restore focus
                            _bodyFocusNode.requestFocus();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'First Name',
                            child: Text('First Name'),
                          ),
                          const PopupMenuItem(
                            value: 'Last Name',
                            child: Text('Last Name'),
                          ),
                          const PopupMenuItem(
                            value: 'Full Name',
                            child: Text('Full Name'),
                          ),
                        ],
                        offset: const Offset(0, 40),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBB03B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: const Text(
                            'Add Customization',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _bodyController,
                      focusNode: _bodyFocusNode,
                      maxLines: 15,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Send a message...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBB03B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
