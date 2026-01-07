import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scheduled_group.dart';
import '../utils/db/sms_db_helper.dart';

final scheduledGroupsProvider =
    NotifierProvider<ScheduledGroupsNotifier, List<ScheduledGroup>>(
      ScheduledGroupsNotifier.new,
    );

class ScheduledGroupsNotifier extends Notifier<List<ScheduledGroup>> {
  @override
  List<ScheduledGroup> build() {
    loadGroups();
    return [];
  }

  Future<void> loadGroups() async {
    final maps = await SmsDbHelper().getScheduledGroups();
    state = maps.map((m) => ScheduledGroup.fromMap(m)).toList();
  }

  Future<int> addGroup(String title) async {
    final group = ScheduledGroup(title: title);
    final id = await SmsDbHelper().insertScheduledGroup(group.toMap());
    await loadGroups();
    return id;
  }

  Future<void> updateGroup(ScheduledGroup group) async {
    await SmsDbHelper().updateScheduledGroup(group.toMap());
    await loadGroups();
  }

  Future<void> deleteGroup(int id) async {
    await SmsDbHelper().deleteScheduledGroup(id);
    await loadGroups();
  }

  Future<void> toggleGroup(ScheduledGroup group, bool isActive) async {
    final updated = ScheduledGroup(
      id: group.id,
      title: group.title,
      isActive: isActive,
    );
    await updateGroup(updated);
  }
}
