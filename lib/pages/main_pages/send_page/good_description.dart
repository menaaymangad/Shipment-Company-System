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

  const GoodsDescriptionPopup({
    super.key,
    required this.controller,
    required this.onDescriptionsSelected,
    required this.dbHelper,
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
    _loadDescriptions();
    _searchController.addListener(_filterList);
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

  Future<void> _loadDescriptions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final descriptions = await widget.dbHelper.getAllGoodsDescriptions();
      setState(() {
        goodsList = descriptions;
        filteredList = descriptions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load descriptions: $e';
      });
      _showError('Failed to load descriptions');
    }
  }

  Future<void> _addNewDescription() async {
    final descriptionEn = _newDescriptionEnController.text.trim();
    final descriptionAr = _newDescriptionArController.text.trim();
    final weight =
        double.tryParse(_weightController.text) ?? 0.0; // Parse weight

    if (descriptionEn.isEmpty || descriptionAr.isEmpty) {
      _showError('Both English and Arabic descriptions are required');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Create a new GoodsDescription object
      final newDescription = GoodsDescription(
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        weight: weight, // Include weight
      );

      // Insert the new description into the database
      await widget.dbHelper.insertGoodsDescription(newDescription);

      setState(() {
        _newDescriptionEnController.clear();
        _newDescriptionArController.clear();
        _weightController.clear(); // Clear the weight field
        isLoading = false;
      });

      // Refresh the list after adding
      await _loadDescriptions();
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
    final weight =
        double.tryParse(_weightController.text) ?? 0.0; // Add this line

    if (descriptionEn.isEmpty || descriptionAr.isEmpty) {
      _showError('Both English and Arabic descriptions are required');
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
          weight: weight, // Add this line
        ),
      );
      _newDescriptionEnController.clear();
      _newDescriptionArController.clear();
      _weightController.clear(); // Clear the weight field
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
      _showSuccess('Description deleted successfully');
    } catch (e) {
      _showError('Failed to delete description');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  // Other methods (e.g., _updateDescription, _deleteDescription, etc.) remain unchanged...

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              selectedForEdit == null
                  ? 'Add New Description'
                  : 'Edit Description',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newDescriptionEnController,
                    decoration: const InputDecoration(
                      hintText: 'English Description',
                      labelText: 'English Description *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _newDescriptionArController,
                    decoration: const InputDecoration(
                      hintText: 'Arabic Description',
                      labelText: 'Arabic Description *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_newDescriptionEnController.text.isEmpty ||
                        _newDescriptionArController.text.isEmpty) {
                      _showError(
                          'Both English and Arabic descriptions are required');
                      return;
                    }
                    selectedForEdit == null
                        ? _addNewDescription()
                        : _updateDescription();
                  },
                  child: Text(selectedForEdit == null ? 'Add' : 'Update'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search descriptions...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  return ListTile(
                    leading: Checkbox(
                      value: item.isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          item.isSelected = value ?? false;
                          if (item.isSelected) {
                            selectedDescriptions.add(item);
                          } else {
                            selectedDescriptions.remove(item);
                          }
                        });
                      },
                    ),
                    title: Text('${item.id} - ${item.descriptionEn}'),
                    subtitle: Text(item.descriptionAr),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.isSelected)
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              initialValue: item.quantity.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  item.quantity = int.tryParse(value) ?? 1;
                                });
                              },
                            ),
                          ),
                        SizedBox(width: 8.w),
                        if (item.isSelected)
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: item.weight.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Weight',
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  item.weight = double.tryParse(value) ?? 0.0;
                                });
                              },
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editItem(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteDescription(item),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
                      });
                    },
                    child: const Text('Cancel Edit'),
                  ),
                TextButton(
                  onPressed: () {
                    widget.onDescriptionsSelected(selectedDescriptions);
                    String descriptions = selectedDescriptions
                        .map((desc) =>
                            '${desc.descriptionEn} *${desc.quantity} (${desc.weight} KG)')
                        .join('\t - ');
                    widget.controller.text = descriptions;
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm Selection'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editItem(GoodsDescription item) {
    setState(() {
      selectedForEdit = item;
      _newDescriptionEnController.text = item.descriptionEn;
      _newDescriptionArController.text = item.descriptionAr;
    });
  }
}
