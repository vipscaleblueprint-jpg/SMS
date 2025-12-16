import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/sms.dart';
import '../../providers/sms_provider.dart';

class AddSmsScreen extends ConsumerStatefulWidget {
  final String eventTitle;
  final int? eventId;
  final DateTime? eventDate;

  const AddSmsScreen({
    super.key,
    required this.eventTitle,
    this.eventId,
    this.eventDate,
  });

  @override
  ConsumerState<AddSmsScreen> createState() => _AddSmsScreenState();
}

class _AddSmsScreenState extends ConsumerState<AddSmsScreen> {
  final TextEditingController _bodyController = TextEditingController(
    text:
        "Subject: Thanks, your spot is saved!\n\n{{first_name}}\n\nThanks for registering for [your webinar name]!\nHere are the details of when we're starting:\nTime: {{ event_time | date: \"%B %d, %Y %I:%M%p (%Z)\" }}\n\nThe webinar link will be emailed to you on the day of the event :)\n\nHere's what I'll be covering in the webinar:\n[insert a numbered list or bullet points of the topics you'll be talking about in the live stream]\n\nTalk soon,\nYour Name",
  );

  bool _isDropdownOpen = false;
  String _selectedTimeOrientation = '--Please Select Time Orientation--';
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
  @override
  void initState() {
    super.initState();
    _relativeTimeValueController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _relativeTimeValueController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now(),
        ),
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
      message: _bodyController.text,
      event_id: widget.eventId,
      isSent: false,
      contact_id: null,
      phone_number: null,
      sender_number: null,
      schedule_time: finalScheduleTime,
    );

    await ref.read(smsProvider.notifier).addSms(sms);
    if (mounted) {
      Navigator.of(context).pop();
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
        actions: [
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
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                            style: TextStyle(
                              color:
                                  _selectedTimeOrientation ==
                                      '--Please Select Time Orientation--'
                                  ? Colors.grey[400]
                                  : Colors.black87,
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
                                      hintText: '3',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
