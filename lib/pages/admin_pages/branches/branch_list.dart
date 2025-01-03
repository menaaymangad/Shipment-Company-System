import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/branches_model.dart';
import '../../../widgets/data_grid_list.dart';

class BranchDataGridEnhanced extends StatelessWidget {
  final List<Branch> branches;
  final Function(Branch) onBranchSelected;
  final String searchQuery;

  const BranchDataGridEnhanced({
    super.key,
    required this.branches,
    required this.onBranchSelected,
    this.searchQuery = '',
  });

  static final List<DataGridColumn<Branch>> columns = [
    DataGridColumn<Branch>(
      header: 'ID',
      getValue: (branch) => '${branch.id ?? ""}',
      flex: 1,
    ),
    DataGridColumn<Branch>(
      header: 'Branch Name',
      getValue: (branch) => branch.branchName,
      flex: 2,
    ),
    DataGridColumn<Branch>(
      header: 'Contact Person',
      getValue: (branch) => branch.contactPersonName,
      flex: 2,
    ),
    DataGridColumn<Branch>(
      header: 'Company',
      getValue: (branch) => branch.branchCompany,
      flex: 2,
    ),
    DataGridColumn<Branch>(
      header: 'Phone 1',
      getValue: (branch) => branch.phoneNo1,
      flex: 2,
    ),
    DataGridColumn<Branch>(
      header: 'Phone 2',
      getValue: (branch) => branch.phoneNo2,
      flex: 2,
    ),
    DataGridColumn<Branch>(
      header: 'Address',
      getValue: (branch) => branch.address,
      flex: 2,
    ),
  ];

  bool _searchPredicate(Branch branch, String query) {
    final searchLower = query.toLowerCase();
    return branch.branchName.toLowerCase().contains(searchLower) ||
        branch.contactPersonName.toLowerCase().contains(searchLower) ||
        branch.branchCompany.toLowerCase().contains(searchLower) ||
        branch.phoneNo1.toLowerCase().contains(searchLower) ||
        branch.phoneNo2.toLowerCase().contains(searchLower) ||
        branch.address.toLowerCase().contains(searchLower);
  }

  @override
  Widget build(BuildContext context) {
    return GenericDataGrid<Branch>(
      items: branches,
      columns: columns,
      onItemSelected: onBranchSelected,
      searchQuery: searchQuery,
      searchPredicate: _searchPredicate,
      cellTextStyle: TextStyle(
        fontSize: 34.sp,
        color: Colors.black87,
      ),
      cellPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
    );
  }
}
