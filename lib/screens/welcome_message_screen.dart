import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/db/scheduled_db_helper.dart';
import '../models/master_sequence.dart';
import '../models/tag.dart';
import '../providers/tags_provider.dart';
import '../providers/contacts_provider.dart';
import '../utils/db_inspector.dart';

class WelcomeMessageScreen extends ConsumerStatefulWidget {
  const WelcomeMessageScreen({super.key});

  @override
  ConsumerState<WelcomeMessageScreen> createState() =>
      _WelcomeMessageScreenState();
}

class _WelcomeMessageScreenState extends ConsumerState<WelcomeMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final _db = ScheduledDbHelper();
  MasterSequence? _welcomeSequence;
  SequenceMessage? _welcomeMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    DbInspector.inspect();
    _loadWelcomeMessage();
  }

  Future<void> _loadWelcomeMessage() async {
    try {
      // Ensure 'new' tag exists to get its correct ID
      final Tag newTag = await ref
          .read(tagsProvider.notifier)
          .getOrCreateTag('new');

      final sequences = await _db.getMasterSequences();
      // Look for a sequence titled "Welcome Message" or one linked to 'new' tag ID
      _welcomeSequence = sequences.firstWhere(
        (s) => s.title == 'Welcome Message' || s.tagId == newTag.id,
        orElse: () =>
            MasterSequence(title: 'Welcome Message', tagId: newTag.id),
      );

      if (_welcomeSequence!.id != null) {
        final messages = await _db.getSequenceMessages(_welcomeSequence!.id!);
        if (messages.isNotEmpty) {
          _welcomeMessage = messages.first;
          _messageController.text = _welcomeMessage!.message;
        }
      }

      if (_welcomeMessage == null && _messageController.text.isEmpty) {
        // Default template if nothing found
        _messageController.text =
            'Welcome and thank you for connecting with us!\n\n'
            'We\'re pleased to have you as part of our contact list. By joining us, you\'ll receive relevant updates, insights, and information about our products, services, and industry developments that we believe will be valuable to you.\n\n'
            'Our goal is to keep you informed, supported, and up to date with content that helps you make confident, informed decisions. From time to time, we may also share important announcements, resources, or opportunities tailored to your interests.\n\n'
            'If you have any questions or would like to learn more about how we can support your business, please don\'t hesitate to reach out. We look forward to building a productive and successful relationship with you.\n\n'
            'Warm regards,\n'
            'VIP SCALE';
      }
    } catch (e) {
      debugPrint('Error loading welcome message: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWelcomeMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      // 1. Ensure 'new' tag exists in tags DB (ContactDbHelper/tags table)
      await ref.read(tagsProvider.notifier).getOrCreateTag('new');

      // 2. Ensure MasterSequence exists
      if (_welcomeSequence?.id == null) {
        final id = await _db.insertMasterSequence(_welcomeSequence!);
        _welcomeSequence = MasterSequence(
          id: id,
          title: _welcomeSequence!.title,
          tagId: _welcomeSequence!.tagId,
          isActive: _welcomeSequence!.isActive,
        );
      }

      // 3. Save SequenceMessage (delay 0 for welcome)
      if (_welcomeMessage == null) {
        final msg = SequenceMessage(
          sequenceId: _welcomeSequence!.id!,
          title: 'Welcome SMS',
          message: text,
          delayDays: 0,
        );
        final id = await _db.insertSequenceMessage(msg);
        _welcomeMessage = SequenceMessage(
          id: id,
          sequenceId: msg.sequenceId,
          title: msg.title,
          message: msg.message,
          delayDays: msg.delayDays,
        );
      } else {
        // Delete and re-insert or update? ScheduledDbHelper doesn't have updateSequenceMessage
        // Let's just delete the old one and add new one for simplicity if update is missing,
        // but wait, I should check if I can add updateSequenceMessage to DB helper.
        // For now, let's just delete old ones for this sequence and add this one as the primary.
        final existing = await _db.getSequenceMessages(_welcomeSequence!.id!);
        for (final m in existing) {
          if (m.id != null) await _db.deleteSequenceMessage(m.id!);
        }

        final msg = SequenceMessage(
          sequenceId: _welcomeSequence!.id!,
          title: 'Welcome SMS',
          message: text,
          delayDays: 0,
        );
        final id = await _db.insertSequenceMessage(msg);
        _welcomeMessage = SequenceMessage(
          id: id,
          sequenceId: msg.sequenceId,
          title: msg.title,
          message: msg.message,
          delayDays: msg.delayDays,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome message updated successfully')),
        );
      }

      // 4. Trigger a sync for existing contacts with 'new' tag
      final contacts = ref.read(contactsProvider);
      final Tag newTag = await ref
          .read(tagsProvider.notifier)
          .getOrCreateTag('new');
      debugPrint('🔄 Manual Sync: Checking contacts for "new" tag...');

      for (final contact in contacts) {
        final hasNewTag = contact.tags.any(
          (t) => t.id == newTag.id || t.name.toLowerCase() == 'new',
        );

        if (hasNewTag) {
          debugPrint('🔄 Syncing contact: ${contact.first_name}');
          // This will trigger checkTriggers in syncSubscriptions
          ref.read(contactsProvider.notifier).updateContact(contact);
        }
      }
    } catch (e) {
      debugPrint('Error saving welcome message: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
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
        actions: [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Screen Title and Chip
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
                          'New Imported Contacts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                    ],
                  ),
                ),

                // Message Content Area
                Expanded(
                  child: Container(
                    color: Colors.grey[200], // Grey background for chat area
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // The Message Bubble
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
                                _messageController.text,
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
                        // Note: Sent status is static in UI for now as per "do not alter UI"
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Sent 13/13',
                            style: TextStyle(
                              color: Color(0xFFFBB03B), // Yellow/Orange color
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Input Area
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            onChanged: (v) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Set welcome message...',
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
                        GestureDetector(
                          onTap: _saveWelcomeMessage,
                          child: Container(
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
