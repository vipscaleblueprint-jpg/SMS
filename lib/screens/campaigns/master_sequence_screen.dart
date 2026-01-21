import 'package:flutter/material.dart';
import '../../models/master_sequence.dart';
import '../../utils/db/scheduled_db_helper.dart';
import '../../widgets/header_user.dart';
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standard Header Area
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Back Button and User Profile
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const HeaderUser(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title and Add Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Master Sequences',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withOpacity(0.9),
                            letterSpacing: -1,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddMasterSequenceScreen(),
                              ),
                            );
                            if (result == true) {
                              _loadSequences();
                            }
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBB03B).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Color(0xFFFBB03B),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: Container(
                color: const Color(0xFFF8F9FA),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFBB03B),
                        ),
                      )
                    : _sequences.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _sequences.length,
                        itemBuilder: (context, index) {
                          final sequence = _sequences[index];
                          return _buildSequenceCard(sequence);
                        },
                      ),
              ),
            ),
          ],
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddMasterSequenceScreen(sequence: sequence),
            ),
          );
          if (result == true) {
            _loadSequences();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sequence.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.label_outline_rounded,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Trigger: Tag ID ${sequence.tagId}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
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
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
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
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(sequence),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
