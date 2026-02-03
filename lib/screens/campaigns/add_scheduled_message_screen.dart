import 'package:flutter/material.dart';
import '../../models/scheduled_group.dart';
import '../../models/scheduled_sms.dart';
import '../../utils/db/scheduled_db_helper.dart';
import '../../utils/scheduling_utils.dart';
import '../../widgets/variable_text_editor.dart';

class AddScheduledMessageScreen extends StatefulWidget {
  final ScheduledGroup group;
  final ScheduledSms? messageToEdit;

  const AddScheduledMessageScreen({
    super.key,
    required this.group,
    this.messageToEdit,
  });

  @override
  State<AddScheduledMessageScreen> createState() =>
      _AddScheduledMessageScreenState();
}

class _AddScheduledMessageScreenState extends State<AddScheduledMessageScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController(
    text:
        "Subject: Thanks, your spot is saved!\n\n{{first_name}}\n\nThanks for registering for [your webinar name]!\nHere are the details of when we're starting:\nTime: {{ event_time | date: \"%B %d, %Y %I:%M%p (%Z)\" }}\n\nThe webinar link will be emailed to you on the day of the event :)\n\nHere's what I'll be covering in the webinar:\n[insert a numbered list or bullet points of the topics you'll be talking about in the live stream]\n\nTalk soon,\nYour Name",
  );
  final ScrollController _monthlyScrollController = ScrollController();
  final ScrollController _weeklyScrollController = ScrollController();
  final FocusNode _bodyFocusNode = FocusNode();

  // Frequency State
  bool _isFrequencyDropdownOpen = false;
  String? _selectedFrequency; // Null means "Please Select Frequency"
  int? _selectedDay; // For monthly frequency
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final List<String> _frequencyOptions = ['Monthly', 'Weekly'];

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(_handleSelectionChanged);
    if (widget.messageToEdit != null) {
      _titleController.text = widget.messageToEdit!.title;
      _bodyController.text = widget.messageToEdit!.message;
      _selectedFrequency = widget.messageToEdit!.frequency;
      _selectedDay = widget.messageToEdit!.scheduledDay;
      if (widget.messageToEdit!.scheduledTime != null) {
        _selectedTime = TimeOfDay.fromDateTime(
          widget.messageToEdit!.scheduledTime!,
        );
      }
    }
  }

  void _handleSelectionChanged() {
    // Selection handling moved to VariableTextEditor or no longer needed here
  }

  @override
  void dispose() {
    _bodyController.removeListener(_handleSelectionChanged);
    _titleController.dispose();
    _bodyController.dispose();
    _weeklyScrollController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveMessage() async {
    // Basic validation
    String? validationError;
    if (_titleController.text.isEmpty) {
      validationError = 'Please enter a title';
    } else if (_selectedFrequency == null) {
      validationError = 'Please select a frequency';
    } else if (_selectedFrequency == 'Monthly' && _selectedDay == null) {
      validationError = 'Please select a day of the month';
    } else if (_selectedFrequency == 'Weekly' && _selectedDay == null) {
      validationError = 'Please select a day of the week';
    } else if (_bodyController.text.isEmpty) {
      validationError = 'Please enter a message';
    }

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      if (widget.group.id == null) {
        throw Exception('Group ID is missing');
      }

      DateTime? scheduledTime;
      if (_selectedFrequency == 'Monthly' && _selectedDay != null) {
        scheduledTime = SchedulingUtils.getNextMonthlyDate(
          _selectedDay!,
          DateTime.now(),
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
        );
      } else if (_selectedFrequency == 'Weekly' && _selectedDay != null) {
        scheduledTime = SchedulingUtils.getNextWeeklyDate(
          _selectedDay!,
          DateTime.now(),
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
        );
      }

      final sms = ScheduledSms(
        id: widget.messageToEdit?.id,
        groupId: widget.group.id!,
        title: _titleController.text,
        frequency: _selectedFrequency!,
        scheduledDay: _selectedDay,
        message: _bodyController.text,
        scheduledTime: scheduledTime,
        status: widget.messageToEdit?.status ?? 'pending',
      );

      // Save to DB
      if (widget.messageToEdit != null) {
        await ScheduledDbHelper().updateMessage(sms);
      } else {
        await ScheduledDbHelper().insertMessage(sms);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to trigger refresh
      }
    } catch (e) {
      debugPrint('Error saving message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        centerTitle: true,
        title: const Text(
          'Scheduled Message',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: _saveMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBB03B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(80, 40), // Adjust size if needed
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  // Title Field
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
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter title',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  // Frequency Field
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
                        _isFrequencyDropdownOpen = !_isFrequencyDropdownOpen;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: _selectedFrequency != null
                              ? const Color(0xFFFBB03B)
                              : Colors.grey.shade300,
                        ),
                        borderRadius: _isFrequencyDropdownOpen
                            ? const BorderRadius.vertical(
                                top: Radius.circular(12),
                              )
                            : BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedFrequency ?? '--Please Select Frequency--',
                            style: TextStyle(
                              color: _selectedFrequency == null
                                  ? Colors.grey[500]
                                  : Colors.black,
                              fontSize: 14,
                              fontWeight: _selectedFrequency != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isFrequencyDropdownOpen)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: _frequencyOptions.map((option) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFrequency = option;
                                _isFrequencyDropdownOpen = false;
                                if (option == 'Monthly') {
                                  _selectedDay =
                                      31; // Default to last day of month
                                } else {
                                  _selectedDay = null;
                                }
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

                  if (_selectedFrequency == 'Monthly' &&
                      !_isFrequencyDropdownOpen &&
                      _selectedDay == null) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Scrollbar(
                          controller: _monthlyScrollController,
                          thumbVisibility: true,
                          thickness: 4,
                          radius: const Radius.circular(2),
                          child: ListView.separated(
                            controller: _monthlyScrollController,
                            itemCount: 31,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final day = index + 1;
                              final isSelected = _selectedDay == day;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDay = day;
                                    _isFrequencyDropdownOpen = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  color: isSelected
                                      ? const Color(0xFFFFF7E6)
                                      : null,
                                  child: Center(
                                    child: Text(
                                      day == 31
                                          ? 'Last day of the month'
                                          : '$day${SchedulingUtils.getDaySuffix(day)} day of the month',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_selectedFrequency == 'Monthly' &&
                      !_isFrequencyDropdownOpen &&
                      _selectedDay != null) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDay = null; // Reset to show picker again
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _selectedDay == 31
                                ? 'Last day of the month'
                                : '$_selectedDay${SchedulingUtils.getDaySuffix(_selectedDay!)} day of the month',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_selectedFrequency == 'Weekly' &&
                      !_isFrequencyDropdownOpen &&
                      _selectedDay == null) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Scrollbar(
                          controller: _weeklyScrollController,
                          thumbVisibility: true,
                          thickness: 4,
                          radius: const Radius.circular(2),
                          child: ListView.separated(
                            controller: _weeklyScrollController,
                            itemCount: SchedulingUtils.weekDays.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final day = index + 1; // 1 = Monday, 7 = Sunday
                              final isSelected = _selectedDay == day;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDay = day;
                                    _isFrequencyDropdownOpen = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  color: isSelected
                                      ? const Color(0xFFFFF7E6)
                                      : null,
                                  child: Center(
                                    child: Text(
                                      SchedulingUtils.weekDays[index],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_selectedFrequency == 'Weekly' &&
                      !_isFrequencyDropdownOpen &&
                      _selectedDay != null) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDay = null; // Reset to show picker again
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${SchedulingUtils.weekDays[_selectedDay! - 1]} of the week',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Time Field
                  const Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFFBB03B),
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFFBB03B),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedTime = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.access_time, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

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
