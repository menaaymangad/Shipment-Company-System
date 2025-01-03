



import 'package:app/models/branches_model.dart';

abstract class BranchState {}

class BranchInitialState extends BranchState {}

class BranchLoadingState extends BranchState {}

class BranchLoadedState extends BranchState {
  final List<Branch> branches;
  BranchLoadedState(this.branches);
}

class BranchErrorState extends BranchState {
  final String errorMessage;
  BranchErrorState(this.errorMessage);
}
