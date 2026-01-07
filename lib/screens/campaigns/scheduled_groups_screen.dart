import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/scheduled_groups_provider.dart';
import '../../models/scheduled_group.dart';
import '../../widgets/header_user.dart';
import 'scheduled_group_details_screen.dart';
import '../home/contact_screen.dart';

class ScheduledGroupsScreen extends ConsumerStatefulWidget {
  const ScheduledGroupsScreen({super.key});

  @override
  ConsumerState<ScheduledGroupsScreen> createState() =>
      _ScheduledGroupsScreenState();
}

class _ScheduledGroupsScreenState extends ConsumerState<ScheduledGroupsScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _showAddGroupDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Text(
            'Create a Scheduled SMS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  hintText: 'Title',
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final id = await ref
                          .read(scheduledGroupsProvider.notifier)
                          .addGroup(titleController.text);
                      if (mounted) {
                        Navigator.pop(context);
                        // Navigate to details of new group
                        final groups = ref.read(scheduledGroupsProvider);
                        final newGroup = groups.firstWhere((g) => g.id == id);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ScheduledGroupDetailsScreen(group: newGroup),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBB03B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(ScheduledGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: Text(
          'This will delete "${group.title}" and all its messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(scheduledGroupsProvider.notifier).deleteGroup(group.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(scheduledGroupsProvider);
    final search = _searchController.text.toLowerCase();
    final filteredGroups = groups
        .where((g) => g.title.toLowerCase().contains(search))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: HeaderUser()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scheduled',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _showAddGroupDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBB03B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Add Scheduled'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search Scheduled SMS',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Title',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 40), // Space for delete icon
                    ],
                  ),
                  const Divider(),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredGroups.length,
                itemBuilder: (context, index) {
                  final group = filteredGroups[index];
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(group.title),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.grey,
                          ),
                          onPressed: () => _showDeleteConfirm(group),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ScheduledGroupDetailsScreen(group: group),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                    ],
                  );
                },
              ),
            ),
            // Bottom Nav with interactive icons
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(
                    icon: Icons.contact_page_outlined,
                    label: 'Contacts',
                    index: 0,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.send_outlined,
                    label: 'Send',
                    index: 1,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.campaign,
                    label: 'Campaigns',
                    index: 2,
                    isActive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isActive = false,
  }) {
    final color = isActive ? const Color(0xFFFBB03B) : Colors.grey[400];
    return Expanded(
      child: InkWell(
        onTap: () {
          if (isActive) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(initialIndex: index),
            ),
            (route) => false,
          );
        },
        child: Column(
          children: [
            const Expanded(child: SizedBox()),
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Expanded(child: SizedBox()),
            if (isActive)
              Container(
                height: 3,
                width: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
              )
            else
              const SizedBox(height: 3),
          ],
        ),
      ),
    );
  }
}
