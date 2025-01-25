import 'package:flutter/material.dart';
import 'package:app/models/user_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UsersList extends StatelessWidget {
  final List<User> users;
  final Function(User) onUserSelected;
  final String searchQuery;

  const UsersList({
    super.key,
    required this.users,
    required this.onUserSelected,
    this.searchQuery = '',
  });

  List<User> _filterUsers(List<User> users, String query) {
    if (query.isEmpty) return users;

    return users.where((user) {
      final searchLower = query.toLowerCase();
      return user.userName.toLowerCase().contains(searchLower) ||
          user.branchName.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filterUsers(users, searchQuery);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(40),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: 48.w,
          dataRowMinHeight: 56.h,
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          headingTextStyle:
              TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold),
          dataTextStyle: TextStyle(fontSize: 18.sp),
          columns: [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('User Name')),
            DataColumn(label: Text('Branch')),
            DataColumn(label: Text('Authorization')),
            DataColumn(label: Text('Allow Login')),
          ],
          rows: filteredUsers.map((user) {
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  return states.contains(WidgetState.selected)
                      ? Colors.grey[300]
                      : null;
                },
              ),
              cells: [
                DataCell(Text('${user.id ?? ""}')),
                DataCell(Text(user.userName)),
                DataCell(Text(user.branchName)),
                DataCell(Text(user.authorization)),
                DataCell(Text(user.allowLogin ? 'Yes' : 'No')),
              ],
              onSelectChanged: (_) => onUserSelected(user),
            );
          }).toList(),
        ),
      ),
    );
  }
}
