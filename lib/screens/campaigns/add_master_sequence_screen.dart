import 'package:flutter/material.dart';
import '../../models/master_sequence.dart';
import '../../models/tag.dart';
import '../../utils/db/scheduled_db_helper.dart';
import '../../widgets/modals/select_tags_dialog.dart';
import '../../providers/tags_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddMasterSequenceScreen extends ConsumerStatefulWidget {
  final MasterSequence? sequence;

  const AddMasterSequenceScreen({super.key, this.sequence});

  @override
  ConsumerState<AddMasterSequenceScreen> createState() =>
      _AddMasterSequenceScreenState();
}

class _AddMasterSequenceScreenState
    extends ConsumerState<AddMasterSequenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final ScheduledDbHelper _dbHelper = ScheduledDbHelper();

  Tag? _selectedTag;
  List<SequenceMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    if (widget.sequence != null) {
      _titleController.text = widget.sequence!.title;
      _loadMessages();
      // Tag loading would happen after tags provider is ready or via a helper
    }
  }

  Future<void> _loadMessages() async {
    if (widget.sequence?.id != null) {
      final messages = await _dbHelper.getSequenceMessages(
        widget.sequence!.id!,
      );
      setState(() {
        _messages = messages;
      });
    }
  }

  Future<void> _saveSequence() async {
    if (!_formKey.currentState!.validate() || _selectedTag == null) {
      if (_selectedTag == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a trigger tag')),
        );
      }
      return;
    }

    final sequence = MasterSequence(
      id: widget.sequence?.id,
      title: _titleController.text,
      tagId: _selectedTag!.id,
      isActive: widget.sequence?.isActive ?? true,
    );

    int sequenceId;
    if (widget.sequence == null) {
      sequenceId = await _dbHelper.insertMasterSequence(sequence);
    } else {
      await _dbHelper.updateMasterSequence(sequence);
      sequenceId = widget.sequence!.id!;
      // Simple strategy for now: delete old messages and re-insert
      final oldMessages = await _dbHelper.getSequenceMessages(sequenceId);
      for (var msg in oldMessages) {
        await _dbHelper.deleteSequenceMessage(msg.id!);
      }
    }

    for (var msg in _messages) {
      final newMsg = SequenceMessage(
        sequenceId: sequenceId,
        title: msg.title,
        message: msg.message,
        delayDays: msg.delayDays,
      );
      await _dbHelper.insertSequenceMessage(newMsg);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _addMessage() {
    showDialog(
      context: context,
      builder: (context) => _AddMessageDialog(
        onSave: (title, content, delay) {
          setState(() {
            _messages.add(
              SequenceMessage(
                sequenceId: widget.sequence?.id ?? 0,
                title: title,
                message: content,
                delayDays: delay,
              ),
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider);
    if (widget.sequence != null && _selectedTag == null && tags.isNotEmpty) {
      _selectedTag = tags.firstWhere(
        (t) => t.id == widget.sequence!.tagId,
        orElse: () => tags.first,
      );
    }

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
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.sequence == null
                            ? 'New Sequence'
                            : 'Edit Sequence',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saveSequence,
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
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  children: [
                    const Text(
                      'Sequence Title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'e.g., Onboarding Sequence',
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
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Trigger Tag',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final List<Tag>? result = await showDialog<List<Tag>>(
                          context: context,
                          builder: (context) => SelectTagsDialog(
                            initialSelectedTags: _selectedTag != null
                                ? [_selectedTag!]
                                : [],
                          ),
                        );
                        if (result != null && result.isNotEmpty) {
                          setState(() => _selectedTag = result.first);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedTag?.name ?? 'Select a tag...',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _selectedTag == null
                                      ? Colors.grey[400]
                                      : Colors.black,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Messages',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFBB03B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          onPressed: _addMessage,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_messages.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Text(
                            'No messages in this sequence yet',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      )
                    else
                      ..._messages.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final msg = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              msg.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              'Day ${msg.delayDays}: ${msg.message}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _confirmDeleteMessage(idx),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Message?'),
        content: const Text(
          'Are you sure you want to remove this message from the sequence?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddMessageDialog extends StatefulWidget {
  final Function(String, String, int) onSave;

  const _AddMessageDialog({required this.onSave});

  @override
  State<_AddMessageDialog> createState() => _AddMessageDialogState();
}

class _AddMessageDialogState extends State<_AddMessageDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final List<DropdownMenuItem<int>> _dropdownItems = [
    const DropdownMenuItem(value: 0, child: Text('Immediate (Day 0)')),
    const DropdownMenuItem(value: 1, child: Text('After 1 day')),
    const DropdownMenuItem(value: 2, child: Text('After 2 days')),
    const DropdownMenuItem(value: 3, child: Text('After 3 days')),
    const DropdownMenuItem(value: 4, child: Text('After 4 days')),
    const DropdownMenuItem(value: 5, child: Text('After 5 days')),
    const DropdownMenuItem(value: 6, child: Text('After 6 days')),
    const DropdownMenuItem(value: 7, child: Text('After 1 week')),
    const DropdownMenuItem(value: 14, child: Text('After 2 weeks')),
    const DropdownMenuItem(value: 21, child: Text('After 3 weeks')),
    const DropdownMenuItem(value: 30, child: Text('After 1 month')),
  ];

  late int _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Drip Message',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Internal Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Welcome Day 0',
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Message Body',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                'When to send?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedDays,
                decoration: InputDecoration(
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                items: _dropdownItems,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDays = val);
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isNotEmpty &&
                        _contentController.text.isNotEmpty) {
                      widget.onSave(
                        _titleController.text,
                        _contentController.text,
                        _selectedDays,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBB03B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Add to Sequence',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
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
