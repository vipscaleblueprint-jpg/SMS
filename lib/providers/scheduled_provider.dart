import 'package:flutter_riverpod/legacy.dart';
import '../../models/scheduled_group.dart';
import '../../utils/db/scheduled_db_helper.dart';

final scheduledGroupsProvider =
    StateNotifierProvider<ScheduledGroupsNotifier, List<ScheduledGroup>>((ref) {
      return ScheduledGroupsNotifier();
    });

class ScheduledGroupsNotifier extends StateNotifier<List<ScheduledGroup>> {
  ScheduledGroupsNotifier() : super([]) {
    loadGroups();
  }

  Future<void> loadGroups() async {
    final groups = await ScheduledDbHelper().getGroups();
    state = groups.reversed.toList();
  }

  Future<void> addGroup(
    String title, {
    Set<String> contactIds = const {},
    Set<String> tagIds = const {},
  }) async {
    final newGroup = ScheduledGroup(
      title: title,
      contactIds: contactIds,
      tagIds: tagIds,
    );
    await ScheduledDbHelper().insertGroup(newGroup);
    await loadGroups();
  }

  Future<void> deleteGroup(int id) async {
    await ScheduledDbHelper().deleteGroup(id);
    await loadGroups();
  }
}
