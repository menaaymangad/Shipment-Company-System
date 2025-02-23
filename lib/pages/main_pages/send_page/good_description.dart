import 'package:app/helper/good_description_db_helper.dart';
import 'package:app/helper/sql_helper.dart';
import 'package:app/models/good_description_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GoodsDescriptionPopup extends StatefulWidget {
  final TextEditingController controller;
  final Function(List<GoodsDescription>) onDescriptionsSelected;
  final DatabaseHelper dbHelper;
  final List<GoodsDescription> initialSelectedDescriptions;
  final bool hasExistingValue;

  const GoodsDescriptionPopup({
    super.key,
    required this.controller,
    required this.onDescriptionsSelected,
    required this.dbHelper,
    this.initialSelectedDescriptions = const [],
    required this.hasExistingValue,
  });

  @override
  State<GoodsDescriptionPopup> createState() => _GoodsDescriptionPopupState();
}

class _GoodsDescriptionPopupState extends State<GoodsDescriptionPopup> {
  final TextEditingController _newDescriptionEnController =
      TextEditingController();
  final TextEditingController _newDescriptionArController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  List<GoodsDescription> goodsList = [];
  List<GoodsDescription> filteredList = [];
  List<GoodsDescription> selectedDescriptions = [];
  GoodsDescription? selectedForEdit;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    selectedDescriptions = List.from(
        widget.initialSelectedDescriptions); // Copy initial selections
    _loadDescriptions();
    _searchController.addListener(_filterList);
  }

  Future<void> _loadDescriptions() async {
    setState(() => isLoading = true);
    try {
      final descriptions = await widget.dbHelper.getAllGoodsDescriptions();

      // Merge selectedDescriptions with database values, preserving quantity and weight
      final mergedSelections = selectedDescriptions.map((selected) {
        final dbItem = descriptions.firstWhere(
          (d) => d.id == selected.id,
          orElse: () => selected, // Keep existing if not in DB
        );
        return selected.copyWith(
          descriptionEn: dbItem.descriptionEn,
          descriptionAr: dbItem.descriptionAr,
          weight: selected.weight ??
              dbItem.weight, // Preserve selected weight if exists
          quantity:
              selected.quantity ?? 1, // Preserve selected quantity if exists
        );
      }).toList();

      setState(() {
        goodsList = descriptions;
        filteredList = descriptions;
        selectedDescriptions = mergedSelections;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _toggleSelection(GoodsDescription item) {
    setState(() {
      if (selectedDescriptions.any((d) => d.id == item.id)) {
        selectedDescriptions.removeWhere((d) => d.id == item.id);
      } else {
        // Add item with initial quantity and weight from DB or defaults
        selectedDescriptions.add(item.copyWith(
          quantity: item.quantity ?? 1,
          weight: item.weight ?? 0.0,
        ));
      }
    });
  }

  void _filterList() {
    setState(() {
      if (_searchController.text.isEmpty) {
        filteredList = List.from(goodsList);
      } else {
        filteredList = goodsList
            .where((item) =>
                item.descriptionEn
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ||
                item.descriptionAr
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _addNewDescription() async {
    final descriptionEn = _newDescriptionEnController.text.trim();
    final descriptionAr = _newDescriptionArController.text.trim();
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final weight = double.tryParse(_weightController.text) ?? 0.0;

    if (descriptionEn.isEmpty || descriptionAr.isEmpty || weight <= 0) {
      _showError(
          'All fields (English, Arabic, Quantity, and Weight) are required, and weight must be positive');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final newDescription = GoodsDescription(
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        weight: weight,
      );

      final id = await widget.dbHelper.insertGoodsDescription(newDescription);

      setState(() {
        _newDescriptionEnController.clear();
        _newDescriptionArController.clear();
        _quantityController.clear();
        _weightController.clear();
        isLoading = false;
      });

      await _loadDescriptions();
      selectedDescriptions
          .add(newDescription.copyWith(id: id, quantity: quantity));
      _showSuccess('Description added successfully');
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      _showError(e.toString());
      if (kDebugMode) {
        print('Failed to add description: $e');
      }
    }
  }

  Future<void> _updateDescription() async {
    if (selectedForEdit == null) return;

    final descriptionEn = _newDescriptionEnController.text.trim();
    final descriptionAr = _newDescriptionArController.text.trim();
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final weight = double.tryParse(_weightController.text) ?? 0.0;

    if (descriptionEn.isEmpty || descriptionAr.isEmpty || weight <= 0) {
      _showError(
          'All fields (English, Arabic, Quantity, and Weight) are required, and weight must be positive');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await widget.dbHelper.updateGoodsDescription(
        GoodsDescription(
          id: selectedForEdit!.id,
          descriptionEn: descriptionEn,
          descriptionAr: descriptionAr,
          weight: weight,
        ),
      );
      _newDescriptionEnController.clear();
      _newDescriptionArController.clear();
      _quantityController.clear();
      _weightController.clear();
      final index =
          selectedDescriptions.indexWhere((d) => d.id == selectedForEdit!.id);
      if (index != -1) {
        selectedDescriptions[index] = selectedDescriptions[index].copyWith(
          descriptionEn: descriptionEn,
          descriptionAr: descriptionAr,
          weight: weight,
          quantity: quantity,
        );
      }
      selectedForEdit = null;
      await _loadDescriptions();
      _showSuccess('Description updated successfully');
    } catch (e) {
      _showError('Failed to update description');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to update description: $e';
      });
    }
  }

  Future<void> _deleteDescription(GoodsDescription description) async {
    try {
      await widget.dbHelper.deleteGoodsDescription(description.id!);
      await _loadDescriptions();
      setState(() {
        selectedDescriptions.removeWhere((desc) => desc.id == description.id);
      });
      _showSuccess('Description deleted successfully');
    } catch (e) {
      _showError('Failed to delete description');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editItem(GoodsDescription item) {
    setState(() {
      selectedForEdit = item;
      _newDescriptionEnController.text = item.descriptionEn;
      _newDescriptionArController.text = item.descriptionAr;
      _quantityController.text = item.quantity.toString();
      _weightController.text = (item.weight ?? 0.0).toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            Text(
              selectedForEdit == null
                  ? 'Add New Description'
                  : 'Edit Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newDescriptionEnController,
                    decoration: InputDecoration(
                      hintText: 'English Description',
                      labelText: 'English Description *',
                      labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87),
                      hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.grey),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: isDarkMode ? Colors.white : Colors.blue)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color:
                                  isDarkMode ? Colors.white54 : Colors.grey)),
                    ),
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _newDescriptionArController,
                    decoration: InputDecoration(
                      hintText: 'Arabic Description',
                      labelText: 'Arabic Description *',
                      labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87),
                      hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.grey),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: isDarkMode ? Colors.white : Colors.blue)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color:
                                  isDarkMode ? Colors.white54 : Colors.grey)),
                    ),
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: () {
                    if (_newDescriptionEnController.text.isEmpty ||
                        _newDescriptionArController.text.isEmpty ||
                        _quantityController.text.isEmpty ||
                        _weightController.text.isEmpty) {
                      _showError(
                          'All fields (English, Arabic, Quantity, and Weight) are required');
                      return;
                    }
                    selectedForEdit == null
                        ? _addNewDescription()
                        : _updateDescription();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.blue : Colors.blue),
                  child: Text(
                    selectedForEdit == null ? 'Add' : 'Update',
                    style: TextStyle(
                        color: isDarkMode ? Colors.black87 : Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search descriptions...',
                prefixIcon: Icon(Icons.search,
                    color: isDarkMode ? Colors.white70 : Colors.black87),
                hintStyle:
                    TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: isDarkMode ? Colors.white : Colors.blue)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: isDarkMode ? Colors.white54 : Colors.grey)),
              ),
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  // Find the selected item if it exists, otherwise use defaults
                  final selectedItem = selectedDescriptions.firstWhere(
                    (d) => d.id == item.id,
                    orElse: () =>
                        item.copyWith(quantity: 1, weight: item.weight ?? 0.0),
                  );

                  return ListTile(
                    leading: Checkbox(
                      value: selectedDescriptions.any((d) => d.id == item.id),
                      onChanged: (value) => _toggleSelection(item),
                      activeColor: isDarkMode ? Colors.blue : Colors.blue,
                      checkColor: isDarkMode ? Colors.white : Colors.white,
                    ),
                    title: Text(
                      '${item.id} - ${item.descriptionEn}',
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                    subtitle: Text(
                      item.descriptionAr,
                      style: TextStyle(
                          color:
                              isDarkMode ? Colors.white70 : Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedDescriptions
                            .any((d) => d.id == item.id)) ...[
                          SizedBox(
                            width: 60.w,
                            child: TextFormField(
                              initialValue: selectedItem.quantity
                                  .toString(), // Use selected quantity
                              onChanged: (value) {
                                setState(() {
                                  final index = selectedDescriptions
                                      .indexWhere((d) => d.id == item.id);
                                  if (index != -1) {
                                    selectedDescriptions[index] =
                                        selectedDescriptions[index].copyWith(
                                      quantity: int.tryParse(value) ?? 1,
                                    );
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Qty',
                                hintStyle: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white54
                                        : Colors.grey),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.blue)),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: isDarkMode
                                            ? Colors.white54
                                            : Colors.grey)),
                              ),
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          SizedBox(
                            width: 80.w,
                            child: TextFormField(
                              initialValue: (selectedItem.weight ?? 0.0)
                                  .toStringAsFixed(1), // Use selected weight
                              onChanged: (value) {
                                setState(() {
                                  final index = selectedDescriptions
                                      .indexWhere((d) => d.id == item.id);
                                  if (index != -1) {
                                    selectedDescriptions[index] =
                                        selectedDescriptions[index].copyWith(
                                      weight: double.tryParse(value) ?? 0.0,
                                    );
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Weight',
                                hintStyle: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white54
                                        : Colors.grey),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.blue)),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: isDarkMode
                                            ? Colors.white54
                                            : Colors.grey)),
                              ),
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                        IconButton(
                          icon: Icon(Icons.edit,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87),
                          onPressed: () => _editItem(item),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteDescription(item),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (selectedForEdit != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedForEdit = null;
                        _newDescriptionEnController.clear();
                        _newDescriptionArController.clear();
                        _quantityController.clear();
                        _weightController.clear();
                      });
                    },
                    child: Text(
                      'Cancel Edit',
                      style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    final updatedSelections = selectedDescriptions
                        .where((selected) =>
                            goodsList.any((item) => item.id == selected.id))
                        .toList();
                    widget.onDescriptionsSelected(updatedSelections);
                    widget.controller.text = updatedSelections
                        .map((d) =>
                            '${d.quantity} - ${d.descriptionEn} (${d.quantity}x${d.weight?.toStringAsFixed(1) ?? '0.0'}kg)')
                        .join('\n');
                    Navigator.pop(context);
                  },
                  child: Text(
                    widget.hasExistingValue ? 'Update' : 'Confirm',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension GoodsDescriptionExtension on GoodsDescription {
  GoodsDescription copyWith({
    int? id,
    String? descriptionEn,
    String? descriptionAr,
    double? weight,
    int? quantity,
  }) {
    return GoodsDescription(
      id: id ?? this.id,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
    );
  }
}
