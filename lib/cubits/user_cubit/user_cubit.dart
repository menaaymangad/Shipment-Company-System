import 'package:app/helper/user_db_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../helper/sql_helper.dart';
import '../../models/user_model.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  UserCubit() : super(UserInitialState());

  Future<void> fetchUsers() async {
    try {
      emit(UserLoadingState());
      final users = await _databaseHelper.getAllUsers();
      emit(UserLoadedState(users));
    } catch (e) {
      emit(UserErrorState('Failed to load users: ${e.toString()}'));
    }
  }

  Future<void> addUser(User user) async {
    try {
      await _databaseHelper.insertUser(user);
      await fetchUsers();
    } catch (e) {
      emit(UserErrorState('Failed to add user: ${e.toString()}'));
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _databaseHelper.updateUser(user);
      await fetchUsers();
    } catch (e) {
      emit(UserErrorState('Failed to update user: ${e.toString()}'));
    }
  }
 
Future<void> changePassword(int userId, String newPassword) async {
    try {
      // First, fetch the existing user to get all current details
      final existingUser = await _databaseHelper.getUserById(userId);

      if (existingUser == null) {
        emit(UserErrorState('User not found'));
        return;
      }

      // Create a new user object with existing details and updated password
      final updatedUser = User(
          id: existingUser.id,
          userName: existingUser.userName,
          branchName: existingUser.branchName,
          authorization: existingUser.authorization,
          allowLogin: existingUser.allowLogin,
          password: newPassword);

      await _databaseHelper.updateUser(updatedUser);
      emit(UserPasswordChangedState());
    } catch (e) {
      emit(UserErrorState('Failed to change password: ${e.toString()}'));
    }
  }

  

  Future<void> deleteUser(int id) async {
    try {
      await _databaseHelper.deleteUser(id);
      await fetchUsers();
    } catch (e) {
      emit(UserErrorState('Failed to delete user: ${e.toString()}'));
    }
  }
}
