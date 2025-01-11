import 'package:app/pages/main_pages/send_page/id_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SendUtils {
  // Custom color palette for consistent design
  static const Color primaryColor = Color(0xFF2C3E50);
  static const Color secondaryColor = Color(0xFF34495E);
  static const Color _lightGreyColor = Color(0xFFF4F6F7);
  static const Color _textColorLight = Color(0xFF4A4A4A);

  /// Builds a card with enhanced styling and optional title
  static Widget buildCard({
    String? title,
    required Widget child,
    double? height,
    Color? backgroundColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(10.r),
        child: Center(child: child),
      ),
    );
  }

  /// Builds an input row with icon and child widget
  static Widget buildInputRow({
    IconData? icon,
    required Widget child,
    Color? iconColor,
    bool isIconButton =
        false, // Add this parameter to toggle between Icon and IconButton
    VoidCallback? onIconPressed,
    // Add this parameter for IconButton's onPressed
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) // Only add the icon if it's provided
          isIconButton
              ? IconButton(
                  icon: Icon(
                    icon,
                    size: 40.h,
                    color: iconColor ?? secondaryColor,
                  ),
                  onPressed: onIconPressed, // Handle the icon button press
                )
              : Icon(
                  icon,
                  size: 40.h,
                  color: iconColor ?? secondaryColor,
                ),
        if (icon != null)
          SizedBox(width: 12.w), // Add spacing only if icon is present
        Expanded(child: child),
      ],
    );
  }

  static Widget buildIdInputRow({
    IconData? icon,
    required Widget child,
    Color? iconColor,
    bool isIconButton =
        false, // Add this parameter to toggle between Icon and IconButton
    VoidCallback? onIconPressed,
    required Function(IdType) onTypeSelected,
    IdType? currentType, // Add this parameter for IconButton's onPressed
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IdTypeSelector(
            currentType: currentType,
            onTypeSelected: onTypeSelected,
          ),
          SizedBox(width: 12.w), // Add spacing only if icon is present
          Expanded(child: child),
        ],
      ),
    );
  }

  static void _showValidationErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Validation Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Builds a custom text field with enhanced styling
  static Widget buildTextField({
    required String hint,
    int? maxLines,
    String? label,
    bool optional = false,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    double? height,
    ValueChanged<String>? onChanged,
    BuildContext? context, // Add context parameter for showing dialogs
  }) {
    return SizedBox(
      height: height ?? 85.h, // Fixed height to prevent shrinking
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: (value) {
          if (validator != null) {
            final errorMessage = validator(value);
            if (errorMessage != null && context != null) {
              _showValidationErrorDialog(context, errorMessage);
            }
            return null; // Return null to avoid showing the error below the field
          }
          return null;
        },
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _textColorLight,
          fontSize: 24.sp,
        ),
        decoration: InputDecoration(
          errorMaxLines: null,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          labelText: hint,
          labelStyle: TextStyle(
            color: enabled ? Colors.grey[700] : Colors.grey[500],
            fontSize: 24.sp,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 24.sp,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ),
          isDense: false,
          isCollapsed: false,
          filled: true,
          fillColor: enabled ? Colors.white : _lightGreyColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          suffixText: optional ? 'Optional' : null,
          suffixStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 20.sp,
          ),
          errorStyle: const TextStyle(
              height: 0), // Hide the error message below the field
        ),
      ),
    );
  }

  static Widget buildDropdownField({
    required BuildContext context,
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool isRequired = true,
    bool enabled = true,
    Widget? suffixIcon,
    double? height,
    String? Function(String?)? validator,
  }) {
    // Ensure the value is valid or set a default value
    final validValue =
        items.contains(value) ? value : (items.isNotEmpty ? items.first : null);

    return SizedBox(
      height: 80.h,
      child: DropdownButtonFormField<String>(
        value: validValue, // Use the valid value
        decoration: InputDecoration(
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(
            fontSize: 24.sp,
            color: enabled ? Colors.grey[700] : Colors.grey[500],
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : _lightGreyColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          suffixIcon: suffixIcon,
          errorMaxLines: null,
          errorStyle: const TextStyle(height: 0),
        ),
        style: TextStyle(
          fontSize: 24.sp,
          color: enabled ? Colors.black87 : Colors.grey[600],
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24.sp),
            ),
          );
        }).toList(),
        validator: (value) {
          if (validator != null) {
            final errorMessage = validator(value);
            if (errorMessage != null) {
              _showValidationErrorDialog(context, errorMessage);
            }
            return null; // Return null to avoid showing the error below the field
          }
          return null;
        },
        onChanged: enabled ? onChanged : null,
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          size: 30.h,
          color: enabled ? primaryColor : Colors.grey[400],
        ),
        dropdownColor: Colors.white,
        alignment: AlignmentDirectional.center,
      ),
    );
  }
}

//
