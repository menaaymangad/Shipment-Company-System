import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/branches_model.dart';

class BranchDataTableEnhanced extends StatelessWidget {
  final List<Branch> branches;
  final Function(Branch) onBranchSelected;
  final String searchQuery;

  const BranchDataTableEnhanced({
    super.key,
    required this.branches,
    required this.onBranchSelected,
    this.searchQuery = '',
  });

  List<Branch> _filterBranches(List<Branch> branches, String query) {
    if (query.isEmpty) return branches;

    return branches.where((branch) {
      final searchLower = query.toLowerCase();
      return branch.branchName.toLowerCase().contains(searchLower) ||
          branch.contactPersonName.toLowerCase().contains(searchLower) ||
          branch.branchCompany.toLowerCase().contains(searchLower) ||
          branch.phoneNo1.toLowerCase().contains(searchLower) ||
          branch.phoneNo2.toLowerCase().contains(searchLower) ||
          branch.address.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBranches = _filterBranches(branches, searchQuery);

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
          columnSpacing: 16.w,
          dataRowMinHeight: 56.h,
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          headingTextStyle:
              TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          dataTextStyle: TextStyle(fontSize: 18.sp),
          columns: [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Branch Name')),
            DataColumn(label: Text('Contact Person')),
            DataColumn(label: Text('Company')),
            DataColumn(label: Text('Phone 1')),
            DataColumn(label: Text('Phone 2')),
            DataColumn(label: Text('Address')),
          ],
          rows: filteredBranches.map((branch) {
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                return states.contains(WidgetState.selected)
                    ? Colors.grey[300]
                    : null;
              }),
              cells: [
                DataCell(Text(
                  '${branch.id ?? ""}',
                )),
                DataCell(Text(branch.branchName)),
                DataCell(Text(branch.contactPersonName)),
                DataCell(Text(branch.branchCompany)),
                DataCell(Text(branch.phoneNo1)),
                DataCell(Text(branch.phoneNo2)),
                DataCell(Text(branch.address)),
              ],
              onSelectChanged: (_) => onBranchSelected(branch),
            );
          }).toList(),
        ),
      ),
    );
  }
}
