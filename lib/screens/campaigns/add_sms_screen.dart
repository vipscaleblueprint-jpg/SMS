import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/sms.dart';
import '../../providers/sms_provider.dart';

class AddSmsScreen extends ConsumerStatefulWidget {
  final String eventTitle;
  final int eventId;
  final DateTime? eventDate;
  final Sms? smsToEdit;

  const AddSmsScreen({
    super.key,
    required this.eventTitle,
    required this.eventId,
    this.eventDate,
    this.smsToEdit,
  });

  @override
  ConsumerState<AddSmsScreen> createState() => _AddSmsScreenState();
}

class _AddSmsScreenState extends ConsumerState<AddSmsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  DateTime? _scheduleDate;
  TimeOfDay? _scheduleTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.smsToEdit?.title ?? '',
    );
    _messageController = TextEditingController(
      text: widget.smsToEdit?.message ?? '',
    );

    if (widget.smsToEdit?.schedule_time != null) {
      _scheduleDate = widget.smsToEdit!.schedule_time;
      _scheduleTime = TimeOfDay.fromDateTime(widget.smsToEdit!.schedule_time!);
    } else if (widget.eventDate != null) {
      _scheduleDate = widget.eventDate;
      _scheduleTime = TimeOfDay.fromDateTime(widget.eventDate!);
    } else {
      final now = DateTime.now();
      _scheduleDate = now;
      _scheduleTime = TimeOfDay.fromDateTime(now);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFBB03B)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _scheduleDate) {
      setState(() {
        _scheduleDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFBB03B)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _scheduleTime) {
      setState(() {
        _scheduleTime = picked;
      });
    }
  }

  Future<void> _saveSms() async {
    if (_formKey.currentState!.validate()) {
      if (_scheduleDate == null || _scheduleTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date and time')),
        );
        return;
      }

      final scheduledDateTime = DateTime(
        _scheduleDate!.year,
        _scheduleDate!.month,
        _scheduleDate!.day,
        _scheduleTime!.hour,
        _scheduleTime!.minute,
      );

      final sms = Sms(
        id: widget.smsToEdit?.id,
        event_id: widget.eventId,
        title: _titleController.text,
        message: _messageController.text,
        status: SmsStatus.pending, // Default to pending for scheduled SMS
        schedule_time: scheduledDateTime,
      );

      try {
        if (widget.smsToEdit != null) {
          await ref.read(smsProvider.notifier).updateSms(sms);
        } else {
          await ref.read(smsProvider.notifier).addSms(sms);
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving SMS: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.smsToEdit == null ? 'Add Scheduled SMS' : 'Edit SMS',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveSms,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFFBB03B),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Internal Title',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Reminder 1',
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
                  vertical: 14,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Message Body',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Schedule Time',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _scheduleDate != null
                                ? DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(_scheduleDate!)
                                : 'Select Date',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _scheduleTime != null
                                ? _scheduleTime!.format(context)
                                : 'Select Time',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
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
