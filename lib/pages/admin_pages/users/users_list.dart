import 'package:app/cubits/user_cubit/user_cubit.dart';
import 'package:app/cubits/user_cubit/user_state.dart';
import 'package:app/models/user_model.dart';
import 'package:app/widgets/data_grid_list.dart';
import 'package:app/widgets/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UsersList extends StatefulWidget {
  final Function(User) onUserSelected;

  const UsersList({super.key, required this.onUserSelected});

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  String _searchQuery = '';

  // Grid columns definition
  List<DataGridColumn<User>> get _userColumns => [
        DataGridColumn<User>(
          header: 'ID',
          getValue: (user) => user.id?.toString() ?? '',
          flex: 1,
        ),
        DataGridColumn<User>(
          header: 'User Name',
          getValue: (user) => user.userName,
          flex: 2,
        ),
        DataGridColumn<User>(
          header: 'Branch',
          getValue: (user) => user.branchName,
          flex: 2,
        ),
        DataGridColumn<User>(
          header: 'Authorization',
          getValue: (user) => user.authorization,
          flex: 2,
        ),
        DataGridColumn<User>(
          header: 'Allow Login',
          getValue: (user) => user.allowLogin ? 'Yes' : 'No',
          flex: 1,
        ),
      ];

  // Search predicate for filtering users
  bool _searchUsers(User user, String query) {
    query = query.toLowerCase();
    return user.userName.toLowerCase().contains(query) ||
        user.branchName.toLowerCase().contains(query);
  }

  @override
  void initState() {
    super.initState();
    context.read<UserCubit>().fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageUtils.buildSearchBar(
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: BlocBuilder<UserCubit, UserState>(
            builder: (context, state) {
              if (state is UserLoadingState) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is UserLoadedState) {
                return GenericDataGrid<User>(
                  items: state.users,
                  columns: _userColumns,
                  onItemSelected: widget.onUserSelected,
                  searchQuery: _searchQuery,
                  searchPredicate: _searchUsers,
                );
              }

              return const Center(child: Text('No data available'));
            },
          ),
        ),
      ],
    );
  }
}
