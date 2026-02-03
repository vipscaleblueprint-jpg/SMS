import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/db/scheduled_db_helper.dart';
import '../models/master_sequence.dart';
import '../utils/db/tags_db_helper.dart';

class WelcomeMessageScreen extends ConsumerStatefulWidget {
  const WelcomeMessageScreen({super.key});

  @override
  ConsumerState<WelcomeMessageScreen> createState() =>
      _WelcomeMessageScreenState();
}

class _WelcomeMessageScreenState extends ConsumerState<WelcomeMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _messageText = '';
  int _sentCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = ScheduledDbHelper();

      // 1. Find the 'new' tag
      final tagsDb = TagsDbHelper.instance;
      final newTag = await tagsDb.getTagByName('new');

      // 2. Find the Welcome Sequence
      final sequences = await db.getMasterSequences();
      final welcomeSeq = sequences.firstWhere(
        (s) =>
            (newTag != null && s.tagId == newTag.id) ||
            s.title == 'Welcome Sequence',
        orElse: () => MasterSequence(title: '', tagId: '', isActive: false),
      );

      if (welcomeSeq.id != null) {
        // 2. Load the message
        final messages = await db.getSequenceMessages(welcomeSeq.id!);
        if (messages.isNotEmpty) {
          _messageText = messages.first.message;
          _messageController.text = _messageText;
        }

        // 3. Count logs
        final dbInstance = await db.database;
        final List<Map<String, dynamic>> logs = await dbInstance.rawQuery(
          '''
          SELECT COUNT(*) as total 
          FROM sequence_logs l
          INNER JOIN sequence_messages m ON l.message_id = m.id
          WHERE m.sequence_id = ?
          ''',
          [welcomeSeq.id],
        );
        _sentCount = Sqflite.firstIntValue(logs) ?? 0;
      }
    } catch (e) {
      debugPrint('❌ Error loading welcome message: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMessage() async {
    final newMsg = _messageController.text.trim();
    if (newMsg.isEmpty) return;

    try {
      final db = ScheduledDbHelper();
      final sequences = await db.getMasterSequences();
      final welcomeSeq = sequences.firstWhere(
        (s) => s.title == 'Welcome Sequence',
      );

      final messages = await db.getSequenceMessages(welcomeSeq.id!);
      if (messages.isNotEmpty) {
        final existing = messages.first;
        final updated = SequenceMessage(
          id: existing.id,
          sequenceId: existing.sequenceId,
          title: existing.title,
          message: newMsg,
          delayDays: existing.delayDays,
        );
        // We need an update method in ScheduledDbHelper if not there
        // Actually it has updateMessage but that's for scheduled_messages.
        // Let's check ScheduledDbHelper for SequenceMessage update.
        // If not there, I'll use rawUpdate.
        final dbInstance = await db.database;
        await dbInstance.update(
          'sequence_messages',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );

        setState(() => _messageText = newMsg);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome message updated!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFBB03B)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Message',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Newly Added Contacts',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _messageText.isEmpty
                              ? "No welcome message set."
                              : _messageText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            'Template',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Sent $_sentCount times',
                      style: const TextStyle(
                        color: Color(0xFFFBB03B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Edit welcome message...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _updateMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBB03B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons
                            .save, // Changed to save because we are updating template
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
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
