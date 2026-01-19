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
      appBar: AppBar(
        title: Text(widget.sequence == null ? 'New Sequence' : 'Edit Sequence'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSequence,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFFBB03B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Sequence Title',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Onboarding Sequence',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            const Text(
              'Trigger Tag',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_selectedTag?.name ?? 'Select a tag...'),
              trailing: const Icon(Icons.chevron_right),
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
            ),
            const Divider(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFFBB03B)),
                  onPressed: _addMessage,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_messages.isEmpty)
              const Center(
                child: Text(
                  'No messages in this sequence yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._messages.asMap().entries.map((entry) {
                final idx = entry.key;
                final msg = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(msg.title),
                    subtitle: Text(
                      'Day ${msg.delayDays}: ${msg.message}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => setState(() => _messages.removeAt(idx)),
                    ),
                  ),
                );
              }),
          ],
        ),
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
  int _delayValue = 0;
  String _delayUnit = 'Days'; // 'Days' or 'Weeks'

  int get _totalDelayDays {
    if (_delayUnit == 'Weeks') return _delayValue * 7;
    return _delayValue;
  }

  void _setPreset(int days) {
    setState(() {
      if (days % 7 == 0 && days > 0) {
        _delayValue = days ~/ 7;
        _delayUnit = 'Weeks';
      } else {
        _delayValue = days;
        _delayUnit = 'Days';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Drip Message'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Internal Title',
                hintText: 'e.g., Welcome Day 0',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                hintText: 'Type your message here...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'When to send?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('After ', style: TextStyle(fontSize: 16)),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _delayValue,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: List.generate(
                      31,
                      (index) =>
                          DropdownMenuItem(value: index, child: Text('$index')),
                    ),
                    onChanged: (val) => setState(() => _delayValue = val!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _delayUnit,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Days', child: Text('Day(s)')),
                      DropdownMenuItem(value: 'Weeks', child: Text('Week(s)')),
                    ],
                    onChanged: (val) => setState(() => _delayUnit = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Presets:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _presetChip('Immediate (Day 0)', 0),
                _presetChip('1 Day', 1),
                _presetChip('3 Days', 3),
                _presetChip('1 Week', 7),
                _presetChip('2 Weeks', 14),
                _presetChip('1 Month', 30),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty &&
                _contentController.text.isNotEmpty) {
              widget.onSave(
                _titleController.text,
                _contentController.text,
                _totalDelayDays,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFBB03B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Add to Sequence'),
        ),
      ],
    );
  }

  Widget _presetChip(String label, int days) {
    final isSelected = _totalDelayDays == days;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) => _setPreset(days),
      selectedColor: const Color(0xFFFBB03B).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFFBB03B) : Colors.black87,
      ),
    );
  }
}
