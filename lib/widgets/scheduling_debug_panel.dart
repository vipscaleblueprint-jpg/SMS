import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/db/scheduled_db_helper.dart';
import '../utils/db/sms_db_helper.dart';
import '../utils/db/tags_db_helper.dart';
import '../services/scheduling_service.dart';
import '../utils/db/event_db_helper.dart';
import 'dart:convert';
import '../utils/db/contact_db_helper.dart';
import '../services/sms_service.dart';
import '../services/sequence_service.dart';
import '../models/contact.dart';

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
      debugPrint('🚀 Manual Dispatch Triggered');
      final db = await ScheduledDbHelper().database;
      final groups = await db.rawQuery('SELECT * FROM scheduled_groups');
      debugPrint('--- RAW GROUPS DB DUMP ---');
      for (var g in groups) {
        debugPrint(g.toString());
      }

      final tagsDb = await TagsDbHelper.instance.database;
      final tags = await tagsDb.rawQuery('SELECT * FROM tags');
      debugPrint('--- RAW TAGS DB DUMP ---');
      for (var t in tags) {
        debugPrint(t.toString());
      }

      final contactTags = await tagsDb.rawQuery('SELECT * FROM contact_tags');
      debugPrint('--- RAW CONTACT_TAGS DUMP ---');
      for (var ct in contactTags) {
        debugPrint(ct.toString());
      }

      await dispatcher(); // Call top-level dispatcher
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ Manual Dispatch Sequence Started!'),
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

  Future<void> _repairTagIds(BuildContext context) async {
    try {
      debugPrint('🔧 Starting Deep Tag ID Repair...');
      final tagsDb = await TagsDbHelper.instance.database;
      final tagRows = await tagsDb.query('tags');

      int tagsMigrated = 0;
      int groupsFixed = 0;
      int messagesFixed = 0;
      int eventsFixed = 0;
      int contactLinksFixed = 0;

      final scheduledDb = await ScheduledDbHelper().database;
      final eventDb = await EventDbHelper().database;
      // final contactDb = await ContactDbHelper.instance.database; // Not needed as we use tagsDb for contact_tags

      for (var row in tagRows) {
        final oldId = row['id'] as String;
        final name = row['name'] as String;

        // Check if ID is legacy (not numeric)
        final isLegacy = !RegExp(r'^\d+$').hasMatch(oldId);

        if (isLegacy) {
          final newId =
              DateTime.now().millisecondsSinceEpoch.toString() +
              (tagsMigrated % 100).toString();
          debugPrint('Migrating Tag "$name": $oldId -> $newId');

          await tagsDb.transaction((txn) async {
            // 1. Update Tags table (Create new, delete old)
            await txn.insert('tags', {
              'id': newId,
              'name': name,
              'color': row['color'],
              'created': row['created'],
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            await txn.delete('tags', where: 'id = ?', whereArgs: [oldId]);

            // 2. Update Contact-Tag links
            final affectedLinks = await txn.update(
              'contact_tags',
              {'tag_id': newId},
              where: 'tag_id = ?',
              whereArgs: [oldId],
            );
            contactLinksFixed += affectedLinks;
          });

          // 3. Update Scheduled Groups
          final groups = await scheduledDb.query('scheduled_groups');
          for (var group in groups) {
            final gid = group['id'];
            final raw = group['tag_ids'] as String?;
            if (raw != null && raw.contains(oldId)) {
              final newRaw = raw
                  .split(',')
                  .map((id) => id == oldId ? newId : id)
                  .join(',');
              await scheduledDb.update(
                'scheduled_groups',
                {'tag_ids': newRaw},
                where: 'id = ?',
                whereArgs: [gid],
              );
              groupsFixed++;
            }
          }

          // 4. Update Scheduled Messages
          final msgs = await scheduledDb.query('scheduled_messages');
          for (var msg in msgs) {
            final mid = msg['id'];
            final raw = msg['tag_ids'] as String?;
            if (raw != null && raw.contains(oldId)) {
              final newRaw = raw
                  .split(',')
                  .map((id) => id == oldId ? newId : id)
                  .join(',');
              await scheduledDb.update(
                'scheduled_messages',
                {'tag_ids': newRaw},
                where: 'id = ?',
                whereArgs: [mid],
              );
              messagesFixed++;
            }
          }

          // 5. Update Events (JSON)
          final events = await eventDb.query('events');
          for (var event in events) {
            final eid = event['id'];
            final rawRecipients = event['recipients'] as String?;
            if (rawRecipients != null && rawRecipients.contains(oldId)) {
              final Map<String, dynamic> recipients = jsonDecode(rawRecipients);
              if (recipients.containsKey('tags')) {
                final List<dynamic> tagIds = recipients['tags'];
                final newTagIds = tagIds
                    .map((id) => id.toString() == oldId ? newId : id)
                    .toList();
                recipients['tags'] = newTagIds;
                await eventDb.update(
                  'events',
                  {'recipients': jsonEncode(recipients)},
                  where: 'id = ?',
                  whereArgs: [eid],
                );
                eventsFixed++;
              }
            }
          }

          tagsMigrated++;
          // Small delay to ensure unique timestamps if multiple tags migrate
          await Future.delayed(const Duration(milliseconds: 2));
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Repair Complete! Migrated $tagsMigrated tags. Updated $contactLinksFixed links, $groupsFixed groups, $messagesFixed messages, $eventsFixed events.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('❌ Deep Repair Error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Deep Repair Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testSend(BuildContext context) async {
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController msgController = TextEditingController(
      text: 'Test message from Debug Panel',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Direct Send'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (with +)',
              ),
              keyboardType: TextInputType.phone,
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: msgController,
              builder: (context, value, _) {
                final len = value.text.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: msgController,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        helperText:
                            'Chars: $len ${len > 160 ? "(Multipart)" : ""}',
                      ),
                      maxLines: 5,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              final msg = msgController.text.trim();
              if (phone.isEmpty || msg.isEmpty) return;
              Navigator.pop(ctx);

              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Testing flexible send to $phone...')),
                );

                // Use sendFlexibleSms for realistic testing
                final dummyContact = Contact(
                  contact_id: 'test-id',
                  first_name: 'Test',
                  last_name: 'User',
                  phone: phone,
                  created: DateTime.now(),
                );

                await SmsService().sendFlexibleSms(
                  contact: dummyContact,
                  message: msg,
                  instant: true,
                  additionalTags: {
                    'event_time': DateTime.now()
                        .add(const Duration(days: 1))
                        .toIso8601String(),
                  },
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Handed off to OS for $phone!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test Failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🛠 Scheduling Debug',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
              const Icon(Icons.bug_report, size: 16, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CompactButton(
                onPressed: () => _checkDueMessages(context),
                icon: Icons.schedule,
                label: 'Due Check',
                color: Colors.blue,
              ),
              _CompactButton(
                onPressed: () => _triggerManualDispatch(context),
                icon: Icons.play_arrow,
                label: 'Dispatch',
                color: Colors.green,
              ),
              _CompactButton(
                onPressed: () async {
                  final db = await SmsDbHelper().database;
                  final count =
                      Sqflite.firstIntValue(
                        await db.rawQuery('SELECT COUNT(*) FROM sms'),
                      ) ??
                      0;
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📜 Total SMS History Records: $count'),
                    ),
                  );
                },
                icon: Icons.history,
                label: 'History Count',
                color: Colors.purple,
              ),
              _CompactButton(
                onPressed: () async {
                  final db = await SmsDbHelper().database;
                  final rows = await db.query(
                    'sms',
                    orderBy: 'id DESC',
                    limit: 5,
                  );
                  debugPrint('--- [HISTORY DUMP] Last 5 records ---');
                  for (final row in rows) {
                    debugPrint(row.toString());
                  }
                  debugPrint('--- END DUMP ---');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📑 History Dumped to Console!'),
                    ),
                  );
                },
                icon: Icons.list_alt,
                label: 'Dump History',
                color: Colors.brown,
              ),
              _CompactButton(
                onPressed: () async {
                  await SequenceService().initializeWelcomeSequence();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🌱 Welcome Sequence Seeded/Checked!'),
                    ),
                  );
                },
                icon: Icons.auto_awesome,
                label: 'Seed Welcome',
                color: Colors.teal,
              ),
              _CompactButton(
                onPressed: () => _repairTagIds(context),
                icon: Icons.build,
                label: 'Repair Tags',
                color: Colors.red.shade700,
              ),
              _CompactButton(
                onPressed: () async {
                  debugPrint('--- [GLOBAL DB DUMP START] ---');

                  // 1. Tags
                  final tagsDb = await TagsDbHelper.instance.database;
                  final tags = await tagsDb.query('tags');
                  debugPrint('\n--- 🏷️ TAGS ---');
                  for (var t in tags)
                    debugPrint('ID: ${t['id']} | Name: ${t['name']}');

                  // 2. Contacts
                  final contactDb = await ContactDbHelper.instance.database;
                  final contactRows = await contactDb.query('contacts');
                  debugPrint('\n--- 👤 CONTACTS ---');
                  for (var c in contactRows)
                    debugPrint(
                      'ID: ${c['contact_id']} | Name: ${c['first_name']} ${c['last_name']} | Phone: ${c['phone']}',
                    );

                  // 3. Scheduled Groups
                  final scheduledDb = await ScheduledDbHelper().database;
                  final groups = await scheduledDb.query('scheduled_groups');
                  debugPrint('\n--- 📁 SCHEDULED GROUPS ---');
                  for (var g in groups)
                    debugPrint(
                      'ID: ${g['id']} | Title: ${g['title']} | Tags: ${g['tag_ids']}',
                    );

                  // 4. Scheduled Messages
                  final schedMsgs = await scheduledDb.query(
                    'scheduled_messages',
                  );
                  debugPrint('\n--- 📨 CAMPAIGN TEMPLATES ---');
                  for (var m in schedMsgs)
                    debugPrint(
                      'ID: ${m['id']} | Title: ${m['title']} | Status: ${m['status']}',
                    );

                  // 5. Master Sequences
                  final sequences = await scheduledDb.query('master_sequences');
                  debugPrint('\n--- 🤖 MASTER SEQUENCES ---');
                  for (var s in sequences)
                    debugPrint(
                      'ID: ${s['id']} | Title: ${s['title']} | TagID: ${s['tag_id']}',
                    );

                  // 6. Sequence Messages
                  final seqMsgs = await scheduledDb.query('sequence_messages');
                  debugPrint('\n--- ✉️ SEQUENCE MESSAGES ---');
                  for (var m in seqMsgs)
                    debugPrint(
                      'ID: ${m['id']} | SeqID: ${m['sequence_id']} | Delay: ${m['delay_days']}d | Message: ${m['message'].toString().substring(0, m['message'].toString().length > 30 ? 30 : m['message'].toString().length)}...',
                    );

                  // 7. Subscriptions
                  final subs = await scheduledDb.query(
                    'sequence_subscriptions',
                  );
                  debugPrint('\n--- 🔗 SUBSCRIPTIONS ---');
                  for (var sub in subs)
                    debugPrint(
                      'ID: ${sub['id']} | ContactID: ${sub['contact_id']} | SeqID: ${sub['sequence_id']}',
                    );

                  // 4. Scheduled Messages (Templates)
                  final messages = await scheduledDb.query(
                    'scheduled_messages',
                  );
                  debugPrint('\n--- 📨 CAMPAIGN TEMPLATES (Recurring) ---');
                  for (var m in messages)
                    debugPrint(
                      'ID: ${m['id']} | Title: ${m['title']} | Status: ${m['status']}',
                    );

                  // 5. Events
                  final eventDb = await EventDbHelper().database;
                  final events = await eventDb.query('events');
                  debugPrint('\n--- 📅 EVENTS ---');
                  for (var e in events)
                    debugPrint(
                      'ID: ${e['id']} | Name: ${e['name']} | Status: ${e['status']} | Recipients: ${e['recipients']}',
                    );

                  // 6. One-Time / Event Instances (SMS Table)
                  final smsDb = await SmsDbHelper().database;
                  final smsRecords = await smsDb.query(
                    'sms',
                    orderBy: 'id DESC',
                    limit: 20,
                  );
                  debugPrint('\n--- ✉️ SMS HISTORY / INSTANCES (Last 20) ---');
                  for (var s in smsRecords)
                    debugPrint(
                      'ID: ${s['id']} | Phone: ${s['phone_number']} | Status: ${s['status']} | EventID: ${s['event_id']} | Batch: ${s['batchId']}',
                    );

                  debugPrint('\n--- [GLOBAL DB DUMP END] ---');

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📈 Global DB Dumped to Console!'),
                    ),
                  );
                },
                icon: Icons.all_out,
                label: 'Dump All',
                color: Colors.black,
              ),
              _CompactButton(
                onPressed: () => _testSend(context),
                icon: Icons.send,
                label: 'Test Send',
                color: Colors.indigo,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Inspector Section
          const Text(
            'Inspect DB:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CompactButton(
                onPressed: () async {
                  final dbHelper = SmsDbHelper();
                  final smsList = await dbHelper.getSmsList();
                  if (!context.mounted) return;
                  _showDialog(
                    context,
                    'One-Time SMS DB',
                    smsList.isEmpty
                        ? 'Empty.'
                        : smsList
                              .map(
                                (s) =>
                                    '[${s.id}] ${s.title}\nStatus: ${s.status}\nTime: ${s.schedule_time}',
                              )
                              .join('\n--\n'),
                  );
                },
                label: 'One-Time',
                color: Colors.teal,
              ),
              _CompactButton(
                onPressed: () async {
                  final dbHelper = ScheduledDbHelper();
                  final messages = await dbHelper.database.then(
                    (db) => db.query('scheduled_messages'),
                  );
                  if (!context.mounted) return;
                  _showDialog(
                    context,
                    'Recurring SMS DB',
                    messages.isEmpty
                        ? 'Empty.'
                        : messages
                              .map(
                                (m) =>
                                    '[${m['id']}] ${m['title']}\nNext: ${m['scheduled_time']}\nStatus: ${m['status']}',
                              )
                              .join('\n--\n'),
                  );
                },
                label: 'Recurring',
                color: Colors.deepOrange,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Console Log Section
          const Text(
            'Log to Console:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CompactButton(
                onPressed: () async {
                  final dbHelper = SmsDbHelper();
                  final rawMaps = await (await dbHelper.database).query('sms');
                  debugPrint(
                    '--- RAW SMS DB DUMP ---\n${rawMaps.join('\n')}\n--- END ---',
                  );
                },
                icon: Icons.sms,
                label: 'One-Time',
                color: Colors.black87,
              ),
              _CompactButton(
                onPressed: () async {
                  final dbHelper = ScheduledDbHelper();
                  final rawMaps = await (await dbHelper.database).query(
                    'scheduled_messages',
                  );
                  debugPrint(
                    '--- RAW RECURRING SMS DUMP ---\n${rawMaps.join('\n')}\n--- END ---',
                  );
                },
                icon: Icons.repeat,
                label: 'Recurring',
                color: Colors.brown,
              ),
              _CompactButton(
                onPressed: () async {
                  final dbHelper = ScheduledDbHelper();
                  final rawMaps = await (await dbHelper.database).query(
                    'scheduled_groups',
                  );
                  debugPrint(
                    '--- RAW GROUPS DB DUMP ---\n${rawMaps.join('\n')}\n--- END ---',
                  );
                },
                icon: Icons.group_work,
                label: 'Groups',
                color: Colors.blueGrey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color color;
  final IconData? icon;

  const _CompactButton({
    required this.onPressed,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14), const SizedBox(width: 4)],
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
