import 'package:flutter/material.dart';
import '../../models/master_sequence.dart';
import '../../utils/db/scheduled_db_helper.dart';
import 'add_master_sequence_screen.dart';

class MasterSequenceScreen extends StatefulWidget {
  const MasterSequenceScreen({super.key});

  @override
  State<MasterSequenceScreen> createState() => _MasterSequenceScreenState();
}

class _MasterSequenceScreenState extends State<MasterSequenceScreen> {
  final ScheduledDbHelper _dbHelper = ScheduledDbHelper();
  List<MasterSequence> _sequences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSequences();
  }

  Future<void> _loadSequences() async {
    setState(() => _isLoading = true);
    final sequences = await _dbHelper.getMasterSequences();
    setState(() {
      _sequences = sequences;
      _isLoading = false;
    });
  }

  Future<void> _deleteSequence(int id) async {
    await _dbHelper.deleteMasterSequence(id);
    _loadSequences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Master Sequences'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFBB03B)),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddMasterSequenceScreen(),
                ),
              );
              if (result == true) {
                _loadSequences();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFBB03B)),
            )
          : _sequences.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sequences.length,
              itemBuilder: (context, index) {
                final sequence = _sequences[index];
                return _buildSequenceCard(sequence);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_motion_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No sequences yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a drip campaign triggered by tags',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddMasterSequenceScreen(),
                ),
              );
              if (result == true) {
                _loadSequences();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBB03B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Create Sequence',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceCard(MasterSequence sequence) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text(
          sequence.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Trigger: Tag ID ${sequence.tagId}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: sequence.isActive,
              activeColor: const Color(0xFFFBB03B),
              onChanged: (value) async {
                final updated = MasterSequence(
                  id: sequence.id,
                  title: sequence.title,
                  tagId: sequence.tagId,
                  isActive: value,
                );
                await _dbHelper.updateMasterSequence(updated);
                _loadSequences();
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddMasterSequenceScreen(sequence: sequence),
                  ),
                );
                if (result == true) {
                  _loadSequences();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(sequence),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(MasterSequence sequence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sequence?'),
        content: Text('Are you sure you want to delete "${sequence.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteSequence(sequence.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
