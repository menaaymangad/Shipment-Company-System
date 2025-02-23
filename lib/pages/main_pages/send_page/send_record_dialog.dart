import 'package:app/cubits/brach_cubit/branch_cubit.dart';
import 'package:app/cubits/brach_cubit/branch_states.dart';
import 'package:app/cubits/send_cubit/send_cubit.dart';
import 'package:app/cubits/send_cubit/send_state.dart';
import 'package:app/models/send_model.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class RecordsTableDialog extends StatefulWidget {
  final Function(SendRecord) onRecordSelected;

  const RecordsTableDialog({
    super.key,
    required this.onRecordSelected,
  });

  @override
  State<RecordsTableDialog> createState() => _RecordsTableDialogState();
}

class _RecordsTableDialogState extends State<RecordsTableDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _sortColumn;
  bool _sortAscending = true;
  String? _selectedAgent;
  String? _selectedBranch;
  final String _initialCodeNumber = 'BA-2400001';
  @override
  void initState() {
    super.initState();

    context.read<SendRecordCubit>().fetchAllSendRecords();
    context.read<BranchCubit>().fetchBranches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SendRecord> _getFilteredAndSortedRecords(List<SendRecord> records) {
    // First filter by search query
    var filteredRecords = _searchQuery.isEmpty
        ? records
        : records.where((record) {
            final search = _searchQuery.toLowerCase();
            return record.codeNumber?.toLowerCase().contains(search) == true ||
                record.truckNumber?.toLowerCase().contains(search) == true ||
                record.senderName?.toLowerCase().contains(search) == true ||
                record.receiverName?.toLowerCase().contains(search) == true ||
                record.receiverCity?.toLowerCase().contains(search) == true ||
                record.senderPhone?.toLowerCase().contains(search) == true ||
                record.receiverPhone?.toLowerCase().contains(search) == true;
          }).toList();

    // Then filter by agent
    if (_selectedAgent != null && _selectedAgent!.isNotEmpty) {
      filteredRecords = filteredRecords
          .where((record) => record.agentName == _selectedAgent)
          .toList();
    }

    // Then filter by branch
    if (_selectedBranch != null && _selectedBranch!.isNotEmpty) {
      filteredRecords = filteredRecords
          .where((record) => record.branchName == _selectedBranch)
          .toList();
    }

    // Then sort if a sort column is selected
    if (_sortColumn != null) {
      filteredRecords.sort((a, b) {
        var aValue = _getSortValue(a, _sortColumn!);
        var bValue = _getSortValue(b, _sortColumn!);
        return _sortAscending
            ? Comparable.compare(aValue ?? '', bValue ?? '')
            : Comparable.compare(bValue ?? '', aValue ?? '');
      });
    }

    return filteredRecords;
  }

  dynamic _getSortValue(SendRecord record, String column) {
    switch (column) {
      case 'date':
        return record.date;
      case 'code':
        return record.codeNumber;
      case 'truck':
        return record.truckNumber;
      case 'sender':
        return record.senderName;
      case 'receiver':
        return record.receiverName;
      case 'city':
        return record.receiverCity;
      default:
        return '';
    }
  }

  Widget _buildAutoSizeCell(String text, {bool isNumeric = false}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      child: AutoSizeText(
        text,
        style: const TextStyle(fontSize: 14),
        maxLines: 2,
        minFontSize: 10,
        overflow: TextOverflow.ellipsis,
        textAlign: isNumeric ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(190.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AppBar(
                        elevation: 1,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        title: const Text(
                          'Saved Records',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.r),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search records...',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  prefixIcon: const Icon(Icons.search,
                                      color: Colors.black54),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              color: Colors.black54),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 400.w),
                            BlocBuilder<BranchCubit, BranchState>(
                              builder: (context, state) {
                                final agents = state is BranchLoadedState
                                    ? state.branches
                                        .map((branch) =>
                                            branch.contactPersonName)
                                        .toSet()
                                        .toList()
                                    : <String>[];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: SizedBox(
                                    width: 200.w,
                                    child: Center(
                                      child: DropdownButton<String>(
                                        value: _selectedAgent,
                                        hint: const Text('Agent'),
                                        items: agents.map((agent) {
                                          return DropdownMenuItem<String>(
                                            value: agent,
                                            child: Text(agent),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedAgent = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Branch Dropdown
                            BlocBuilder<BranchCubit, BranchState>(
                              builder: (context, state) {
                                final branches = state is BranchLoadedState
                                    ? state.branches
                                        .map((branch) => branch.branchName)
                                        .toSet()
                                        .toList()
                                    : <String>[];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: SizedBox(
                                    width: 200.w,
                                    child: Center(
                                      child: DropdownButton<String>(
                                        value: _selectedBranch,
                                        hint: const Text('Branch'),
                                        items: branches.map((branch) {
                                          return DropdownMenuItem<String>(
                                            value: branch,
                                            child: Text(branch),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedBranch = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              body: BlocBuilder<SendRecordCubit, SendRecordState>(
                builder: (context, state) {
                  if (state is SendRecordLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is SendRecordListLoaded) {
                   
                    final filteredRecords =
                        _getFilteredAndSortedRecords(state.sendRecords);

                    if (filteredRecords.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No matching records found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return DataTable2(
                      scrollController: ScrollController(),
                      horizontalScrollController: ScrollController(),
                      headingRowColor: WidgetStatePropertyAll(Colors.grey[100]),
                      dataRowHeight: 60,
                      headingRowHeight: 56,
                      horizontalMargin: 16,
                      columnSpacing: 16,
                      showCheckboxColumn: false,
                      minWidth: 2000,
                      columns: [
                        DataColumn2(
                          label: _buildAutoSizeCell('Date'),
                          size: ColumnSize.M,
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumn = 'date';
                              _sortAscending = ascending;
                            });
                          },
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Code'),
                          size: ColumnSize.M,
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumn = 'code';
                              _sortAscending = ascending;
                            });
                          },
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Truck'),
                          size: ColumnSize.M,
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumn = 'truck';
                              _sortAscending = ascending;
                            });
                          },
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Sender'),
                          size: ColumnSize.M,
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumn = 'sender';
                              _sortAscending = ascending;
                            });
                          },
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Sender Phone'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Sender ID'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Receiver'),
                          size: ColumnSize.M,
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumn = 'receiver';
                              _sortAscending = ascending;
                            });
                          },
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Receiver Phone'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Country'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('City'),
                          size: ColumnSize.M,
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumn = 'city';
                              _sortAscending = ascending;
                            });
                          },
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Street'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('ZIP'),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Weight (kg)',
                              isNumeric: true),
                          size: ColumnSize.S,
                          numeric: true,
                        ),
                        DataColumn2(
                          label:
                              _buildAutoSizeCell('Good Value', isNumeric: true),
                          size: ColumnSize.S,
                          numeric: true,
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Insurance %',
                              isNumeric: true),
                          size: ColumnSize.S,
                          numeric: true,
                        ),
                        DataColumn2(
                          label:
                              _buildAutoSizeCell('Total Cost', isNumeric: true),
                          size: ColumnSize.S,
                          numeric: true,
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Agent'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: _buildAutoSizeCell('Branch'),
                          size: ColumnSize.M,
                        ),
                        const DataColumn2(
                          label: Text('Actions'),
                          size: ColumnSize.M,
                        ),
                      ],
                      rows: filteredRecords.map((record) {
                        return DataRow2(
                          onTap: () => _showRecordOptionsDialog(record),
                          cells: [
                            DataCell(_buildAutoSizeCell(record.date ?? '')),
                            DataCell(
                                _buildAutoSizeCell(record.codeNumber ?? '')),
                            DataCell(
                                _buildAutoSizeCell(record.truckNumber ?? '')),
                            DataCell(
                                _buildAutoSizeCell(record.senderName ?? '')),
                            DataCell(
                                _buildAutoSizeCell(record.senderPhone ?? '')),
                            DataCell(_buildAutoSizeCell(
                                record.senderIdNumber ?? '')),
                            DataCell(
                                _buildAutoSizeCell(record.receiverName ?? '')),
                            DataCell(
                                _buildAutoSizeCell(record.receiverPhone ?? '')),
                            DataCell(_buildAutoSizeCell(
                                record.receiverCountry ?? '')),
                            DataCell(
                                _buildAutoSizeCell(record.receiverCity ?? '')),
                            DataCell(
                                _buildAutoSizeCell(record.streetName ?? '')),
                            DataCell(_buildAutoSizeCell(record.zipCode ?? '')),
                            DataCell(_buildAutoSizeCell(
                              record.totalWeightKg?.toStringAsFixed(2) ?? '',
                              isNumeric: true,
                            )),
                            DataCell(_buildAutoSizeCell(
                              record.goodsValue?.toStringAsFixed(2) ?? '',
                              isNumeric: true,
                            )),
                            DataCell(_buildAutoSizeCell(
                              record.insurancePercent?.toStringAsFixed(1) ?? '',
                              isNumeric: true,
                            )),
                            DataCell(_buildAutoSizeCell(
                              record.totalPostCost?.toStringAsFixed(2) ?? '',
                              isNumeric: true,
                            )),
                            DataCell(
                                _buildAutoSizeCell(record.agentName ?? '')),
                            DataCell(
                                _buildAutoSizeCell(record.branchName ?? '')),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: Colors.blue[600],
                                    tooltip: 'Edit Record',
                                    onPressed: () {
                                      widget.onRecordSelected(record);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      color: Colors.red[600],
                                      tooltip: 'Delete Record',
                                      onPressed: () {
                                        setState(() {
                                          _showDeleteConfirmation(
                                              context, record);
                                        });
                                      })
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  }
                  return const Center(child: Text('No records found'));
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, SendRecord record) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Delete Record'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete record with code ${record.codeNumber}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              context
                  .read<SendRecordCubit>()
                  .deleteSendRecord(record.id!, record.codeNumber!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Record deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRecordOptionsDialog(SendRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Options - ${record.codeNumber}'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _handleNewRecord(record),
              child: const Text('New'),
            ),
            ElevatedButton(
              onPressed: () => _handleEditRecord(record),
              child: const Text('Edit'),
            ),
            ElevatedButton(
              onPressed: () => _handleViewRecord(record),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNewRecord(SendRecord originalRecord) async {
    Navigator.pop(context); // Close options dialog

    // Get all records to find the latest code for this truck AND branch
    final records = await context.read<SendRecordCubit>().fetchAllSendRecords();

    // Filter records for the same truck AND branch
    final truckBranchRecords = records
        .where((r) =>
            r.truckNumber == originalRecord.truckNumber &&
            r.branchName == originalRecord.branchName)
        .toList();

    // Find latest code for this truck and branch combination
    String latestCode = truckBranchRecords.isNotEmpty
        ? truckBranchRecords
            .map((r) => r.codeNumber ?? '')
            .reduce((a, b) => a.compareTo(b) > 0 ? a : b)
        : _initialCodeNumber; // Use initial code if no records exist

    // Generate new code based on latest code for this truck and branch
    final newCodeNumber = _incrementCodeNumber(latestCode);

    // Create new record with preserved truck number and new code
    final newRecord = originalRecord.copyWith(
      codeNumber: newCodeNumber,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      truckNumber: originalRecord.truckNumber, // Preserve truck number
      branchName: originalRecord.branchName, // Preserve branch name

      // Reset calculated fields
      boxNumber: 0,
      palletNumber: 0,
      realWeightKg: 0,
      length: 0,
      width: 0,
      height: 0,
      isDimensionCalculated: false,
      additionalKg: 0,
      totalWeightKg: 0,
      goodsDescription: '',
      insurancePercent: 0,
      goodsValue: 0,
      doorToDoorPrice: 0,
      pricePerKg: 0,
      minimumPrice: 0,
      insuranceAmount: 0,
      customsCost: 0,
      exportDocCost: 0,
      boxPackingCost: 0,
      doorToDoorCost: 0,
      postSubCost: 0,
      discountAmount: 0,
      totalPostCost: 0,
      totalPostCostPaid: 0,
      unpaidAmount: 0,
      totalCostEuroCurrency: 0,
      unpaidAmountEuro: 0,
    );

    Navigator.pop(context, {'action': 'new', 'record': newRecord});
  }

  String _incrementCodeNumber(String codeNumber) {
    try {
      final parts = codeNumber.split('-');
      if (parts.length != 2) return codeNumber;

      final prefix = parts[0];
      final numericPart = parts[1];

      if (numericPart.length != 7) return codeNumber;

      final yearPart = numericPart.substring(0, 2);
      final sequence = numericPart.substring(2);

      final newSequence = (int.parse(sequence) + 1).toString().padLeft(5, '0');
      return '$prefix-$yearPart$newSequence';
    } catch (e) {
      print('Error incrementing code: $e');
      return codeNumber;
    }
  }

  void _handleEditRecord(SendRecord record) {
    Navigator.pop(context); // Close the options dialog
    Navigator.pop(context,
        {'action': 'edit', 'record': record}); // Close the table dialog
  }

  void _handleViewRecord(SendRecord record) {
    Navigator.pop(context); // Close the options dialog
    Navigator.pop(context,
        {'action': 'view', 'record': record}); // Close the table dialog
  }
}
