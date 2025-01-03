import 'package:app/helper/branch_db_helper.dart';
import 'package:app/models/branches_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../helper/sql_helper.dart';
import 'branch_states.dart';



class BranchCubit extends Cubit<BranchState> {
  final DatabaseHelper _databaseHelper;

  BranchCubit(this._databaseHelper) : super(BranchInitialState());

  Future<void> fetchBranches() async {
    try {
      emit(BranchLoadingState());
      final branches = await getBranches();
      emit(BranchLoadedState(branches));
    } catch (e) {
      emit(BranchErrorState('Failed to load branches: ${e.toString()}'));
    }
  }

  // Define the private method _getBranches
  Future<List<Branch>> getBranches() async {
    return await _databaseHelper.getAllBranches();
  }

  Future<void> addBranch(Branch branch) async {
    try {
      await _databaseHelper.insertBranch(branch);
      await fetchBranches();
    } catch (e) {
      emit(BranchErrorState('Failed to add branch: ${e.toString()}'));
    }
  }

  Future<void> updateBranch(Branch branch) async {
    try {
      await _databaseHelper.updateBranch(branch);
      await fetchBranches();
    } catch (e) {
      emit(BranchErrorState('Failed to update branch: ${e.toString()}'));
    }
  }

  Future<void> deleteBranch(int branchId) async {
    try {
      await _databaseHelper.deleteBranch(branchId);
      await fetchBranches();
    } catch (e) {
      emit(BranchErrorState('Failed to delete branch: ${e.toString()}'));
    }
  }
}
