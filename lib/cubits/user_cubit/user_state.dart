import '../../models/user_model.dart';

abstract class UserState {}

class UserInitialState extends UserState {}

class UserLoadingState extends UserState {}

class UserLoadedState extends UserState {
  final List<User> users;
  UserLoadedState(this.users);
}

class UserErrorState extends UserState {
  final String errorMessage;
  UserErrorState(this.errorMessage);
}
class UserPasswordChangedState extends UserState {}