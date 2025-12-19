import 'package:flutter/material.dart';
import '../../models/scheduled_message.dart';

class AddScheduledMessageScreen extends StatefulWidget {
  const AddScheduledMessageScreen({super.key});

  @override
  State<AddScheduledMessageScreen> createState() =>
      _AddScheduledMessageScreenState();
}

class _AddScheduledMessageScreenState extends State<AddScheduledMessageScreen> {
  final TextEditingController _titleController = TextEditingController(
    text: 'Hello Mesage',
  );
  final TextEditingController _bodyController = TextEditingController(
    text:
        'Subject: Thanks, your spot is saved!\n\n{{first_name}}\n\nThanks for registering for [your webinar name]!\nHere are the details of when we’re starting:\nTime: {{ event_time | date: "%B %d, %Y %I:%M%p (%Z)" }}\n\nThe webinar link will be emailed to you on the day of the event :)\n\nHere\'s what I\'ll be covering in the webinar:\n[insert a numbered list or bullet points of the topics you\'ll be talking about in the live stream]\n\nTalk soon,\nYour Name',
  );

  bool _isFrequencyOpen = false;
  String? _selectedFrequency;

  // Keeping this helper though seemingly unused if not called, but good for structure if we re-add it.
  Widget _buildFrequencyOption(String option) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFrequency = option;
          _isFrequencyOpen = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: double.infinity,
        alignment: Alignment.center,
        child: Text(
          option,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }

  String? _selectedMonthlyDay;

  String? _selectedWeeklyDay;

  Widget _buildWeeklyDayOption(String option) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedWeeklyDay = option;
          _selectedFrequency = option; // Change main display to the day
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: double.infinity,
        alignment: Alignment.center,
        child: Text(
          option,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
      ),
    );
  }

  void _insertTag(String tag) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    final int start = selection.start >= 0 ? selection.start : text.length;
    final int end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, tag);
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + tag.length),
    );
  }

  void _showMonthlyDayPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Day of Month',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 31,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final text = '$day${_getDaySuffix(day)} day of the month';
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMonthlyDay = text;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            text,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  void _showCustomizationOptions() {
    final options = {
      'First Name': '{{first_name}}',
      'Last Name': '{{last_name}}',
      'Email': '{{email}}',
      'Phone': '{{phone}}',
      'Event Time': '{{event_time}}',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Customization',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...options.entries.map(
                (entry) => ListTile(
                  title: Text(
                    entry.key,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    _insertTag(entry.value);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
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
                onPressed: () {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a title')),
                    );
                    return;
                  }
                  if (_selectedFrequency == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a frequency'),
                      ),
                    );
                    return;
                  }

                  String frequency = _selectedFrequency!;
                  String detail = '';

                  if (_selectedFrequency == 'Monthly') {
                    detail = _selectedMonthlyDay ?? '15 nth day of the month';
                  } else if (_weekdays.contains(_selectedFrequency)) {
                    frequency = 'Weekly';
                    detail = _selectedFrequency!;
                  } else if (_selectedFrequency == 'Weekly') {
                    frequency = 'Weekly';
                    detail = _selectedWeeklyDay ?? 'Monday';
                  }

                  final newMessage = ScheduledMessage(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _titleController.text,
                    date: DateTime.now(), // Placeholder for now
                    frequency: frequency,
                    frequencyDetail: detail,
                    body: _bodyController.text,
                  );

                  Navigator.of(context).pop(newMessage);
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFBB03B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Frequency
                      const Text(
                        'Frequency',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFrequencyOpen = !_isFrequencyOpen;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color:
                                      (_isFrequencyOpen ||
                                          _selectedFrequency != null)
                                      ? const Color(0xFFFBB03B)
                                      : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _selectedFrequency ??
                                        '--Please Select Frequency--',
                                    style: TextStyle(
                                      color: _selectedFrequency != null
                                          ? Colors.black87
                                          : Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isFrequencyOpen)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _buildFrequencyOption('Monthly'),
                                  Divider(
                                    height: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                  _buildFrequencyOption('Weekly'),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (_selectedFrequency == 'Monthly') ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _showMonthlyDayPicker,
                          child: Container(
                            height: 48,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFBB03B),
                              ),
                            ),
                            child: Text(
                              _selectedMonthlyDay ?? '30th day of the month',
                              style: const TextStyle(
                                color: Colors
                                    .black, // or Color(0xFFFBB03B) if you want text to be orange too, but usually black/grey is good for full text, let's stick to black as it was partially black before
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_selectedFrequency == 'Weekly') ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              for (var day in _weekdays) ...[
                                _buildWeeklyDayOption(day),
                                if (day != 'Sunday')
                                  Divider(
                                    height: 1,
                                    color: Colors.grey.shade300,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Body SMS
                      const Text(
                        'Body SMS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bodyController,
                        maxLines: 15,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFBB03B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Always visible regardless of frequency selection
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _showCustomizationOptions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBB03B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Add Customization',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Message Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFFFBB03B)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
