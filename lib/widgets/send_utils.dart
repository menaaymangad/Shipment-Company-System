import 'package:app/cubits/theme_cubit/theme_cubit_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SendUtils {
  // Custom color palette for consistent design
  static Color primaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color secondaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color getBackgroundColor(BuildContext context) {
    final isDark = context.watch<SendThemeCubit>().state;
    return isDark ? Colors.grey[850]! : Colors.white;
  }

  static Color getTextColor(BuildContext context) {
    final isDark = context.watch<SendThemeCubit>().state;
    return isDark ? Colors.white : Colors.black87;
  }

  /// Builds a card with enhanced styling and optional title
  static Widget buildCard({
    required BuildContext context,
    String? title,
    required Widget child,
    double? height,
    Color? backgroundColor,
  }) {
    Theme.of(context);
    final isDark = context.watch<SendThemeCubit>().state;
    return Card(
      elevation: 4,
      color: backgroundColor ?? (isDark ? Colors.black : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
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
    required BuildContext context,
    Widget? icon,
    required Widget child,
    Color? iconColor,
    VoidCallback? onIconPressed,
    String? label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            IconTheme(
              data: IconThemeData(
                size: 24.sp,
                color: iconColor ?? getTextColor(context),
              ),
              child: icon,
            ),
          if (icon != null) SizedBox(width: 8.w),
          if (label != null)
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: getTextColor(context),
              ),
            ),
          if (label != null) SizedBox(width: 24.w),
          Expanded(
              child: child), // Ensure child expands to fill available width
        ],
      ),
    );
  }

  static void _showValidationErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Validation Error',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: getTextColor(context),
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: getTextColor(context),
            ),
          ),
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
    required BuildContext context,
    required String hint,
    int? maxLines = 1,
    String? label,
    bool optional = false,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    double? height = 50, // Fixed height for consistency
    ValueChanged<String>? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    AutovalidateMode? autovalidateMode,
    double? padding = 48, // Default padding for all fields
  }) {
    final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

    final isDark = context.watch<SendThemeCubit>().state;
    return ValueListenableBuilder<String?>(
      valueListenable: errorNotifier,
      builder: (context, errorMessage, child) {
        return Container(
          height: height!.h,
          width: double.infinity, // Ensure full width
          padding: EdgeInsets.symmetric(horizontal: padding!.w),
          child: TextFormField(
            autovalidateMode: autovalidateMode,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            controller: controller,
            maxLines: maxLines,
            enabled: enabled,
            keyboardType: keyboardType,
            validator: (value) {
              final error = validator?.call(value);
              errorNotifier.value = error;
              return error;
            },
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: enabled
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600]),
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
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.5,
                ),
              ),
              labelText: label ?? hint,
              labelStyle: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: enabled
                    ? (isDark ? Colors.white : Colors.grey[700])
                    : (isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey[500]),
              ),
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              isDense: false,
              isCollapsed: false,
              filled: true,
              fillColor: isDark
                  ? Colors.grey[850]
                  : Theme.of(context).colorScheme.surface,
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
                borderSide: BorderSide(
                  color: primaryColor(context),
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              suffixText: optional ? 'Optional' : null,
              suffixStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.grey[500],
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
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
    double? height = 50, // Fixed height for consistency
    String? Function(String?)? validator,
    double? padding = 48, // Default padding for all fields
  }) {
    final validValue =
        items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

    final isDark = context.watch<SendThemeCubit>().state;
    return ValueListenableBuilder<String?>(
      valueListenable: errorNotifier,
      builder: (context, errorMessage, child) {
        return Container(
          height: height!.h,
          width: double.infinity, // Ensure full width
          padding: EdgeInsets.symmetric(horizontal: padding!.w),
          child: DropdownButtonFormField<String>(
            value: validValue,
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
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: enabled
                    ? (isDark ? Colors.white : Colors.grey[700])
                    : (isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey[500]),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.grey[850]
                  : Theme.of(context).colorScheme.surface,
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
                borderSide: BorderSide(
                  color: primaryColor(context),
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
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: enabled
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600]),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: isDark
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
            validator: (value) {
              final error = validator?.call(value);
              errorNotifier.value = error;
              return error;
            },
            onChanged: enabled ? onChanged : null,
            isExpanded: true, // Ensures the dropdown fills the available width
            icon: Icon(
              Icons.arrow_drop_down,
              size: 30.h,
              color: enabled ? primaryColor(context) : Colors.grey[400],
            ),
            dropdownColor: isDark
                ? Colors.grey[850]
                : Theme.of(context).colorScheme.surface,
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
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
