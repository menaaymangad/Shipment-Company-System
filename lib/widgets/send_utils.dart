import 'package:app/pages/main_pages/send_page/id_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(8.r),
        child: Center(child: child),
      ),
    );
  }

  static Widget buildInputRow({
    Widget? icon, // Change IconData? to Widget?
    required Widget child,
    Color? iconColor,
    VoidCallback? onIconPressed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) icon, // Use the provided widget as the icon
        if (icon != null)
          SizedBox(width: 8.w), // Add spacing only if icon is present
        Expanded(child: child),
      ],
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

  static Widget buildTextField({
    required String hint,
    int? maxLines = 1,
    String? label,
    bool optional = false,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    double? height = 50,
    ValueChanged<String>? onChanged,
    BuildContext? context,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    AutovalidateMode? autovalidateMode,
  }) {
    final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

    return ValueListenableBuilder<String?>(
      valueListenable: errorNotifier,
      builder: (context, errorMessage, child) {
        return SizedBox(
          height: height!.h,
          child: TextFormField(
            autovalidateMode: autovalidateMode,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            controller: controller,
            // onChanged: (value) {
            //   errorNotifier.value = validator?.call(value);
            //   onChanged?.call(value);
            // },
            maxLines: maxLines,
            enabled: enabled,
            keyboardType: keyboardType,
            validator: (value) {
              final error = validator?.call(value);
              errorNotifier.value = error;
              return error; // Pass the error back to the form
            },
            textAlign: TextAlign.start,
            style: TextStyle(
              color: _textColorLight,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              errorMaxLines: null,
              prefixIcon: errorMessage != null
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: IconButton(
                        icon: Icon(Icons.error_outline, color: Colors.red),
                        onPressed: () {
                          _showValidationErrorDialog(context, errorMessage);
                        },
                      ),
                    )
                  : null,
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
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
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
                  height: 0, fontSize: 0), // Hide the error message
            ),
          ),
        );
      },
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
    final ValueNotifier<String?> errorNotifier = ValueNotifier(null);
    return ValueListenableBuilder<String?>(
      valueListenable: errorNotifier,
      builder: (context, errorMessage, child) {
        return SizedBox(
          height: 50.h,
          child: DropdownButtonFormField<String>(
            value: validValue, // Use the valid value
            decoration: InputDecoration(
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.5,
                ),
              ),
              labelText: isRequired ? '$label *' : label,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: enabled ? Colors.grey[700] : Colors.grey[500],
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              filled: true,
              fillColor: enabled ? Colors.white : _lightGreyColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
              suffixIcon: suffixIcon,
              errorMaxLines: null,
              prefixIcon: errorMessage != null
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: IconButton(
                        icon: Icon(Icons.error_outline, color: Colors.red),
                        onPressed: () {
                          _showValidationErrorDialog(context, errorMessage);
                        },
                      ),
                    )
                  : null,
              errorStyle: const TextStyle(
                  height: 0, fontSize: 0), // Hide the error message
            ),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: enabled ? Colors.black87 : Colors.grey[600],
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp),
                ),
              );
            }).toList(),
            validator: (value) {
              final error = validator?.call(value);
              errorNotifier.value = error;
              return error; // Pass the error back to the form
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
      },
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convert the new value to uppercase
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
//
