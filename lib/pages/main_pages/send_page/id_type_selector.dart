// Modified SendUtils implementation for ID type selection
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IdTypeSelector extends StatefulWidget {
  final Function(IdType) onTypeSelected;
  final IdType? currentType;
  final Color? iconColor;
  const IdTypeSelector({
    super.key,
    required this.onTypeSelected,
    this.currentType,
    this.iconColor,
  });

  @override
  State<IdTypeSelector> createState() => _IdTypeSelectorState();
}

class _IdTypeSelectorState extends State<IdTypeSelector> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.all(0),
      iconSize: 24.sp,
      color: widget.iconColor,
      icon: Icon(Icons.assignment_ind_outlined),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: IdType.values.map((type) {
                  return ListTile(
                    title: Text(type.toString().split('.').last),
                    leading: Radio<IdType>(
                      value: type,
                      groupValue: widget.currentType,
                      onChanged: (IdType? value) {
                        if (value != null) {
                          widget.onTypeSelected(value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    onTap: () {
                      widget.onTypeSelected(type);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ID Type enum
enum IdType {
  drivingLicense,
  governmentId,
  nationalId,
  passportNumber,
  residentialId
}
