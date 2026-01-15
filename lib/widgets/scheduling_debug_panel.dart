import 'package:flutter/material.dart';
import '../utils/db/scheduled_db_helper.dart';
import '../services/scheduling_service.dart';

/// Debug helper widget for testing scheduled messages
/// Add this to your app during development to test scheduling
class SchedulingDebugPanel extends StatelessWidget {
  const SchedulingDebugPanel({super.key});

  Future<void> _checkDueMessages(BuildContext context) async {
    final dbHelper = ScheduledDbHelper();
    final now = DateTime.now();
    final messages = await dbHelper.getDueMessages(now);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Due Messages'),
        content: Text(
          messages.isEmpty
              ? 'No messages due right now'
              : 'Found ${messages.length} due messages:\n\n${messages.map((m) => '• ${m.title}\n  Scheduled: ${m.scheduledTime}\n  Status: ${m.status}').join('\n\n')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerManualDispatch(BuildContext context) async {
    try {
      // Manually trigger the dispatcher
      dispatcher();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Manual dispatch triggered! Check console logs.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAllScheduledMessages(BuildContext context) async {
    final dbHelper = ScheduledDbHelper();
    final groups = await dbHelper.getGroups();

    final buffer = StringBuffer();
    for (final group in groups) {
      buffer.writeln('📁 ${group.title}');
      buffer.writeln('   Active: ${group.isActive}');

      final messages = await dbHelper.getMessagesByGroupId(group.id!);
      for (final msg in messages) {
        buffer.writeln('   • ${msg.title}');
        buffer.writeln('     Frequency: ${msg.frequency}');
        buffer.writeln('     Day: ${msg.scheduledDay}');
        buffer.writeln('     Next run: ${msg.scheduledTime}');
        buffer.writeln('     Status: ${msg.status}');
      }
      buffer.writeln('');
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('All Scheduled Messages'),
        content: SingleChildScrollView(
          child: Text(
            buffer.isEmpty ? 'No scheduled messages' : buffer.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '🔧 Scheduling Debug Panel',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _checkDueMessages(context),
            icon: const Icon(Icons.schedule),
            label: const Text('Check Due Messages'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _triggerManualDispatch(context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Trigger Manual Dispatch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAllScheduledMessages(context),
            icon: const Icon(Icons.list),
            label: const Text('Show All Messages'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
